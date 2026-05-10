from fastapi import FastAPI, File, UploadFile, Depends
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from database import connect_db, get_db, get_collection
import easyocr
import os
import shutil
import json
from datetime import datetime
from ai_service import summarize_text, process_image_with_gemini
from auth import get_password_hash, verify_password, create_access_token, decode_access_token, get_current_user
from contextlib import asynccontextmanager
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    global reader
    # Connect to MongoDB when the server starts
    print("Startup: Connecting to MongoDB...")
    connect_db()
    
    # Pre-load EasyOCR model
    print("Startup: Pre-loading EasyOCR fallback model (this may take a moment)...")
    try:
        reader = easyocr.Reader(['en'], gpu=False, verbose=False)
        print("Startup: EasyOCR model loaded successfully.")
    except Exception as e:
        print(f"Startup Error: Failed to load EasyOCR: {e}")
    
    print("Server started! Ready for requests.")
    yield
    print("Shutting down...")

# Initialize the FastAPI App
app = FastAPI(
    title="AI Study Camera API",
    description="Backend for the Snap & Learn mobile application",
    version="1.0.0",
    lifespan=lifespan
)

# Allow Flutter app to communicate with the backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def read_root():
    return {"message": "Welcome to the AI Study Camera API!"}

@app.post("/api/register")
async def register(user_data: dict):
    try:
        username = user_data.get("username")
        password = user_data.get("password")
        
        print(f"Registering user: {username}")
        
        if not username or not password:
            return {"status": "error", "message": "Username and password are required"}
            
        users_collection = get_collection("users")
        if users_collection is None:
            print("Error: users_collection is None. Database connection failed.")
            return {"status": "error", "message": "Database connection error. Please check your MONGO_URI."}
            
        if users_collection.find_one({"username": username}):
            print(f"Error: Username '{username}' already exists.")
            return {"status": "error", "message": "Username already exists"}
            
        hashed_password = get_password_hash(password)
        users_collection.insert_one({
            "username": username,
            "password": hashed_password
        })
        print(f"Success: User '{username}' registered successfully.")
        return {"status": "success", "message": "User registered successfully"}
    except Exception as e:
        print(f"Exception during registration: {e}")
        return {"status": "error", "message": f"Internal server error: {str(e)}"}

@app.post("/api/login")
async def login(user_data: dict):
    try:
        username = user_data.get("username")
        password = user_data.get("password")
        
        print(f"Login attempt received for: {username}")
        
        users_collection = get_collection("users")
        if users_collection is None:
            print("Login Error: Database is NOT connected.")
            return {"status": "error", "message": "Database connection error."}
            
        user = users_collection.find_one({"username": username})
        
        if not user or not verify_password(password, user["password"]):
            print(f"Login Error: Invalid credentials for {username}")
            return {"status": "error", "message": "Invalid username or password"}
            
        access_token = create_access_token(data={"sub": username})
        print(f"Login Success: {username} is now logged in.")
        return {
            "status": "success", 
            "access_token": access_token,
            "username": username
        }
    except Exception as e:
        print(f"CRITICAL LOGIN ERROR: {e}")
        return {"status": "error", "message": f"Internal server error: {str(e)}"}

@app.post("/api/upload")
async def upload_image(file: UploadFile = File(...), username: str = Depends(get_current_user)):
    global reader
    # 1. Load the model ONLY if it hasn't been loaded yet
    if reader is None:
        print("Loading AI Model for the first time... this may take a minute.")
        reader = easyocr.Reader(['en'], gpu=False, verbose=False)

    try:
        # Read the file bytes
        file_bytes = await file.read()
        mime_type = file.content_type or "image/jpeg"
        
        # 1. Attempt processing with Gemini
        print(f"Processing {file.filename} with Gemini AI...")
        gemini_json_raw = process_image_with_gemini(file_bytes, mime_type)
        
        try:
            study_data = json.loads(gemini_json_raw)
            extracted_text = study_data.get("summary", "No summary generated.")
            ai_summary = extracted_text
            quiz_data = study_data.get("quiz", [])
            cards_data = study_data.get("cards", [])
        except Exception as e:
            print(f"JSON Parse Error: {e}. Raw: {gemini_json_raw}")
            extracted_text = gemini_json_raw
            ai_summary = "Processed but failed to structure data."
            quiz_data = []
            cards_data = []
        
        # 3. Save to MongoDB
        db = get_db()
        if db is not None:
            try:
                notes_collection = db["scanned_notes"]
                notes_collection.insert_one({
                    "username": username,
                    "filename": file.filename,
                    "extracted_text": ai_summary,
                    "ai_summary": ai_summary,
                    "quiz": quiz_data,
                    "cards": cards_data,
                    "timestamp": datetime.now().isoformat()
                })
            except Exception as e:
                print(f"Database exception: {e}")
            
        return {
            "status": "success",
            "filename": file.filename, 
            "extracted_text": ai_summary,
            "ai_summary": ai_summary,
            "quiz": quiz_data,
            "cards": cards_data,
            "message": "Processed successfully!"
        }

    except Exception as e:
        print(f"Error during OCR extraction: {e}")
        return {
            "status": "error", 
            "filename": file.filename,
            "extracted_text": f"Error: Failed to process image. Details: {e}",
            "message": "Failed to process image."
        }

@app.get("/api/notes")
async def get_notes(username: str = Depends(get_current_user)):
    try:
        notes_collection = get_collection("scanned_notes")
        if notes_collection is not None:
            # Fetch only the notes belonging to this user
            notes = list(notes_collection.find({"username": username}, {"_id": 0}))
            return {"status": "success", "notes": notes}
        return {"status": "error", "message": "Database not connected"}
    except Exception as e:
        print(f"Error fetching notes: {e}")
        return {"status": "error", "message": str(e)}

@app.get("/api/stats")
async def get_stats(username: str = Depends(get_current_user)):
    try:
        notes_collection = get_collection("scanned_notes")
        if notes_collection is not None:
            # Count user's notes
            total_notes = notes_collection.count_documents({"username": username})
            
            # Simulated calculation for Demo
            study_hours = total_notes * 0.5 # Assume 30 mins per note
            avg_score = 85 # Placeholder
            streak = 5 # Placeholder
            
            return {
                "status": "success",
                "total_notes": total_notes,
                "study_hours": f"{study_hours:.1f}",
                "avg_score": f"{avg_score}%",
                "streak": f"{streak}"
            }
        return {"status": "error", "message": "Database not connected"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.delete("/api/notes")
async def delete_all_notes(username: str = Depends(get_current_user)):
    try:
        notes_collection = get_collection("scanned_notes")
        if notes_collection is not None:
            # Only delete notes for the current user
            result = notes_collection.delete_many({"username": username})
            return {"status": "success", "message": f"Deleted {result.deleted_count} notes successfully!"}
        return {"status": "error", "message": "Database not connected"}
    except Exception as e:
        print(f"Error deleting notes: {e}")
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

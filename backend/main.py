from contextlib import asynccontextmanager
from datetime import datetime
import json
import os
import socket

from fastapi import Depends, FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from ai_service import process_image_with_gemini
from auth import create_access_token, get_current_user, get_password_hash, verify_password
from database import connect_db, get_collection, get_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Startup: Connecting to MongoDB...")
    connect_db()

    print("Startup: Skipping EasyOCR (using Gemini Vision instead).")
    print("--- AI HEALTH CHECK ---")
    key = os.getenv("GEMINI_API_KEY")
    if not key or "YOUR_" in key:
        print("[!] WARNING: GEMINI_API_KEY is not set correctly in .env!")
    else:
        print("[+] GEMINI_API_KEY found. Testing connection...")
        try:
            import google.generativeai as genai

            model = genai.GenerativeModel("gemini-2.5-flash")
            model.generate_content("Ping")
            print("[+] Gemini AI Connection: SUCCESS")
        except Exception as exc:
            print(f"[-] Gemini AI Connection: FAILED - {exc}")
    print("-----------------------")

    try:
        hostname = socket.gethostname()
        local_ip = socket.gethostbyname(hostname)
        print(f"SERVER IS LIVE AT: http://{local_ip}:8000")
        print("Use this IP in Flutter for a physical Android/iOS device.")
    except Exception:
        print("Could not determine local IP automatically.")
    print("-----------------------")

    print("Server started! Ready for requests.")
    yield
    print("Shutting down...")


app = FastAPI(
    title="AI Study Camera API",
    description="Backend for the Snap & Learn mobile application",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def health_check():
    return {"status": "success", "message": "AI Study Camera API is running"}


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
            return {
                "status": "error",
                "message": "Database connection error. Please check your MONGO_URI.",
            }

        if users_collection.find_one({"username": username}):
            print(f"Error: Username '{username}' already exists.")
            return {"status": "error", "message": "Username already exists"}

        hashed_password = get_password_hash(password)
        users_collection.insert_one({"username": username, "password": hashed_password})
        print(f"Success: User '{username}' registered successfully.")
        return {"status": "success", "message": "User registered successfully"}
    except Exception as exc:
        print(f"Exception during registration: {exc}")
        return {"status": "error", "message": f"Internal server error: {exc}"}


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
            "username": username,
        }
    except Exception as exc:
        print(f"CRITICAL LOGIN ERROR: {exc}")
        return {"status": "error", "message": f"Internal server error: {exc}"}


@app.post("/api/upload")
async def upload_image(
    file: UploadFile = File(...),
    username: str = Depends(get_current_user),
):
    print(f"DEBUG: Starting upload_image for user: {username}")
    try:
        print("DEBUG: Reading file bytes...")
        file_bytes = await file.read()
        print(f"DEBUG: File size: {len(file_bytes)} bytes")
        mime_type = file.content_type
        if not mime_type or mime_type == "application/octet-stream":
            mime_type = "image/jpeg"

        print(f"DEBUG: Calling Gemini AI with MIME: {mime_type}...")
        gemini_json_raw = process_image_with_gemini(file_bytes, mime_type)
        print(f"DEBUG: Gemini raw response received (length: {len(gemini_json_raw)})")

        try:
            print("DEBUG: Parsing JSON response...")
            study_data = json.loads(gemini_json_raw)
            ai_summary = study_data.get("summary", "No summary generated.")
            quiz_data = study_data.get("quiz", [])
            cards_data = study_data.get("cards", [])
        except Exception as exc:
            print("--- CRITICAL JSON PARSE ERROR ---")
            print(f"Error: {exc}")
            with open("debug_output.txt", "w", encoding="utf-8") as debug_file:
                debug_file.write(f"ERROR: {exc}\n\nRAW OUTPUT:\n{gemini_json_raw}")
            print("----------------------------------")

            ai_summary = "FAILED TO EXTRACT TEXT. Please check your API key and server logs."
            if "Error" in gemini_json_raw:
                ai_summary += f" {gemini_json_raw}"
            quiz_data = []
            cards_data = []

        db = get_db()
        if db is not None:
            try:
                db["scanned_notes"].insert_one(
                    {
                        "username": username,
                        "filename": file.filename,
                        "extracted_text": ai_summary,
                        "ai_summary": ai_summary,
                        "quiz": quiz_data,
                        "cards": cards_data,
                        "timestamp": datetime.now().isoformat(),
                    }
                )
            except Exception as exc:
                print(f"Database exception: {exc}")

        return {
            "status": "success",
            "filename": file.filename,
            "extracted_text": ai_summary,
            "ai_summary": ai_summary,
            "quiz": quiz_data,
            "cards": cards_data,
            "message": "Processed successfully!",
        }

    except Exception as exc:
        print(f"Error during OCR extraction: {exc}")
        return {
            "status": "error",
            "filename": file.filename,
            "extracted_text": f"Error: Failed to process image. Details: {exc}",
            "message": "Failed to process image.",
        }


@app.get("/api/notes")
async def get_notes(username: str = Depends(get_current_user)):
    try:
        notes_collection = get_collection("scanned_notes")
        if notes_collection is not None:
            notes = list(notes_collection.find({"username": username}))
            # Convert ObjectId to string for JSON serialization
            for note in notes:
                note["_id"] = str(note["_id"])
            return {"status": "success", "notes": notes}
        return {"status": "error", "message": "Database not connected"}
    except Exception as exc:
        print(f"Error fetching notes: {exc}")
        return {"status": "error", "message": str(exc)}

@app.delete("/api/notes/{note_id}")
async def delete_note(note_id: str, username: str = Depends(get_current_user)):
    try:
        from bson.objectid import ObjectId
        notes_collection = get_collection("scanned_notes")
        if notes_collection is not None:
            result = notes_collection.delete_one({"_id": ObjectId(note_id), "username": username})
            if result.deleted_count > 0:
                return {"status": "success", "message": "Note deleted successfully!"}
            return {"status": "error", "message": "Note not found or unauthorized"}
        return {"status": "error", "message": "Database not connected"}
    except Exception as exc:
        print(f"Error deleting note: {exc}")
        return {"status": "error", "message": str(exc)}


@app.get("/api/stats")
async def get_stats(username: str = Depends(get_current_user)):
    try:
        notes_collection = get_collection("scanned_notes")
        if notes_collection is not None:
            total_notes = notes_collection.count_documents({"username": username})
            study_hours = total_notes * 0.5

            return {
                "status": "success",
                "total_notes": total_notes,
                "study_hours": f"{study_hours:.1f}",
                "avg_score": "85%",
                "streak": "5",
            }
        return {"status": "error", "message": "Database not connected"}
    except Exception as exc:
        return {"status": "error", "message": str(exc)}


@app.delete("/api/notes")
async def delete_all_notes(username: str = Depends(get_current_user)):
    try:
        notes_collection = get_collection("scanned_notes")
        if notes_collection is not None:
            result = notes_collection.delete_many({"username": username})
            return {
                "status": "success",
                "message": f"Deleted {result.deleted_count} notes successfully!",
            }
        return {"status": "error", "message": "Database not connected"}
    except Exception as exc:
        print(f"Error deleting notes: {exc}")
        return {"status": "error", "message": str(exc)}


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

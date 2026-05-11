from pymongo import MongoClient
import certifi
import os
from dotenv import load_dotenv

load_dotenv()
MONGO_URI = os.getenv("MONGO_URI")

if not MONGO_URI:
    raise SystemExit("MONGO_URI is not set. Add it to backend/.env before running this test.")

try:
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000, tlsCAFile=certifi.where())
    # The ismaster command is cheap and does not require auth.
    client.admin.command('ismaster')
    print("MongoDB connection successful!")
    
    db = client["ai_study_camera"]
    print(f"Connected to database: {db.name}")
    
except Exception as e:
    print(f"MongoDB connection failed: {e}")
finally:
    if "client" in locals():
        client.close()

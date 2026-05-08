from pymongo import MongoClient
import os
import certifi
from dotenv import load_dotenv

# Load variables from .env file
load_dotenv()

# Get MONGO_URI from environment variables
MONGO_URI = os.getenv("MONGO_URI")

client = None
db = None

def connect_db():
    global client, db
    if not MONGO_URI:
        print("Error: MONGO_URI not found in .env file")
        return

    try:
        # tlsCAFile=certifi.where() is essential for SSL connection on many systems
        client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000, tlsCAFile=certifi.where())
        db = client["ai_study_camera"]
        # Trigger a connection to verify
        client.admin.command('ping')
        
        # Ensure 'users' collection has a unique index on 'username'
        db["users"].create_index("username", unique=True)
        
        print("Connected to MongoDB successfully!")
    except Exception as e:
        print(f"Could not connect to MongoDB: {e}")

def get_db():
    return db

def get_collection(collection_name: str):
    if db is not None:
        return db[collection_name]
    return None


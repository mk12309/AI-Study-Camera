from pymongo import MongoClient
import certifi

MONGO_URI = "mongodb+srv://MAHNOOR:12345@cluster0.ttnxxc7.mongodb.net/?appName=Cluster0"

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
    client.close()

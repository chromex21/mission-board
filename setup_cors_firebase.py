#!/usr/bin/env python3
"""
Configure CORS for Firebase Storage using Firebase Admin SDK
This uses your Firebase credentials from firebase-tools
"""

import firebase_admin
from firebase_admin import credentials, storage as firebase_storage
import json

def configure_cors_firebase():
    bucket_name = 'mission-board-b8dbc.firebasestorage.app'
    project_id = 'mission-board-b8dbc'
    
    cors_configuration = [
        {
            "origin": ["*"],
            "method": ["GET"],
            "maxAgeSeconds": 3600
        }
    ]
    
    try:
        # Initialize Firebase Admin SDK with default credentials
        if not firebase_admin._apps:
            # Use default application credentials (will use gcloud auth if available)
            firebase_admin.initialize_app(options={
                'storageBucket': bucket_name
            })
        
        # Get storage client
        bucket = firebase_storage.bucket()
        
        # Set CORS configuration using the underlying Google Cloud client
        bucket.cors = cors_configuration
        bucket.patch()
        
        print("✅ SUCCESS! CORS configuration has been applied!")
        print(f"\nBucket: {bucket_name}")
        print(f"Configuration: {json.dumps(cors_configuration, indent=2)}")
        print("\n✅ Your Firebase Storage bucket can now serve images to web clients!")
        print("✅ You can now test uploading images in your app!")
        return True
        
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        print("\nTrying alternative method with gcloud...")
        return False

if __name__ == '__main__':
    success = configure_cors_firebase()
    exit(0 if success else 1)

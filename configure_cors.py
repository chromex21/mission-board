#!/usr/bin/env python3
"""
Configure CORS for Firebase Storage bucket using application default credentials
"""

from google.cloud import storage
from google.auth.exceptions import DefaultCredentialsError
import json

def configure_cors():
    bucket_name = 'mission-board-b8dbc.firebasestorage.app'
    
    cors_configuration = [
        {
            "origin": ["*"],
            "method": ["GET"],
            "maxAgeSeconds": 3600
        }
    ]
    
    try:
        # Initialize storage client
        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        
        # Set CORS configuration
        bucket.cors = cors_configuration
        bucket.patch()
        
        print("✅ SUCCESS! CORS configuration has been applied!")
        print(f"\nBucket: {bucket_name}")
        print(f"Configuration: {json.dumps(cors_configuration, indent=2)}")
        print("\n✅ Your Firebase Storage bucket can now serve images to web clients!")
        print("✅ You can now test uploading images in your app!")
        return True
        
    except DefaultCredentialsError:
        print("❌ ERROR: Could not find Google Cloud credentials")
        print("\nTo fix this, run:")
        print("  gcloud auth application-default login")
        print("\nOr set your service account JSON:")
        print("  $env:GOOGLE_APPLICATION_CREDENTIALS='path/to/service-account-key.json'")
        return False
        
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        print(f"\nMake sure:")
        print(f"  1. You have Google Cloud SDK installed")
        print(f"  2. You're authenticated: gcloud auth application-default login")
        print(f"  3. The bucket name is correct: {bucket_name}")
        return False

if __name__ == '__main__':
    success = configure_cors()
    exit(0 if success else 1)

#!/usr/bin/env python3
"""Configure CORS for Firebase Storage bucket using gcloud auth from Firebase CLI"""

import json
import subprocess
import sys

def set_cors():
    bucket_name = 'mission-board-b8dbc.firebasestorage.app'
    cors_config = [
        {
            "origin": ["*"],
            "method": ["GET"],
            "maxAgeSeconds": 3600
        }
    ]
    
    # Write CORS config to temp file
    with open('cors_config.json', 'w') as f:
        json.dump(cors_config, f)
    
    # Use gsutil via gcloud
    try:
        # First try to activate service account from firebase
        print("Attempting to configure CORS for bucket:", bucket_name)
        
        # Try using firebase's gcloud configuration
        result = subprocess.run([
            'gcloud', 'storage', 'buckets', 'update',
            f'gs://{bucket_name}',
            '--cors-config=cors_config.json'
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ CORS configuration set successfully!")
            print("Your Firebase Storage bucket can now serve images to web clients.")
            return True
        else:
            print("Error:", result.stderr)
            # Try alternate method with gsutil
            print("\nTrying alternate method with gsutil...")
            result = subprocess.run([
                'gsutil', 'cors', 'set', 'cors.json',
                f'gs://{bucket_name}'
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                print("✅ CORS configuration set successfully!")
                return True
            else:
                print("Error:", result.stderr)
                return False
                
    except FileNotFoundError as e:
        print(f"❌ Error: {e}")
        print("Google Cloud SDK tools not found in PATH")
        return False

if __name__ == '__main__':
    success = set_cors()
    sys.exit(0 if success else 1)

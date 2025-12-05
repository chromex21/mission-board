const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);
const https = require('https');

async function getAccessToken() {
  try {
    const { stdout } = await execAsync('gcloud auth application-default print-access-token');
    return stdout.trim();
  } catch (error) {
    console.error('Error getting access token:', error.message);
    return null;
  }
}

async function setCorsViaRest() {
  const bucketName = 'mission-board-b8dbc.firebasestorage.app';
  
  const token = await getAccessToken();
  
  if (!token) {
    console.error('❌ Could not get access token. Make sure gcloud is configured:');
    console.error('  gcloud auth login');
    console.error('  gcloud config set project mission-board-b8dbc');
    return false;
  }

  const corsConfig = {
    cors: [
      {
        origin: ['*'],
        method: ['GET'],
        maxAgeSeconds: 3600
      }
    ]
  };

  const data = JSON.stringify(corsConfig);
  
  const options = {
    hostname: 'storage.googleapis.com',
    path: `/storage/v1/b/${bucketName}?fields=cors`,
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      'Content-Length': data.length
    }
  };

  return new Promise((resolve) => {
    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          console.log('✅ CORS configuration set successfully!');
          console.log('Your Firebase Storage bucket can now serve images to any origin.');
          resolve(true);
        } else {
          console.error(`❌ Error (${res.statusCode}):`, responseData);
          resolve(false);
        }
      });
    });

    req.on('error', (error) => {
      console.error('❌ Request error:', error.message);
      resolve(false);
    });

    req.write(data);
    req.end();
  });
}

async function main() {
  const success = await setCorsViaRest();
  if (success) {
    console.log('\n✅ You can now test uploading images in your app!');
  }
  process.exit(success ? 0 : 1);
}

main();

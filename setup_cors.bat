@echo off
REM Configure CORS for Firebase Storage using REST API

setlocal enabledelayedexpansion

set BUCKET=mission-board-b8dbc.firebasestorage.app
set PROJECT=mission-board-b8dbc

echo Getting access token...
for /f "usebackq tokens=*" %%A in (`gcloud auth application-default print-access-token 2^>nul`) do set TOKEN=%%A

if "!TOKEN!"=="" (
    echo.
    echo ❌ Could not get gcloud access token
    echo.
    echo Please configure gcloud:
    echo   gcloud auth login
    echo   gcloud config set project mission-board-b8dbc
    echo.
    pause
    exit /b 1
)

echo Token obtained. Setting CORS configuration...

curl -X PATCH ^
  -H "Authorization: Bearer !TOKEN!" ^
  -H "Content-Type: application/json" ^
  -d "{\"cors\":[{\"origin\":[\"*\"],\"method\":[\"GET\"],\"maxAgeSeconds\":3600}]}" ^
  "https://storage.googleapis.com/storage/v1/b/%BUCKET%?fields=cors"

echo.
echo ✅ CORS configuration applied!
pause

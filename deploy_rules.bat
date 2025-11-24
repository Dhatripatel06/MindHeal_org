@echo off
REM Firestore Rules Deployment Script for Windows
REM Run this script to deploy the Firestore security rules

echo 🔥 Deploying Firestore Security Rules...
echo ======================================

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI is not installed.
    echo    Install it with: npm install -g firebase-tools
    echo    Then login with: firebase login
    pause
    exit /b 1
)

REM Check if firestore.rules exists
if not exist "firestore.rules" (
    echo ❌ firestore.rules file not found!
    echo    Make sure you're in the project root directory
    pause
    exit /b 1
)

echo ✅ Firebase CLI found
echo ✅ firestore.rules file found

REM Check if user is logged in
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Not logged in to Firebase
    echo    Run: firebase login
    pause
    exit /b 1
)

echo ✅ Firebase authentication confirmed
echo.

REM Deploy the rules
echo Deploying Firestore rules...
firebase deploy --only firestore:rules

if %errorlevel% equ 0 (
    echo.
    echo 🎉 SUCCESS! Firestore rules have been deployed.
    echo.
    echo Your Mental Wellness app now has proper security rules:
    echo ✅ Users can only access their own data
    echo ✅ Biofeedback and mood session data is protected
    echo ✅ Data validation is enforced
    echo.
    echo You can now:
    echo 1. Test the app with authentication
    echo 2. View data in the History page
    echo 3. Sync data across devices
) else (
    echo.
    echo ❌ FAILED to deploy Firestore rules.
    echo    Check your Firebase project configuration
    echo    Run: firebase use --add
    echo    Then try again: deploy_rules.bat
)

pause
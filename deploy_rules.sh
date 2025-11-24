#!/bin/bash

# Firestore Rules Deployment Script
# Run this script to deploy the Firestore security rules

echo "🔥 Deploying Firestore Security Rules..."
echo "======================================"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null
then
    echo "❌ Firebase CLI is not installed."
    echo "   Install it with: npm install -g firebase-tools"
    echo "   Then login with: firebase login"
    exit 1
fi

# Check if firestore.rules exists
if [ ! -f "firestore.rules" ]; then
    echo "❌ firestore.rules file not found!"
    echo "   Make sure you're in the project root directory"
    exit 1
fi

echo "✅ Firebase CLI found"
echo "✅ firestore.rules file found"

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase"
    echo "   Run: firebase login"
    exit 1
fi

echo "✅ Firebase authentication confirmed"

# Deploy the rules
echo ""
echo "Deploying Firestore rules..."
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! Firestore rules have been deployed."
    echo ""
    echo "Your Mental Wellness app now has proper security rules:"
    echo "✅ Users can only access their own data"
    echo "✅ Biofeedback and mood session data is protected"
    echo "✅ Data validation is enforced"
    echo ""
    echo "You can now:"
    echo "1. Test the app with authentication"
    echo "2. View data in the History page"
    echo "3. Sync data across devices"
else
    echo ""
    echo "❌ FAILED to deploy Firestore rules."
    echo "   Check your Firebase project configuration"
    echo "   Run: firebase use --add"
    echo "   Then try again: ./deploy_rules.sh"
fi
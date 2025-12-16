#!/bin/bash

# AuraSphere Pro - Firestore Rules Deployment Script
# This script safely deploys Firestore security rules to production

set -e

echo "🔒 AuraSphere Pro - Firestore Rules Deployment"
echo "=============================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI not installed${NC}"
    echo "Install with: npm install -g firebase-tools"
    exit 1
fi

# Check if firestore.rules exists
if [ ! -f "firestore.rules" ]; then
    echo -e "${RED}❌ firestore.rules not found in current directory${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Pre-Deployment Checks${NC}"
echo ""

# Check if user is authenticated
if ! firebase projects:list > /dev/null 2>&1; then
    echo -e "${RED}❌ Not authenticated with Firebase${NC}"
    echo "Run: firebase login"
    exit 1
fi

echo -e "${GREEN}✅ Firebase CLI authenticated${NC}"

# List current project
PROJECT=$(firebase projects:list 2>/dev/null | grep "^" | head -1 | awk '{print $1}')
echo -e "${GREEN}✅ Using project: $PROJECT${NC}"
echo ""

# Show rules file info
echo -e "${YELLOW}📄 Rules File Information${NC}"
echo "File: firestore.rules"
echo "Size: $(wc -c < firestore.rules) bytes"
echo "Lines: $(wc -l < firestore.rules)"
echo ""

# Validate rules syntax
echo -e "${YELLOW}🔍 Validating Rules Syntax${NC}"
if firebase rules:test > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Rules syntax is valid${NC}"
else
    echo -e "${YELLOW}⚠️  Could not validate with emulator (optional)${NC}"
fi
echo ""

# Confirmation
echo -e "${YELLOW}⚠️  CONFIRMATION REQUIRED${NC}"
echo "This will deploy firestore.rules to: $PROJECT"
echo ""
read -p "Continue with deployment? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}🚀 Deploying Firestore Rules${NC}"

# Deploy only firestore rules
if firebase deploy --only firestore:rules --project "$PROJECT"; then
    echo ""
    echo -e "${GREEN}✅ Deployment successful!${NC}"
    echo ""
    echo -e "${YELLOW}📊 Next Steps${NC}"
    echo "1. Monitor rule violations in Firebase Console"
    echo "   → Cloud Firestore > Rules > Violations tab"
    echo ""
    echo "2. Check Cloud Logging for permission errors"
    echo "   → Logging > Log Explorer"
    echo ""
    echo "3. Test on staging/dev environment first (recommended)"
    echo ""
    echo "4. Monitor Sentry for permission-related errors"
    echo "   → Dashboard > Issues > Filter by permission"
    echo ""
    echo -e "${YELLOW}📝 Rollback Command${NC}"
    echo "If issues occur, rollback with:"
    echo "firebase deploy --only firestore:rules --project $PROJECT"
    echo "(After reverting firestore.rules to previous version)"
else
    echo ""
    echo -e "${RED}❌ Deployment failed${NC}"
    echo "Check the error above and verify:"
    echo "1. Rules syntax is valid"
    echo "2. You have deployment permissions"
    echo "3. Firebase project is properly configured"
    exit 1
fi

#!/bin/bash
# AuraSphere Pro - Operational Health Check
# Run this to verify all systems are functional

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     AuraSphere Pro - Operational Health Check                 ║"
echo "║     Status verification for all 12 phases                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_count=0
pass_count=0
fail_count=0

# Helper functions
check_file() {
    local file=$1
    local name=$2
    check_count=$((check_count + 1))
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $name"
        pass_count=$((pass_count + 1))
    else
        echo -e "${RED}✗${NC} $name (missing: $file)"
        fail_count=$((fail_count + 1))
    fi
}

check_dir() {
    local dir=$1
    local name=$2
    check_count=$((check_count + 1))
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $name"
        pass_count=$((pass_count + 1))
    else
        echo -e "${RED}✗${NC} $name (missing: $dir)"
        fail_count=$((fail_count + 1))
    fi
}

check_port() {
    local port=$1
    local name=$2
    check_count=$((check_count + 1))
    if nc -z 127.0.0.1 "$port" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $name (port $port)"
        pass_count=$((pass_count + 1))
    else
        echo -e "${YELLOW}⚠${NC} $name (port $port not responding)"
        fail_count=$((fail_count + 1))
    fi
}

check_http() {
    local url=$1
    local name=$2
    check_count=$((check_count + 1))
    local status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    if [ "$status" = "200" ]; then
        echo -e "${GREEN}✓${NC} $name ($url)"
        pass_count=$((pass_count + 1))
    else
        echo -e "${YELLOW}⚠${NC} $name ($url - HTTP $status)"
        fail_count=$((fail_count + 1))
    fi
}

# Phase checks
echo -e "${BLUE}PHASE VERIFICATION${NC}"
echo "────────────────────────────────────────────────────────────────"

echo -e "${BLUE}Phases 1-5: Core Features${NC}"
check_file "web/src/rbac/rbacSystem.js" "Web RBAC system"
check_file "web/src/sidebar/Sidebar.tsx" "Sidebar navigation"
check_file "web/src/onboarding/OnboardingFlow.tsx" "Smart onboarding"
check_file "lib/services/openai_service.dart" "AI suggestions"
check_file "lib/services/loyalty_service.dart" "Loyalty rewards"

echo ""
echo -e "${BLUE}Phases 6-9: Infrastructure${NC}"
check_file "firestore.rules" "Firestore rules"
check_file "functions/src/index.ts" "Cloud Functions"
check_file "lib/config/constants.dart" "App constants"
check_file "docs/api_reference.md" "API documentation"

echo ""
echo -e "${BLUE}Phases 10-12: Advanced Systems${NC}"
check_file "web/src/pricing/subscriptionTiers.js" "Subscription billing"
check_file "lib/screens/employee/employee_dashboard.dart" "Mobile employee app"
check_file "shared/auth/rolePermissions.js" "Role permissions"
check_file "lib/services/aiHelpers.js" "AI data helpers"
check_file "lib/onboarding/roleBasedOnboarding.js" "Role-based onboarding"

# Build artifacts
echo ""
echo -e "${BLUE}BUILD ARTIFACTS${NC}"
echo "────────────────────────────────────────────────────────────────"
check_dir "build/web" "Flutter web build"
check_file "build/web/index.html" "Web app entry point"
check_dir "functions/lib" "Cloud Functions compiled"

# Server status
echo ""
echo -e "${BLUE}SERVER STATUS${NC}"
echo "────────────────────────────────────────────────────────────────"
check_http "http://localhost:3000/index.html" "Web app server"
check_http "http://localhost:3000/" "Web app root"

# Configuration
echo ""
echo -e "${BLUE}CONFIGURATION${NC}"
echo "────────────────────────────────────────────────────────────────"
check_file ".env.example" "Environment template"
check_file "firebase.json" "Firebase config"
check_file "pubspec.yaml" "Flutter dependencies"
check_file "functions/package.json" "Node dependencies"

# Security
echo ""
echo -e "${BLUE}SECURITY${NC}"
echo "────────────────────────────────────────────────────────────────"
check_file ".gitignore" ".gitignore configured"
check_file "docs/STRIPE_SECURITY_SETUP.md" "Stripe security guide"

# Summary
echo ""
echo "════════════════════════════════════════════════════════════════"
echo -e "SUMMARY: ${GREEN}${pass_count}${NC} passed, ${RED}${fail_count}${NC} failed, total ${check_count} checks"

if [ $fail_count -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ ALL SYSTEMS OPERATIONAL${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Open http://localhost:3000 in browser"
    echo "2. Login with Firebase test account"
    echo "3. Test role-based access"
    echo "4. See OPERATIONAL_GUIDE.md for full details"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}✗ SOME SYSTEMS NEED ATTENTION${NC}"
    echo ""
    echo "Common issues:"
    echo "• Web server: Run 'python3 -m http.server 3000' in build/web/"
    echo "• Missing files: Run 'flutter pub get && cd functions && npm install'"
    echo "• Build needed: Run 'flutter build web'"
    echo ""
    exit 1
fi

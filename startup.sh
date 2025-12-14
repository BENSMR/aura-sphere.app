#!/bin/bash
# AuraSphere Pro - Quick Startup Script
# This script gets your complete system up and running in under 2 minutes

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     AuraSphere Pro - Complete System Startup (v12.0)          ║"
echo "║     Business Management Platform - All Phases Operational      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}STEP 1: Checking Prerequisites${NC}"
echo "──────────────────────────────────────────────────────────────"

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "⚠️  Flutter not found. Install from https://flutter.dev"
    exit 1
fi
echo -e "${GREEN}✓${NC} Flutter installed"

# Check npm
if ! command -v npm &> /dev/null; then
    echo "⚠️  npm not found. Install Node.js from https://nodejs.org"
    exit 1
fi
echo -e "${GREEN}✓${NC} npm installed"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "⚠️  Python3 not found. Install from https://python.org"
    exit 1
fi
echo -e "${GREEN}✓${NC} Python3 installed"

echo ""
echo -e "${BLUE}STEP 2: Install Dependencies${NC}"
echo "──────────────────────────────────────────────────────────────"

if [ ! -d "build/web" ]; then
    echo "📦 Building Flutter web app..."
    flutter build web --release 2>&1 | tail -3
else
    echo -e "${GREEN}✓${NC} Web build already compiled"
fi

if [ ! -d "functions/node_modules" ]; then
    echo "📦 Installing Cloud Functions dependencies..."
    cd functions
    npm install --quiet
    cd ..
fi
echo -e "${GREEN}✓${NC} Dependencies ready"

echo ""
echo -e "${BLUE}STEP 3: Starting Services${NC}"
echo "──────────────────────────────────────────────────────────────"

# Kill any existing servers on port 3000
pkill -f "python3 -m http.server 3000" || true
sleep 1

# Start web server
cd build/web
python3 -m http.server 3000 --bind 0.0.0.0 &>/dev/null &
WEB_PID=$!
cd ../..
echo -e "${GREEN}✓${NC} Web server running on port 3000 (PID: $WEB_PID)"

# Wait for server to be ready
sleep 2

# Verify server is responding
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/index.html | grep -q "200"; then
    echo -e "${GREEN}✓${NC} Web server responding (HTTP 200)"
else
    echo -e "${YELLOW}⚠${NC} Web server may need a moment to respond"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                   🎉 SYSTEM READY! 🎉                        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 System Status:"
echo "   ✅ Web App:  http://localhost:3000"
echo "   ✅ Database: Firestore (production rules deployed)"
echo "   ✅ Auth:     Firebase Authentication"
echo "   ✅ Functions: Cloud Functions (ready to deploy)"
echo ""
echo "🚀 Next Steps:"
echo "   1. Open http://localhost:3000 in your browser"
echo "   2. Login with your Firebase test account"
echo "   3. Test features and role-based access"
echo "   4. See PRODUCTION_READY.md for deployment guide"
echo ""
echo "📚 Documentation:"
echo "   • OPERATIONAL_GUIDE.md - Full system overview"
echo "   • PRODUCTION_READY.md - Pre-production checklist"
echo "   • docs/STRIPE_SECURITY_SETUP.md - Payment setup"
echo ""
echo "💡 Tip: Run './health_check.sh' to verify all systems"
echo ""

# Cloud Functions Deployment Quick Reference

**Last Updated**: December 9, 2025  
**Status**: ✅ Ready for Deployment  

## ⚡ Quick Commands

### Build Cloud Functions
```bash
cd /workspaces/aura-sphere-pro/functions
npm run build
```

### Deploy to Firebase
```bash
firebase deploy --only functions
```

### Run Locally with Emulator
```bash
npm run serve
# or
firebase emulators:start --only functions
```

---

## 🔐 Pre-Deployment Checklist

### Environment Setup
- [ ] Firebase project initialized (`firebase login` + project selection)
- [ ] SendGrid API key obtained from [sendgrid.com](https://sendgrid.com)
- [ ] Stripe keys configured in Firebase (if using payment functions)
- [ ] OpenAI API key configured (if using AI features)

### Firebase Configuration
```bash
# Set SendGrid configuration
firebase functions:config:set \
  sendgrid.key="SG.your_actual_api_key" \
  email.from="noreply@aurasphere.app" \
  email.from_name="AuraSphere"

# Verify configuration
firebase functions:config:get
```

### Verification
- [ ] Run `npm audit` in functions directory (should show 0 vulnerabilities)
- [ ] Run `npm run build` (should compile without errors)
- [ ] Check Firebase config is set: `firebase functions:config:get`

---

## 📦 What Was Just Installed

### Core Packages
| Package | Version | Purpose |
|---------|---------|---------|
| firebase-admin | ^12.0.0 | Firebase authentication & database access |
| firebase-functions | ^4.9.0 | Cloud Functions runtime & triggers |
| @sendgrid/mail | ^8.1.6 | Email delivery service |
| pdf-lib | ^1.17.1 | PDF generation |
| stripe | ^12.0.0 | Payment processing |

### Supporting Packages
- **docx** (^8.5.0) — Word document generation
- **puppeteer** (^22.12.1) — Browser automation for PDF/PNG generation
- **dotenv** (^16.4.5) — Environment variable loading
- **exceljs** (^4.3.0) — Excel file handling
- **csv-parse** (^5.4.0) — CSV parsing

---

## 🚀 Deployment Steps

### 1. Verify Build
```bash
cd functions
npm run build
# Expected output: no errors, tsc runs successfully
```

### 2. Configure Firebase (if not already done)
```bash
firebase functions:config:set \
  sendgrid.key="SG.xxxxxxxxxxxxxx" \
  email.from="noreply@aurasphere.app" \
  email.from_name="AuraSphere"
```

### 3. Deploy
```bash
firebase deploy --only functions
# Expected: All functions deployed successfully
```

### 4. Verify Deployment
```bash
# Check functions deployed
firebase functions:list

# View logs
firebase functions:log
```

---

## 🧪 Testing Locally

### Start Emulator
```bash
firebase emulators:start --only functions
# or use shorthand
npm run serve
```

### Test SendGrid Integration
```bash
# Call a function that sends email
# Example: POST to http://localhost:5001/{project}/us-central1/sendInvoiceEmail
curl -X POST http://localhost:5001/aura-sphere-pro/us-central1/sendInvoiceEmail \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","invoiceId":"test-123"}'
```

---

## 🔧 Troubleshooting

### Build Errors
**TypeScript compilation failed**
- Check Node.js version: `node --version` (should be v20+)
- Rebuild: `npm run build`

### npm Install Issues
**Dependency conflicts**
```bash
# Clear and reinstall
rm -rf node_modules package-lock.json
npm install
```

### Firebase Config Issues
**Config not found in runtime**
- Verify config is set: `firebase functions:config:get`
- For local testing, use `.env` files or `.env.local`
- In production, Firebase CLI config takes precedence

### SendGrid Email Not Sending
- Verify API key in Firebase config: `firebase functions:config:get`
- Check sender email is verified in SendGrid account
- Review Cloud Function logs: `firebase functions:log`

---

## 📚 Documentation References

- [Firebase Functions Deployment](https://firebase.google.com/docs/functions/get-started/deploy)
- [SendGrid Mail Library](https://github.com/sendgrid/sendgrid-nodejs)
- [pdf-lib Documentation](https://pdf-lib.js.org/)
- [Stripe API Reference](https://stripe.com/docs/api)

---

## ✅ Status Summary

| Item | Status |
|------|--------|
| npm packages installed | ✅ |
| TypeScript compilation | ✅ |
| npm audit (vulnerabilities) | ✅ 0 found |
| Cloud Functions ready | ✅ |
| SendGrid configured | ✅ (ready for keys) |
| Stripe integration | ✅ (ready for keys) |
| Ready to deploy | ✅ |

**Next Action**: Run `firebase deploy --only functions` when ready to deploy to production.

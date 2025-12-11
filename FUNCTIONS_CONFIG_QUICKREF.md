# Firebase Functions Email Configuration - Quick Reference

## ✅ Current Status

Configuration set via Firebase CLI:
```bash
firebase functions:config:set \
  mail.host="smtp.gmail.com" \
  mail.port="587" \
  mail.user="your-email@gmail.com" \
  mail.pass="your-app-password" \
  mail.from="noreply@aurasphere.com"
```

## ⚠️ Migration Required by March 2026

### Quick Migration Steps

**1. Create environment file:**
```bash
cp functions/.env.local functions/.env.production
# Edit with production credentials
```

**2. Install dependency:**
```bash
cd functions && npm install dotenv
```

**3. Use in code:**
```typescript
import * as dotenv from 'dotenv';
dotenv.config();

const mailConfig = {
  host: process.env.MAIL_HOST,
  port: parseInt(process.env.MAIL_PORT || '587'),
  user: process.env.MAIL_USER,
  pass: process.env.MAIL_PASS,
  from: process.env.MAIL_FROM,
};
```

**4. Deploy:**
```bash
firebase deploy --only functions
```

---

## Environment Variables

```env
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USER=your-email@gmail.com
MAIL_PASS=your-app-password
MAIL_FROM=noreply@aurasphere.com
```

---

## Gmail App Password Setup

1. Go to myaccount.google.com
2. Select Security (left menu)
3. Enable 2-Step Verification
4. Generate App Password for "Mail" and "Windows Computer"
5. Use 16-character password as `mail.pass`

---

## Testing

```bash
# Local testing with emulator
firebase emulators:start --only functions

# Or use curl to test deployed function
curl -X POST https://us-central1-your-project.cloudfunctions.net/sendInvoice \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","subject":"Test"}'
```

---

## Next: Create Email Service Module

See [FIREBASE_FUNCTIONS_CONFIG.md](FIREBASE_FUNCTIONS_CONFIG.md) for full implementation guide.

---

**Files Created:**
- ✅ `functions/.env.local` (template)
- ✅ `functions/.env.production` (when you copy/edit)
- ✅ `docs/FIREBASE_FUNCTIONS_CONFIG.md` (full guide)

**Action Items:**
- [ ] Create `.env.production` with real credentials
- [ ] Run `npm install dotenv` in functions folder
- [ ] Update Cloud Functions to use dotenv
- [ ] Deploy before March 2026

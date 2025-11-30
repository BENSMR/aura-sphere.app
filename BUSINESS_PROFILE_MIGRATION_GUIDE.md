# 🔄 Business Profile Migration Guide

**Status:** ✅ Migration Functions Ready | **Date:** November 29, 2025

---

## Overview

This guide covers migrating business profiles from the old structure (nested in user documents) to the new type-safe structure (in `users/{uid}/meta/business` subcollection).

### Migration Strategy
- **Automatic:** Data automatically loads with defaults on first access
- **Manual:** Use migration function to proactively move data for all users
- **Safe:** Non-destructive (doesn't delete old data, adds new)
- **Reversible:** Rollback function available if needed

---

## 📋 What Gets Migrated

### Old Structure
```firestore
users/{uid}
  ├── business: {
  │     businessName: "...",
  │     taxId: "...",
  │     ... other fields
  │   }
  └── ... other user data
```

### New Structure
```firestore
users/{uid}/meta/business
  ├── businessName: "..."
  ├── legalName: "..."
  ├── taxId: "..."
  ├── vatNumber: "..."
  ├── address: "..."
  ├── city: "..."
  ├── postalCode: "..."
  ├── logoUrl: "..."
  ├── invoicePrefix: "AS-"
  ├── documentFooter: "..."
  ├── brandColor: "#0A84FF"
  ├── watermarkText: "..."
  ├── invoiceTemplate: "minimal"
  ├── defaultCurrency: "EUR"
  ├── defaultLanguage: "en"
  ├── taxSettings: { ... }
  └── updatedAt: Timestamp
```

### Automatic Defaults Applied
- `invoicePrefix` → `"AS-"` (if missing)
- `brandColor` → `"#0A84FF"` (if missing)
- `invoiceTemplate` → `"minimal"` (if missing)
- `defaultCurrency` → `"EUR"` (if missing)
- `defaultLanguage` → `"en"` (if missing)
- All empty strings for missing text fields

---

## 🚀 Migration Methods

### Method 1: Automatic (Recommended for Production)

No action needed! When users log in:
1. `BusinessProvider.start(userId)` is called
2. `BusinessProfileService.loadProfile(userId)` checks for profile
3. If missing, creates with defaults
4. Profile available immediately

**Advantages:**
- ✅ No downtime
- ✅ Gradual (happens per user)
- ✅ Safe (uses existing logic)
- ✅ No manual intervention

**Timeline:** Users migrated as they log in

---

### Method 2: Manual Migration Function (Bulk)

**When to Use:**
- Need all users migrated immediately
- Before major deployment
- For testing/staging environment
- Compliance or audit requirements

**Prerequisites:**
1. Deploy Cloud Functions
2. Get admin authentication token
3. Ensure Firestore rules allow writes

**Steps:**

1. **Deploy the migration function:**
```bash
cd functions
npm run build
firebase deploy --only functions:migrateBusinessProfiles
```

2. **Verify deployment:**
```bash
firebase functions:log --limit 50
```

3. **Get authentication token:**
```bash
# Using Firebase CLI
firebase auth:export /tmp/accounts.json --format json

# Or get your own token via Firebase Console → Settings → Service Accounts
```

4. **Run migration:**
```bash
curl -X POST \
  https://your-project.cloudfunctions.net/migrateBusinessProfiles \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json"
```

5. **Check results:**
```json
{
  "status": "success",
  "summary": {
    "migrated": 150,
    "skipped": 45,
    "errors": 2,
    "total": 197
  },
  "message": "Migration complete: 150 migrated, 45 skipped, 2 errors",
  "timestamp": "2025-11-29T10:30:00.000Z",
  "errorDetails": [
    {
      "userId": "user123",
      "reason": "Firestore write failed"
    }
  ]
}
```

---

## 🔍 Verify Migration

### Check Migration Status

```bash
curl -X GET \
  https://your-project.cloudfunctions.net/verifyBusinessProfileMigration
```

**Response:**
```json
{
  "status": "success",
  "summary": {
    "totalUsers": 197,
    "oldStructureOnly": 15,
    "newStructureOnly": 150,
    "bothStructures": 32,
    "migrationProgress": "150/197 users have new structure"
  },
  "timestamp": "2025-11-29T10:35:00.000Z"
}
```

### Interpretation

- **oldStructureOnly:** Users not yet migrated (manually migrate if needed)
- **newStructureOnly:** Successfully migrated users
- **bothStructures:** Dual structure (old + new) - safe to clean up old data later
- **migrationProgress:** Percentage of users with new structure

---

## ↩️ Rollback Migration

### If Issues Occur

```bash
curl -X POST \
  https://your-project.cloudfunctions.net/rollbackBusinessProfileMigration \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json"
```

**What This Does:**
- Copies data from `users/{uid}/meta/business` back to `users/{uid}.business`
- Restores old structure while keeping new structure intact
- Non-destructive (doesn't delete either)
- Allows safe reversal

**Response:**
```json
{
  "status": "success",
  "summary": {
    "rolledBack": 150,
    "errors": 0,
    "total": 197
  },
  "message": "Rollback complete: 150 restored, 0 errors",
  "timestamp": "2025-11-29T10:40:00.000Z"
}
```

---

## 📊 Migration Architecture

### Function Files

**File:** `functions/src/migrations/migrate_business_profiles.ts`

**Includes:**
1. `migrateBusinessProfiles()` — Main migration function
2. `verifyBusinessProfileMigration()` — Check migration status
3. `rollbackBusinessProfileMigration()` — Revert migration

**Features:**
- ✅ Error handling per user
- ✅ Detailed error logging
- ✅ Progress tracking
- ✅ Timestamp recording
- ✅ Security checks
- ✅ Transaction-safe writes

---

## 🔒 Security Considerations

### Authentication
- Migration function requires authentication token
- Verification function is public (read-only)
- Rollback requires authentication token

### Data Protection
- Uses `merge: true` (doesn't overwrite other fields)
- Server timestamps only (user cannot set timestamps)
- Firestore rules enforce ownership
- No data is deleted

### Audit Trail
- All operations logged to Cloud Logging
- Timestamps recorded in documents
- Migration details available in Firebase Console

---

## 📈 Performance

### Migration Speed
- **~1-2 seconds per user** (depends on document size)
- **~500 users in 10-20 minutes**
- Parallel reads, sequential writes (safe)

### Resource Usage
- **Memory:** 1GB allocated
- **Timeout:** 9 minutes
- **Network:** Minimal (Firestore internal)

### Optimization
For large deployments (>10,000 users):
1. Run migration in staging first
2. Test performance metrics
3. Consider batch size adjustments
4. Run during off-peak hours

---

## 🧪 Testing Migration

### Pre-Migration Testing

1. **Test in development:**
```bash
# Deploy to Firebase emulator
firebase emulators:start

# Run migration against emulator
curl -X POST http://localhost:5001/your-project/us-central1/migrateBusinessProfiles
```

2. **Test in staging:**
```bash
# Deploy functions to staging project
firebase deploy --only functions:migrateBusinessProfiles --project staging-project

# Run migration
curl -X POST \
  https://staging-project.cloudfunctions.net/migrateBusinessProfiles \
  -H "Authorization: Bearer STAGING_TOKEN"
```

3. **Verify results:**
```bash
# Check both structures exist
firebase firestore:describe --project staging-project
```

### Post-Migration Testing

1. **User login test:**
   - User logs in
   - BusinessProvider.start() called
   - Profile loads successfully
   - No errors in logs

2. **Profile update test:**
   - User updates business profile
   - Data saves to new location
   - Firestore rules allow write
   - Old data not affected

3. **Backward compatibility test:**
   - App still reads legacy profile if needed
   - Invoice exports still work
   - Business branding applies correctly

---

## 📋 Migration Checklist

### Pre-Migration
- [ ] Backup Firestore data
- [ ] Review migration code
- [ ] Test in staging environment
- [ ] Get admin authentication token
- [ ] Notify team of migration time
- [ ] Plan maintenance window (if needed)

### Migration Execution
- [ ] Run verify function (check status)
- [ ] Deploy Cloud Functions
- [ ] Run migration function
- [ ] Monitor logs for errors
- [ ] Check results
- [ ] Resolve any errors

### Post-Migration
- [ ] Verify migration percentage (>95% recommended)
- [ ] Test user login flow
- [ ] Test profile updates
- [ ] Monitor error logs (24-48 hours)
- [ ] Check Firestore usage/costs
- [ ] Update documentation
- [ ] Communicate completion to team

### Cleanup (Optional, Later)
- [ ] After 1-2 weeks, delete old `business` field from user documents
- [ ] Run final verification
- [ ] Document cleanup completion

---

## 🐛 Troubleshooting

### Migration Fails with "Unauthorized"

**Cause:** Invalid or missing authentication token

**Fix:**
```bash
# Get new admin token from Firebase Console
# Settings → Service Accounts → Generate New Private Key

# Set token
export ADMIN_TOKEN="your-new-token"

# Retry migration
curl -X POST \
  https://your-project.cloudfunctions.net/migrateBusinessProfiles \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Migration Fails with "Timeout"

**Cause:** Too many users, needs more time

**Fix:**
1. Increase timeout in function (currently 540 seconds)
2. Run in multiple batches:
   ```typescript
   // Modify function to accept startAfter parameter
   const startAfter = req.query.startAfter || null;
   // Only process 100 users per batch
   ```

### Some Users Show Errors

**Cause:** Specific document write failures

**Fix:**
1. Check error details in response
2. Verify user document exists
3. Check Firestore rules allow write
4. Re-run migration (idempotent - safe to retry)

### Old and New Data Don't Match

**Cause:** Manual edits after migration, or write conflicts

**Fix:**
1. Run rollback
2. Fix source data
3. Re-run migration

---

## 📚 Related Documentation

- [BUSINESSPROVIDER_QUICK_START.md](BUSINESSPROVIDER_QUICK_START.md) — Using BusinessProvider
- [BUSINESSPROVIDER_DEPLOYMENT_GUIDE.md](BUSINESSPROVIDER_DEPLOYMENT_GUIDE.md) — Deployment
- [BUSINESSPROVIDER_FINAL_SUMMARY.md](BUSINESSPROVIDER_FINAL_SUMMARY.md) — Complete overview
- Cloud Functions: [functions/src/migrations/migrate_business_profiles.ts](../functions/src/migrations/migrate_business_profiles.ts)

---

## 🎯 Summary

**Three Migration Approaches:**

1. **Automatic** — Happens on user login (recommended)
   - Safest, no downtime, gradual
   - Takes a few weeks for all users

2. **Manual** — Run migration function once
   - Fast, all users immediately
   - Good for staging/testing

3. **Hybrid** — Auto-migrate active users, manually migrate inactive
   - Best of both worlds
   - Recommended for production

---

## ✅ Success Criteria

Migration is complete when:
- [ ] 95%+ of users have new structure
- [ ] No errors in migration logs
- [ ] User login works normally
- [ ] Profile updates work normally
- [ ] Invoice exports include business branding
- [ ] No performance degradation

---

**Status:** 🟢 Migration Functions Ready

Functions deployed and available in `functions/src/migrations/migrate_business_profiles.ts`

---

*Last updated: November 29, 2025*  
*Status: Ready for Deployment*

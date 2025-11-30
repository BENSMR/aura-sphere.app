# 📋 Post-Deployment Operations Guide

**Status:** Ready for Operations  
**Date:** November 29, 2025

---

## 🎯 What to Do After Deployment

This guide covers monitoring, troubleshooting, and operations after the Business Profile system is deployed to production.

---

## 📊 Day 1-3: Immediate Monitoring

### Monitor These Metrics

**Firebase Console → Firestore**
```
✅ Read requests: Should increase
✅ Write requests: Should increase
✅ Error rate: Should stay near 0%
✅ Latency: Should be <100ms average
```

**Firebase Console → Functions**
```
✅ Execution count: Should see migration calls
✅ Error rate: Should stay near 0%
✅ Execution time: Should be <5 seconds per call
✅ Memory usage: Should stay <200MB
```

**App Logs**
```
✅ Login success rate: Should be >99%
✅ Profile load success: Should be >99%
✅ No new crash reports
✅ No unknown errors in console
```

### What to Look For

**🟢 Healthy Indicators:**
- Users logging in normally
- Profiles loading successfully
- No errors in Firebase console
- Invoice exports include branding
- Profile updates working

**🔴 Warning Signs:**
- High error rate (>1%)
- Profile load failures
- Firestore quota exceeded
- Function timeouts
- Unexpected new crashes

### Action Items (Day 1)
- [ ] Check Firebase Console for errors
- [ ] Monitor app crash reports
- [ ] Test user flow on device
- [ ] Review function logs
- [ ] Check Firestore usage

---

## 🔄 Day 3-7: Data Migration

### If You Chose Manual Migration

**Before Starting:**
- [ ] Ensure all users are on latest app version
- [ ] Backup Firestore data
- [ ] Test migration in staging (if not done)
- [ ] Alert team of migration time

**Running Migration:**

```bash
# 1. Get admin token
export ADMIN_TOKEN="your-admin-token"

# 2. Run migration
curl -X POST \
  https://your-project.cloudfunctions.net/migrateBusinessProfiles \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json"

# 3. Monitor progress (real-time logs)
firebase functions:log --limit 100 --follow

# 4. Check results
curl https://your-project.cloudfunctions.net/verifyBusinessProfileMigration
```

**Expected Output:**
```json
{
  "status": "success",
  "summary": {
    "migrated": 150,
    "skipped": 45,
    "errors": 2,
    "total": 197
  },
  "timestamp": "2025-11-30T10:00:00Z"
}
```

**If Migration Fails:**

1. **Small number of errors (0-2%):**
   - Acceptable, continue
   - Re-run migration (idempotent - safe)
   - Check error details

2. **High number of errors (>5%):**
   - Stop migration
   - Run rollback function
   - Investigate root cause
   - Fix issues
   - Re-run migration

```bash
# Rollback if needed
curl -X POST \
  https://your-project.cloudfunctions.net/rollbackBusinessProfileMigration \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### If You Chose Automatic Migration

**No action needed!** Users will migrate as they log in.

**Monitor:**
```bash
# Daily check migration progress
curl https://your-project.cloudfunctions.net/verifyBusinessProfileMigration

# Expected progression:
# Day 1: ~20% migrated (active users)
# Day 3: ~50% migrated
# Day 7: ~80% migrated
# Week 2: ~95% migrated
```

**After 2 Weeks:**

If you want to migrate remaining users (5-10% inactive), run manual migration:

```bash
curl -X POST \
  https://your-project.cloudfunctions.net/migrateBusinessProfiles \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Result: Remaining users migrated
# Skipped: Previously migrated users (automatic - idempotent)
```

---

## 🔍 Week 1-2: Validation

### Test Complete User Flow

**Test 1: New User**
```
1. Download app from store
2. Create account
3. Log in
4. Auto-initialize BusinessProvider (verify in logs)
5. Check: businessProvider.profile != null
6. Create business profile
7. Create invoice
8. Verify invoice has branding
✅ PASS: All steps work, no errors
```

**Test 2: Existing User (Pre-Migration)**
```
1. Log in with old account
2. Auto-initialize BusinessProvider
3. Profile loads (with defaults if not migrated yet)
4. Create invoice
5. Verify branding applies
✅ PASS: Backward compatible, works with old data
```

**Test 3: Profile Update**
```
1. Log in
2. Update business profile (name, color, etc.)
3. Verify Firestore write succeeds
4. Create invoice
5. Verify new settings applied
✅ PASS: Changes save and apply
```

**Test 4: Logo Upload**
```
1. Log in
2. Upload logo image
3. Verify appears in business profile
4. Create invoice
5. Verify logo in invoice
✅ PASS: Logo uploads and renders
```

### Validation Checklist
- [ ] New user can create business profile
- [ ] Existing users auto-load profile
- [ ] Profile updates work
- [ ] Logo uploads work
- [ ] Invoice exports include branding
- [ ] Color changes apply
- [ ] Template changes apply
- [ ] No crashes or errors

---

## 📈 Week 2-4: Performance Tuning

### Check Performance Baseline

**Firebase Console → Firestore**

```
Create a custom dashboard:
- Read operations per day
- Write operations per day
- Average read latency
- Average write latency
- Storage usage trend
- Network bandwidth
```

**Expected Numbers (1000 active users):**
- Daily reads: 2000-5000
- Daily writes: 500-1000
- Average latency: 20-50ms
- Storage growth: 1-5MB/week

### Monitor Costs

```
Firebase pricing:
- Firestore reads: $0.06 per 100K reads
- Firestore writes: $0.18 per 100K writes
- Firestore storage: $0.18 per GB-month
- Functions: $0.40 per 1M invocations

Estimate for 1000 active users:
- Monthly reads: ~150K = $0.90
- Monthly writes: ~40K = $0.07
- Monthly storage: ~20MB = ~$0.004
- Functions: ~1K calls = ~$0.0004
Total: ~$1/month per 1000 users
```

### Optimization Opportunities

**If reads are high:**
- Add Firestore indexing
- Cache frequently accessed profiles
- Batch fetch multiple profiles

**If writes are high:**
- Reduce update frequency
- Batch updates into single write
- Review business_profile_form_screen.dart

**If storage grows quickly:**
- Clean up old profile versions (keep latest only)
- Archive inactive user profiles
- Review data model for unnecessary fields

---

## 🚨 Troubleshooting Guide

### Issue 1: Users Report "Profile Not Loading"

**Symptoms:**
```
❌ Profile is null on login
❌ Business name doesn't appear
❌ Invoice has no branding
```

**Diagnosis:**
```bash
# 1. Check Firestore rules
firebase firestore:inspect --collection="users/{uid}/meta/business"

# 2. Check for errors in logs
firebase functions:log | grep -i error

# 3. Check user document exists
firebase firestore:inspect --document="users/{userId}/meta/business"
```

**Solutions:**
1. **If rules are wrong:**
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **If document doesn't exist:**
   ```bash
   # Run migration to create missing documents
   curl -X POST https://your-project.cloudfunctions.net/migrateBusinessProfiles \
     -H "Authorization: Bearer $ADMIN_TOKEN"
   ```

3. **If user has old structure:**
   ```bash
   # Check old location
   firebase firestore:inspect --document="users/{userId}"
   
   # If business field exists, migration will copy it
   # If not, create with defaults
   ```

---

### Issue 2: Firestore Quota Exceeded

**Symptoms:**
```
❌ Permission denied errors
❌ All Firestore operations failing
❌ "Exceeded quota for quota metric" in logs
```

**Diagnosis:**
```bash
# Check Firebase Console → Firestore → Usage

# Look for:
- Sudden spike in operations
- Unexplained high reads/writes
- Any runaway loops
```

**Solutions:**

**Option 1: Request quota increase**
- Firebase Console → Settings
- Click "Request quota increase"
- Select metric and requested limit
- Wait for approval (usually 24-48 hours)

**Option 2: Reduce load temporarily**
- Pause any batch operations
- Wait for quota reset (daily at midnight UTC)
- Monitor usage going forward

**Option 3: Optimize code**
- Review Firestore queries
- Add query indexes
- Batch operations together
- Cache results where possible

---

### Issue 3: Migration Function Timeout

**Symptoms:**
```
❌ Migration function hangs at 9 minutes
❌ Partial data migrated
❌ Verify shows mixed state
```

**Diagnosis:**
```bash
# Check function logs
firebase functions:log | grep -i timeout

# Count total users
firebase firestore:size --collection=users
```

**Solutions:**

**If < 500 users:**
- Retry migration (idempotent - safe)
- Increase memory in function configuration

**If > 500 users:**
- Split into batches:
  ```bash
  # Add startAfter parameter to migration function
  # Run multiple times with batch size 100
  
  curl -X POST "...migrateBusinessProfiles?startAfter=user123" ...
  ```

- Increase timeout in function code:
  ```typescript
  // Change timeoutSeconds from 540 to 900
  .runWith({ timeoutSeconds: 900 })
  ```

---

### Issue 4: High Error Rate in Logs

**Symptoms:**
```
❌ Multiple errors in Firebase logs
❌ Some operations failing
❌ Inconsistent behavior
```

**Common Errors & Fixes:**

| Error | Cause | Fix |
|-------|-------|-----|
| `Permission denied` | Firestore rules wrong | Re-deploy rules |
| `Document not found` | Migration incomplete | Run migration function |
| `Invalid field value` | Type mismatch in serialization | Check BusinessProfile.fromMap() |
| `Timeout` | Operation too slow | Optimize query or increase timeout |
| `Out of memory` | Function memory exceeded | Increase memory allocation |
| `Auth token expired` | Migration function auth issue | Get new admin token |

---

### Issue 5: Invoice Exports Missing Branding

**Symptoms:**
```
❌ Invoice PDF has no color
❌ Logo not showing
❌ Business name missing
```

**Diagnosis:**
```
1. Check: Is businessProvider.profile null?
2. Check: Are PDF export services using getFullBusinessProfile()?
3. Check: Is logo URL valid?
4. Check: Are colors in correct format (#RRGGBB)?
```

**Solutions:**

**If profile is null:**
- User not logged in (confirm auth state)
- Profile not created (create in settings)
- Profile not loaded (check Firestore rules)

**If profile exists but branding doesn't apply:**
- Check PDF export service uses profile
- Verify colors are proper format
- Verify logo URL is accessible
- Check PDF library version (should be 3.11.3+)

**Quick Test:**
```bash
# Check if profile exists
firebase firestore:inspect --document="users/{userId}/meta/business"

# If exists, check fields:
# ✅ brandColor: should be like "#0A84FF"
# ✅ logoUrl: should be valid URL
# ✅ businessName: should have value
```

---

## 📝 Regular Maintenance

### Daily (Automated)

**Set up daily monitoring:**
```bash
# Create scheduled function to check daily
# (In your Firebase project)

# Check:
- Error rates
- Performance metrics
- Firestore usage
- Function execution times
```

### Weekly

**Manual review:**
- [ ] Check Firestore usage trends
- [ ] Review error logs
- [ ] Verify migration progress (if manual)
- [ ] Test new user flow
- [ ] Check performance metrics

### Monthly

**Deep dive:**
- [ ] Review cost vs. baseline
- [ ] Analyze user growth impact
- [ ] Plan capacity upgrades
- [ ] Review security logs
- [ ] Update documentation

### Quarterly

**Strategic review:**
- [ ] Assess feature adoption
- [ ] Plan feature additions
- [ ] Review architecture decisions
- [ ] Update performance benchmarks
- [ ] Plan infrastructure upgrades

---

## 🎯 Success Metrics

### KPIs to Track

**Reliability:**
- [ ] Profile load success rate: >99%
- [ ] Invoice export success rate: >99%
- [ ] API error rate: <0.1%
- [ ] Uptime: >99.5%

**Performance:**
- [ ] Profile load time: <200ms
- [ ] Invoice export time: <1000ms
- [ ] Firestore latency: <50ms
- [ ] App startup time: <2000ms

**Adoption:**
- [ ] % of users with business profile: >50%
- [ ] % of invoices using business branding: >80%
- [ ] User satisfaction: >4.0/5.0

**Operational:**
- [ ] Error logs reviewed: Daily
- [ ] Quota monitoring: Real-time
- [ ] Backup completion: 100%
- [ ] Incident response: <1 hour

---

## 🔄 Rollback Procedures

**If you need to rollback the entire deployment:**

### Step 1: Stop Using New Feature
```bash
# In feature_constants.dart
const bool BUSINESS_PROFILE_ENABLED = false;
```

### Step 2: Deploy Revert Code
```bash
git revert <deployment-commit>
flutter pub get
flutter build apk/ios
# Deploy to stores
```

### Step 3: Restore Data (If Needed)
```bash
# If migration was run and data needs reverting
curl -X POST \
  https://your-project.cloudfunctions.net/rollbackBusinessProfileMigration \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Step 4: Verify Rollback
```bash
# Test that old code still works
# Verify Firestore has old structure
firebase firestore:inspect --document="users/{userId}"
```

---

## 📞 Escalation Paths

**For Different Issues:**

| Issue | Owner | Escalation |
|-------|-------|-----------|
| Firestore quota exceeded | DevOps | Firebase Support |
| High error rate | Backend | Senior Engineer |
| User complaints | Support | Product Manager |
| Performance degradation | Platform | Infrastructure Team |
| Security concern | Security | Security Lead |

---

## 📚 Reference Documentation

**For different operational needs:**

- Quick troubleshoot: [BUSINESSPROVIDER_QUICK_START.md](BUSINESSPROVIDER_QUICK_START.md)
- Complete guide: [BUSINESSPROVIDER_FINAL_SUMMARY.md](BUSINESSPROVIDER_FINAL_SUMMARY.md)
- Migration help: [BUSINESS_PROFILE_MIGRATION_GUIDE.md](BUSINESS_PROFILE_MIGRATION_GUIDE.md)
- Deployment checklist: [BUSINESSPROVIDER_DEPLOYMENT_CHECKLIST.md](BUSINESSPROVIDER_DEPLOYMENT_CHECKLIST.md)

---

## ✅ Deployment Sign-Off

After completing the steps above:

- [ ] Day 1-3: Monitor metrics and logs
- [ ] Day 3-7: Complete data migration
- [ ] Week 1-2: Validate user flows
- [ ] Week 2-4: Tune performance
- [ ] Month 1: Establish operational baseline
- [ ] Month 3: Strategic review

---

## 🎓 Team Training

### For Developers
- Understand BusinessProvider initialization
- Know how to update business profile
- Understand Firestore security rules
- Know where to find logs

### For Operations
- Monitor Firebase metrics
- Know how to run migration
- Know rollback procedures
- Know escalation paths

### For Support
- Understand user flow
- Know how to check profile status
- Know common issues and fixes
- Know escalation procedures

---

## 📋 Checklist for Day 1

Production deployment checklist:

- [ ] Firestore rules deployed
- [ ] Cloud Functions deployed
- [ ] App version published
- [ ] Firebase console monitored
- [ ] Team notified of go-live
- [ ] Support team briefed
- [ ] Rollback plan reviewed
- [ ] Escalation contacts listed
- [ ] Documentation linked from wiki
- [ ] Success criteria documented

---

## ✨ Summary

**What to do after deployment:**

1. **Immediately** (Day 1): Monitor Firebase metrics
2. **Early** (Days 3-7): Run data migration
3. **First week**: Validate complete user flow
4. **First month**: Establish baseline and optimize
5. **Ongoing**: Daily monitoring, weekly review, monthly analysis

**Expected Outcome:**
- 100% of users have profiles (migrated or auto-created)
- All invoices include business branding
- Zero critical issues
- <0.1% error rate
- System performing within baseline

---

**Status:** 🟢 Ready for Production Operations

*This guide covers everything needed to successfully operate the Business Profile system after deployment.*

---

*Last updated: November 29, 2025*  
*Reference: BUSINESSPROVIDER_FINAL_SUMMARY.md*

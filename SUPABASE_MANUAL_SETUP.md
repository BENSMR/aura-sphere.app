# Supabase Setup — Manual Dashboard Method

> **Status**: ✅ PostgreSQL schema ready | ⏳ Awaiting your manual Supabase setup

Since the Supabase CLI installation is blocked in this environment, use the **Supabase Dashboard** instead (faster anyway).

---

## What's Already Done ✅

1. **PostgreSQL Schema Created**
   - File: `supabase/migrations/20251219000000_init.sql` (445 lines)
   - 35 tables with relationships, RLS policies, and indexes
   - Committed to GitHub (commit `4ae64844`)

2. **Migration Specifications Complete**
   - `MIGRATION_AGENT_BRIEF.md` - 6-phase execution plan
   - `MIGRATION_FIREBASE_TO_SUPABASE.md` - Technical reference
   - 3 service code templates (user, invoice, expense)

3. **Environment Template**
   - `.env.local.example` - Copy this to `.env.local` and fill in credentials

---

## What You Need to Do (5 minutes)

### Step 1: Deploy Schema to Supabase

1. Go to https://supabase.com/dashboard
2. Select your project `fppmuibvpxrkwmymszhd`
3. Click **SQL Editor** (left sidebar)
4. Click **"New Query"** button
5. Open this file locally:
   ```
   supabase/migrations/20251219000000_init.sql
   ```
6. Copy **entire contents** (445 lines)
7. Paste into Supabase SQL Editor
8. Click **"Run"** button (⏵ icon, top right)
9. Wait for success message ✅

### Step 2: Verify Schema Deployed

In **SQL Editor**, run:
```sql
SELECT COUNT(*) as table_count 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

Should return: `35` (25 user-owned tables + 10 shared tables)

### Step 3: Get Your Credentials

1. Click **Settings** (bottom left)
2. Click **API**
3. Find and copy:
   - **Project URL** → looks like `https://fppmuibvpxrkwmymszhd.supabase.co`
   - **Anon (public) key** → starts with `eyJ...` (long token)
   - **Service Role key** (for backend functions)

### Step 4: Create `.env.local`

In project root, create/edit `.env.local`:

```bash
cp .env.local.example .env.local
```

Then edit `.env.local`:

```env
SUPABASE_URL=https://fppmuibvpxrkwmymszhd.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Replace with your **actual** values from Step 3.

⚠️ **Important**: 
- `.env.local` is already in `.gitignore` (won't be committed)
- Never share SUPABASE_SERVICE_ROLE_KEY publicly
- SUPABASE_ANON_KEY is safe to expose (it's the public key)

### Step 5: Ready for Agent Handoff ✅

Once above steps complete, you have:
- ✅ PostgreSQL schema deployed
- ✅ Supabase project ready
- ✅ `.env.local` configured
- ✅ Migration specifications ready
- ✅ Code templates ready

Now hand to coding agent:
- `MIGRATION_AGENT_BRIEF.md` (execution plan)
- `.env.local` (credentials)

---

## Quick Checklist

- [ ] Go to https://supabase.com/dashboard
- [ ] Select project `fppmuibvpxrkwmymszhd`
- [ ] **SQL Editor** → New Query
- [ ] Copy `supabase/migrations/20251219000000_init.sql` (entire file, 445 lines)
- [ ] Paste into SQL Editor
- [ ] Click **Run** 
- [ ] Wait for ✅ success
- [ ] Verify: Run table count query (should show 35)
- [ ] **Settings** → **API** → Copy credentials
- [ ] Create `.env.local` with:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY`
- [ ] Ready for agent handoff ✅

---

## Troubleshooting

**Q: Schema deployment failed?**  
A: Check for syntax errors. If stuck, run schema one table at a time.

**Q: Can't find credentials?**  
A: In Supabase dashboard → **Settings** → **API** → look for "Project URL" (not "Connection String")

**Q: Want to see schema visually?**  
A: In Supabase dashboard → **Database** → **Tables** → browse tables (after deployment)

**Q: What if I make a mistake?**  
A: Go to **Settings** → **Database** → **Reset Database** (starts fresh, loses all data)

---

## Time Estimate

| Step | Time |
|------|------|
| Deploy schema | 2 min |
| Verify schema | 1 min |
| Get credentials | 1 min |
| Create `.env.local` | 1 min |
| **Total** | **~5 min** |

---

## Next: Agent Execution

Once above complete, hand to coding agent:

```
Files to provide:
- MIGRATION_AGENT_BRIEF.md (main execution guide)
- MIGRATION_FIREBASE_TO_SUPABASE.md (technical reference)
- .env.local (SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY)
- lib/services/*_supabase.dart (code templates)

Agent will:
- Phase 1 (Days 1-3): Update dependencies, setup auth
- Phase 2 (Days 4-7): Convert models to snake_case
- Phase 3 (Days 8-12): Update providers for Supabase streams
- Phase 4 (Days 13-16): Migrate all services to postgrest
- Phase 5 (Days 17-21): Convert 179 Cloud Functions → Edge Functions
- Phase 6 (Days 22-25): Testing, cleanup, Firebase removal

Deliverable: Single PR with all changes
```

---

**Status**: 🟢 Ready for manual Supabase setup via dashboard

# Supabase Setup via Dashboard (5-Minute Guide)

> **You are here**: Setup Phase | **Next**: Hand specifications to coding agent

## Step 1: Create Supabase Account & Project (3 min)

1. Open https://supabase.com in browser
2. Click **"Sign Up"** (or login if you have account)
3. Create account with email
4. Go to **Dashboard** → Click **"New Project"**
5. Fill in:
   - **Name**: `aura-sphere-pro`
   - **Password**: Store securely (you'll need this)
   - **Region**: Pick closest to your users (e.g., `us-east-1`)
6. Click **"Create new project"** → Wait 2-3 min for database to spin up

## Step 2: Get Credentials (1 min)

Once project dashboard loads:

1. Click **Settings** (bottom left sidebar)
2. Click **API** 
3. Copy these two values:
   - **Project URL** → Save as `SUPABASE_URL`
   - **Anon (Public) key** → Save as `SUPABASE_ANON_KEY`

**Example:**
```
SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Step 3: Deploy PostgreSQL Schema (1 min)

1. In project dashboard, click **SQL Editor** (left sidebar)
2. Click **"New Query"**
3. **Copy-paste the entire schema** from:
   - File: [MIGRATION_FIREBASE_TO_SUPABASE.md](MIGRATION_FIREBASE_TO_SUPABASE.md#postgresql-schema-complete-structure)
   - Section: "PostgreSQL Schema - Complete Structure"
4. Click **"Run"** (⏵ button, top right)
5. Wait for success message ✅

## Step 4: Create .env.local (1 min)

In project root (`/workspaces/aura-sphere-pro/`), create file:

**File: `.env.local`**
```bash
SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Replace with your actual values from Step 2.

## Step 5: Verify Setup (Optional)

In Supabase dashboard:
- Go to **SQL Editor** → Run this query:
  ```sql
  SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
  ```
- Should see 35 tables listed (users, invoices, expenses, etc.)

---

## You Are Done! ✅

**Next steps:**
1. Pass these files to coding agent:
   - `MIGRATION_AGENT_BRIEF.md` ← **Main execution guide**
   - `MIGRATION_FIREBASE_TO_SUPABASE.md` ← **Complete spec reference**
   - `.env.local` ← **Credentials (secured)**

2. Agent will execute 6-phase migration over 25-30 days

3. Deliverable: Single PR with all Firebase → Supabase code changes

---

## Troubleshooting

**Q: Schema deployment failed?**  
A: Check for SQL syntax errors. If stuck, paste schema in Supabase's SQL Editor one table at a time.

**Q: Can't find API credentials?**  
A: Go to **Settings** → **API** → look for "Project URL" and "Anon" key (not "service_role").

**Q: Need to reset database?**  
A: In **Settings** → **Database** → **Reset Database** (destructive, starts fresh).

---

**Time elapsed**: ~5 minutes | **Ready for agent**: ✅ YES

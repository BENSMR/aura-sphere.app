# 🚀 Deploy Aurasphere Landing Page with GitHub Pages

This guide shows how to deploy your Aurasphere landing page for free using GitHub Pages.

---

## 📋 Quick Setup (5 Minutes)

### Step 1: Push Code to GitHub

```bash
cd /workspaces/aura-sphere-pro

# Add the index.html file
git add index.html

# Commit
git commit -m "feat: add aurasphere landing page"

# Push to GitHub main branch
git push origin main
```

### Step 2: Enable GitHub Pages in Repository Settings

1. Go to your GitHub repository: `https://github.com/BENSMR/aura-sphere.app`
2. Click **Settings** (top right)
3. Select **Pages** (left sidebar)
4. Under "Build and deployment":
   - **Source**: Select `Deploy from a branch`
   - **Branch**: Select `main`
   - **Folder**: Select `/ (root)`
   - Click **Save**

### Step 3: Your Site is Live! 🎉

GitHub Pages will automatically deploy your site.

- **URL**: `https://BENSMR.github.io/aura-sphere.app/`
- **Status**: Check "Pages" section (it will show "Your site is live")

---

## 🎯 What Happened

GitHub Pages:
- ✅ Takes your repository
- ✅ Deploys `index.html` as the homepage
- ✅ Hosts it for free at `https://YOUR_USERNAME.github.io/YOUR_REPO/`
- ✅ Updates automatically when you push to `main`

---

## 📝 Important Notes

### 1. **Custom Domain** (Optional)

If you own a domain (e.g., `aurasphere.io`):

1. In GitHub Settings → Pages → Custom domain
2. Enter: `aurasphere.io`
3. Update your domain's DNS settings:
   ```
   CNAME record → BENSMR.github.io
   ```
4. Click Save

GitHub automatically creates a CNAME file and sets up HTTPS.

### 2. **Update Formspree ID**

The form currently uses a placeholder: `https://formspree.io/f/YOUR_FORMSPREE_ID`

To make the form work:

1. Go to [formspree.io](https://formspree.io)
2. Create a new form (it's free)
3. Copy your form ID (looks like: `m1a2b3c4`)
4. Update the form action in `index.html`:

```html
<form action="https://formspree.io/f/m1a2b3c4" method="POST">
```

### 3. **Additional Pages** (Privacy, Terms, Refund)

Create these files in the repo:

**File: `privacy.html`**
```html
<!DOCTYPE html>
<html>
<head><title>Privacy Policy</title></head>
<body style="background:#000; color:#fff; font-family:sans-serif; padding:2rem;">
  <h1>Privacy Policy</h1>
  <p>Black Diamond LTD (UIC: 207807571, Sofia, Bulgaria)</p>
  <p>Your privacy is important to us...</p>
  <a href="/">← Back Home</a>
</body>
</html>
```

**File: `terms.html`**
```html
<!DOCTYPE html>
<html>
<head><title>Terms of Service</title></head>
<body style="background:#000; color:#fff; font-family:sans-serif; padding:2rem;">
  <h1>Terms of Service</h1>
  <p>By using Aurasphere...</p>
  <a href="/">← Back Home</a>
</body>
</html>
```

**File: `refund.html`**
```html
<!DOCTYPE html>
<html>
<head><title>Refund Policy</title></head>
<body style="background:#000; color:#fff; font-family:sans-serif; padding:2rem;">
  <h1>Refund Policy</h1>
  <p>30-day money-back guarantee...</p>
  <a href="/">← Back Home</a>
</body>
</html>
```

Then push them:
```bash
git add privacy.html terms.html refund.html
git commit -m "docs: add legal pages"
git push origin main
```

---

## 🔄 Continuous Deployment

Every time you push to `main`:
1. GitHub automatically deploys your changes
2. Site updates in ~30 seconds
3. No build process needed (GitHub Pages handles static HTML)

```bash
# Make a change to index.html
# Then:
git add index.html
git commit -m "update: landing page copy"
git push origin main

# Your live site updates automatically ✅
```

---

## 📊 Monitor Deployment Status

**In GitHub Repository**:
1. Go to **Settings** → **Pages**
2. Scroll down to "Deployments" section
3. Click the latest deployment to see:
   - ✅ If deployed successfully
   - ❌ Any errors
   - 🔗 Live URL

Or watch the **Actions** tab:
- Click **Actions** (top menu)
- Watch the GitHub Pages deployment run
- See logs if there are issues

---

## 🎨 Making Changes

After deployment, you can make changes anytime:

### Update styling:
```html
<!-- In <style> section -->
:root {
  --accent: #00ff00; /* Change color */
}
```

### Update copy:
```html
<h1>New Heading</h1>
<p>New description...</p>
```

### Update pricing:
```html
<div class="plan-card">
  <h3>Pro</h3>
  <div class="price">$19.99/mo</div>
  <p>New features here...</p>
</div>
```

Then push:
```bash
git add index.html
git commit -m "update: [describe changes]"
git push origin main
```

Changes live in ~30 seconds.

---

## 🚨 Troubleshooting

### "Site not live yet"
- Wait 2-3 minutes for GitHub Pages to build
- Check Settings → Pages → Deployment status
- Ensure branch is `main` and folder is `/`

### "404 error on live site"
- Make sure `index.html` is in repository root (not in a folder)
- Check file path: `/workspaces/aura-sphere-pro/index.html`
- Commit message format doesn't matter, just `git push`

### "Form doesn't submit"
- Update `YOUR_FORMSPREE_ID` with real ID from formspree.io
- Check browser console (F12) for errors
- Formspree requires valid email

### "Custom domain not working"
- Wait 24-48 hours for DNS propagation
- Check CNAME record is set correctly in domain registrar
- GitHub should auto-create CNAME file in repo

---

## ✅ Deployment Checklist

- [x] `index.html` pushed to GitHub
- [ ] GitHub Pages enabled in Settings
- [ ] Site live at `https://BENSMR.github.io/aura-sphere.app/`
- [ ] Form ID updated (Formspree)
- [ ] Privacy/Terms pages added (optional)
- [ ] Custom domain configured (optional)

---

## 📱 Mobile Preview

Your site is **fully responsive**:
- ✅ Desktop (1440px+)
- ✅ Tablet (768px - 1023px)
- ✅ Mobile (320px - 767px)

Test it:
```bash
# During development
python3 -m http.server 8000
# Visit: http://localhost:8000
```

---

## 🔗 Useful Links

- **GitHub Pages Docs**: https://pages.github.com/
- **Formspree**: https://formspree.io/
- **Custom Domain**: https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site
- **Deploy Status**: https://github.com/BENSMR/aura-sphere.app/settings/pages

---

## 🎯 Next Steps

1. **Push code** (see Step 1 above)
2. **Enable Pages** (see Step 2 above)
3. **Wait 2 minutes** for deployment
4. **Visit your live site** 🚀
5. **Update Formspree ID** to make form work
6. **Add legal pages** (privacy, terms, refund)
7. **Configure custom domain** (if you own one)

---

**Your Aurasphere landing page is now live with GitHub Pages!** 🌟

Need help? Check the [GitHub Pages documentation](https://pages.github.com/) or ask me!

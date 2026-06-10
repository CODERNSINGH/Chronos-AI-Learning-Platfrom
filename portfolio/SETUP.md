# 🚀 Quick Setup Guide

## Step 1: Personalize Your Website (5 minutes)

### A. Update GitHub Links
Open `index.html` and find & replace:
- Search: `https://github.com`
- Replace with: `https://github.com/yourprofile/chronos`

### B. Update Contact Information
Around line 460, update:
```html
<p><a href="mailto:your.email@example.com">your.email@example.com</a></p>
<p><a href="https://linkedin.com/in/yourname" target="_blank">linkedin.com/in/yourname</a></p>
```

### C. Update App Description (Optional)
In the hero section, customize:
```html
<h1 class="hero-title">
    Learn Smarter with
    <span class="gradient-text">Chronos</span>
</h1>
<p class="hero-subtitle">
    Your custom description here...
</p>
```

## Step 2: Test Locally (1 minute)

```bash
# Navigate to portfolio folder
cd portfolio

# Open in browser (Mac)
open index.html

# Or on Windows
start index.html

# Or on Linux
firefox index.html
```

## Step 3: Deploy to Internet (Choose One)

### ✅ Option 1: GitHub Pages (Recommended for Developers)

```bash
# 1. Create GitHub repository named "chronos-portfolio"
# 2. In portfolio folder:
git init
git add .
git commit -m "Add Chronos portfolio website"
git branch -M main
git remote add origin https://github.com/yourprofile/chronos-portfolio.git
git push -u origin main

# 3. Go to repository Settings → Pages
# 4. Select "Deploy from branch" → main branch
# 5. Wait 2-3 minutes
# Your site: https://yourprofile.github.io/chronos-portfolio
```

### ✅ Option 2: Netlify (Fastest & Easiest)

1. Go to [netlify.com](https://netlify.com)
2. Sign up with GitHub
3. Click "New site from Git"
4. Select your portfolio repository
5. Click "Deploy"
6. Your site is live in seconds!

Optional: Connect your own domain

### ✅ Option 3: Vercel

1. Go to [vercel.com](https://vercel.com)
2. Sign up with GitHub
3. Click "New Project"
4. Select your repository
5. Click "Deploy"

## Step 4: Share Your Portfolio

Perfect links to share:
- **Portfolio**: Your deployed website URL
- **GitHub**: `https://github.com/yourprofile/chronos`
- **Project Showcase**: Link this in your resume/portfolio

## Customization Examples

### Change Brand Colors

Edit `styles.css` (line 14):
```css
:root {
    --primary-color: #FF6B6B;    /* Your color */
    --secondary-color: #4ECDC4;  /* Your color */
}
```

### Add Your Logo

Replace line 28 in `index.html`:
```html
<!-- From: -->
<span class="logo-icon">⏱️</span>

<!-- To: -->
<img src="your-logo.png" style="width: 28px; height: 28px;">
```

### Customize Welcome Message

Update line 122:
```html
<p class="hero-subtitle">
    Custom tagline about your app here
</p>
```

## File Structure

```
portfolio/
├── index.html          # Main website
├── styles.css          # Design system
├── script.js           # Interactions
├── README.md           # Documentation
├── SETUP.md            # This file
└── screenshots/        # Your app screenshots (19 images)
    ├── 01_onboarding.png
    ├── 02_model_picker.png
    └── ... (17 more)
```

## SEO Tips

Make your portfolio discoverable:

1. **Update Meta Tags** (index.html, line 6):
```html
<meta name="description" content="Chronos - Your App Description">
<meta name="keywords" content="ios, app, learning, ai">
```

2. **Update Title** (line 5):
```html
<title>Chronos - Your Portfolio | Developer Name</title>
```

3. **Add Google Analytics** (optional):
Add before `</body>` tag:
```html
<script async src="https://www.googletagmanager.com/gtag/js?id=YOUR-GA-ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'YOUR-GA-ID');
</script>
```

## Make the Contact Form Work

### Option A: FormSubmit.co (Easiest)

1. In `index.html`, find the form (around line 440)
2. Update the form action:
```html
<form class="contact-form" action="https://formspree.io/f/YOUR_FORM_ID" method="POST">
```
3. Replace `YOUR_FORM_ID` with your actual ID from formspree.io

### Option B: Netlify Forms (If using Netlify)

Just add this to the form tag:
```html
<form class="contact-form" name="contact" method="POST" netlify>
```

## Advanced Customization

### Add More Features
- Add testimonials section
- Add stats/metrics section
- Add blog link
- Add download link to app

### Performance Optimization
- Compress images with [TinyPNG.com](https://tinypng.com)
- Minify CSS/JS (if deploying)
- Use CDN for images

### Custom Domain
- Buy domain from Namecheap, GoDaddy, etc.
- Point domain to your deployment (see your host's docs)

## Troubleshooting

### Website doesn't look right
- Clear browser cache (Ctrl+Shift+Delete)
- Make sure all 3 files are in same folder
- Check console for errors (F12)

### Images not showing
- Verify screenshot folder path
- Check file names match exactly
- Ensure images are in `portfolio/screenshots/`

### Form not working
- Check browser console for errors (F12)
- Verify FormSubmit/Netlify setup
- Test with actual email address

### Deployment not working
- Make sure all files are pushed to git
- Check deployment service status
- Review error logs in deployment dashboard

## Tools Used

- **HTML5** - Semantic markup
- **CSS3** - Modern styling
- **JavaScript (ES6+)** - Vanilla interactions
- **Font**: SF Pro Display (Apple's system font)

No frameworks, no dependencies, no build process needed!

## What's Included

✅ 100% responsive design
✅ Smooth animations
✅ Dark mode ready
✅ All 19 screenshots
✅ Contact form
✅ GitHub integration
✅ Mobile optimized
✅ SEO ready
✅ Fast loading
✅ Easy customization

## Next Steps

1. ✅ Personalize content (5 min)
2. ✅ Test locally (1 min)
3. ✅ Deploy online (2-5 min)
4. ✅ Share with recruiters (∞ impressions!)

---

**Your professional portfolio is ready! 🎉**

Questions? Check README.md or review the code comments.

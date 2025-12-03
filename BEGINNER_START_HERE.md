# 🚀 Beginner's Quick Start Guide

**Welcome!** This guide will help you go from zero to deployed application.

## 📋 What You'll Do (In Order)

```
1. ✅ Verify Prerequisites
   └─> Run: verify-setup.bat (Windows) or bash verify-setup.sh (Mac/Linux)

2. ✅ Run App Locally
   └─> cd app && npm install && npm run dev
   └─> Open: http://localhost:3000

3. ✅ Test Docker Locally
   └─> cd app && docker build -t nextjs-app:local .
   └─> docker run -p 3000:3000 nextjs-app:local

4. ✅ Configure AWS
   └─> Get AWS Access Keys from AWS Console
   └─> Run: aws configure

5. ✅ Deploy Infrastructure
   └─> cd infrastructure/environments/dev
   └─> terraform init
   └─> terraform apply
   └─> Save the outputs!

6. ✅ Setup Bitbucket
   └─> Add 4 variables in Bitbucket (see Step 5 in guide)
   └─> Push code to develop branch

7. ✅ Verify Deployment
   └─> Check Bitbucket pipeline
   └─> Visit ALB URL from terraform output
```

## 🎯 Start Here

### Option 1: Complete Step-by-Step Guide
👉 **Read:** `STEP_BY_STEP_GUIDE.md` (detailed instructions for each step)

### Option 2: Quick Reference
👉 **Read:** `QUICKSTART.md` (quick commands)

### Option 3: Check Prerequisites First
👉 **Read:** `CHECK_PREREQUISITES.md`
👉 **Run:** `verify-setup.bat` (Windows) or `bash verify-setup.sh` (Mac/Linux)

## ⚡ Quick Commands Cheat Sheet

```bash
# 1. Run locally
cd app
npm install
npm run dev

# 2. Test Docker
docker build -t nextjs-app:local .
docker run -p 3000:3000 nextjs-app:local

# 3. Configure AWS
aws configure

# 4. Deploy infrastructure
cd infrastructure/environments/dev
terraform init
terraform apply

# 5. Get outputs (save these!)
terraform output

# 6. Push to Bitbucket
git add .
git commit -m "Initial commit"
git push origin develop
```

## 🆘 Need Help?

- **Detailed Guide:** `STEP_BY_STEP_GUIDE.md`
- **Architecture:** `README.md`
- **Troubleshooting:** See troubleshooting section in `STEP_BY_STEP_GUIDE.md`

## 📚 File Guide

- `STEP_BY_STEP_GUIDE.md` - **START HERE** - Complete beginner guide
- `QUICKSTART.md` - Quick reference for experienced users
- `README.md` - Architecture and technical details
- `CHECK_PREREQUISITES.md` - What you need before starting
- `verify-setup.bat` / `verify-setup.sh` - Check if everything is installed

---

**Ready?** Open `STEP_BY_STEP_GUIDE.md` and follow along! 🎉


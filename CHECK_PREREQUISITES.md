# Prerequisites Checklist

Before starting, verify you have everything installed:

## Required Software

### 1. Node.js
```bash
node --version
```
**Expected:** v18.0.0 or higher
**If missing:** Download from https://nodejs.org/

### 2. npm (comes with Node.js)
```bash
npm --version
```
**Expected:** v9.0.0 or higher

### 3. Docker
```bash
docker --version
```
**Expected:** Docker version 20.10 or higher
**If missing:** Download from https://www.docker.com/get-started

### 4. AWS CLI
```bash
aws --version
```
**Expected:** aws-cli/2.x.x
**If missing:** 
- Windows: Download MSI from https://aws.amazon.com/cli/
- Mac: `brew install awscli`
- Linux: `sudo apt-get install awscli` or `sudo yum install awscli`

### 5. Terraform
```bash
terraform --version
```
**Expected:** Terraform v1.5.0 or higher
**If missing:** Download from https://www.terraform.io/downloads

### 6. Git
```bash
git --version
```
**Expected:** git version 2.x.x
**If missing:** Download from https://git-scm.com/downloads

## Required Accounts

- [ ] AWS Account (https://aws.amazon.com)
- [ ] Bitbucket Account (https://bitbucket.org)
- [ ] Bitbucket Repository created

## AWS Setup

- [ ] AWS Account created and logged in
- [ ] IAM user created (or use root account - not recommended)
- [ ] Access Key ID obtained
- [ ] Secret Access Key obtained
- [ ] AWS CLI configured (`aws configure`)

## Verification Commands

Run these to verify everything:

```bash
# Check all versions
node --version && npm --version && docker --version && aws --version && terraform --version && git --version

# Test AWS connection (after configuring)
aws sts get-caller-identity

# Test Docker
docker ps

# Test Node.js
node -e "console.log('Node.js works!')"
```

If all commands work, you're ready to start! 🚀


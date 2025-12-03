# GCP Account Setup Guide for CA4

**Student**: Philip Eykamp
**Project**: CA4 Multi-Cloud Deployment
**Date**: November 13, 2025

---

## 🎯 Goal

Set up Google Cloud Platform account with $300 free credits (90 days) to deploy CA4's GKE compute tier.

---

## ⏱️ Estimated Time: 15-20 minutes

---

## 📋 Prerequisites

- **Credit card** (required for GCP account verification, won't be charged during free trial)
- **Email address** (can use existing Gmail or create new account)
- **Phone number** (for SMS verification)

---

## 🚀 Step-by-Step Setup

### Step 1: Create GCP Account (5 minutes)

1. **Navigate to GCP Free Tier**:
   - Open browser: https://cloud.google.com/free
   - Click **"Get started for free"** or **"Start free"**

2. **Sign in with Google Account**:
   - Use existing Gmail account, or
   - Create new Google account if you prefer separate identity for cloud work

3. **Country and Terms**:
   - Select **Country**: United States
   - Review and accept **Terms of Service**
   - Click **Continue**

---

### Step 2: Account Verification (5 minutes)

1. **Account Type**:
   - Select **Account type**: Individual (unless you have business account)

2. **Payment Information**:
   - Enter **credit card details**
   - ⚠️ **Important**: You will NOT be charged during 90-day free trial
   - GCP requires card for identity verification only
   - Billing will be paused until you manually upgrade to paid account

3. **Phone Verification**:
   - Enter **phone number**
   - Receive and enter **verification code** via SMS

4. **Activate Free Trial**:
   - Click **"Start my free trial"**
   - You should see: **"$300 credit activated"**

---

### Step 3: Verify Free Credits (2 minutes)

1. **Check Credit Balance**:
   - Go to: https://console.cloud.google.com/billing
   - Click on **"Billing Account"**
   - Verify: **"$300.00 credits remaining"**
   - Verify: **"Trial ends in 90 days"** (or similar)

2. **Confirm Billing Alert**:
   - Set up **budget alert** (optional but recommended):
     - Click **"Budgets & alerts"**
     - Create budget: **$100 threshold**
     - This emails you if you approach credit limit

---

### Step 4: Create CA4 Project (3 minutes)

1. **Create New Project**:
   - Go to: https://console.cloud.google.com/projectcreate
   - Or click **"Select a project"** (top bar) → **"New Project"**

2. **Project Settings**:
   - **Project name**: `ca4-multi-cloud` (or your choice)
   - **Project ID**: Will auto-generate (e.g., `ca4-multi-cloud-123456`)
     - ⚠️ **Copy this Project ID** - you'll need it for Terraform
   - **Organization**: None (unless you have one)
   - **Location**: No organization
   - Click **"Create"**

3. **Select Your Project**:
   - Wait for project creation (~10 seconds)
   - Click **"Select project"** when prompted
   - Verify project name appears in top bar

---

### Step 5: Enable Required APIs (5 minutes)

GCP requires enabling specific APIs before Terraform can use them.

1. **Enable Compute Engine API**:
   - Go to: https://console.cloud.google.com/apis/library/compute.googleapis.com
   - Click **"Enable"**
   - Wait for activation (~30 seconds)

2. **Enable Kubernetes Engine API**:
   - Go to: https://console.cloud.google.com/apis/library/container.googleapis.com
   - Click **"Enable"**
   - Wait for activation (~30 seconds)

3. **Enable IAM API** (for service accounts):
   - Go to: https://console.cloud.google.com/apis/library/iam.googleapis.com
   - Click **"Enable"**

4. **Enable Cloud Resource Manager API**:
   - Go to: https://console.cloud.google.com/apis/library/cloudresourcemanager.googleapis.com
   - Click **"Enable"**

**Alternative (Enable All at Once)**:
```bash
# If you have gcloud CLI installed (optional)
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

---

### Step 6: Create Service Account for Terraform (5 minutes)

Terraform needs credentials to manage GCP resources.

1. **Go to Service Accounts**:
   - Navigate to: https://console.cloud.google.com/iam-admin/serviceaccounts
   - Click **"Create Service Account"**

2. **Service Account Details**:
   - **Service account name**: `terraform-ca4`
   - **Service account ID**: `terraform-ca4` (auto-fills)
   - **Description**: "Terraform automation for CA4 multi-cloud deployment"
   - Click **"Create and Continue"**

3. **Grant Permissions**:
   - Click **"Select a role"**
   - Search and select: **"Kubernetes Engine Admin"**
   - Click **"Add Another Role"**
   - Search and select: **"Compute Admin"**
   - Click **"Add Another Role"**
   - Search and select: **"Service Account User"**
   - Click **"Continue"**
   - Click **"Done"** (skip user access for now)

4. **Create JSON Key**:
   - Find your `terraform-ca4` service account in the list
   - Click **three dots** (⋮) on the right → **"Manage keys"**
   - Click **"Add Key"** → **"Create new key"**
   - Select **"JSON"**
   - Click **"Create"**
   - ⚠️ **Save the JSON file** that downloads (e.g., `ca4-multi-cloud-123456-abcdef123456.json`)
   - ⚠️ **Move to safe location**: `~/.gcp/ca4-terraform-key.json`

```bash
# Create GCP credentials directory
mkdir -p ~/.gcp

# Move downloaded key (adjust filename)
mv ~/Downloads/ca4-multi-cloud-*-*.json ~/.gcp/ca4-terraform-key.json

# Secure the file (read-only for you)
chmod 600 ~/.gcp/ca4-terraform-key.json
```

---

## ✅ Verification Checklist

Before proceeding to Terraform, verify:

- [ ] GCP account created with $300 credits activated
- [ ] Credit balance shows **$300.00** at https://console.cloud.google.com/billing
- [ ] Project `ca4-multi-cloud` (or your name) created
- [ ] **Project ID copied** (e.g., `ca4-multi-cloud-123456`)
- [ ] Required APIs enabled:
  - [ ] Compute Engine API
  - [ ] Kubernetes Engine API
  - [ ] IAM API
  - [ ] Cloud Resource Manager API
- [ ] Service account `terraform-ca4` created with roles:
  - [ ] Kubernetes Engine Admin
  - [ ] Compute Admin
  - [ ] Service Account User
- [ ] JSON key downloaded and saved to `~/.gcp/ca4-terraform-key.json`

---

## 📝 Information to Save

You'll need these values for Terraform configuration:

```bash
# Save these values for terraform.tfvars
GCP_PROJECT_ID="ca4-multi-cloud-123456"  # Replace with your actual Project ID
GCP_REGION="us-central1"                 # Recommended: close to AWS us-east-2
GCP_CREDENTIALS_FILE="~/.gcp/ca4-terraform-key.json"
```

**Copy your actual Project ID**:
- Found at: https://console.cloud.google.com/home/dashboard
- Or in top bar dropdown (next to project name)

---

## 🔐 Security Best Practices

### Protect Your Service Account Key

The JSON key file is **highly sensitive** - it grants full access to your GCP project.

**Do**:
- ✅ Store in `~/.gcp/` directory (ignored by git)
- ✅ Set permissions to `600` (read-only for you)
- ✅ Never commit to git repository
- ✅ Delete old keys when no longer needed

**Don't**:
- ❌ Commit to GitHub
- ❌ Share in Slack/Discord
- ❌ Email to anyone
- ❌ Store in project directory (already in .gitignore as `**/serviceaccount.json`)

---

## 🧪 Optional: Test GCP CLI (if you want)

Install `gcloud` CLI for easier GCP management (optional):

```bash
# macOS (Homebrew)
brew install --cask google-cloud-sdk

# Verify installation
gcloud --version

# Authenticate with your GCP account
gcloud auth login

# Set default project
gcloud config set project ca4-multi-cloud-123456  # Use your Project ID

# Verify
gcloud config list
gcloud projects list
```

---

## 💰 Cost Monitoring

### Set Up Budget Alerts (Recommended)

1. Go to: https://console.cloud.google.com/billing/budgets
2. Click **"Create Budget"**
3. **Budget name**: "CA4 Monthly Budget"
4. **Projects**: Select `ca4-multi-cloud`
5. **Budget amount**:
   - Type: **Specified amount**
   - Target amount: **$100** (monthly)
6. **Threshold alerts**:
   - 50% = $50
   - 90% = $90
   - 100% = $100
7. Click **"Finish"**

You'll receive emails when spending approaches these thresholds.

---

## 🚧 Troubleshooting

### Issue: "Credit card declined"
**Solution**:
- Use different card
- Contact bank (may flag Google as suspicious transaction)
- Try prepaid Visa gift card (some work with GCP)

### Issue: "Project quota exceeded"
**Solution**:
- New accounts are limited to 1-2 projects initially
- Delete unused projects: https://console.cloud.google.com/cloud-resource-manager
- Or request quota increase

### Issue: "API not enabled" error during Terraform
**Solution**:
- Re-enable APIs from Step 5
- Wait 2-3 minutes for propagation
- Retry Terraform command

### Issue: "Permission denied" with service account
**Solution**:
- Verify service account has all 3 roles (Step 6)
- Re-download JSON key if corrupted
- Check `~/.gcp/ca4-terraform-key.json` file permissions

---

## 📚 Useful GCP Console Links

Once your project is set up:

- **Dashboard**: https://console.cloud.google.com/home/dashboard
- **Billing**: https://console.cloud.google.com/billing
- **Kubernetes Engine**: https://console.cloud.google.com/kubernetes/list
- **Compute Instances**: https://console.cloud.google.com/compute/instances
- **VPC Networks**: https://console.cloud.google.com/networking/networks/list
- **IAM**: https://console.cloud.google.com/iam-admin/iam
- **APIs & Services**: https://console.cloud.google.com/apis/dashboard

---

## ✅ Next Steps

Once your GCP account is set up:

1. ✅ **Notify me** - I'll create Terraform configuration for GKE cluster
2. ⏭️ **Terraform GCP** - Deploy 2-node GKE cluster (2-3 hours)
3. ⏭️ **WireGuard VPN** - Connect AWS ↔ GCP (2-3 hours)
4. ⏭️ **Deploy Applications** - Producer/Processor to GCP (1-2 hours)
5. ⏭️ **Test & Document** - VPN failure scenario (2-3 hours)

**Total remaining time**: 8-12 hours

---

## 🆘 Need Help?

If you encounter issues during GCP setup:

1. **Check GCP Status**: https://status.cloud.google.com/
2. **GCP Free Tier FAQ**: https://cloud.google.com/free/docs/free-cloud-features
3. **GCP Support**: https://console.cloud.google.com/support (available even on free tier)

---

**When you've completed the setup, let me know your GCP Project ID and I'll create the Terraform configuration!**

---

**Last Updated**: November 13, 2025
**Status**: Ready for GCP account creation

# gcloud CLI Setup Complete ✓

**Date**: November 17, 2025
**Status**: ✅ Successfully installed and configured

---

## Installation Summary

### What Was Installed

- **Google Cloud SDK**: Version 548.0.0
- **Location**: `/Users/jr.ikamp/Downloads/CA4/google-cloud-sdk/`
- **Python**: Using Anaconda Python 3.10.11
- **Authentication**: Service account `terraform-metals-price-tracker@metals-price-tracker.iam.gserviceaccount.com`

### Components Installed

- ✅ gcloud CLI Core Libraries
- ✅ BigQuery Command Line Tool (bq)
- ✅ Cloud Storage Command Line Tool (gsutil)
- ✅ Google Cloud CRC32C Hash Tool

### GCP Project Configuration

- **Project ID**: `metals-price-tracker`
- **Project Number**: `85308756208`
- **Project Status**: ACTIVE
- **Created**: November 18, 2025

### APIs Enabled

- ✅ Compute Engine API (`compute.googleapis.com`)
- ✅ Kubernetes Engine API (`container.googleapis.com`)
- ✅ IAM API (`iam.googleapis.com`)
- ✅ Cloud Resource Manager API (`cloudresourcemanager.googleapis.com`)

---

## How to Use gcloud

### Option 1: Source Environment Setup (Recommended)

Before running any gcloud or GCP deployment commands:

```bash
cd /Users/jr.ikamp/Downloads/CA4
source scripts/setup-gcloud-env.sh
```

This sets up:
- `PATH` to include gcloud CLI
- `CLOUDSDK_PYTHON` to use Python 3.10
- `CLOUDSDK_CORE_PROJECT` to metals-price-tracker

### Option 2: Run Deployment Script

The deployment script automatically sources the environment:

```bash
cd /Users/jr.ikamp/Downloads/CA4
./scripts/deploy-gcp-gke.sh
```

---

## Manual Shell Configuration (Optional)

If you want gcloud available in all terminal sessions, you need to add this to your shell profile.

**Note**: Your `~/.zshrc` is owned by root, so you'll need to use sudo:

```bash
sudo sh -c 'cat >> /Users/jr.ikamp/.zshrc << "EOF"

# Google Cloud SDK
export CLOUDSDK_PYTHON=/Users/jr.ikamp/Applications/anaconda3/bin/python3
source /Users/jr.ikamp/Downloads/CA4/google-cloud-sdk/path.zsh.inc
source /Users/jr.ikamp/Downloads/CA4/google-cloud-sdk/completion.zsh.inc
EOF'
```

Then reload your shell:
```bash
source ~/.zshrc
```

**Alternative**: Create a personal config file:

```bash
cat >> ~/.zshrc_personal << 'EOF'
# Google Cloud SDK
export CLOUDSDK_PYTHON=/Users/jr.ikamp/Applications/anaconda3/bin/python3
source /Users/jr.ikamp/Downloads/CA4/google-cloud-sdk/path.zsh.inc
source /Users/jr.ikamp/Downloads/CA4/google-cloud-sdk/completion.zsh.inc
EOF

# Add to main zshrc (one time):
echo "source ~/.zshrc_personal" | sudo tee -a ~/.zshrc
```

---

## Verification

### Test gcloud CLI

```bash
source scripts/setup-gcloud-env.sh
gcloud version
```

Expected output:
```
Google Cloud SDK 548.0.0
bq 2.1.25
core 2025.11.17
gcloud-crc32c 1.0.0
gsutil 5.35
```

### Check Authentication

```bash
source scripts/setup-gcloud-env.sh
gcloud auth list
```

Should show:
```
ACTIVE  ACCOUNT
*       terraform-metals-price-tracker@metals-price-tracker.iam.gserviceaccount.com
```

### Check Project

```bash
source scripts/setup-gcloud-env.sh
gcloud config get-value project
```

Should show:
```
metals-price-tracker
```

### List Enabled APIs

```bash
source scripts/setup-gcloud-env.sh
gcloud services list --enabled
```

---

## Troubleshooting

### Issue: "gcloud: command not found"

**Solution**: Source the environment setup:
```bash
source scripts/setup-gcloud-env.sh
```

### Issue: "Python version error"

**Solution**: The environment setup script sets `CLOUDSDK_PYTHON` to Python 3.10. Make sure to source it.

### Issue: "Permission denied"

**Solution**: Check that scripts are executable:
```bash
chmod +x scripts/setup-gcloud-env.sh
chmod +x scripts/deploy-gcp-gke.sh
```

---

## Common gcloud Commands

### Project Management

```bash
# List projects
gcloud projects list

# Describe project
gcloud projects describe metals-price-tracker

# Switch project
gcloud config set project metals-price-tracker
```

### API Management

```bash
# List enabled APIs
gcloud services list --enabled

# Enable API
gcloud services enable compute.googleapis.com

# Disable API (careful!)
gcloud services disable SOME-API
```

### Authentication

```bash
# List authenticated accounts
gcloud auth list

# Login with user account (interactive)
gcloud auth login

# Use service account (already configured)
gcloud auth activate-service-account --key-file=~/.gcp/metals-price-tracker-terraform-key.json
```

### GKE Commands

```bash
# List GKE clusters (after deployment)
gcloud container clusters list

# Get cluster credentials (for kubectl)
gcloud container clusters get-credentials ca4-gke-compute \
  --zone=us-central1-a \
  --project=metals-price-tracker

# Describe cluster
gcloud container clusters describe ca4-gke-compute \
  --zone=us-central1-a
```

---

## Next Steps

Now that gcloud is installed and configured:

1. ✅ **gcloud CLI installed** - Complete
2. ✅ **GCP project configured** - Complete
3. ✅ **APIs enabled** - Complete
4. ✅ **Service account authenticated** - Complete
5. ⏭️ **Deploy GCP infrastructure** - Ready to run:

```bash
cd /Users/jr.ikamp/Downloads/CA4
./scripts/deploy-gcp-gke.sh
```

This will:
- Deploy GKE cluster (2 nodes, e2-medium)
- Create VPC network
- Configure firewall rules
- Set up static IP for VPN gateway
- Configure kubectl for GKE cluster

**Deployment Time**: 5-8 minutes
**Cost**: $0 (using GCP free credits)

---

## Files Created

- `google-cloud-sdk/` - gcloud installation directory
- `scripts/setup-gcloud-env.sh` - Environment setup helper
- `scripts/deploy-gcp-gke.sh` - Updated deployment script (auto-sources env)

---

**Status**: ✅ Ready to deploy GCP infrastructure

#!/bin/bash
# Helper script to set up gcloud environment
# Source this file before running gcloud commands

export PATH=/Users/jr.ikamp/Downloads/CA4/google-cloud-sdk/bin:$PATH
export CLOUDSDK_PYTHON=/Users/jr.ikamp/Applications/anaconda3/bin/python3
export CLOUDSDK_CORE_PROJECT=metals-price-tracker

# Verify setup
if command -v gcloud &> /dev/null; then
    echo "✓ gcloud CLI configured"
    echo "  Version: $(gcloud version --format='value(Google Cloud SDK)')"
    echo "  Project: $(gcloud config get-value project 2>/dev/null)"
    echo "  Python: $CLOUDSDK_PYTHON"
else
    echo "✗ gcloud CLI not found"
    exit 1
fi

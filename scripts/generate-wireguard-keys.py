#!/usr/bin/env python3
"""
Generate WireGuard key pairs for AWS and GCP VPN
Uses Curve25519 for key generation (WireGuard standard)
"""

import base64
import os
from cryptography.hazmat.primitives.asymmetric import x25519
from cryptography.hazmat.primitives import serialization

def generate_keypair():
    """Generate a WireGuard-compatible private/public key pair"""
    # Generate private key
    private_key = x25519.X25519PrivateKey.generate()

    # Get public key
    public_key = private_key.public_key()

    # Serialize to WireGuard format (base64-encoded)
    private_bytes = private_key.private_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PrivateFormat.Raw,
        encryption_algorithm=serialization.NoEncryption()
    )

    public_bytes = public_key.public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw
    )

    # Base64 encode (WireGuard format)
    private_b64 = base64.b64encode(private_bytes).decode('utf-8')
    public_b64 = base64.b64encode(public_bytes).decode('utf-8')

    return private_b64, public_b64

if __name__ == "__main__":
    print("Generating WireGuard Key Pairs...")
    print("=" * 70)

    # Generate AWS keys
    aws_private, aws_public = generate_keypair()
    print("\n🔑 AWS VPN Gateway Keys:")
    print(f"Private Key: {aws_private}")
    print(f"Public Key:  {aws_public}")

    # Generate GCP keys
    gcp_private, gcp_public = generate_keypair()
    print("\n🔑 GCP VPN Gateway Keys:")
    print(f"Private Key: {gcp_private}")
    print(f"Public Key:  {gcp_public}")

    # Save to files
    os.makedirs("k8s/wireguard/keys", exist_ok=True)

    with open("k8s/wireguard/keys/aws-private.key", "w") as f:
        f.write(aws_private)
    with open("k8s/wireguard/keys/aws-public.key", "w") as f:
        f.write(aws_public)
    with open("k8s/wireguard/keys/gcp-private.key", "w") as f:
        f.write(gcp_private)
    with open("k8s/wireguard/keys/gcp-public.key", "w") as f:
        f.write(gcp_public)

    print("\n✅ Keys saved to k8s/wireguard/keys/")
    print("=" * 70)
    print("\n⚠️  IMPORTANT: These keys are sensitive! Never commit them to Git.")
    print("   They are already in .gitignore: k8s/wireguard/keys/")

#!/bin/bash
# Script pour auditer les ports exposés
# À exécuter sur le VPS via SSH

set -e

OUTPUT_DIR="proofs/SECURITY-COOLIFY-PROD/02_ports"

echo "=== Auditing exposed ports ==="

# 2.1) Audit ports exposés
sudo ss -lntp > "${OUTPUT_DIR}/ss_full.txt"
echo "✓ ss_full.txt created"

docker ps --format "table {{.Names}}\t{{.Ports}}" > "${OUTPUT_DIR}/docker_ports.txt"
echo "✓ docker_ports.txt created"

echo ""
echo "=== Port audit complete ==="
echo "Files saved in: ${OUTPUT_DIR}/"
echo ""
echo "Next step: Analyze outputs and create audit_ports.txt table"
echo "Then apply fixes and run post-fix verification"

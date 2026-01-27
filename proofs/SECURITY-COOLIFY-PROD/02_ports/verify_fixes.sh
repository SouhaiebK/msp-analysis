#!/bin/bash
# Script pour vérifier les ports après corrections
# À exécuter sur le VPS via SSH après avoir appliqué les fixes

set -e

OUTPUT_DIR="proofs/SECURITY-COOLIFY-PROD/02_ports"

echo "=== Verifying port fixes ==="

# 2.3) Preuve post-fix
sudo ss -lntp | egrep ':(5678|8000|5432|6379)\b' || true > "${OUTPUT_DIR}/post_fix_ss.txt"
echo "✓ post_fix_ss.txt created"

docker ps --format "table {{.Names}}\t{{.Ports}}" > "${OUTPUT_DIR}/post_fix_docker.txt"
echo "✓ post_fix_docker.txt created"

echo ""
echo "=== Post-fix verification complete ==="
echo "Files saved in: ${OUTPUT_DIR}/"
echo ""
echo "Check that no private services listen on 0.0.0.0"

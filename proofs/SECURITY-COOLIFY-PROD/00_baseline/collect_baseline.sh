#!/bin/bash
# Script pour collecter l'état baseline Docker et Coolify
# À exécuter sur le VPS via SSH

set -e

OUTPUT_DIR="proofs/SECURITY-COOLIFY-PROD/00_baseline"

echo "=== Collecting Docker baseline ==="
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}" > "${OUTPUT_DIR}/docker_ps.txt"
echo "✓ docker_ps.txt created"

docker network ls > "${OUTPUT_DIR}/docker_networks.txt"
echo "✓ docker_networks.txt created"

sudo ss -lntp > "${OUTPUT_DIR}/ss_listening.txt"
echo "✓ ss_listening.txt created"

echo ""
echo "=== Baseline collection complete ==="
echo "Files saved in: ${OUTPUT_DIR}/"
echo ""
echo "Next step: Document Coolify configuration in coolify_stacks.txt"

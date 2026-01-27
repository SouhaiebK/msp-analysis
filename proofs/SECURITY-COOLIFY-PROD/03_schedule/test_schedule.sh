#!/bin/bash
# Script pour tester les workflows Schedule Trigger
# À exécuter sur le VPS via SSH

set -e

OUTPUT_DIR="proofs/SECURITY-COOLIFY-PROD/03_schedule"

N8N_CONTAINER=$(docker ps | grep -i "n8n" | grep -v "worker" | awk '{print $1}' | head -n 1)

if [ -z "$N8N_CONTAINER" ]; then
    echo "ERROR: n8n container not found"
    exit 1
fi

echo "=== Testing n8n Schedule Trigger ==="
echo "n8n container: $N8N_CONTAINER"
echo ""

# 3.2) Vérifier timezone
echo "=== Step 3.2: Checking timezone configuration ==="
docker exec -it "$N8N_CONTAINER" sh -lc 'echo "GENERIC_TIMEZONE=$GENERIC_TIMEZONE"; date; ls -la' > "${OUTPUT_DIR}/timezone_config.txt" 2>&1
echo "✓ timezone_config.txt created"

# 3.3) Logs récents (pour workflows schedule)
echo "=== Step 3.3: Collecting recent logs ==="
docker logs --since=10m "$N8N_CONTAINER" | tail -n 200 > "${OUTPUT_DIR}/logs_test.txt" 2>&1
echo "✓ logs_test.txt created"

echo ""
echo "=== Schedule tests complete ==="
echo "Files saved in: ${OUTPUT_DIR}/"
echo ""
echo "Next step: Check UI n8n for workflow executions and document in executions_test.txt"

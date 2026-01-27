#!/bin/bash
# Script pour tester la connectivité réseau entre n8n et analytics-api
# À exécuter sur le VPS via SSH après configuration Coolify

set -e

OUTPUT_DIR="proofs/SECURITY-COOLIFY-PROD/01_network"

# Variables (à adapter selon votre configuration)
ANALYTICS_CONTAINER=$(docker ps | grep -i "analytics" | grep -v "worker" | awk '{print $1}' | head -n 1)
N8N_CONTAINER=$(docker ps | grep -i "n8n" | grep -v "worker" | awk '{print $1}' | head -n 1)
DESTINATION_NETWORK="${DESTINATION_NETWORK:-coolify-destination-1}"  # À remplacer par le vrai nom

if [ -z "$ANALYTICS_CONTAINER" ]; then
    echo "ERROR: Analytics container not found"
    exit 1
fi

if [ -z "$N8N_CONTAINER" ]; then
    echo "ERROR: n8n container not found"
    exit 1
fi

echo "=== Network connectivity tests ==="
echo "Analytics container: $ANALYTICS_CONTAINER"
echo "n8n container: $N8N_CONTAINER"
echo "Destination network: $DESTINATION_NETWORK"
echo ""

# 1.2) Identification hostname réel
echo "=== Step 1.2: Identifying analytics hostname ==="
docker inspect "$ANALYTICS_CONTAINER" --format '{{json .NetworkSettings.Networks}}' > "${OUTPUT_DIR}/container_network.json"
echo "✓ container_network.json created"

docker network inspect "$DESTINATION_NETWORK" | head -n 80 > "${OUTPUT_DIR}/network_inspect.txt"
echo "✓ network_inspect.txt created"

# Extraire le hostname depuis le réseau
ANALYTICS_HOSTNAME=$(docker inspect "$ANALYTICS_CONTAINER" --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{end}}' | xargs -I {} docker network inspect {} --format '{{range .Containers}}{{.Name}}{{end}}' | grep -i analytics | head -n 1)

if [ -z "$ANALYTICS_HOSTNAME" ]; then
    # Fallback: utiliser le nom du container
    ANALYTICS_HOSTNAME=$(docker inspect "$ANALYTICS_CONTAINER" --format '{{.Name}}' | sed 's/^\///')
fi

echo "Detected analytics hostname: $ANALYTICS_HOSTNAME"
echo ""

# 1.3) Tests connectivité depuis n8n
echo "=== Step 1.3: Testing connectivity from n8n ==="

# Test DNS
echo "Testing DNS resolution..."
docker exec -it "$N8N_CONTAINER" sh -lc "getent hosts $ANALYTICS_HOSTNAME || nslookup $ANALYTICS_HOSTNAME || true" > "${OUTPUT_DIR}/dns_test.txt" 2>&1
echo "✓ dns_test.txt created"

# Test HTTP
echo "Testing HTTP connectivity..."
docker exec -it "$N8N_CONTAINER" sh -lc "curl -sS -D- http://${ANALYTICS_HOSTNAME}:8000/health || curl -sS -D- http://${ANALYTICS_HOSTNAME}:8000/" > "${OUTPUT_DIR}/http_test.txt" 2>&1
echo "✓ http_test.txt created"

echo ""
echo "=== Network tests complete ==="
echo "Check outputs in: ${OUTPUT_DIR}/"

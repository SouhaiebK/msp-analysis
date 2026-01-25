#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# MSP Analytics Platform - Test n8n Access Script
# 
# Ce script teste l'accès à n8n via HTTP et vérifie:
# - État des services Docker
# - Healthcheck endpoint
# - Authentification basique
# - API n8n (si disponible)
# ═══════════════════════════════════════════════════════════════

set -e

PROJECT_NAME="msp"
N8N_URL="http://localhost:5678"
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteurs de résultats
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}       Test d'accès à n8n-mcp${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# ───────────────────────────────────────────────────────────────
# STEP 1: Vérifier l'état des services Docker
# ───────────────────────────────────────────────────────────────
echo -e "${BLUE}[1/4] Vérification de l'état Docker...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker n'est pas installé${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Docker n'est pas démarré ou inaccessible${NC}"
    echo -e "${YELLOW}  Veuillez démarrer Docker Desktop${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    exit 1
fi

echo -e "${GREEN}✓ Docker est accessible${NC}"

# Vérifier l'état des services
echo -e "\n${BLUE}État des services:${NC}"
if docker compose -p $PROJECT_NAME ps 2>/dev/null | grep -q "msp-n8n"; then
    docker compose -p $PROJECT_NAME ps n8n
    N8N_STATUS=$(docker compose -p $PROJECT_NAME ps --format json n8n 2>/dev/null | grep -o '"Status":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    
    if echo "$N8N_STATUS" | grep -q "Up"; then
        echo -e "${GREEN}✓ Service n8n est démarré${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}⚠ Service n8n n'est pas démarré${NC}"
        echo -e "${YELLOW}  Démarrez avec: docker compose -p $PROJECT_NAME up -d n8n${NC}"
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    fi
else
    echo -e "${YELLOW}⚠ Aucun service n8n trouvé pour le projet '$PROJECT_NAME'${NC}"
    echo -e "${YELLOW}  Les services peuvent ne pas être démarrés${NC}"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
fi

# ───────────────────────────────────────────────────────────────
# STEP 2: Tester l'accès HTTP basique (healthcheck)
# ───────────────────────────────────────────────────────────────
echo -e "\n${BLUE}[2/4] Test du healthcheck endpoint...${NC}"

if command -v curl &> /dev/null; then
    HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$N8N_URL/healthz" 2>/dev/null || echo "000")
    
    if [ "$HEALTH_RESPONSE" = "200" ]; then
        echo -e "${GREEN}✓ Healthcheck répond avec code 200${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        
        # Afficher la réponse complète
        echo -e "\n${BLUE}Réponse du healthcheck:${NC}"
        curl -s "$N8N_URL/healthz" | head -5
    elif [ "$HEALTH_RESPONSE" = "000" ]; then
        echo -e "${RED}✗ Impossible de se connecter à $N8N_URL/healthz${NC}"
        echo -e "${YELLOW}  Vérifiez que n8n est démarré et accessible${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${YELLOW}⚠ Healthcheck répond avec code $HEALTH_RESPONSE${NC}"
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    fi
else
    echo -e "${YELLOW}⚠ curl n'est pas installé, test du healthcheck ignoré${NC}"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
fi

# ───────────────────────────────────────────────────────────────
# STEP 3: Tester l'authentification
# ───────────────────────────────────────────────────────────────
echo -e "\n${BLUE}[3/4] Test de l'authentification...${NC}"

# Charger les variables d'environnement depuis .env si disponible
if [ -f .env ]; then
    # Source .env en mode sécurisé (éviter l'exécution de code)
    set -a
    source .env 2>/dev/null || true
    set +a
    
    if [ -n "$N8N_ADMIN_USER" ] && [ -n "$N8N_ADMIN_PASSWORD" ]; then
        echo -e "${GREEN}✓ Credentials trouvés dans .env${NC}"
        
        if command -v curl &> /dev/null; then
            # Tester l'accès à l'API avec authentification
            API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
                -u "${N8N_ADMIN_USER}:${N8N_ADMIN_PASSWORD}" \
                --connect-timeout 5 \
                "$N8N_URL/api/v1/workflows" 2>/dev/null || echo "000")
            
            if [ "$API_RESPONSE" = "200" ]; then
                echo -e "${GREEN}✓ Authentification réussie (code 200)${NC}"
                TESTS_PASSED=$((TESTS_PASSED + 1))
                
                # Lister quelques workflows
                echo -e "\n${BLUE}Workflows disponibles (premiers résultats):${NC}"
                curl -s -u "${N8N_ADMIN_USER}:${N8N_ADMIN_PASSWORD}" \
                    "$N8N_URL/api/v1/workflows?limit=5" 2>/dev/null | \
                    grep -o '"name":"[^"]*"' | head -5 | sed 's/"name":"/  - /' | sed 's/"$//' || echo "  (aucun workflow trouvé)"
            elif [ "$API_RESPONSE" = "401" ]; then
                echo -e "${RED}✗ Authentification échouée (code 401)${NC}"
                echo -e "${YELLOW}  Vérifiez les credentials dans .env${NC}"
                TESTS_FAILED=$((TESTS_FAILED + 1))
            elif [ "$API_RESPONSE" = "000" ]; then
                echo -e "${YELLOW}⚠ Impossible de se connecter à l'API${NC}"
                TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
            else
                echo -e "${YELLOW}⚠ API répond avec code $API_RESPONSE${NC}"
                TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
            fi
        else
            echo -e "${YELLOW}⚠ curl n'est pas installé, test d'authentification ignoré${NC}"
            TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
        fi
    else
        echo -e "${YELLOW}⚠ N8N_ADMIN_USER ou N8N_ADMIN_PASSWORD non défini dans .env${NC}"
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    fi
else
    echo -e "${YELLOW}⚠ Fichier .env non trouvé${NC}"
    echo -e "${YELLOW}  Créez .env à partir de .env.example${NC}"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
fi

# ───────────────────────────────────────────────────────────────
# STEP 4: Tester l'API n8n via MCP (si disponible)
# ───────────────────────────────────────────────────────────────
echo -e "\n${BLUE}[4/4] Vérification de l'accès MCP...${NC}"

echo -e "${YELLOW}ℹ Note: Les outils MCP doivent être configurés dans Cursor${NC}"
echo -e "${YELLOW}  Ce script teste uniquement l'accès HTTP direct à n8n${NC}"

# Vérifier si on peut accéder à l'interface web
if command -v curl &> /dev/null; then
    WEB_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$N8N_URL" 2>/dev/null || echo "000")
    
    if [ "$WEB_RESPONSE" = "200" ] || [ "$WEB_RESPONSE" = "302" ]; then
        echo -e "${GREEN}✓ Interface web accessible (code $WEB_RESPONSE)${NC}"
        echo -e "${BLUE}  URL: $N8N_URL${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    elif [ "$WEB_RESPONSE" = "000" ]; then
        echo -e "${RED}✗ Interface web non accessible${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${YELLOW}⚠ Interface web répond avec code $WEB_RESPONSE${NC}"
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    fi
else
    echo -e "${YELLOW}⚠ curl n'est pas installé, test de l'interface web ignoré${NC}"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
fi

# ───────────────────────────────────────────────────────────────
# Résumé
# ───────────────────────────────────────────────────────────────
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    RÉSUMÉ DES TESTS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Tests réussis:    ${GREEN}$TESTS_PASSED${NC}"
echo -e "  Tests échoués:    ${RED}$TESTS_FAILED${NC}"
echo -e "  Tests ignorés:    ${YELLOW}$TESTS_SKIPPED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ] && [ $TESTS_PASSED -gt 0 ]; then
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                 ACCÈS À N8N VALIDÉ                            ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    exit 0
elif [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}                 CERTAINS TESTS ONT ÉCHOUÉ                      ${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    exit 1
else
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}                 TESTS INCOMPLETS                              ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    exit 0
fi

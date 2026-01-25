# ═══════════════════════════════════════════════════════════════
# MSP Analytics Platform - Test n8n Access Script (PowerShell)
# 
# Ce script teste l'accès à n8n via HTTP et vérifie:
# - État des services Docker
# - Healthcheck endpoint
# - Authentification basique
# - API n8n (si disponible)
# ═══════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

$PROJECT_NAME = "msp"
$N8N_URL = "http://localhost:5678"

# Compteurs de résultats
$script:TESTS_PASSED = 0
$script:TESTS_FAILED = 0
$script:TESTS_SKIPPED = 0

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
Write-ColorOutput "       Test d'accès à n8n-mcp" "Cyan"
Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
Write-Host ""

# ───────────────────────────────────────────────────────────────
# STEP 1: Vérifier l'état des services Docker
# ───────────────────────────────────────────────────────────────
Write-ColorOutput "[1/4] Vérification de l'état Docker..." "Cyan"

try {
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker non disponible"
    }
    Write-ColorOutput "✓ Docker est accessible" "Green"
} catch {
    Write-ColorOutput "✗ Docker n'est pas installé ou démarré" "Red"
    Write-ColorOutput "  Veuillez démarrer Docker Desktop" "Yellow"
    $script:TESTS_FAILED++
    exit 1
}

# Vérifier l'état des services
Write-Host ""
Write-ColorOutput "État des services:" "Cyan"
try {
    $services = docker compose -p $PROJECT_NAME ps 2>&1
    if ($services -match "msp-n8n") {
        docker compose -p $PROJECT_NAME ps n8n
        
        $n8nStatus = docker compose -p $PROJECT_NAME ps --format json n8n 2>&1 | ConvertFrom-Json
        if ($n8nStatus.Status -match "Up") {
            Write-ColorOutput "✓ Service n8n est démarré" "Green"
            $script:TESTS_PASSED++
        } else {
            Write-ColorOutput "⚠ Service n8n n'est pas démarré" "Yellow"
            Write-ColorOutput "  Démarrez avec: docker compose -p $PROJECT_NAME up -d n8n" "Yellow"
            $script:TESTS_SKIPPED++
        }
    } else {
        Write-ColorOutput "⚠ Aucun service n8n trouvé pour le projet '$PROJECT_NAME'" "Yellow"
        Write-ColorOutput "  Les services peuvent ne pas être démarrés" "Yellow"
        $script:TESTS_SKIPPED++
    }
} catch {
    Write-ColorOutput "⚠ Impossible de vérifier l'état des services" "Yellow"
    $script:TESTS_SKIPPED++
}

# ───────────────────────────────────────────────────────────────
# STEP 2: Tester l'accès HTTP basique (healthcheck)
# ───────────────────────────────────────────────────────────────
Write-Host ""
Write-ColorOutput "[2/4] Test du healthcheck endpoint..." "Cyan"

try {
    $healthResponse = Invoke-WebRequest -Uri "$N8N_URL/healthz" -Method Get -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    
    if ($healthResponse.StatusCode -eq 200) {
        Write-ColorOutput "✓ Healthcheck répond avec code 200" "Green"
        $script:TESTS_PASSED++
        
        Write-Host ""
        Write-ColorOutput "Réponse du healthcheck:" "Cyan"
        Write-Host $healthResponse.Content
    } else {
        Write-ColorOutput "⚠ Healthcheck répond avec code $($healthResponse.StatusCode)" "Yellow"
        $script:TESTS_SKIPPED++
    }
} catch {
    Write-ColorOutput "✗ Impossible de se connecter à $N8N_URL/healthz" "Red"
    Write-ColorOutput "  Vérifiez que n8n est démarré et accessible" "Yellow"
    $script:TESTS_FAILED++
}

# ───────────────────────────────────────────────────────────────
# STEP 3: Tester l'authentification
# ───────────────────────────────────────────────────────────────
Write-Host ""
Write-ColorOutput "[3/4] Test de l'authentification..." "Cyan"

if (Test-Path ".env") {
    # Charger les variables d'environnement depuis .env
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]*)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
    
    $n8nUser = $env:N8N_ADMIN_USER
    $n8nPassword = $env:N8N_ADMIN_PASSWORD
    
    if ($n8nUser -and $n8nPassword) {
        Write-ColorOutput "✓ Credentials trouvés dans .env" "Green"
        
        try {
            $credPair = "$($n8nUser):$($n8nPassword)"
            $bytes = [System.Text.Encoding]::ASCII.GetBytes($credPair)
            $base64 = [System.Convert]::ToBase64String($bytes)
            $headers = @{
                "Authorization" = "Basic $base64"
            }
            
            $apiResponse = Invoke-WebRequest -Uri "$N8N_URL/api/v1/workflows" -Method Get -Headers $headers -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            
            if ($apiResponse.StatusCode -eq 200) {
                Write-ColorOutput "✓ Authentification réussie (code 200)" "Green"
                $script:TESTS_PASSED++
                
                # Lister quelques workflows
                Write-Host ""
                Write-ColorOutput "Workflows disponibles (premiers résultats):" "Cyan"
                $workflows = $apiResponse.Content | ConvertFrom-Json
                if ($workflows.data) {
                    $workflows.data | Select-Object -First 5 | ForEach-Object {
                        Write-Host "  - $($_.name)"
                    }
                } else {
                    Write-Host "  (aucun workflow trouvé)"
                }
            } else {
                Write-ColorOutput "⚠ API répond avec code $($apiResponse.StatusCode)" "Yellow"
                $script:TESTS_SKIPPED++
            }
        } catch {
            if ($_.Exception.Response.StatusCode -eq 401) {
                Write-ColorOutput "✗ Authentification échouée (code 401)" "Red"
                Write-ColorOutput "  Vérifiez les credentials dans .env" "Yellow"
                $script:TESTS_FAILED++
            } else {
                Write-ColorOutput "⚠ Impossible de se connecter à l'API" "Yellow"
                Write-Host "  Erreur: $($_.Exception.Message)"
                $script:TESTS_SKIPPED++
            }
        }
    } else {
        Write-ColorOutput "⚠ N8N_ADMIN_USER ou N8N_ADMIN_PASSWORD non défini dans .env" "Yellow"
        $script:TESTS_SKIPPED++
    }
} else {
    Write-ColorOutput "⚠ Fichier .env non trouvé" "Yellow"
    Write-ColorOutput "  Créez .env à partir de .env.example" "Yellow"
    $script:TESTS_SKIPPED++
}

# ───────────────────────────────────────────────────────────────
# STEP 4: Tester l'API n8n via MCP (si disponible)
# ───────────────────────────────────────────────────────────────
Write-Host ""
Write-ColorOutput "[4/4] Vérification de l'accès MCP..." "Cyan"

Write-ColorOutput "ℹ Note: Les outils MCP doivent être configurés dans Cursor" "Yellow"
Write-ColorOutput "  Ce script teste uniquement l'accès HTTP direct à n8n" "Yellow"

try {
    $webResponse = Invoke-WebRequest -Uri $N8N_URL -Method Get -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    
    if ($webResponse.StatusCode -eq 200 -or $webResponse.StatusCode -eq 302) {
        Write-ColorOutput "✓ Interface web accessible (code $($webResponse.StatusCode))" "Green"
        Write-ColorOutput "  URL: $N8N_URL" "Cyan"
        $script:TESTS_PASSED++
    } else {
        Write-ColorOutput "⚠ Interface web répond avec code $($webResponse.StatusCode)" "Yellow"
        $script:TESTS_SKIPPED++
    }
} catch {
    Write-ColorOutput "✗ Interface web non accessible" "Red"
    $script:TESTS_FAILED++
}

# ───────────────────────────────────────────────────────────────
# Résumé
# ───────────────────────────────────────────────────────────────
Write-Host ""
Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
Write-ColorOutput "                    RÉSUMÉ DES TESTS" "Cyan"
Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
Write-Host ""
Write-Host "  Tests réussis:    $($script:TESTS_PASSED)" -ForegroundColor Green
Write-Host "  Tests échoués:    $($script:TESTS_FAILED)" -ForegroundColor Red
Write-Host "  Tests ignorés:    $($script:TESTS_SKIPPED)" -ForegroundColor Yellow
Write-Host ""

if ($script:TESTS_FAILED -eq 0 -and $script:TESTS_PASSED -gt 0) {
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Green"
    Write-ColorOutput "                 ACCÈS À N8N VALIDÉ                            " "Green"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Green"
    exit 0
} elseif ($script:TESTS_FAILED -gt 0) {
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Red"
    Write-ColorOutput "                 CERTAINS TESTS ONT ÉCHOUÉ                      " "Red"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Red"
    exit 1
} else {
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Yellow"
    Write-ColorOutput "                 TESTS INCOMPLETS                              " "Yellow"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Yellow"
    exit 0
}

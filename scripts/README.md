# Scripts de test MSP Analytics

## test-n8n-access.sh / test-n8n-access.ps1

Scripts pour tester l'accès à n8n et valider la configuration.

### Prérequis

1. Docker Desktop doit être démarré
2. Les services doivent être démarrés: `docker compose -p msp up -d`
3. Le fichier `.env` doit contenir les credentials n8n

### Utilisation

#### Linux/Mac

```bash
chmod +x scripts/test-n8n-access.sh
./scripts/test-n8n-access.sh
```

#### Windows (PowerShell)

```powershell
.\scripts\test-n8n-access.ps1
```

### Ce que le script teste

1. **État Docker**: Vérifie que Docker est accessible et que le service n8n est démarré
2. **Healthcheck**: Teste l'endpoint `/healthz` pour vérifier que n8n répond
3. **Authentification**: Teste l'accès à l'API avec les credentials du `.env`
4. **Interface web**: Vérifie que l'interface web est accessible

### Sortie attendue

```
═══════════════════════════════════════════════════════════════
       Test d'accès à n8n-mcp
═══════════════════════════════════════════════════════════════

[1/4] Vérification de l'état Docker...
✓ Docker est accessible

État des services:
NAME        IMAGE              STATUS
msp-n8n     n8nio/n8n:latest  Up (healthy)
✓ Service n8n est démarré

[2/4] Test du healthcheck endpoint...
✓ Healthcheck répond avec code 200

Réponse du healthcheck:
{"status":"ok"}

[3/4] Test de l'authentification...
✓ Credentials trouvés dans .env
✓ Authentification réussie (code 200)

Workflows disponibles (premiers résultats):
  - WF-01: Sync Tickets
  - WF-02: Sync Time Entries

[4/4] Vérification de l'accès MCP...
ℹ Note: Les outils MCP doivent être configurés dans Cursor
  Ce script teste uniquement l'accès HTTP direct à n8n
✓ Interface web accessible (code 200)
  URL: http://localhost:5678

═══════════════════════════════════════════════════════════════
                    RÉSUMÉ DES TESTS
═══════════════════════════════════════════════════════════════

  Tests réussis:    4
  Tests échoués:    0
  Tests ignorés:    0

═══════════════════════════════════════════════════════════════
                 ACCÈS À N8N VALIDÉ                            
═══════════════════════════════════════════════════════════════
```

### Dépannage

#### Docker non démarré

```
✗ Docker n'est pas démarré ou inaccessible
  Veuillez démarrer Docker Desktop
```

**Solution**: Démarrer Docker Desktop

#### Service n8n non démarré

```
⚠ Service n8n n'est pas démarré
  Démarrez avec: docker compose -p msp up -d n8n
```

**Solution**: 
```bash
docker compose -p msp up -d n8n
```

#### Healthcheck échoue

```
✗ Impossible de se connecter à http://localhost:5678/healthz
  Vérifiez que n8n est démarré et accessible
```

**Solutions**:
1. Vérifier que le service est démarré: `docker compose -p msp ps n8n`
2. Vérifier les logs: `docker compose -p msp logs n8n`
3. Redémarrer le service: `docker compose -p msp restart n8n`

#### Authentification échouée

```
✗ Authentification échouée (code 401)
  Vérifiez les credentials dans .env
```

**Solutions**:
1. Vérifier que `.env` existe et contient `N8N_ADMIN_USER` et `N8N_ADMIN_PASSWORD`
2. Vérifier que les credentials sont corrects
3. Redémarrer n8n après modification du `.env`: `docker compose -p msp restart n8n`

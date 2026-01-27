# GATE 2 - Exposition involontaire de ports privés

## Instructions

### 2.1) Audit ports exposés

```bash
# Sur le VPS (SSH)
sudo ss -lntp > ss_full.txt
docker ps --format "table {{.Names}}\t{{.Ports}}" > docker_ports.txt
```

Analyser et créer tableau dans `audit_ports.txt`:
```
Port | Service | Bind (0.0.0.0 / 127.0.0.1) | Risque
-----|---------|------------------------------|-------
5678 | n8n     | 0.0.0.0 / 127.0.0.1        | HIGH / LOW
8000 | analytics-api | ...                   | ...
5432 | postgres | ...                       | ...
6379 | redis   | ...                        | ...
```

### 2.2) Correction selon cas

**CAS A (service public via proxy Coolify)**:
- Retirer `ports:` du compose Coolify OU ne pas mapper sur l'hôte
- Utiliser exposition gérée par Coolify (domain + proxy)
- Redeploy

**CAS B (service privé)**:
- Aucun domain assigné dans Coolify
- Aucun `ports:` publié
- Si publication temporaire nécessaire: bind localhost uniquement `127.0.0.1:PORT_HOTE:PORT_CONTENEUR`

Documenter actions dans `fixes_applied.txt`.

### 2.3) Preuve post-fix

```bash
# Sur le VPS (SSH)
sudo ss -lntp | egrep ':(5678|8000|5432|6379)\b' || true > post_fix_ss.txt
docker ps --format "table {{.Names}}\t{{.Ports}}" > post_fix_docker.txt
```

## Critère PASS

- Aucun service privé n'écoute sur 0.0.0.0
- Services internes n'ont pas de ports publiés
- Services publics passent par proxy (domain) et pas par host-port brut

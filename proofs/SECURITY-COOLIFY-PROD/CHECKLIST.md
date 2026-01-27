# Checklist: Sécurisation Coolify + n8n Production

## GATE 0 — Baseline

- [ ] `docker_ps.txt` - Output complet de `docker ps --format "table ..."`
- [ ] `docker_networks.txt` - Output complet de `docker network ls`
- [ ] `ss_listening.txt` - Output complet de `sudo ss -lntp`
- [ ] `coolify_stacks.txt` - Configuration Coolify documentée avec:
  - [ ] Destination n8n (nom exact)
  - [ ] Destination analytics-api (nom exact)
  - [ ] Docker Network de la Destination (nom exact)

**PASS si**: Tous les fichiers présents + 3 infos Coolify documentées

## GATE 1 — Réseau Coolify

- [ ] `coolify_config.txt` - Configuration réseau documentée
- [ ] `container_network.json` - JSON des réseaux du container analytics
- [ ] `network_inspect.txt` - Inspection du réseau Destination
- [ ] `dns_test.txt` - Test DNS depuis n8n vers analytics-api
- [ ] `http_test.txt` - Test HTTP depuis n8n vers analytics-api

**PASS si**: 
- Les 2 stacks sur même réseau Destination
- DNS résout depuis n8n
- curl retourne HTTP 200 ou réponse applicative

## GATE 2 — Ports privés

- [ ] `ss_full.txt` - Output complet de `sudo ss -lntp`
- [ ] `docker_ports.txt` - Output complet de `docker ps --format "table ..."`
- [ ] `audit_ports.txt` - Tableau d'analyse des ports avec risques
- [ ] `fixes_applied.txt` - Documentation des corrections appliquées
- [ ] `post_fix_ss.txt` - Vérification post-fix (ss)
- [ ] `post_fix_docker.txt` - Vérification post-fix (docker ps)

**PASS si**:
- Aucun service privé n'écoute sur 0.0.0.0
- Services internes n'ont pas de ports publiés
- Services publics passent par proxy (domain)

## GATE 3 — Schedule Trigger

- [ ] `workflows_status.txt` - Statut des workflows (Saved, Active, Timezone, Interval)
- [ ] `timezone_config.txt` - Configuration timezone dans container n8n
- [ ] `executions_test.txt` - Compte et timestamps des exécutions test
- [ ] `logs_test.txt` - Logs n8n des 10 dernières minutes
- [ ] `cli_test.txt` - (Optionnel) Test CLI n8n execute

**PASS si**:
- Timezone contrôlée (workflow et/ou global)
- Au moins 1 workflow schedule exécute réellement
- Preuves executions + logs présentes

## Verdict final

- [ ] `40_verdict.md` complété avec:
  - [ ] Statut PASS/BLOCKED pour chaque gate
  - [ ] Justifications pour chaque gate
  - [ ] Liste des fixes appliqués
  - [ ] Liste des risques restants

## Règle critique

⚠️ **Si une sortie manque → BLOCKED pour ce gate**

⚠️ **Redacter tous les secrets** (tokens, passwords) mais garder noms containers/réseaux/ports

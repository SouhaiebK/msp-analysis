# Notes importantes - Gate 12A

## Limitations connues

### 1. Credentials via MCP

La création de credentials n'est **pas disponible via MCP n8n**. Cette fonctionnalité nécessite l'accès à l'UI n8n.

**Solution**: Créer le credential manuellement dans l'UI n8n (voir `CREDENTIALS_SETUP.md`).

### 2. WF-10 et WF-20 nécessitent une boucle sur les tenants

Les workflows WF-10 et WF-20 dans leur forme actuelle n'ont pas de boucle sur les tenants. Ils doivent être modifiés pour:

1. Ajouter un node "Get Tenants" (comme dans WF-01)
2. Ajouter un node "Split in Batches" pour boucler sur les tenants
3. Mettre à jour les URLs pour utiliser `{{ $json.id }}` au lieu d'un tenant_id hardcodé

**Recommandation**: Modifier ces workflows pour suivre le même pattern que WF-01.

### 3. Expression n8n pour tenant_id

Les workflows utilisent `{{ $json.id }}` car:
- `/internal/tenants` retourne `[{id: "...", name: "...", ...}, ...]`
- Le node "Split in Batches" itère sur ce tableau
- Chaque item dans la boucle est un objet avec `id`, `name`, etc.

## Structure des données

### Réponse de /internal/tenants
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "CCA Demo",
    "is_active": true,
    "llm_enabled": true
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "name": "Client 2 Demo",
    "is_active": true,
    "llm_enabled": false
  }
]
```

### Données passées aux sous-workflows
Quand WF-01 appelle WF-01A ou WF-01B via Execute Workflow, il passe l'objet tenant complet:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "CCA Demo",
  "is_active": true,
  "llm_enabled": true
}
```

Donc dans WF-01A et WF-01B, on utilise `{{ $json.id }}` pour extraire l'ID du tenant.

## Prochaines améliorations

1. **Modifier WF-10 et WF-20** pour boucler sur les tenants
2. **Ajouter des nodes Set** dans WF-01 pour mapper les données si nécessaire
3. **Tester l'isolation multi-tenant** en vérifiant que chaque tenant ne voit que ses propres données
4. **Ajouter des logs** dans les workflows pour le debugging

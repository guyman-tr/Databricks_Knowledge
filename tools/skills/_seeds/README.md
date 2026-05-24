# `tools/skills/_seeds/` — per-domain seed YAMLs

Generic tooling in `tools/skills/` is parameterized via these seed files so that adding a new super-domain (E, F, G, ...) requires only authoring a YAML, not forking scripts.

## Schema

```yaml
id: <slug>                    # required; matches CLI --domain flag and skill folder suffix
display_name: <string>        # human-readable name for report headers
skill_folder: <string>        # destination folder under /Workspace/databricks/data-skills/skills/
parent_spec: <NNN-name>       # back-link to the spec that introduced or refreshed this domain

# Tier 1 — production KPI views (etoro_kpi or etoro_kpi_prep)
# Match against knowledge/skills/_kpi_views_index.json by self_ref equality.
kpi_seeds:
  - etoro_kpi.<view_name>

# Tier 2 — Genie space TITLES, matched case-insensitive substring against
# knowledge/skills/_genie_spaces_index.json[].title.
genie_seeds:
  - "<Genie title or fragment>"

# Manually selected anchor hubs in canonical Schema.Object form.
# Match against the canonical node names in knowledge/skills/_join_graph.json.
hub_tables:
  - Schema.Object

# Regex patterns for find_embedded_domain_members.py to identify nodes that
# "feel like" this domain by name but were placed in OTHER Louvain clusters.
embedded_scan_patterns:
  - "(?i)\\bpattern\\b"

# Confluence corpus query terms — driven by extract_confluence_edges.py.
# Selection scorer in that extractor weights stability (depth, backlinks,
# title pattern, age) over recency.
confluence_query_terms:
  - "<search phrase>"

# Louvain cluster IDs that contain this domain's core (from _CHECKPOINT_A.md
# or fresh clustering). Empty = discover dynamically from hub_tables.
primary_clusters: []

# Sibling clusters where embedded members of this domain may live (e.g.,
# AML nodes Louvain placed with Customer-snapshot).
embedded_clusters: []

# Other domain IDs that may share bridge tables — used to label cross-edges.
sibling_domains:
  - <other_id>
```

## Consumers

| Tool | Reads from seed |
|---|---|
| `enumerate_production_anchors.py` | `kpi_seeds`, `genie_seeds` |
| `summarize_subgraph.py` | `hub_tables`, `genie_seeds`, `kpi_seeds`, `primary_clusters`, `sibling_domains` |
| `find_embedded_domain_members.py` | `embedded_scan_patterns`, `embedded_clusters` |
| `extract_confluence_edges.py` (Phase A.5) | `confluence_query_terms` |
| `cross_check_staleness.py` (Phase A.5b) | all of the above (verdict ranking via `_AUTHORITY_HIERARCHY.md`) |

## Adding a new domain

1. Author `tools/skills/_seeds/<new-domain>.yaml` following the schema above.
2. Run each generic tool with `--domain <new-domain>`. Outputs land under `knowledge/skills/_<new-domain>_*.md`.
3. Phase B decision gate (per `.specify/templates/domain-build-template.md`) — choose the partition shape from the semantic-model outputs.
4. Author `SKILL.md` files matching the chosen shape, lint via `lint_skill.py`, deploy via `sync_to_databricks.py`.

## Why this exists

Before spec 011, per-domain logic was hardcoded in scripts like `summarize_payments_subgraph.py` — adding a new domain required forking the script. With seeds, all per-domain choices live in one YAML and the scripts are stable.

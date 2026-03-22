---
description: "[FUTURE] Propagate column descriptions downstream to undocumented UC objects. Not yet implemented — placeholder for Phase 3 downstream propagation."
---

# Propagate Downstream — DWH (Column Description Propagation)

**Status**: NOT YET IMPLEMENTED — empty vessel for future work.

## Purpose

After all target schemas have completed ALTER deployment (via `deploy-alter-dwh`), propagate column descriptions downstream to UC objects that do NOT have their own wiki documentation. This ensures undocumented downstream tables/views inherit meaningful column descriptions from their documented upstream sources.

---

## Key Design Decisions (Agreed)

### 1. Documented Objects Are NEVER Overwritten

Objects that have their own wiki documentation (`.md` file in any target schema) are **skipped** during propagation. Their curated, context-specific descriptions take precedence over inherited upstream descriptions.

### 2. Schema-Aware Skip List

Before propagation, build a "documented objects registry" by scanning all `_index.md` files across all target schemas. Map documented Synapse objects to their UC targets. Any downstream UC object in this registry is skipped.

### 3. Execution Order

Process schemas bottom-up (dependency order):
1. DWH_dbo first (foundation dimensions/facts)
2. Dealing_dbo second
3. BI_DB_dbo third
4. EXW_dbo, eMoney_dbo last

Within each schema, process objects by depth from `_dependency_order.json` (depth 0 first).

### 4. Propagation Scope

Only propagate to UC objects that:
- Exist in Unity Catalog (verified via `DESCRIBE TABLE`)
- Do NOT have their own wiki documentation
- Have matching column names (identical or plausible renames)
- Are not in the propagation blacklist (`dwh-semantic-doc-config.json → propagation.blacklist`)

---

## Infrastructure Available

The following infrastructure already exists and will be used:

| Component | Path | Status |
|-----------|------|--------|
| Deep propagation library | `knowledge/synapse/Wiki/_deep_propagate_lib.py` | Exists — needs documented-objects skip filter |
| Dependency order graph | `knowledge/synapse/Wiki/_dependency_order.json` | Exists |
| Propagation blacklist | `.specify/Configs/dwh-semantic-doc-config.json` → `propagation.blacklist` | Exists |
| Synapse dependency graph | Used by `_deep_propagate_lib.py` → `_load_synapse_downstream()` | Exists |
| Name-pattern discovery | Used by `_deep_propagate_lib.py` → `query_name_pattern()` | Exists |

---

## TODO — Implementation Plan

When this command is implemented, it needs:

1. **Documented objects registry** — new function in `_deep_propagate_lib.py`:
   ```
   load_documented_objects_registry(wiki_base) → set of UC FQNs to skip
   ```

2. **Skip filter in execute_batches()** — skip nodes matching documented objects

3. **Clash resolution strategy** — when multiple upstream objects could propagate to the same downstream column, decide which wins (highest tier? most specific? first to arrive?)

4. **Scope report** — before execution, show the user:
   - Total downstream objects discovered
   - How many are documented (will be skipped)
   - How many will receive propagated descriptions
   - Estimated ALTER statement count

5. **Command interface** — invocation, arguments, batch processing, resume support

---

## Invocation (Future)

```text
/propagate-downstream-dwh {schema_name} [discover | execute | status]
```

| Argument | Description |
|----------|-------------|
| `discover` | Run discovery only — generate scope report, no ALTERs |
| `execute` | Run full propagation (discovery + ALTER execution) |
| `status` | Show propagation progress |

---

## Rule File References

```
.cursor/rules/dwh-semantic-doc/11w-write-objects.mdc  (Section 11: Downstream Propagation)
.cursor/rules/semantic-layer-core/deploy-index-management.mdc
```

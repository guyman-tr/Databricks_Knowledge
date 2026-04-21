# Object lineage — EXW_dbo.RemoveSuffix

> **Synapse**: Function (Scalar). **Unity Catalog**: `_Not_Migrated` (no Generic Pipeline gold table / TVF mapping in UC for this object).

## Referenced objects (Source Objects)

| Object | Schema | Notes |
|--------|--------|-------|
| *(none — pure string expression)* | — | No external table or object references |

## Output contract

Scalar function — returns **VARCHAR(MAX)**: the substring of `@Input` that appears before the **first** occurrence of `@Delimiter`. Returns `@Input` unchanged if `@Delimiter` is not found.

## Pipeline notes

- **Phase 10B (repo)**: Functions stay in-repo; UC External Lineage injection does not apply until a UC entity exists.
- **Callers**: Used as a string utility in EXW_dbo SPs that parse EXW_Settings ResourceName paths. Exact caller list not confirmed — grep `EXW_dbo.RemoveSuffix` in SP files to enumerate.

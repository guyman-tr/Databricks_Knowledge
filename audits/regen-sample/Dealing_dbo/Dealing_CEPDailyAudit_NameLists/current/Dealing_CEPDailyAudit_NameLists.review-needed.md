# Dealing_dbo.Dealing_CEPDailyAudit_NameLists — Review Needed

> Items flagged for domain expert review. **Named Lists drive CID-based CEP rules — treat as sensitive configuration even without a `CID` column.**

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|
| | | | | | |

## Tier 4 (UNVERIFIED) Columns

- **UpdateDate** — Documented as `GETDATE()` at SP execution; confirm dashboards must use **`ChangeTime`** / **`Date`** for business timelines.

## Columns Needing Clarification

- **`Name`** — Confirm whether stored **`Name`** always matches **CEP UI** at event time or can reflect **later renames** via log resolution (align with **`ListCIDMapping.ListName`** behavior).

## Structural Questions

- **`Change In CIDs` vs `ListCIDMapping`** — Confirm that **every** list-level **`Change In CIDs`** row has **corresponding per-CID** rows on the **same `Date`** (and document **exceptions** if any).
- **List inventory** — Provide **sanitized** examples of list **names** / **purposes** for wiki enrichment (avoid **client-identifying** labels in public docs).
- **Sensitivity** — Confirm **access tier** for **list names** (operational confidentiality).
- **Atlassian** — No Jira/Confluence hits in the generating run; link internal **CEP** documentation if it exists.
- **Weekly sibling** — Confirm **`Dealing_CEPWeeklyAudit_NameLists`** rollup rules.

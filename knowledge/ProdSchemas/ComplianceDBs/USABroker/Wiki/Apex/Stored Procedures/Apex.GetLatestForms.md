# Apex.GetLatestForms

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetLatestForms.sql`  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetLatestForms` returns the most current version of every distinct form registered in the Apex form library. Forms are versioned documents (JSON bodies) used during onboarding and compliance workflows; over time the same form name may have multiple versions as regulatory requirements evolve. This procedure always returns exactly one row per form name — the row with the highest `ID` value, representing the latest published version.

It is called by form-management UIs, by services that need to know which form versions are "live," and by tooling that detects whether newly submitted forms need migration or re-validation against the latest definitions.

---

## 2. Parameters

None. This procedure takes no parameters and returns all forms in their latest state.

---

## 3. Result Sets

**Result Set 1 – Latest Form Definitions (all columns)**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `ID` | `Apex.Form` | Surrogate primary key; the highest ID per form name indicates the latest version. |
| `FormName` | `Apex.Form` | Logical name of the form. |
| `Hash` | `Apex.Form` | Integrity hash of the JSON body. |
| `JsonBody` | `Apex.Form` | Full JSON definition (nvarchar(max)). |
| `Version` | `Apex.Form` | Version number of this form definition. |

One row per distinct `FormName`. If only one version of a form exists, that row is returned.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `Form` | `Apex` | SELECT | CTE + subquery pattern; no locking hints. |

---

## 5. Logic Flow

1. **CTE `LastForms`:** Groups `Apex.Form` by `FormName` and selects `MAX(ID) AS ID` per group — this identifies the latest record for each form name.
2. **Outer query:** `SELECT *` from `Apex.Form WHERE ID IN (SELECT ID FROM LastForms)` — returns the full row for each latest form.

The `MAX(ID)` approach assumes form IDs are monotonically increasing (identity column), which ensures the largest ID corresponds to the most recently inserted version.

---

## 6. Error Handling

No explicit error handling. Returns an empty result set if the `Form` table is empty.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.Form` | Table | Only data source |
| `Apex.GetForm` | Stored Procedure | Point-lookup by FormName + Version |
| `Apex.SaveForm` | Stored Procedure | Companion writer; creates the records returned here |

---

## 8. Usage Notes

- This procedure does **not** filter by `Active` or publish status — all forms stored in the table are considered eligible. If a form management lifecycle is added in the future, an `IsActive` filter should be applied here.
- The `SELECT *` pattern means the result set will automatically include any future columns added to `Apex.Form`; callers that rely on positional column ordering should use named columns in their data readers.
- `JsonBody` is `nvarchar(max)`; avoid calling this in tight loops. Consider caching the result in the application layer.
- To retrieve a specific form at a specific version, use `Apex.GetForm` instead.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetLatestForms.sql` | Quality Score: 8.5/10*

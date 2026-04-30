# Apex.GetApexDataAndState

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetApexDataAndState.sql`  
**Author:** Dmitriy Gavrish  
**Created:** 2021-05-13  
**Last Modified:** 2021-10-11 (Yulia Kramer — COAKV-3673/3708: fix lastUpdatedOn and created fields)  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetApexDataAndState` is the combined account + workflow-state reader for a user's Apex brokerage enrollment. It is called when a service needs a full picture of where a user stands: the external Apex account identifiers, the internal state-machine position, who approved the account, when it was approved, and whether any outstanding validation errors are blocking progress.

The procedure returns **two result sets** in a single round-trip, making it the preferred call for dashboard rendering and workflow-orchestration services that need both the approval metadata and the validation error list simultaneously.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID identifying the user whose combined account+state data is requested. |

---

## 3. Result Sets

**Result Set 1 – Combined Account / State / Approval snapshot**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `ApexID` | `Apex.ApexData` | External Apex account identifier. NULL if no ApexData row exists. |
| `GCID` | `Apex.State` | Global Customer ID (from the State row, which drives the LEFT JOINs). |
| `StatusID` | `Apex.ApexData` | Apex account lifecycle status code. NULL if no ApexData row. |
| `BeginTime` | `Apex.State` | Timestamp when the current state was entered. |
| `Comment` | `Apex.State` | Free-text comment attached to the current state (e.g., rejection reason). |
| `ApexStateID` | `Apex.State` | Numeric ID of the current Apex state-machine node. |
| `ApproverName` | `Apex.UserData` | Name of the staff member who approved the account. NULL if not yet approved. |
| `ApprovedByDate` | `Apex.UserData` | UTC timestamp of approval. NULL if not yet approved. |
| `Created` | `Apex.UserData` | UTC timestamp when the UserData record was first created. |

Returns 0 rows if no `State` row exists for the given `GCID`.

**Result Set 2 – Validation Error IDs**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `ApexValidationErrorID` | `Apex.UserValidationErrors` | ID of each active validation error blocking the user's progression. |

Returns 0 rows if no validation errors are present.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `State` | `Apex` | SELECT | Driving table for the first result set. |
| `ApexData` | `Apex` | SELECT | LEFT JOIN on `GCID`; may not exist. |
| `UserData` | `Apex` | SELECT | LEFT JOIN on `GCID`; may not exist. |
| `UserValidationErrors` | `Apex` | SELECT | Simple filter for second result set. |

---

## 5. Logic Flow

1. **Result Set 1:** LEFT JOINs `Apex.State` → `Apex.ApexData` → `Apex.UserData` on `GCID`. Filters by `s.GCID = @GCID`. Returns combined account/state/approval fields.
2. **Result Set 2:** Simple `SELECT` from `Apex.UserValidationErrors` filtered by `GCID = @GCID`.

The `State` table is the anchor; if no State row exists the first result set is empty. LEFT JOINs ensure missing `ApexData` or `UserData` rows produce NULLs rather than suppressing the State row.

---

## 6. Error Handling

No explicit TRY/CATCH. Standard SQL Server exception propagation. The COAKV-3673/3708 fix (2021-10-11) corrected column selection so that `lastUpdatedOn` and `Created` return actual values rather than column defaults.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.State` | Table | Primary driver table |
| `Apex.ApexData` | Table | LEFT JOIN source |
| `Apex.UserData` | Table | LEFT JOIN source for approval metadata |
| `Apex.UserValidationErrors` | Table | Source for second result set |
| `Apex.GetApexData` | Stored Procedure | Simpler single-table variant |
| `Apex.SaveState` | Stored Procedure | Writes the State and UserValidationErrors rows read here |

---

## 8. Usage Notes

- Callers must handle two result sets; most ORMs and ADO.NET `NextResult()` patterns apply.
- The LEFT JOIN strategy means the procedure succeeds even when `ApexData` or `UserData` rows are missing — appropriate for partially-onboarded users.
- An empty second result set means the user has no active validation errors and may proceed through the workflow.
- Prefer this procedure over separate calls to `GetApexData` + `GetState` + `UserValidationErrors` to reduce round-trips.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetApexDataAndState.sql` | Quality Score: 8.5/10*

# Apex.SaveUserParametersUpdatesMask

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserParametersUpdatesMask.sql`  
**Author:** Serhii Poltava  
**Created:** 2020-01-03  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveUserParametersUpdatesMask` creates or replaces the bitmask-encoded parameter update flags for a customer in the `UserParameters` table. The `UpdatesMask` field records which user parameter groups (e.g., account settings, trading preferences, notification preferences) have pending updates that need to be applied or synchronised. This is a lightweight control record used by background processing services to track which parameter categories are "dirty" and need attention.

It is called when a customer changes a parameter-governed setting that must be propagated to Apex or processed by the workflow engine.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID (MERGE key). |
| `@UpdatesMask` | `int` | No | Bitmask value representing the set of parameter groups with pending updates. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `UserParameters` | `Apex` | MERGE (UPDATE / INSERT) | Unconditional update on MATCHED (no change-detection). |

---

## 5. Logic Flow

MERGE on `target.GCID = source.GCID`:

- **WHEN MATCHED:** `UPDATE SET target.UpdatesMask = source.UpdatesMask` — always writes, no change-detection.
- **WHEN NOT MATCHED BY TARGET:** `INSERT (GCID, UpdatesMask) VALUES (GCID, UpdatesMask)`.

The MERGE source is a single-row virtual table constructed from the input parameters.

---

## 6. Error Handling

No explicit error handling. MERGE exceptions propagate.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.UserParameters` | Table | User parameter control record |
| `Apex.GetUserParametersUpdatesMask` | Stored Procedure | Companion reader (listed among existing Wiki docs) |

---

## 8. Usage Notes

- Unlike most other Save procedures in this schema, this MERGE does **not** use change-detection — every call writes the `UpdatesMask` value regardless of whether it changed. This is intentional: callers set the exact current mask each time, overwriting any previous value.
- `UpdatesMask` is typically a cumulative bitmask: callers OR new bits into the existing value before calling (read-modify-write pattern in the application layer).
- After the parameter update is processed by the workflow engine, the service is expected to clear the relevant bits from `UpdatesMask` by calling this procedure again with the cleared value.
- The `Apex.UserParameters` table may have additional columns beyond `GCID` and `UpdatesMask` that are managed by other procedures.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserParametersUpdatesMask.sql` | Quality Score: 8.5/10*

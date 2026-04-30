# Apex.SaveApexData

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveApexData.sql`  
**Author:** Serhii Poltava  
**Created:** 2019-10-11  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveApexData` records or updates the binding between an internal Global Customer ID (`GCID`) and an external Apex Clearing account ID (`ApexID`). This binding is fundamental to the entire Apex integration: once an `ApexID` is assigned by Apex Clearing, it must be permanently associated with exactly one `GCID`. The procedure enforces this invariant by raising a hard exception if an attempt is made to bind an `ApexID` to a different `GCID` than it was originally assigned to.

After the binding validation, the procedure upserts the row using a MERGE, updating the `StatusID` only when it has actually changed — preventing unnecessary write amplification.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@ApexID` | `varchar(8)` | No | The Apex Clearing-assigned account identifier. |
| `@GCID` | `int` | No | The internal Global Customer ID to bind (or verify binding) to the ApexID. |
| `@StatusID` | `int` | No | The current Apex account status code. |

---

## 3. Result Sets

None. This is a write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `ApexData` | `Apex` | SELECT (binding check) + MERGE (INSERT / UPDATE) | Uses `TOP 1` for the binding check; MERGE on `GCID + ApexID`. |

---

## 5. Logic Flow

1. **Binding validation:**
   - `SELECT TOP 1 GCID FROM Apex.ApexData WHERE ApexID = @ApexID` → `@ExistingGCID`.
   - If `@ExistingGCID IS NOT NULL AND @ExistingGCID <> @GCID`: THROW error 51000 with descriptive message — "ApexID is already bound to a different GCID."
2. **MERGE** on `Target.GCID = Source.GCID AND Target.ApexID = Source.ApexID`:
   - **WHEN NOT MATCHED BY TARGET:** INSERT `(ApexID, GCID, StatusID)`.
   - **WHEN MATCHED AND `Target.StatusID <> Source.StatusID`:** UPDATE `StatusID = @StatusID`, reset `UpdatedSync = 0`.

The change-detection on `StatusID` means a no-op MERGE when the status has not changed, avoiding spurious dirty pages and sync events.

---

## 6. Error Handling

- `THROW 51000` with a custom message when `ApexID` is already bound to a different `GCID`. This is a hard data-integrity error; the caller must not retry with the same inputs.
- No TRY/CATCH beyond the explicit THROW; other exceptions propagate normally.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.ApexData` | Table | Binding registry and status store |
| `Apex.GetApexData` | Stored Procedure | Reads the row written here (by GCID) |
| `Apex.GetApexDataAndState` | Stored Procedure | Reads the row written here (JOINed with State + UserData) |

---

## 8. Usage Notes

- The `THROW 51000` error is intentionally unrecoverable — if an `ApexID` appears bound to two different GCIDs, it signals a serious integration bug that requires manual investigation.
- `UpdatedSync = 0` is set when the status changes; this flag is presumably read by a sync process to identify rows needing downstream propagation.
- The MERGE key is `(GCID, ApexID)` — one user could theoretically have multiple `ApexID` values (e.g., re-opened accounts), but each `ApexID` is unique to one `GCID`.
- The `TOP 1` in the binding check assumes `ApexID` uniqueness; if multiple rows per `ApexID` were possible, the logic would be incorrect. Confirm that a unique index enforces this at the table level.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveApexData.sql` | Quality Score: 9.0/10*

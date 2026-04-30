# Apex.SaveUserDataUpdates

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserDataUpdates.sql`  
**Author:** Serhii Poltava  
**Created:** 2019-12-02  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveUserDataUpdates` appends a new user-data change notification to the `UserDataUpdates` audit log. When a customer's profile data changes in the source system, the event pipeline calls this procedure to record which fields changed (encoded as a bitmask in `UpdatesMask`) and when. This log drives the Apex synchronisation process: the workflow engine reads these records to determine what data needs to be re-submitted to Apex Clearing.

Each call always creates a new row — this is an append-only event log, not an upsert. The history of all changes is preserved for audit and replay purposes.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID of the customer whose data changed. |
| `@UpdatesMask` | `int` | No | Bitmask encoding which user-data field groups changed (each bit = a data domain). |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `UserDataUpdates` | `Apex` | INSERT | Append-only; `BeginTime` is a default column (GETUTCDATE() or similar). |

---

## 5. Logic Flow

1. `INSERT INTO Apex.UserDataUpdates (GCID, UpdatesMask) VALUES (@GCID, @UpdatesMask)`.
2. `BeginTime` is not passed — it is populated by a column default (presumably `GETUTCDATE()`).
3. `UserDataUpdatesId` is an identity column populated automatically.

Minimal logic — pure event-log append.

---

## 6. Error Handling

No explicit error handling. SQL Server exceptions (e.g., foreign key violations if GCID is invalid) propagate to the caller.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.UserDataUpdates` | Table | Event log — INSERT target |
| `Apex.GetUserDataUpdates` | Stored Procedure | Reads full history written here |
| `Apex.GetLastUserDataUpdates` | Stored Procedure | Reads the most recent event written here |

---

## 8. Usage Notes

- `UpdatesMask` is a bitmask; each bit represents a specific user-data field group (e.g., bit 1 = name change, bit 2 = address change). Consult the Apex integration specification for the bit layout.
- This is an event log — each call creates a new row. High-churn customers will accumulate many rows. Consider a data retention policy for old `UserDataUpdates` records.
- The `BeginTime` column is set by the database default (not by this procedure), so the timestamp reflects the DB server's UTC clock, not the caller's.
- Callers should avoid batching multiple `UpdatesMask` values into a single bitmask and calling once; instead, emit one event per change occurrence to preserve accurate change history.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserDataUpdates.sql` | Quality Score: 8.5/10*

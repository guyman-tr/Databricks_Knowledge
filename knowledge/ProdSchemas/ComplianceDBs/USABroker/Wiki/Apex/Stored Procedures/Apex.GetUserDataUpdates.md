# Apex.GetUserDataUpdates

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetUserDataUpdates.sql`  
**Author:** Serhii Poltava  
**Created:** 2019-12-06  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetUserDataUpdates` retrieves the **complete history** of user-data update events for a given customer. Each row represents a discrete notification that one or more fields in the customer's profile changed, encoded as a bitmask in `UpdatesMask`. The full history is valuable for audit trails, debugging synchronisation gaps, and reconciliation workflows that need to replay or review all changes since account creation.

This contrasts with `Apex.GetLastUserDataUpdates`, which returns only the single most recent event.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID of the customer whose full update history is requested. |

---

## 3. Result Sets

**Result Set 1 – All Update Events (chronological)**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `UserDataUpdatesId` | `Apex.UserDataUpdates` | Surrogate primary key; higher values are more recent. |
| `GCID` | `Apex.UserDataUpdates` | Global Customer ID (echoed). |
| `UpdatesMask` | `Apex.UserDataUpdates` | Bitmask identifying which user-data fields changed in this event. |
| `BeginTime` | `Apex.UserDataUpdates` | UTC timestamp when this update event was recorded. |

Returns 0 rows if no update events have been recorded for the given GCID. May return many rows for active customers.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `UserDataUpdates` | `Apex` | SELECT | No locking hints; returns all rows for the GCID (unordered). |

---

## 5. Logic Flow

1. Simple `SELECT` from `Apex.UserDataUpdates`.
2. Filters by `GCID = @GCID`.
3. Returns all four columns; no `ORDER BY` clause (result order is non-deterministic).

No aggregates, joins, or CTEs. This is a pure history dump for a single customer.

---

## 6. Error Handling

No explicit error handling. Empty result if no history exists.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.UserDataUpdates` | Table | Only data source |
| `Apex.SaveUserDataUpdates` | Stored Procedure | Companion writer; appends a new row for each change event |
| `Apex.GetLastUserDataUpdates` | Stored Procedure | Single-row variant returning only the most recent event |

---

## 8. Usage Notes

- No `ORDER BY` is specified; if chronological ordering is needed, the caller should sort by `UserDataUpdatesId ASC` or `BeginTime ASC`.
- For high-activity customers this result set may be large; consider pagination or switching to `GetLastUserDataUpdates` for real-time processing.
- `UpdatesMask` is a bitmask integer; each bit corresponds to a specific profile-field group. Consult the Apex integration specification for the bit layout.
- Note that no `NOLOCK` is used here — this ensures callers read only committed events, which is important for audit purposes.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetUserDataUpdates.sql` | Quality Score: 8.5/10*

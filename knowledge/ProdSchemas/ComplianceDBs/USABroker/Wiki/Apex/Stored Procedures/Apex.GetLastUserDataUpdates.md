# Apex.GetLastUserDataUpdates

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetLastUserDataUpdates.sql`  
**Author:** Serhii Poltava  
**Created:** 2019-12-12  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetLastUserDataUpdates` retrieves the most recent user-data update event record for a given customer. The `UserDataUpdates` table maintains an ordered log of bitmask-encoded notifications that indicate which parts of a user's profile changed (name, address, documents, etc.). By selecting the row with the maximum `UserDataUpdatesId`, this procedure answers "what was the last set of changes recorded for this user?"

This is called by synchronisation services that need to detect whether new user-data changes have arrived since the last successful Apex submission, and by reconciliation jobs that verify the update pipeline is not stalled.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID of the user whose most recent update event is requested. |

---

## 3. Result Sets

**Result Set 1 – Most Recent Update Event**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `GCID` | `Apex.UserDataUpdates` | Global Customer ID (echoed). |
| `UpdatesMask` | `Apex.UserDataUpdates` | Bitmask encoding which user-data fields changed in this update event. |
| `BeginTime` | `Apex.UserDataUpdates` | UTC timestamp when this update event was recorded. |

Returns 0 rows if no update events exist for the given GCID.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `UserDataUpdates` | `Apex` | SELECT | Read with `NOLOCK`; uses an `IN (SELECT MAX(...))` pattern to find the latest row. |

---

## 5. Logic Flow

1. `NOLOCK` read on `Apex.UserDataUpdates` with `GCID = @GCID`.
2. Correlated subquery selects `MAX(UserDataUpdatesId)` for the same `GCID`.
3. `UserDataUpdatesId IN (...)` filter ensures only the single most recent row is returned.
4. Returns `GCID`, `UpdatesMask`, `BeginTime`.

---

## 6. Error Handling

No explicit error handling. Returns empty if no update records exist for the GCID.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.UserDataUpdates` | Table | Only data source |
| `Apex.SaveUserDataUpdates` | Stored Procedure | Companion writer; inserts the rows read here |
| `Apex.GetUserDataUpdates` | Stored Procedure | Full-history variant; returns all update events for the GCID |

---

## 8. Usage Notes

- `UpdatesMask` is a bitmask integer; each bit position corresponds to a specific user-data field group (e.g., personal info, address, tax information). Consult the integration specification for bit definitions.
- Use `Apex.GetUserDataUpdates` when the full history of update events is needed rather than just the latest.
- The `IN (SELECT MAX(...))` pattern is logically equivalent to `WHERE UserDataUpdatesId = (SELECT MAX(...))` and returns at most one row since `UserDataUpdatesId` is the primary key.
- The `NOLOCK` hint is acceptable for this use case since the calling logic is checking recency, not performing a transactional decision.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetLastUserDataUpdates.sql` | Quality Score: 8.5/10*

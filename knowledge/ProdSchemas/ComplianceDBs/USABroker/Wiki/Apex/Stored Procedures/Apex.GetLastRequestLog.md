# Apex.GetLastRequestLog

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetLastRequestLog.sql`  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetLastRequestLog` retrieves the most recent request log entry for a given user, optionally scoped to a specific modification type. The `RequestLog` table records every request sent to the Apex Clearing API and the resulting status. By selecting the row with the highest `RequestLogID`, this procedure answers "what was the last thing we sent to Apex for this user (of a given type), and what happened?"

This is used by monitoring services, retry logic, and workflow orchestrators to determine whether a pending submission needs to be retried, whether Apex acknowledged the last request, and what event mask was included.

---

## 2. Parameters

| Parameter | Type | Nullable | Default | Description |
|-----------|------|----------|---------|-------------|
| `@GCID` | `int` | No | — | Global Customer ID of the user whose latest request log entry is retrieved. |
| `@ModifyTypeID` | `int` | Yes | `NULL` | If provided, filters to the most recent row where `ModifyTypeID` equals this value. If NULL, no filter is applied on modify type. |

---

## 3. Result Sets

**Result Set 1 – Most Recent Request Log Entry**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `RequestLogID` | `Apex.RequestLog` | Surrogate PK; the highest value for this GCID (or GCID + ModifyType). |
| `GCID` | `Apex.RequestLog` | Global Customer ID. |
| `ApexRequestID` | `Apex.RequestLog` | GUID sent with the request to Apex Clearing for correlation. |
| `ApexLastEventID` | `Apex.RequestLog` | The Apex event ID acknowledged in this log entry. |
| `StatusID` | `Apex.RequestLog` | Status code of the request/response cycle. |
| `UpdateEventMask` | `Apex.RequestLog` | Bitmask indicating which data fields were included in the request. |
| `LogID` | `Apex.RequestLog` | GUID identifying the associated application log entry. |
| `ModifyTypeID` | `Apex.RequestLog` | Type of modification this request represented. |
| `BeginTime` | `Apex.RequestLog` | UTC timestamp when the request was initiated. |

Returns 0 rows if no log exists for the given GCID (and ModifyTypeID filter).

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `RequestLog` | `Apex` | SELECT | Read with `NOLOCK`; uses a correlated subquery to find `MAX(RequestLogID)`. |

---

## 5. Logic Flow

1. `NOLOCK` read on `Apex.RequestLog` with filter `GCID = @GCID`.
2. The `MAX(RequestLogID)` correlated subquery selects only the most recent row for the user.
3. If `@ModifyTypeID` is not NULL, an additional filter `ModifyTypeID = @ModifyTypeID` is applied.
4. Returns all nine columns of the qualifying row.

The `@ModifyTypeID IS NULL OR ModifyTypeID = @ModifyTypeID` pattern allows the parameter to be optional without dynamic SQL.

---

## 6. Error Handling

No explicit error handling. Returns empty if no matching log entry exists.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.RequestLog` | Table | Only data source |
| `Apex.SaveRequestLog` | Stored Procedure | Companion writer; inserts/updates the rows read here |

---

## 8. Usage Notes

- The `MAX(RequestLogID)` subquery pattern assumes auto-incrementing IDs represent insertion order; this is always true for an identity column.
- When `@ModifyTypeID` is supplied, the procedure finds the most recent log entry overall first (by `MAX(RequestLogID)` across all modify types) and then checks the type filter — it does NOT independently find the latest row per modify type. If you need the latest entry for a specific type regardless of newer entries of other types, query `Apex.RequestLog` directly.
- The `NOLOCK` hint makes this safe for high-frequency polling but may occasionally read a row mid-write.
- `UpdateEventMask` is a bitmask; consult the Apex integration specification for bit definitions.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetLastRequestLog.sql` | Quality Score: 8.5/10*

# Apex.SaveRequestLog

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveRequestLog.sql`  
**Author:** Serhii Poltava  
**Created:** 2019-10-11  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveRequestLog` records and maintains the lifecycle of a request sent to Apex Clearing for a specific customer. Each request to Apex is identified by an `ApexRequestID` GUID; this procedure creates the initial log entry when the request is submitted and updates it when the response arrives (new event ID, status change, or updated log reference). Only actual changes trigger an update — preventing spurious writes when the same state is reported multiple times.

The `RequestLog` table is the audit trail for Apex API interactions and is the basis for monitoring, retry logic, and reconciliation against Apex's own event log.

---

## 2. Parameters

| Parameter | Type | Nullable | Default | Description |
|-----------|------|----------|---------|-------------|
| `@GCID` | `int` | No | — | Global Customer ID. |
| `@ApexRequestID` | `uniqueidentifier` | No | — | Apex-generated GUID identifying this specific request. |
| `@ApexLastEventID` | `int` | No | — | The most recent Apex event ID associated with this request. |
| `@StatusID` | `int` | No | — | Current status code of the request/response cycle. |
| `@UpdateEventMask` | `int` | No | — | Bitmask of the data fields included in this request. |
| `@LogID` | `uniqueidentifier` | No | — | GUID linking to the application log entry for this request. |
| `@ModifyTypeID` | `int` | Yes | `NULL` | Type code classifying the modification type of this request. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `RequestLog` | `Apex` | MERGE (INSERT / conditional UPDATE) | Change-detection on `ApexLastEventID`, `StatusID`, `UpdateEventMask`, and `LogID`. |

---

## 5. Logic Flow

MERGE on `Target.GCID = Source.GCID AND Target.ApexRequestID = Source.ApexRequestID`:

- **WHEN NOT MATCHED BY TARGET:** INSERT all seven fields — creates the initial log entry.
- **WHEN MATCHED AND** (any of `ApexLastEventID`, `StatusID`, `UpdateEventMask` differ, OR `LogID` differs):
  - UPDATE the four changeable fields using `ISNULL(@param, Target.field)`.
- If MATCHED but nothing changed: no-op (no write).

Change-detection ensures the log is only written when the request state actually evolves.

---

## 6. Error Handling

No explicit error handling. MERGE exceptions propagate. Unique key violations on the `(GCID, ApexRequestID)` composite would indicate a MERGE race condition.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.RequestLog` | Table | Request audit log store |
| `Apex.GetLastRequestLog` | Stored Procedure | Reads the most recent log entry for a GCID |

---

## 8. Usage Notes

- `ApexRequestID` is the natural key for this table — one row per request sent to Apex for a given customer. The same `ApexRequestID` will be passed on the initial submit and on each status update, updating the same row.
- The `ISNULL(@param, Target.field)` UPDATE pattern means NULL inputs preserve existing values; this allows partial status updates without re-supplying all fields.
- `UpdateEventMask` is a bitmask recording which data domains were included in the submission (e.g., personal info, documents); consult the Apex integration specification for bit layout.
- `ModifyTypeID` categorises the type of change submitted (e.g., initial application, address update, document upload); it is optional and NULL is valid.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveRequestLog.sql` | Quality Score: 8.5/10*

# Apex.GetRequestLog

> Retrieves an Apex API request log entry by the Apex request ID, used for polling request status from the clearing house.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns RequestLog row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex.GetRequestLog retrieves a request log entry by ApexRequestID. Used during the polling workflow when the system checks the status of a previously submitted Apex Clearing API request. The procedure looks up the request by its GUID identifier and returns the current status, event progression, and metadata.

---

## 2. Business Logic

No complex business logic. Simple SELECT by ApexRequestID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ApexRequestID | uniqueidentifier | NO | - | CODE-BACKED | The Apex API request GUID to look up. Matches against ix_RequestLog_ApexRequestID index. |

**Returns**: RequestLogID, GCID, ApexRequestID, ApexLastEventID, StatusID, UpdateEventMask, LogID, ModifyTypeID.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Apex.RequestLog | Read | Queries by ApexRequestID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.GetRequestLog (procedure)
└── Apex.RequestLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Apex.RequestLog | Table | Read by ApexRequestID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up a request by ID

```sql
EXEC Apex.GetRequestLog @ApexRequestID = '86A8B14D-FEA6-4AA6-90B3-4777DC23866B';
```

### 8.2 Check request status for debugging

```sql
EXEC Apex.GetRequestLog @ApexRequestID = '0D3C8556-A49D-4143-B9DA-24FE03D8A18D';
-- Returns StatusID, ModifyTypeID for the request
```

### 8.3 Verify request exists

```sql
EXEC Apex.GetRequestLog @ApexRequestID = '00000000-0000-0000-0000-000000000000';
-- Empty result if not found
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.GetRequestLog | Type: Stored Procedure | Source: USABroker/Apex/Stored Procedures/Apex.GetRequestLog.sql*

# History.CloseMultiplePositionsFail

> Synonym providing local-schema access to DB_Logs.History.CloseMultiplePositionsFail - the audit log table capturing failed "close multiple positions" requests, recording the customer, the position IDs that were targeted, and failure details.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | Alias: DB_Logs.History.CloseMultiplePositionsFail |
| **Partition** | N/A (resolves to target in DB_Logs) |
| **Indexes** | N/A (resolves to target in DB_Logs) |

---

## 1. Business Meaning

`History.CloseMultiplePositionsFail` is a cross-database synonym pointing to `DB_Logs.History.CloseMultiplePositionsFail`. The underlying table logs failures in the "close multiple positions" workflow - the eToro mechanism that allows closing a set of specific positions (identified by a list of position IDs) in a single request. When such a batch close request fails, this table captures the failure for diagnostics and support investigation.

From `Trade.CloseMultiplePositionsFailInfo` usage, each row captures: the customer (CID), the list of position IDs that were targeted (PositionIDsToClose, stored as a comma-separated varchar), the failure description (FailDescription), when the original request was made (RequestOccurred), when the failure was recorded (FailOccurred, UTC), and optional correlation fields (ClientRequestGuid, ErrorCode).

The comment in `Trade.CloseMultiplePositionsFailInfo` (`-- [History].[CloseByInstrumentFailInfo]`) suggests this procedure evolved from or replaced a `CloseByInstrumentFailInfo` procedure - the "close multiple positions" functionality was renamed/generalized from "close by instrument."

---

## 2. Business Logic

### 2.1 Multi-Position Close Failure Audit

**What**: Each INSERT records one failed batch close-multiple-positions request.

**Columns/Parameters Involved**: CID, PositionIDsToClose, FailDescription, RequestOccurred, FailOccurred, ClientRequestGuid, ErrorCode

**Rules**:
- Written exclusively via Trade.CloseMultiplePositionsFailInfo (Trade schema SP)
- PositionIDsToClose is varchar(MAX), nullable - stores the serialized list of position IDs targeted by the failed request (e.g., "123,456,789")
- RequestOccurred is caller-provided (when the original request was made); FailOccurred is always GETUTCDATE() (when the failure was logged) - the two timestamps allow measuring latency before failure detection
- ClientRequestGuid (uniqueidentifier, nullable) - correlates to the original API/service request
- ErrorCode (int, nullable) - structured error code; NULL if caller did not provide one
- No SET NOCOUNT ON, no error handling in the writing SP - exceptions propagate to the caller
- The writing SP lives in the Trade schema (not History), the only SSDT SP that touches this table

---

## 3. Data Overview

N/A for Synonym (target table is in DB_Logs).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym) | - | - | - | CODE-BACKED | Synonym resolves to DB_Logs.History.CloseMultiplePositionsFail. Target columns inferred from Trade.CloseMultiplePositionsFailInfo: CID (int, customer ID), PositionIDsToClose (varchar(max), nullable, serialized position ID list), FailDescription (varchar(max), failure/error text), RequestOccurred (datetime, caller-provided request timestamp), FailOccurred (datetime, UTC via GETUTCDATE(), when failure was logged), ClientRequestGuid (uniqueidentifier, nullable, request correlation ID), ErrorCode (int, nullable, structured error code). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | DB_Logs.History.CloseMultiplePositionsFail | Synonym | All operations redirect to this target in DB_Logs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CloseMultiplePositionsFailInfo | INSERT | Writer | Inserts one record per failed close-multiple-positions request |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CloseMultiplePositionsFail (synonym)
└── DB_Logs.History.CloseMultiplePositionsFail (table - external database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| DB_Logs.History.CloseMultiplePositionsFail | Table (external DB) | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CloseMultiplePositionsFailInfo | Stored Procedure (Trade schema) | Writes close-multiple-positions failure audit entries |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Show recent close-multiple-positions failures

```sql
SELECT TOP 20
    CID,
    PositionIDsToClose,
    FailDescription,
    RequestOccurred,
    FailOccurred,
    ClientRequestGuid,
    ErrorCode
FROM History.CloseMultiplePositionsFail WITH (NOLOCK)
ORDER BY FailOccurred DESC
```

### 8.2 Find failures for a specific customer

```sql
SELECT TOP 20 *
FROM History.CloseMultiplePositionsFail WITH (NOLOCK)
WHERE CID = 12345
ORDER BY FailOccurred DESC
```

### 8.3 Group failures by error code (last 7 days)

```sql
SELECT
    ErrorCode,
    COUNT(*) AS FailureCount,
    MIN(FailOccurred) AS FirstOccurrence,
    MAX(FailOccurred) AS LastOccurrence
FROM History.CloseMultiplePositionsFail WITH (NOLOCK)
WHERE FailOccurred >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY ErrorCode
ORDER BY FailureCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/6 applicable (synonym)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.CloseMultiplePositionsFail | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.CloseMultiplePositionsFail.sql*

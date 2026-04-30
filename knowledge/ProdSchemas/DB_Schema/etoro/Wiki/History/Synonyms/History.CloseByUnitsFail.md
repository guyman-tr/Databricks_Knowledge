# History.CloseByUnitsFail

> Synonym providing local-schema access to DB_Logs.History.CloseByUnitsFail - the audit log table capturing failed "close by units" requests, recording which customer, instrument, and failure reason were involved.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | Alias: DB_Logs.History.CloseByUnitsFail |
| **Partition** | N/A (resolves to target in DB_Logs) |
| **Indexes** | N/A (resolves to target in DB_Logs) |

---

## 1. Business Meaning

`History.CloseByUnitsFail` is a cross-database synonym pointing to `DB_Logs.History.CloseByUnitsFail`. The underlying table is the failure audit log for the "close by units" feature - the eToro mechanism that allows closing a position by specifying the number of units to close rather than the full position. When a close-by-units request fails, this table captures the failure event for diagnostics and support.

From `History.CloseByUnitsFailInfo` usage, each row captures: the customer (CID), the instrument involved (InstrumentID), the failure description (FailDescription), the number of units the request attempted to close (TotalUnitsToClose), when the failure occurred (FailOccurred, UTC), and optional request correlation fields (ClientRequestGuid, CloseByUnitsID, ErrorCode). The nullable correlation fields were added later to enable linking failure records to specific API requests and error codes.

---

## 2. Business Logic

### 2.1 Close-By-Units Failure Audit

**What**: Each INSERT records one failed close-by-units request with full context for debugging.

**Columns/Parameters Involved**: CID, InstrumentID, FailDescription, TotalUnitsToClose, FailOccurred, ClientRequestGuid, CloseByUnitsID, ErrorCode

**Rules**:
- Written exclusively via History.CloseByUnitsFailInfo (the only SSDT SP that touches this table)
- FailOccurred is always set to GETUTCDATE() by the writing procedure - it is not caller-provided
- ClientRequestGuid (uniqueidentifier, nullable) - correlates the failure to the original API/service request
- CloseByUnitsID (bigint, nullable) - the close-by-units request ID, if one was generated before the failure
- ErrorCode (int, nullable) - structured error code for the failure type; NULL indicates the caller did not provide a code
- FailDescription (varchar(max)) - free-text error/failure description; can contain exception messages or stack traces

---

## 3. Data Overview

N/A for Synonym (target table is in DB_Logs).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym) | - | - | - | CODE-BACKED | Synonym resolves to DB_Logs.History.CloseByUnitsFail. Target columns inferred from History.CloseByUnitsFailInfo: CID (int, customer ID), InstrumentID (int, FK to instrument catalog), FailDescription (varchar(max), failure text), TotalUnitsToClose (decimal(16,8), units requested), FailOccurred (datetime, UTC timestamp via GETUTCDATE()), ClientRequestGuid (uniqueidentifier, nullable, request correlation), CloseByUnitsID (bigint, nullable, close-by-units request ID), ErrorCode (int, nullable, structured error code). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | DB_Logs.History.CloseByUnitsFail | Synonym | All operations redirect to this target in DB_Logs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.CloseByUnitsFailInfo | INSERT | Writer | Inserts one record per close-by-units failure event |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CloseByUnitsFail (synonym)
└── DB_Logs.History.CloseByUnitsFail (table - external database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| DB_Logs.History.CloseByUnitsFail | Table (external DB) | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.CloseByUnitsFailInfo | Stored Procedure | Writes close-by-units failure audit entries |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Show recent close-by-units failures

```sql
SELECT TOP 20
    CID,
    InstrumentID,
    FailDescription,
    TotalUnitsToClose,
    FailOccurred,
    ClientRequestGuid,
    CloseByUnitsID,
    ErrorCode
FROM History.CloseByUnitsFail WITH (NOLOCK)
ORDER BY FailOccurred DESC
```

### 8.2 Find failures for a specific customer

```sql
SELECT TOP 20 *
FROM History.CloseByUnitsFail WITH (NOLOCK)
WHERE CID = 12345
ORDER BY FailOccurred DESC
```

### 8.3 Group failures by error code and instrument

```sql
SELECT
    InstrumentID,
    ErrorCode,
    COUNT(*) AS FailureCount,
    MIN(FailOccurred) AS FirstOccurrence,
    MAX(FailOccurred) AS LastOccurrence
FROM History.CloseByUnitsFail WITH (NOLOCK)
WHERE FailOccurred >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY InstrumentID, ErrorCode
ORDER BY FailureCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/6 applicable (synonym)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.CloseByUnitsFail | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.CloseByUnitsFail.sql*

# History.CloseByUnitsFailInfo

> Simple insert procedure for the close-by-units failure audit log: appends one failure record to History.CloseByUnitsFail (via synonym to DB_Logs) capturing the customer, instrument, failure description, and optional request correlation fields.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @InstrumentID + @FailDescription (no generated key returned) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.CloseByUnitsFailInfo` is the sole writer for `History.CloseByUnitsFail` (a synonym to `DB_Logs.History.CloseByUnitsFail`). It logs failures in the "close by units" feature - the eToro mechanism that allows closing a position by specifying the number of units to close rather than the full position. When this operation fails, this procedure records the failure event with customer context, instrument, units requested, failure reason, and optional correlation IDs for distributed tracing.

The procedure uses SET NOCOUNT ON (suppresses row count messages) but has no TRY/CATCH and no explicit transaction. It is a pure fire-and-forget failure logger - if the INSERT itself fails, the exception propagates to the caller, but this is unlikely since it is logging to an append-only audit table.

The FailOccurred timestamp is always set by the procedure to GETUTCDATE() (UTC) - callers cannot override the timestamp.

---

## 2. Business Logic

### 2.1 Close-By-Units Failure Recording

**What**: Each call appends one failure event to the close-by-units audit trail.

**Columns/Parameters Involved**: @CID, @InstrumentID, @FailDescription, @TotalUnitsToClose, @ClientRequestGuid, @CloseByUnitsID, @ErrorCode

**Rules**:
- @CID (int, required) - the customer whose position close failed
- @InstrumentID (int, required) - the instrument the close was attempted on
- @FailDescription (varchar(max), required) - free-text description of why the close failed; may contain exception messages or diagnostic details
- @TotalUnitsToClose (decimal(16,8), required) - how many units were requested in the failed close; important for support diagnosis
- @ClientRequestGuid (uniqueidentifier, nullable, default NULL) - request correlation ID from the calling service; links to the originating API call
- @CloseByUnitsID (bigint, nullable, default NULL) - the close-by-units request ID if one was generated before the failure; NULL if failure occurred before ID generation
- @ErrorCode (int, nullable, default NULL) - structured error code for the failure type; NULL if the caller did not provide one
- FailOccurred is set to GETUTCDATE() inside the procedure - not caller-provided
- No return value, no OUTPUT parameter, no result set

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID of the account that attempted the close-by-units operation. FK to Customer.Customer.CID (implicit). Used to identify the affected customer for support investigation. |
| 2 | @InstrumentID | int | NO | - | CODE-BACKED | Instrument ID of the asset that was being closed. FK to instrument catalog (implicit). Helps identify whether failures cluster around specific instruments (e.g., due to market conditions or instrument configuration). |
| 3 | @FailDescription | varchar(max) | NO | - | CODE-BACKED | Free-text failure description. May contain exception type, error message, or stack trace context from the calling service. Primary diagnostic field for support investigation. |
| 4 | @TotalUnitsToClose | decimal(16,8) | NO | - | CODE-BACKED | The number of units the calling service attempted to close when the failure occurred. Precision: 16 digits total, 8 decimal places (matching eToro's standard unit precision). Stored as-is - not compared to any position balance in this procedure. |
| 5 | @ClientRequestGuid | uniqueidentifier | YES | NULL | CODE-BACKED | Distributed tracing ID from the calling service's request. Allows correlating this failure log entry with the originating service request, API gateway log, or application trace. NULL if the caller did not provide one. |
| 6 | @CloseByUnitsID | bigint | YES | NULL | CODE-BACKED | The close-by-units request ID, if one was assigned before the failure. NULL when the failure occurred before the request ID was generated (early-stage failures). Allows cross-referencing with the close-by-units request tracking table. |
| 7 | @ErrorCode | int | YES | NULL | CODE-BACKED | Structured error code identifying the failure type. NULL if the caller did not supply one. When populated, enables failure frequency analysis grouped by error type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | History.CloseByUnitsFail (synonym) | Write target | Appends one failure record per close-by-units failure event |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Close-by-units processing service | (application call) | Application | Called when a close-by-units request fails at any stage in the processing pipeline. No SSDT procedures call this. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CloseByUnitsFailInfo (procedure)
└── History.CloseByUnitsFail (synonym -> DB_Logs.History.CloseByUnitsFail)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CloseByUnitsFail | Synonym -> Table (DB_Logs) | INSERT target - one failure row per close-by-units failure event |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Close-by-units processing service | Application | Calls when close-by-units requests fail |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

SET NOCOUNT ON (suppresses row count output). No TRY/CATCH, no BEGIN TRAN. FailOccurred is always GETUTCDATE() - not caller-provided. The SP comment `-- fail insert sp` confirms its sole purpose is failure logging.

---

## 8. Sample Queries

### 8.1 Find recent close-by-units failures

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

### 8.2 Find failures for a specific request

```sql
SELECT *
FROM History.CloseByUnitsFail WITH (NOLOCK)
WHERE ClientRequestGuid = '550E8400-E29B-41D4-A716-446655440000'
```

### 8.3 Failure frequency by instrument and error code

```sql
SELECT
    InstrumentID,
    ErrorCode,
    COUNT(*) AS FailureCount,
    AVG(CAST(TotalUnitsToClose AS FLOAT)) AS AvgUnitsRequested,
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

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.CloseByUnitsFailInfo | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.CloseByUnitsFailInfo.sql*

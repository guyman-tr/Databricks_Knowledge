# History.PostPositionOpen

> Batch processor that dequeues position-open events from Trade.PostPositionOpenMot, writes them to History.PositionChangeLog_Active_BIGINT (ChangeTypeID=0), optionally enqueues UK SDRT stamp-duty fee records into Trade.PostPositionOpenForSdrt, and deletes the processed rows from the source queue - all in a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BatchSize + @StatusID - controls how many pending records to process and which status to filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.PostPositionOpen` is the batch processing procedure that moves position-open records from the `Trade.PostPositionOpenMot` memory-optimized queue into the position change log. It is NOT an async step procedure (it does not follow the @Params/@PartsToDo/@ID interface); instead, it is called directly by a background scheduler with a batch size and status filter.

When a position opens, the trading engine inserts a snapshot into `Trade.PostPositionOpenMot` (StatusID=0). This procedure picks up those pending records and:
1. Inserts them into `History.PositionChangeLog_Active_BIGINT` as ChangeTypeID=0 (Position Open) entries
2. Optionally enqueues a SDRT (Stamp Duty Reserve Tax) fee record into `Trade.PostPositionOpenForSdrt` if the position qualifies for UK stamp duty
3. Deletes the processed rows from `Trade.PostPositionOpenMot`

All three operations execute within a single transaction. On failure, the transaction is rolled back and Trade.PostPositionOpenMot rows are flagged with StatusID=@StatusID-1 (typically -1) to indicate failure for investigation.

`Monitor.PostPositionOpenMotRowExists_Datadog` monitors this queue's depth for alerting.

Data flow: (1) SELECT TOP @BatchSize into temp table #Positions with 3 indexes; (2) BEGIN TRAN; (3) INSERT INTO PositionChangeLog_Active_BIGINT with ChangeTypeID=0 + ClientVersion from Customer.Login; (4) if SDRT rate (FeatureID=118) > 0, INSERT qualifying positions into Trade.PostPositionOpenForSdrt; (5) DELETE processed rows from Trade.PostPositionOpenMot; (6) COMMIT; (7) on error: ROLLBACK, mark @StatusID-1, RAISERROR.

---

## 2. Business Logic

### 2.1 Open Position Change Log Entry (ChangeTypeID=0)

**What**: Inserts the position-open snapshot into PositionChangeLog_Active_BIGINT. Since this is an open event, "Previous" values equal current values (no prior state).

**Columns/Parameters Involved**: `History.PositionChangeLog_Active_BIGINT`, `ChangeTypeID`, all A.* columns from #Positions

**Rules**:
- ChangeTypeID = 0 (hard-coded constant = Position Open)
- PreviousCloseOnEndOfWeek = CloseOnEndOfWeek (same for open)
- PreviousEndOfWeekFee = 0, EndOfWeekFee = 0 (no fee at open)
- PreviousAmount = Amount, AmountChanged = 0, NewAmount = Amount (no change at open)
- PreviousLimitRate = LimitRate (same for open)
- PreviousStopRate = StopRate (same for open)
- OrigParentPositionID = ParentPositionID (same at open - no detachments yet)
- PrevTreeID = TreeID (same at open)
- PreviouseUnitsBaseValueCents = UnitsBaseValueCents (same at open)
- ExecutedWithoutSettings = 0 (hard-coded)
- ClientVersion: LEFT JOIN Customer.Login on CID; NULL if login record not found

### 2.2 UK SDRT (Stamp Duty Reserve Tax) Fee Queue

**What**: Qualifying UK stock buys generate a SDRT fee entry in Trade.PostPositionOpenForSdrt.

**Columns/Parameters Involved**: `Maintenance.Feature.FeatureID=118`, `Trade.PostPositionOpenForSdrt`, `Trade.InstrumentMetaData`

**Rules**:
- SDRT only runs if FeatureID=118 (SDRT rate) > 0 (enabled in Maintenance.Feature)
- All conditions must be true for a position to generate a SDRT fee:
  - OpenActionType IN (0, 1, 3, 8, 9, 16, 17) - Dictionary.OpenPositionActionType
  - SettlementTypeID = 1 - Dictionary.SettlementTypes (standard settlement)
  - Leverage = 1 (no leverage - spot/non-leveraged position)
  - IsBuy = 1 (buy direction only - SDRT is a buy-side tax)
  - imd.ISINCountryCode = 'GB' (UK instrument)
  - imd.ExchangeID = 7 (LSE - London Stock Exchange)
  - imd.InstrumentTypeID = 5 (Stocks - Dictionary.CurrencyType)
  - ROUND(Amount * @SdrtRate, 2, 1) >= 0.01 (minimum 1 cent fee)
- Fee = ROUND(Amount * @SdrtRate, 2, 1) (0.5% UK stamp duty rate typically)
- StatusID = 0 on insert (pending for Trade.PostPositionOpenForSdrtCharge processor)

**Diagram**:
```
Position is UK Stock Buy (non-leveraged, LSE, SettlementType=1)?
    |
    AND SDRT feature (FeatureID=118) rate > 0?
    |
    YES -> INSERT INTO Trade.PostPositionOpenForSdrt (StatusID=0)
    NO  -> Skip SDRT queue
```

### 2.3 Batch Processing and Error Handling

**What**: @BatchSize controls throughput; @StatusID controls which records to pick up and where to mark failures.

**Columns/Parameters Involved**: `@BatchSize`, `@StatusID`, `Trade.PostPositionOpenMot.StatusID`

**Rules**:
- SELECT TOP @BatchSize records WHERE StatusID=@StatusID from Trade.PostPositionOpenMot
- Typical call: @BatchSize=1000, @StatusID=0
- On success: rows are DELETEd from Trade.PostPositionOpenMot
- On failure: ROLLBACK; UPDATE Trade.PostPositionOpenMot SET StatusID=@StatusID-1 (e.g., -1 for "error"); RAISERROR with original error message
- StatusID=-1 marks rows for investigation/retry without losing data

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BatchSize | INT | NO | - | CODE-BACKED | Number of records to dequeue per call. Typical value: 1000. Controls throughput - higher values reduce call overhead but increase transaction duration. |
| 2 | @StatusID | INT | NO | - | CODE-BACKED | Filter value for Trade.PostPositionOpenMot.StatusID. Typical value: 0 (pending). On failure, rows are set to @StatusID-1 (typically -1) to mark error state. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StatusID filter | Trade.PostPositionOpenMot | READ + DELETE | Primary source queue; reads pending records by StatusID, deletes after successful processing |
| All position fields | History.PositionChangeLog_Active_BIGINT | INSERT | Writes position-open change log entries with ChangeTypeID=0 |
| CID | Customer.Login | LEFT JOIN | Reads ClientVersion for the change log entry |
| FeatureID=118 | Maintenance.Feature | Lookup | Reads SDRT rate (0 = disabled, >0 = enabled with that rate) |
| Qualifying positions | Trade.PostPositionOpenForSdrt | INSERT (conditional) | Enqueues SDRT fee records for UK non-leveraged stock buys |
| InstrumentID | Trade.InstrumentMetaData | INNER JOIN (conditional) | Reads ISINCountryCode, ExchangeID, InstrumentTypeID for SDRT qualification |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT repository. Called by background scheduler/job directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PostPositionOpen (procedure)
+-- Trade.PostPositionOpenMot (table - source queue, memory-optimized)
+-- History.PositionChangeLog_Active_BIGINT (table - INSERT target)
+-- Customer.Login (table - ClientVersion lookup)
+-- Maintenance.Feature (table - FeatureID=118 SDRT rate)
+-- Trade.PostPositionOpenForSdrt (table - conditional SDRT fee queue)
+-- Trade.InstrumentMetaData (table - SDRT instrument qualification)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PostPositionOpenMot | Table (Memory-Optimized) | Source queue - SELECT TOP @BatchSize pending records, DELETE on success, UPDATE StatusID on failure |
| History.PositionChangeLog_Active_BIGINT | Table | INSERT target for position-open change log entries (ChangeTypeID=0) |
| Customer.Login | Table | LEFT JOIN to get ClientVersion for the change log entry |
| Maintenance.Feature | Table | Reads FeatureID=118 for SDRT rate (0=disabled) |
| Trade.PostPositionOpenForSdrt | Table | Conditional INSERT target for UK SDRT fee queue |
| Trade.InstrumentMetaData | Table | INNER JOIN for SDRT qualification (ISINCountryCode, ExchangeID, InstrumentTypeID) |

### 6.2 Objects That Depend On This

No dependents found in SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ChangeTypeID=0 | Business rule | Hard-coded to 0 (Position Open) for all records inserted |
| Previous=Current for opens | Business rule | PreviousAmount=Amount, PreviousLimitRate=LimitRate, etc. - at open there is no prior state |
| Single transaction | ACID | All three DML operations (PositionChangeLog INSERT, SDRT INSERT, PostPositionOpenMot DELETE) are atomic |
| StatusID=-1 on error | Error marking | Failed batches set StatusID to @StatusID-1; prevents reprocessing, enables investigation |
| SDRT FeatureID=118 gate | Feature flag | SDRT fee processing only runs when Maintenance.Feature FeatureID=118 > 0 |
| SDRT minimum 0.01 | Business rule | SDRT fee must be at least 1 cent; very small positions may not generate a SDRT record |
| Temp table indexing | Performance | Three indexes on #Positions (CLUSTERED PositionID, NC CID, NC InstrumentID) for efficient JOIN performance |

---

## 8. Sample Queries

### 8.1 Standard batch processing call

```sql
EXEC History.PostPositionOpen @BatchSize = 1000, @StatusID = 0
```

### 8.2 Check pending queue depth

```sql
SELECT COUNT(*) AS PendingPositionOpens
FROM Trade.PostPositionOpenMot WITH (NOLOCK)
WHERE StatusID = 0
```

### 8.3 Check for failed records (StatusID=-1)

```sql
SELECT TOP 20 PositionID, CID, Occurred, StatusID
FROM Trade.PostPositionOpenMot WITH (NOLOCK)
WHERE StatusID < 0
ORDER BY Occurred DESC
```

### 8.4 Verify recent position-open change log entries

```sql
SELECT TOP 20 PositionID, CID, ChangeTypeID, Occurred, NewAmount
FROM History.PositionChangeLog_Active_BIGINT WITH (NOLOCK)
WHERE ChangeTypeID = 0  -- Position Open
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 30 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PostPositionOpen | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.PostPositionOpen.sql*

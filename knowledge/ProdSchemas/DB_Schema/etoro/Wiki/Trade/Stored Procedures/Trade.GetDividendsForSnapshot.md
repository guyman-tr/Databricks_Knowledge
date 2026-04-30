# Trade.GetDividendsForSnapshot

> Within a transaction, claims pending dividends (Status=0 to Status=3) for position snapshot taking, returning dividend details including market close time and correction references.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ExchangeIDs (TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDividendsForSnapshot is a WRITER procedure that claims pending dividends for the position snapshot phase. When a dividend's ex-date market close has passed, this procedure atomically transitions Status from 0 (pending) to 3 (snapshot being taken) and sets PositionsSnapshotStarted to the current UTC time. It returns the dividend details so the snapshot service can capture which positions are eligible.

This procedure exists as the first step in the dividend payment pipeline. Before dividends can be paid, the system needs to snapshot which positions were open at the market close on the ex-date. Each instrument dividend has two rows (CFD and real stock), and only those whose market close time has passed (MarketCloseDateTimeUtc IS NOT NULL) are claimed.

The operation runs inside an explicit BEGIN TRANSACTION / COMMIT to ensure atomicity.

---

## 2. Business Logic

### 2.1 Snapshot Claim Pattern

**What**: Atomically transitions pending dividends to snapshot-in-progress state.

**Columns/Parameters Involved**: `Status`, `PositionsSnapshotStarted`, `MarketCloseDateTimeUtc`

**Rules**:
- Status=0: pending processing (eligible for snapshot)
- Status=3: snapshot being taken (claimed by this call)
- PositionsSnapshotStarted = GETUTCDATE() records when the snapshot began
- MarketCloseDateTimeUtc computed via Trade.GetMarketCloseTimeByExDate(ExchangeID, InstrumentID, ExDate)
- Only rows where MarketCloseDateTimeUtc IS NOT NULL are claimed (market close has been determined)
- Runs in explicit transaction for atomicity

### 2.2 Dual Position Type + Instrument Type Logic

**What**: Handles CFD vs real and Index vs Stock instrument type differences.

**Columns/Parameters Involved**: `PositionType`, `IsSettled`, `InstrumentTypeID`

**Rules**:
- PositionType=0/IsSettled=0: CFD dividend; PositionType=1/IsSettled=1: real stock dividend
- InstrumentTypeID IN (4,5): Index/Stock - InstrumentID passed to market close function
- Other types: InstrumentID is NULL for market close calculation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExchangeIDs | Trade.IdIntList (TVP) | NO | - | CODE-BACKED | Exchange IDs to process. Filters via InstrumentMetaData.ExchangeID. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | int | NO | - | CODE-BACKED | Dividend claimed for snapshot. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument paying the dividend. |
| 3 | IsSettled | bit | NO | - | CODE-BACKED | 0=CFD dividend, 1=real stock dividend. |
| 4 | PaymentDate | date | YES | - | CODE-BACKED | Scheduled payment date. |
| 5 | ExDate | date | YES | - | CODE-BACKED | Ex-dividend date (cutoff for position eligibility). |
| 6 | MarketCloseDateTimeUtc | datetime | YES | - | CODE-BACKED | UTC market close time on the ex-date. |
| 7 | CorrectionDividendID | int | YES | - | CODE-BACKED | Original dividend if this is a correction. |
| 8 | NegativeDividendAllowed | bit | YES | - | CODE-BACKED | Whether debit dividends are allowed. |
| 9 | RetakeDividendID | int | YES | - | CODE-BACKED | Dividend that needs retaking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| * | Trade.IndexDividends | UPDATE + OUTPUT | Dividend status transition |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Exchange and instrument type |
| ExchangeID, ExDate | Trade.GetMarketCloseTimeByExDate | Function call | Market close calculation |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDividendsForSnapshot (procedure)
+-- Trade.IndexDividends (table)
+-- Trade.InstrumentMetaData (table)
+-- Trade.GetMarketCloseTimeByExDate (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends | Table | UPDATE SET Status=3 + OUTPUT |
| Trade.InstrumentMetaData | Table | JOIN for ExchangeID and InstrumentTypeID |
| Trade.GetMarketCloseTimeByExDate | Function | Market close time computation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | Called by dividend snapshot service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

WRITER procedure. Uses explicit BEGIN TRANSACTION / COMMIT.

---

## 8. Sample Queries

### 8.1 Claim dividends for snapshot

```sql
DECLARE @Exchanges Trade.IdIntList;
INSERT INTO @Exchanges (Id) VALUES (1), (2);
EXEC Trade.GetDividendsForSnapshot @ExchangeIDs = @Exchanges;
```

### 8.2 Check pending dividends before claiming

```sql
SELECT TID.DividendID, TID.InstrumentID, TID.ExDate, TID.Status
FROM   Trade.IndexDividends TID WITH (NOLOCK)
WHERE  TID.Status = 0;
```

### 8.3 Monitor snapshot progress

```sql
SELECT DividendID, InstrumentID, PositionsSnapshotStarted
FROM   Trade.IndexDividends WITH (NOLOCK)
WHERE  Status = 3;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.6/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDividendsForSnapshot | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDividendsForSnapshot.sql*

# Trade.GetDividendsForSnapshot_DryRun

> Dry-run variant of GetDividendsForSnapshot - merges production dividends into the DryRun table, then claims pending dividends for snapshot taking.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ExchangeIDs (TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDividendsForSnapshot_DryRun is the dry-run counterpart of Trade.GetDividendsForSnapshot. Before claiming dividends, it first calls Trade.Merge_IndexDividends_DryRun to sync the _DryRun table with production data, then applies the same snapshot claim logic (Status=0 to Status=3) on the _DryRun table.

This procedure exists to support dividend pipeline testing with production-aligned data. The merge step ensures the dry-run table reflects the latest production dividends before testing the snapshot flow.

---

## 2. Business Logic

### 2.1 Pre-Snapshot Merge

**What**: Syncs the DryRun table with production before claiming.

**Columns/Parameters Involved**: `Trade.Merge_IndexDividends_DryRun`

**Rules**:
- EXEC Trade.Merge_IndexDividends_DryRun runs first within the transaction
- This ensures the dry-run table has all current production dividends
- Then the standard snapshot claim logic executes on _DryRun

### 2.2 Snapshot Claim on DryRun

**What**: Same claim pattern as production but on the _DryRun table.

**Columns/Parameters Involved**: `Status`, `MarketCloseDateTimeUtc`

**Rules**:
- Same as GetDividendsForSnapshot but targeting Trade.IndexDividends_DryRun
- Does NOT include RetakeDividendID in output (fewer columns than production)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExchangeIDs | Trade.IdIntList (TVP) | NO | - | CODE-BACKED | Exchange IDs to process. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | int | NO | - | CODE-BACKED | Dividend claimed for dry-run snapshot. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument paying the dividend. |
| 3 | IsSettled | bit | NO | - | CODE-BACKED | 0=CFD, 1=real stock. |
| 4 | PaymentDate | date | YES | - | CODE-BACKED | Scheduled payment date. |
| 5 | ExDate | date | YES | - | CODE-BACKED | Ex-dividend date. |
| 6 | MarketCloseDateTimeUtc | datetime | YES | - | CODE-BACKED | UTC market close on ex-date. |
| 7 | CorrectionDividendID | int | YES | - | CODE-BACKED | Original dividend if correction. |
| 8 | NegativeDividendAllowed | bit | YES | - | CODE-BACKED | Whether debit dividends allowed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| * | Trade.IndexDividends_DryRun | UPDATE + OUTPUT | DryRun dividend table |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Exchange lookup |
| - | Trade.Merge_IndexDividends_DryRun | EXEC | Pre-merge production data |
| ExchangeID, ExDate | Trade.GetMarketCloseTimeByExDate | Function call | Market close calculation |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDividendsForSnapshot_DryRun (procedure)
+-- Trade.Merge_IndexDividends_DryRun (procedure)
+-- Trade.IndexDividends_DryRun (table)
+-- Trade.InstrumentMetaData (table)
+-- Trade.GetMarketCloseTimeByExDate (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Merge_IndexDividends_DryRun | Stored Procedure | EXEC - sync DryRun with production |
| Trade.IndexDividends_DryRun | Table | UPDATE + OUTPUT |
| Trade.InstrumentMetaData | Table | JOIN for ExchangeID |
| Trade.GetMarketCloseTimeByExDate | Function | Market close time |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | Called by dry-run dividend service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

WRITER procedure. Uses explicit BEGIN TRANSACTION / COMMIT.

---

## 8. Sample Queries

### 8.1 Run dry-run snapshot

```sql
DECLARE @Exchanges Trade.IdIntList;
INSERT INTO @Exchanges (Id) VALUES (1), (2);
EXEC Trade.GetDividendsForSnapshot_DryRun @ExchangeIDs = @Exchanges;
```

### 8.2 Check dry-run snapshot status

```sql
SELECT DividendID, Status, PositionsSnapshotStarted
FROM   Trade.IndexDividends_DryRun WITH (NOLOCK)
WHERE  Status = 3;
```

### 8.3 Compare production vs dry-run pending count

```sql
SELECT 'Prod' AS Src, COUNT(*) FROM Trade.IndexDividends WITH (NOLOCK) WHERE Status = 0
UNION ALL
SELECT 'DryRun', COUNT(*) FROM Trade.IndexDividends_DryRun WITH (NOLOCK) WHERE Status = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDividendsForSnapshot_DryRun | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDividendsForSnapshot_DryRun.sql*

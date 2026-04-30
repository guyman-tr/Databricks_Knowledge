# Trade.CheckAllInstrumentUpload

> DBA monitoring procedure that verifies all recently added instruments have complete candle data, closing prices, and source data across all required candle types.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - autonomous check |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CheckAllInstrumentUpload is a data completeness check that verifies every instrument added in the last 24 hours has the required supporting data in all candle timeframes, closing price sources, and historical closing prices. If any instrument is missing data for any candle type, the procedure reports the gap.

This procedure exists to catch instrument onboarding issues early. When a new instrument is added to the platform (e.g., a new stock or crypto), it requires candle data at multiple timeframes (1min, 5min, 10min, 15min, 30min, 60min, 240min, 1440min/daily, 10080min/weekly), plus closing price source data and historical closing prices. Missing data would cause chart display failures and incorrect PnL calculations.

The procedure selects instruments from Trade.InstrumentMetaData where CreateDate > getdate()-1, then counts distinct instruments in dbo.T_CurrentCandle for each CandleType, Trade.InstrumentClosingPriceSourceData, and dbo.HistoryClosingPrices. Any count mismatch is reported as 'Missingdata'.

---

## 2. Business Logic

### 2.1 Candle Data Completeness Check

**What**: Verifies all 9 candle timeframes plus 2 price data sources have data for every new instrument.

**Columns/Parameters Involved**: `Trade.InstrumentMetaData.CreateDate`, `dbo.T_CurrentCandle.CandleType`, `Trade.InstrumentClosingPriceSourceData`, `dbo.HistoryClosingPrices`

**Rules**:
- Instruments scoped: CreateDate > getdate()-1 (last 24 hours)
- Candle types checked: 1, 5, 10, 15, 30, 60, 240, 1440, 10080
- Additional checks: InstrumentClosingPriceSourceData, HistoryClosingPrices
- Pass: All 11 counts equal the instrument count
- Fail: Any count less than instrument count - reports as 'Missingdata' with the specific source name

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. It operates on instruments created in the last 24 hours.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Trade.InstrumentMetaData | SELECT | Gets recently added instruments |
| (reads) | dbo.T_CurrentCandle | SELECT | Checks candle data completeness across all timeframes |
| (reads) | Trade.InstrumentClosingPriceSourceData | SELECT | Checks closing price source data exists |
| (reads) | dbo.HistoryClosingPrices | SELECT | Checks historical closing prices exist |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DBA monitoring | (manual/job) | EXEC | Run as part of instrument onboarding verification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CheckAllInstrumentUpload (procedure)
+-- Trade.InstrumentMetaData (table)
+-- dbo.T_CurrentCandle (table)
+-- Trade.InstrumentClosingPriceSourceData (table)
+-- dbo.HistoryClosingPrices (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | SELECT instruments created in last 24h |
| dbo.T_CurrentCandle | Table | SELECT count of instruments per CandleType |
| Trade.InstrumentClosingPriceSourceData | Table | SELECT count of instruments with source data |
| dbo.HistoryClosingPrices | Table | SELECT count of instruments with closing prices |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none) | - | Ad-hoc DBA monitoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run the completeness check

```sql
EXEC Trade.CheckAllInstrumentUpload;
```

### 8.2 Manually check instruments added in last 24 hours

```sql
SELECT InstrumentID, CreateDate
FROM   Trade.InstrumentMetaData WITH (NOLOCK)
WHERE  CreateDate > GETDATE() - 1;
```

### 8.3 Check candle data for a specific instrument

```sql
SELECT CandleType, COUNT(*) AS CandleCount
FROM   dbo.T_CurrentCandle WITH (NOLOCK)
WHERE  InstrumentID = @InstrumentID
GROUP BY CandleType
ORDER BY CandleType;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CheckAllInstrumentUpload | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CheckAllInstrumentUpload.sql*

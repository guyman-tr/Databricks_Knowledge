# Trade.GetInstrumentByCreateData

> Reports how many recently created instruments exist across multiple related tables - a cross-database instrument provisioning audit.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | ObjectName + Total (result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure checks how many instruments created after a given date exist in each of several related tables across the etoro and PriceLog databases. It answers: "After we added new instruments, did all the required downstream tables get populated?" This is an instrument provisioning completeness check.

The procedure exists to support operations/DBA validation after new instruments are onboarded. When instruments are created in Trade.InstrumentMetaData, they should also appear in PriceLog candle tables, closing price tables, and split ratio tables. This SP reports the count of matching instruments in each table to identify gaps.

Data flow: caller passes @CreateDate. The SP runs 5 UNIONed queries counting distinct instruments with CreateDate > @CreateDate across: Trade.InstrumentMetaData, PriceLog.Candles.T_CurrentCandle, PriceLog.Trade.InstrumentClosingPriceSourceData, PriceLog.History.ClosingPrices, and dbo.PriceSplitRatio. Uses READ UNCOMMITTED isolation.

---

## 2. Business Logic

### 2.1 Instrument Provisioning Completeness

**What**: Validates that new instruments propagated to all required tables.

**Columns/Parameters Involved**: `@CreateDate`, `CreateDate`, `InstrumentID`

**Rules**:
- Each UNION segment counts distinct InstrumentIDs that exist in both InstrumentMetaData (created after @CreateDate) and the target table
- A mismatch between the InstrumentMetaData count and any downstream table count indicates missing provisioning
- Cross-database joins to PriceLog require linked server or 3-part naming

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CreateDate | DATE | NO | - | CODE-BACKED | Date threshold. Only instruments created after this date are counted. |
| 2 | ObjectName (output) | VARCHAR | NO | - | CODE-BACKED | Full table name being checked (e.g., 'etoro.Trade.InstrumentMetaData'). |
| 3 | Total (output) | INT | NO | - | CODE-BACKED | Count of distinct instruments from InstrumentMetaData (CreateDate > @CreateDate) found in this table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.InstrumentMetaData | FROM | Source of new instruments by CreateDate |
| (body) | PriceLog.Candles.T_CurrentCandle | JOIN | Checks candle data presence |
| (body) | PriceLog.Trade.InstrumentClosingPriceSourceData | JOIN | Checks closing price source |
| (body) | PriceLog.History.ClosingPrices | JOIN | Checks historical closing prices |
| (body) | dbo.PriceSplitRatio | JOIN | Checks split ratio data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentByCreateData (procedure)
+-- Trade.InstrumentMetaData (table)
+-- PriceLog.Candles.T_CurrentCandle (cross-db table)
+-- PriceLog.Trade.InstrumentClosingPriceSourceData (cross-db table)
+-- PriceLog.History.ClosingPrices (cross-db table)
+-- dbo.PriceSplitRatio (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | FROM/JOIN - base set of new instruments |
| PriceLog.Candles.T_CurrentCandle | Table (cross-db) | JOIN - candle data check |
| PriceLog.Trade.InstrumentClosingPriceSourceData | Table (cross-db) | JOIN - closing price source check |
| PriceLog.History.ClosingPrices | Table (cross-db) | JOIN - historical closing price check |
| dbo.PriceSplitRatio | Table | JOIN - split ratio check |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Uses READ UNCOMMITTED transaction isolation level.

---

## 8. Sample Queries

### 8.1 Check instruments created in last 30 days

```sql
EXEC Trade.GetInstrumentByCreateData @CreateDate = '2026-02-14';
```

### 8.2 Check new instruments from today

```sql
EXEC Trade.GetInstrumentByCreateData @CreateDate = CAST(GETDATE() AS DATE);
```

### 8.3 Direct metadata count

```sql
SELECT  COUNT(*) AS NewInstruments
FROM    Trade.InstrumentMetaData WITH (NOLOCK)
WHERE   CreateDate > '2026-02-14';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentByCreateData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentByCreateData.sql*

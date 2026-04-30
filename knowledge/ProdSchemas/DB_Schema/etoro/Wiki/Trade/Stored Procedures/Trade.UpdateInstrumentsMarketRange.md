# Trade.UpdateInstrumentsMarketRange

> Batch-updates MarketRange, MarketRangePercentage, and MarketRangeValidationType in Trade.ProviderToInstrument for a set of instruments supplied via TVP.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentNewConfigTable (TVP - Trade.InstrumentMarketRangeConfigTable) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateInstrumentsMarketRange configures the market range parameters for a batch of instruments in `Trade.ProviderToInstrument`. Market range is the maximum price deviation from the market price that eToro accepts for order execution. If a customer's requested price deviates beyond the market range, the order may be rejected or repriced - this is a key execution quality control mechanism.

Three fields are updated:
- **MarketRange**: absolute price deviation limit (in instrument price units)
- **MarketRangePercentage**: percentage-based deviation limit
- **MarketRangeValidationType**: controls which type of market range validation is applied (absolute, percentage, or a combination)

This procedure is called during instrument configuration when configuring execution tolerance parameters - for example, when onboarding a new batch of instruments or adjusting market range settings after market volatility changes.

---

## 2. Business Logic

### 2.1 Batch UPDATE via Temp Table with Clustered Index

**What**: The TVP is materialized into a temp table with a clustered index on InstrumentID to optimize the JOIN.

**Columns/Parameters Involved**: All TVP columns -> `Trade.ProviderToInstrument.MarketRange`, `.MarketRangePercentage`, `.MarketRangeValidationType`

**Rules**:
- TVP is copied to `#InstrumentNewConfigTable` with `CREATE CLUSTERED INDEX CIX ON #InstrumentNewConfigTable (InstrumentID)` for JOIN optimization
- `UPDATE Trade.ProviderToInstrument SET MarketRange=ct.MarketRange, MarketRangePercentage=ct.MarketRangePercentage, MarketRangeValidationType=ct.MarketRangeValidationType INNER JOIN #InstrumentNewConfigTable ON InstrumentID`
- No existence check for InstrumentIDs; no SyncConfiguration INSERT (unlike MaxPositionUnits/MaxRateDiff)
- No explicit transaction; single-statement UPDATE

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentNewConfigTable | Trade.InstrumentMarketRangeConfigTable READONLY | NO | - | CODE-BACKED | TVP with market range config per instrument. Used columns: InstrumentID (NOT NULL, JOIN key), MarketRange (int, nullable - absolute price deviation limit), MarketRangePercentage (decimal(5,2), nullable - percentage deviation limit), MarketRangeValidationType (tinyint, NOT NULL - validation mode). Also in TVP but unused by this SP: InstrumentTypeID, Symbol, Precision. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentNewConfigTable | Trade.InstrumentMarketRangeConfigTable | TVP | Input parameter type |
| UPDATE target | Trade.ProviderToInstrument | Modifier | Updates MarketRange, MarketRangePercentage, MarketRangeValidationType per InstrumentID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no explicit permission grants found in SSDT. Invoked by instrument configuration tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentsMarketRange (procedure)
+-- Trade.InstrumentMarketRangeConfigTable (TVP type)
+-- Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMarketRangeConfigTable | User Defined Type (TVP) | Input parameter type |
| Trade.ProviderToInstrument | Table | UPDATE target for MarketRange, MarketRangePercentage, MarketRangeValidationType |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (instrument configuration tooling) | - | Called when reconfiguring market range execution parameters |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. TVP materialized into `#InstrumentNewConfigTable` with CLUSTERED INDEX on InstrumentID.

### 7.2 Constraints

N/A for stored procedure. Uses SET NOCOUNT ON. No TRY/CATCH. No explicit transaction.

---

## 8. Sample Queries

### 8.1 Update market range for a batch of instruments
```sql
DECLARE @Config Trade.InstrumentMarketRangeConfigTable;

INSERT INTO @Config (InstrumentID, InstrumentTypeID, Precision, MarketRange, MarketRangePercentage, MarketRangeValidationType)
VALUES
  (1001, 4, 2, 50, 0.50, 1),
  (1002, 4, 2, 75, 0.75, 1);

EXEC Trade.UpdateInstrumentsMarketRange @InstrumentNewConfigTable = @Config;
```

### 8.2 Check current market range settings
```sql
SELECT pti.InstrumentID, pti.MarketRange, pti.MarketRangePercentage, pti.MarketRangeValidationType
FROM   Trade.ProviderToInstrument pti WITH (NOLOCK)
WHERE  pti.InstrumentID IN (1001, 1002);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentsMarketRange | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentsMarketRange.sql*

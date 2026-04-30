# Trade.UpsertFuturesInstrumentRiskSettings

> Upserts stop-loss and take-profit percentage buffers for futures instruments via MERGE, accepting a table-valued parameter. Default buffer of 2.00% applied when inserting new instruments with null buffer values.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FuturesInstrumentRiskSettings TVP (MERGE on InstrumentID into FuturesInstrumentRiskSettings) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure manages the risk buffer settings for futures instruments - the percentage cushion applied to stop-loss and take-profit orders. For futures, market gaps and volatility can cause prices to spike through exact SL/TP levels, so a buffer percentage is added to create a safety margin.

The procedure accepts a batch of updates via a table-valued parameter (`Trade.Tv_FuturesInstrumentRiskSettings`) and uses MERGE to upsert into `Trade.FuturesInstrumentRiskSettings`:

- **Update existing**: Updates StopLossPercentageBuffer and/or TakeProfitPercentageBuffer, but only when the source value IS NOT NULL (null-safe: passing null leaves the existing value unchanged)
- **Insert new**: Inserts the instrument with provided buffers, defaulting to 2.00% for any null buffer value

This is a configuration management procedure, typically called by the risk/trading operations team when adjusting futures risk parameters.

---

## 2. Business Logic

### 2.1 MERGE Statement

```sql
MERGE Trade.FuturesInstrumentRiskSettings AS Target
USING @FuturesInstrumentRiskSettings AS Source
ON Target.InstrumentID = Source.InstrumentID
WHEN MATCHED THEN
    UPDATE SET
        StopLossPercentageBuffer = CASE WHEN Source.StopLossPercentageBuffer IS NOT NULL
            THEN Source.StopLossPercentageBuffer ELSE Target.StopLossPercentageBuffer END,
        TakeProfitPercentageBuffer = CASE WHEN Source.TakeProfitPercentageBuffer IS NOT NULL
            THEN Source.TakeProfitPercentageBuffer ELSE Target.TakeProfitPercentageBuffer END
WHEN NOT MATCHED BY TARGET THEN
    INSERT (InstrumentID, StopLossPercentageBuffer, TakeProfitPercentageBuffer)
    VALUES (Source.InstrumentID,
            ISNULL(Source.StopLossPercentageBuffer, @DefaultPercentageBuffer),
            ISNULL(Source.TakeProfitPercentageBuffer, @DefaultPercentageBuffer))
```

- **Null-safe update**: CASE expression preserves existing value when source buffer is NULL
- **Default on insert**: @DefaultPercentageBuffer = 2.00; new instruments get 2% if not specified
- Match key: InstrumentID (natural key for futures instruments)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FuturesInstrumentRiskSettings | Trade.Tv_FuturesInstrumentRiskSettings | NO | - | CODE-BACKED | Table-valued parameter containing rows to upsert. Each row: InstrumentID, StopLossPercentageBuffer (nullable), TakeProfitPercentageBuffer (nullable). |

### Internal Variables

| Variable | Value | Description |
|----------|-------|-------------|
| @DefaultPercentageBuffer | 2.00 | Default buffer percentage applied when inserting a new instrument with null buffer value. |

### Output

No result sets. Side effect: `Trade.FuturesInstrumentRiskSettings` rows inserted or updated.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID, StopLossPercentageBuffer, TakeProfitPercentageBuffer | Trade.FuturesInstrumentRiskSettings | WRITE (MERGE) | Target table for upsert. |
| (TVP definition) | Trade.Tv_FuturesInstrumentRiskSettings | Type Reference | Table-valued parameter type defining the input schema. |

### 5.2 Referenced By

Not analyzed. Called by risk/trading operations tooling for futures risk configuration management.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpsertFuturesInstrumentRiskSettings (procedure)
+-- Trade.FuturesInstrumentRiskSettings (table) - MERGE target
+-- Trade.Tv_FuturesInstrumentRiskSettings (TVP type) - input type
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FuturesInstrumentRiskSettings | Table | MERGE target: insert/update buffer settings per InstrumentID. |
| Trade.Tv_FuturesInstrumentRiskSettings | User Defined Table Type | Input TVP schema definition. |

### 6.2 Objects That Depend On This

Not analyzed.

---

## 7. Technical Details

### 7.1 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Default buffer 2.00% | Business Rule | New instruments without explicit buffers get 2.00% safety margin. Reflects standard futures risk tolerance. |
| Null-safe update | Business Rule | Passing NULL for a buffer column leaves the existing value unchanged. Allows partial updates. |
| READONLY TVP | Technical | @FuturesInstrumentRiskSettings marked READONLY - cannot be modified inside the procedure. |

---

## 8. Sample Queries

### 8.1 Upsert risk settings for two futures instruments

```sql
DECLARE @Settings Trade.Tv_FuturesInstrumentRiskSettings
INSERT INTO @Settings VALUES (1001, 1.50, 2.50)  -- explicit buffers
INSERT INTO @Settings VALUES (1002, NULL, NULL)   -- will use 2.00% default if new, unchanged if existing
EXEC Trade.UpsertFuturesInstrumentRiskSettings @Settings
```

### 8.2 Check current settings

```sql
SELECT InstrumentID, StopLossPercentageBuffer, TakeProfitPercentageBuffer
FROM Trade.FuturesInstrumentRiskSettings WITH (NOLOCK)
ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpsertFuturesInstrumentRiskSettings | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpsertFuturesInstrumentRiskSettings.sql*

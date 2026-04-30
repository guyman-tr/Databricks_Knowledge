# Trade.UpsertProviderMarginMarkupByInstrument

> Upserts the margin markup percentage for provider-instrument pairs via MERGE, accepting a table-valued parameter. Updates MarkupPercentage for existing pairs; inserts new pairs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderMarginMarkupByInstrument TVP (MERGE on InstrumentID+ProviderID into ProviderMarginMarkupByInstrument) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure manages the margin markup percentage that eToro charges on top of the provider's margin for each instrument-provider combination. Margin markup is an additional percentage applied to the base margin requirement, generating revenue when customers trade with leverage.

The procedure accepts a batch via `Trade.Tv_ProviderMarginMarkupByInstrument` and uses MERGE to upsert into `Trade.ProviderMarginMarkupByInstrument`:

- **Match key**: InstrumentID + ProviderID (each provider can have different markups per instrument)
- **Update**: Always updates MarkupPercentage when the pair exists (no null-safe logic - overwrite)
- **Insert**: Adds new provider-instrument pairs with the provided MarkupPercentage

This is a configuration management procedure used by the trading operations team to adjust margin costs per provider routing.

---

## 2. Business Logic

### 2.1 MERGE Statement

```sql
MERGE Trade.ProviderMarginMarkupByInstrument AS Target
USING @ProviderMarginMarkupByInstrument AS Source
ON Target.InstrumentID = Source.InstrumentID AND Target.ProviderID = Source.ProviderID
WHEN MATCHED THEN
    UPDATE SET MarkupPercentage = Source.MarkupPercentage
WHEN NOT MATCHED BY TARGET THEN
    INSERT (InstrumentID, ProviderID, MarkupPercentage)
    VALUES (Source.InstrumentID, Source.ProviderID, Source.MarkupPercentage)
```

- Match key: InstrumentID AND ProviderID (composite key)
- **Overwrite on update**: No null-safe guard - always overwrites MarkupPercentage
- **No default on insert**: MarkupPercentage must be specified in the TVP

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderMarginMarkupByInstrument | Trade.Tv_ProviderMarginMarkupByInstrument | NO | - | CODE-BACKED | Table-valued parameter. Each row: InstrumentID, ProviderID, MarkupPercentage. |

### Output

No result sets. Side effect: `Trade.ProviderMarginMarkupByInstrument` rows inserted or updated.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID, ProviderID, MarkupPercentage | Trade.ProviderMarginMarkupByInstrument | WRITE (MERGE) | Target table for upsert. |
| (TVP definition) | Trade.Tv_ProviderMarginMarkupByInstrument | Type Reference | Table-valued parameter type defining the input schema. |

### 5.2 Referenced By

Not analyzed. Called by trading operations tooling for margin markup configuration.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpsertProviderMarginMarkupByInstrument (procedure)
+-- Trade.ProviderMarginMarkupByInstrument (table) - MERGE target
+-- Trade.Tv_ProviderMarginMarkupByInstrument (TVP type) - input type
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderMarginMarkupByInstrument | Table | MERGE target: insert/update markup percentage per InstrumentID+ProviderID. |
| Trade.Tv_ProviderMarginMarkupByInstrument | User Defined Table Type | Input TVP schema definition. |

### 6.2 Objects That Depend On This

Not analyzed.

---

## 7. Technical Details

### 7.1 Comparison with UpsertFuturesInstrumentRiskSettings

| Aspect | UpsertFuturesInstrumentRiskSettings | UpsertProviderMarginMarkupByInstrument |
|--------|-------------------------------------|----------------------------------------|
| Match key | InstrumentID | InstrumentID + ProviderID |
| Update behavior | Null-safe (preserves existing if null) | Overwrite (always updates) |
| Insert default | 2.00% if null | No default - value must be provided |
| Column count | 2 (SL buffer, TP buffer) | 1 (MarkupPercentage) |

---

## 8. Sample Queries

### 8.1 Upsert markup for provider-instrument pairs

```sql
DECLARE @Markups Trade.Tv_ProviderMarginMarkupByInstrument
INSERT INTO @Markups VALUES (1001, 42, 0.5)   -- InstrumentID=1001, ProviderID=42, Markup=0.5%
INSERT INTO @Markups VALUES (1002, 42, 1.0)   -- Different instrument, same provider
EXEC Trade.UpsertProviderMarginMarkupByInstrument @Markups
```

### 8.2 Check current markups for a provider

```sql
SELECT InstrumentID, ProviderID, MarkupPercentage
FROM Trade.ProviderMarginMarkupByInstrument WITH (NOLOCK)
WHERE ProviderID = 42
ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpsertProviderMarginMarkupByInstrument | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpsertProviderMarginMarkupByInstrument.sql*

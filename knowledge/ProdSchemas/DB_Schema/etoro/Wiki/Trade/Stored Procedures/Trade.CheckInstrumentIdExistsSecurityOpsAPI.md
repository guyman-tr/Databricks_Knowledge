# Trade.CheckInstrumentIdExistsSecurityOpsAPI

> Returns existence flags (BIT) for a given InstrumentID across six key tables: InstrumentImages, SplitRatio, LiquidityProviderContracts, Instrument, Currency, and InstrumentMetaData.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CheckInstrumentIdExistsSecurityOpsAPI is a lookup procedure used by the Security Operations API to verify whether an instrument has data in the required reference tables before performing operations. It provides a quick "does this instrument exist in the system?" check across six dimensions.

This procedure exists because the SecurityOps API needs to validate instrument data completeness before allowing instrument-related operations. Rather than making six separate queries, this procedure returns all flags in a single result set. The checks include: instrument images (for UI display), split ratio history, liquidity provider contracts (for hedging), the core instrument record, currency mapping, and metadata.

---

## 2. Business Logic

### 2.1 Multi-Table Existence Check

**What**: Returns BIT flags for instrument presence across six tables.

**Columns/Parameters Involved**: `@InstrumentID`

**Rules**:
- IsInstrumentImagesExists: Trade.InstrumentImages has a row for this InstrumentID
- IsSplitRatioExists: History.SplitRatio has a row (instrument has had stock splits)
- IsLiquidityProviderContractsExists: Trade.LiquidityProviderContracts has a row (hedging configured)
- IsInstrumentExists: Trade.Instrument has the core record
- IsCurrencyExists: Dictionary.Currency has a matching CurrencyID (note: uses @InstrumentID as CurrencyID, applicable when instrument IS a currency pair)
- IsInstrumentMetaDataExists: Trade.InstrumentMetaData has metadata

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument ID to check across all six tables. Also used as CurrencyID for the currency check. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | IsInstrumentImagesExists | BIT | NO | - | CODE-BACKED | 1 if Trade.InstrumentImages has data for this instrument, 0 otherwise. |
| 3 | IsSplitRatioExists | BIT | NO | - | CODE-BACKED | 1 if History.SplitRatio has stock split records for this instrument. |
| 4 | IsLiquidityProviderContractsExists | BIT | NO | - | CODE-BACKED | 1 if Trade.LiquidityProviderContracts has hedging contracts configured. |
| 5 | IsInstrumentExists | BIT | NO | - | CODE-BACKED | 1 if Trade.Instrument has the core instrument record. |
| 6 | IsCurrencyExists | BIT | NO | - | CODE-BACKED | 1 if Dictionary.Currency has a matching CurrencyID. |
| 7 | IsInstrumentMetaDataExists | BIT | NO | - | CODE-BACKED | 1 if Trade.InstrumentMetaData has metadata for this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.InstrumentImages | EXISTS check | Image data existence |
| @InstrumentID | History.SplitRatio | EXISTS check | Split history existence |
| @InstrumentID | Trade.LiquidityProviderContracts | EXISTS check | Hedging contract existence |
| @InstrumentID | Trade.Instrument | EXISTS check | Core instrument existence |
| @InstrumentID | Dictionary.Currency | EXISTS check | Currency record existence |
| @InstrumentID | Trade.InstrumentMetaData | EXISTS check | Metadata existence |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SecurityOps API | (external) | EXEC | Called for instrument validation before operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CheckInstrumentIdExistsSecurityOpsAPI (procedure)
+-- Trade.InstrumentImages (table)
+-- History.SplitRatio (table)
+-- Trade.LiquidityProviderContracts (table)
+-- Trade.Instrument (table)
+-- Dictionary.Currency (table)
+-- Trade.InstrumentMetaData (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentImages | Table | EXISTS check |
| History.SplitRatio | Table | EXISTS check |
| Trade.LiquidityProviderContracts | Table | EXISTS check |
| Trade.Instrument | Table | EXISTS check |
| Dictionary.Currency | Table | EXISTS check |
| Trade.InstrumentMetaData | Table | EXISTS check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SecurityOps API | External | Instrument validation endpoint |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check instrument completeness

```sql
EXEC Trade.CheckInstrumentIdExistsSecurityOpsAPI @InstrumentID = 1001;
```

### 8.2 Find instruments missing images

```sql
SELECT I.InstrumentID
FROM   Trade.Instrument I WITH (NOLOCK)
       LEFT JOIN Trade.InstrumentImages II WITH (NOLOCK) ON I.InstrumentID = II.InstrumentID
WHERE  II.InstrumentID IS NULL;
```

### 8.3 Check all six tables for a specific instrument

```sql
SELECT 'InstrumentImages' AS Source, COUNT(*) AS Cnt FROM Trade.InstrumentImages WITH (NOLOCK) WHERE InstrumentID = @InstrumentID
UNION ALL
SELECT 'SplitRatio', COUNT(*) FROM History.SplitRatio WITH (NOLOCK) WHERE InstrumentID = @InstrumentID
UNION ALL
SELECT 'LPContracts', COUNT(*) FROM Trade.LiquidityProviderContracts WITH (NOLOCK) WHERE InstrumentID = @InstrumentID
UNION ALL
SELECT 'Instrument', COUNT(*) FROM Trade.Instrument WITH (NOLOCK) WHERE InstrumentID = @InstrumentID
UNION ALL
SELECT 'Currency', COUNT(*) FROM Dictionary.Currency WITH (NOLOCK) WHERE CurrencyID = @InstrumentID
UNION ALL
SELECT 'MetaData', COUNT(*) FROM Trade.InstrumentMetaData WITH (NOLOCK) WHERE InstrumentID = @InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CheckInstrumentIdExistsSecurityOpsAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CheckInstrumentIdExistsSecurityOpsAPI.sql*

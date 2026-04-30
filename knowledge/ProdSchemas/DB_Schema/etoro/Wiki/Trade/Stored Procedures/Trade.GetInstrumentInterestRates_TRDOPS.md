# Trade.GetInstrumentInterestRates_TRDOPS

> Bulk variant of Trade.GetInstrumentInterestRates for TradingOps - resolves interest rates for multiple instruments with validation and NULL checking.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID (result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the TradingOps variant of Trade.GetInstrumentInterestRates, designed for bulk operations. It accepts a table-valued parameter (TVP) of instrument IDs, validates that all instruments exist in Trade.ProviderToInstrument, resolves their interest rates via the same currency-based lookup chain, and validates that no NULL values exist in the result set before returning.

The procedure exists to support TradingOps admin tools that need to view/modify interest rates for multiple instruments at once. Unlike the single-instrument version, this variant includes strict validation: it raises error 60127 if any instrument ID is invalid, and raises a custom error if any result column is NULL (indicating incomplete rate configuration).

Data flow: caller passes @instrumentid_list TVP. The SP first validates all IDs exist in ProviderToInstrument (raises 60127 if any are missing). Then creates #GetInstrument temp table from Trade.GetInstrument joined to the input list. Resolves rates via Dictionary.Currency + Dictionary.InterestRate into #Results. Validates no NULLs in results (raises error if any found). Returns #Results.

---

## 2. Business Logic

### 2.1 Input Validation - Instrument Existence

**What**: Ensures all requested instruments exist in the provider configuration.

**Columns/Parameters Involved**: `@instrumentid_list`, `Trade.ProviderToInstrument`

**Rules**:
- LEFT JOIN input list to ProviderToInstrument; if any PTI.InstrumentID IS NULL, the instrument doesn't exist
- Raises error 60127: "One or more InstrumentIDs were not found in the Trade.ProviderToInstrument"
- Returns immediately without processing if validation fails

### 2.2 Output Validation - NULL Check

**What**: Ensures the resolved interest rate configuration is complete for all instruments.

**Columns/Parameters Involved**: All output columns

**Rules**:
- After resolving rates, checks ALL 12 output columns for NULL values
- If ANY row has ANY NULL column, raises: "One or more columns contain NULL values in the result set"
- This prevents incomplete rate data from reaching admin tools
- NULL check covers: InstrumentID, InterestRateID, InterestRateName, InterestRate, UpdatedByUser, InstrumentTypeID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell, OverNightFeePatternID, SettlementTypeID

### 2.3 Interest Rate Resolution Chain

**What**: Same resolution as Trade.GetInstrumentInterestRates but for multiple instruments.

**Rules**:
- Same chain: Instrument -> SellCurrencyID -> Dictionary.Currency.InterestRateID -> Dictionary.InterestRate
- Uses temp tables (#GetInstrument, #Results) for multi-instrument processing

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentid_list | Trade.InstrumentIDsTbl (TVP) | NO (READONLY) | - | CODE-BACKED | Table-valued parameter containing instrument IDs. Uses Trade.InstrumentIDsTbl type. |
| 2 | InstrumentID (output) | INT | NO | - | CODE-BACKED | Instrument identifier. Validated to exist in ProviderToInstrument. |
| 3 | InterestRateID (output) | INT | NO | -1 | CODE-BACKED | Interest rate definition ID. Defaults to -1 via ISNULL. FK to Dictionary.InterestRate. |
| 4 | InterestRateName (output) | VARCHAR | NO | - | CODE-BACKED | Human-readable rate name. Validated not NULL. |
| 5 | InterestRate (output) | DECIMAL | NO | - | CODE-BACKED | Base interest rate. Validated not NULL. |
| 6 | InstrumentTypeID (output) | INT | NO | - | CODE-BACKED | Asset class. Validated not NULL. |
| 7 | InterestRateBuy (output) | DECIMAL | NO | - | CODE-BACKED | Buy/Long overnight fee rate. Validated not NULL. |
| 8 | InterestRateSell (output) | DECIMAL | NO | - | CODE-BACKED | Sell/Short overnight fee rate. Validated not NULL. |
| 9 | MarkupBuy (output) | DECIMAL | NO | - | CODE-BACKED | eToro markup on buy rate. Validated not NULL. |
| 10 | MarkupSell (output) | DECIMAL | NO | - | CODE-BACKED | eToro markup on sell rate. Validated not NULL. |
| 11 | UpdatedByUser (output) | VARCHAR | NO | - | CODE-BACKED | Last user who updated. Validated not NULL. |
| 12 | OverNightFeePatternID (output) | INT | NO | - | CODE-BACKED | Fee pattern (e.g., triple Wednesday). Validated not NULL. |
| 13 | SettlementTypeID (output) | TINYINT | NO | - | CODE-BACKED | Settlement type this rate applies to. Validated not NULL. See [Settlement Type](../../_glossary.md#settlement-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instrumentid_list | Trade.ProviderToInstrument | LEFT JOIN (validation) | Validates all input instruments exist |
| (body) | Trade.GetInstrument | SELECT INTO (JOIN) | Instrument data for rate resolution |
| (body) | Dictionary.Currency | LEFT JOIN | Maps SellCurrencyID to InterestRateID |
| (body) | Dictionary.InterestRate | LEFT JOIN | Rate definition matching InstrumentTypeID + InterestRateID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentInterestRates_TRDOPS (procedure)
+-- Trade.GetInstrument (view)
+-- Trade.ProviderToInstrument (table)
+-- Dictionary.Currency (table)
+-- Dictionary.InterestRate (table)
+-- Trade.InstrumentIDsTbl (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrument | View | SELECT INTO - provides instrument type and currencies |
| Trade.ProviderToInstrument | Table | LEFT JOIN - validates instrument existence |
| Dictionary.Currency | Table | LEFT JOIN - resolves SellCurrencyID to InterestRateID |
| Dictionary.InterestRate | Table | LEFT JOIN - provides rate definition |
| Trade.InstrumentIDsTbl | User Defined Type | TVP parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Error handling:
- RAISERROR(60127, 16, 1): raised when input instruments don't exist in ProviderToInstrument
- RAISERROR('One or more columns contain NULL values', 16, 1): raised when results have incomplete rate data

---

## 8. Sample Queries

### 8.1 Execute with TVP

```sql
DECLARE @Ids Trade.InstrumentIDsTbl;
INSERT INTO @Ids (InstrumentID) VALUES (1001), (1002), (1003);
EXEC Trade.GetInstrumentInterestRates_TRDOPS @instrumentid_list = @Ids;
```

### 8.2 Compare single and bulk results

```sql
EXEC Trade.GetInstrumentInterestRates @InstrumentID = 1001;

DECLARE @Ids Trade.InstrumentIDsTbl;
INSERT INTO @Ids (InstrumentID) VALUES (1001);
EXEC Trade.GetInstrumentInterestRates_TRDOPS @instrumentid_list = @Ids;
```

### 8.3 Check for instruments with incomplete rate config

```sql
SELECT  gi.InstrumentID, gi.InstrumentTypeID, gi.SellCurrencyID,
        c.InterestRateID, ir.InterestRateName
FROM    Trade.GetInstrument gi WITH (NOLOCK)
LEFT JOIN Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyID = gi.SellCurrencyID
LEFT JOIN Dictionary.InterestRate ir WITH (NOLOCK)
        ON ir.InstrumentTypeID = gi.InstrumentTypeID
        AND ir.InterestRateID = c.InterestRateID
WHERE   ir.InterestRateID IS NULL
AND     gi.InstrumentID > 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentInterestRates_TRDOPS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentInterestRates_TRDOPS.sql*

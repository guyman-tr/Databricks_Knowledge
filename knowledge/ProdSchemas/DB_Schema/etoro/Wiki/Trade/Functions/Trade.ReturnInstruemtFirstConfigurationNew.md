# Trade.ReturnInstruemtFirstConfigurationNew

> Extended version of the instrument configuration reconstruction function that includes futures-specific parameters (Multiplier, MinimalTick, expiration dates, settlement method) in addition to all standard instrument creation parameters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns VARCHAR(8000) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ReturnInstruemtFirstConfigurationNew is an extended version of Trade.ReturnInstruemtFirstConfiguration. It performs the same task - reconstructing the original EXEC Trade.InsertInstrumentRealTable command from XML parameter history - but includes additional futures/derivatives-specific parameters that were added after the original function was created.

The function exists because when futures instruments were added to the eToro platform, the instrument creation procedure gained new parameters (IsFuture, Multiplier, MinimalTick, LastTradingDateTime, ExpirationDateTime, SettlementTime, IndexPointValue, StopLossMarginInAssetCurrency, InitialMarginInAssetCurrency, CFICode, SettlementMethod, UnitOfMeasure) that the original function did not extract. Rather than modifying the original, this "New" version was created to handle the expanded parameter set.

Like its predecessor, it reads from History.InstrumentInsertParameters (cross-schema, History schema) and produces a VARCHAR(8000) concatenated command string. Note: the same typo in the name persists ("Instruemt").

---

## 2. Business Logic

### 2.1 XML Parameter Extraction (Extended)

**What**: Parses XML containing all instrument configuration parameters including futures-specific fields.

**Columns/Parameters Involved**: `@Instrument_ID1`, `ParametersValues` (XML)

**Rules**:
- Same core logic as Trade.ReturnInstruemtFirstConfiguration
- Adds 12 futures-specific parameters extracted from the same XML: IsFuture, Multiplier, MinimalTick, LastTradingDateTime, ExpirationDateTime, SettlementTime, IndexPointValue, StopLossMarginInAssetCurrency, InitialMarginInAssetCurrency, CFICode, SettlementMethod, UnitOfMeasure
- Note: Several futures parameters (LastTradingDateTime, ExpirationDateTime, SettlementTime, IndexPointValue, StopLossMarginInAssetCurrency, InitialMarginInAssetCurrency, CFICode, SettlementMethod, UnitOfMeasure) all reference `(Root/VolatilityRateInPips/@Value)` in the XML path - this appears to be a copy-paste bug where the XPath was not updated for each new parameter

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Instrument_ID1 | INT | NO | - | CODE-BACKED | The InstrumentID to look up in History.InstrumentInsertParameters. Retrieves the most recent XML parameter snapshot for this instrument. |
| 2 | Return value | VARCHAR(8000) | YES | - | CODE-BACKED | A complete EXEC Trade.InsertInstrumentRealTable command string including all standard and futures-specific parameters. Concatenation of two VARCHAR(8000) variables allows up to ~16000 characters. NULL if no history exists. Note: futures parameter values may be incorrect due to XPath bug (all read from VolatilityRateInPips node). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Instrument_ID1 | History.InstrumentInsertParameters | SELECT (WHERE) | Reads the XML parameter snapshot, TOP 1 ordered by InsertDate DESC |

### 5.2 Referenced By (other objects point to this)

No consumers found in the codebase. This is a diagnostic/ad-hoc utility function.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReturnInstruemtFirstConfigurationNew (function)
  +-- History.InstrumentInsertParameters (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.InstrumentInsertParameters | Table | SELECT TOP 1 ParametersValues WHERE InstrumentID = @Instrument_ID1 ORDER BY InsertDate DESC |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get configuration for a futures instrument
```sql
SELECT Trade.ReturnInstruemtFirstConfigurationNew(5001) AS FuturesConfig
```

### 8.2 Compare old vs new function output
```sql
SELECT I.InstrumentID,
       Trade.ReturnInstruemtFirstConfiguration(I.InstrumentID) AS OldConfig,
       Trade.ReturnInstruemtFirstConfigurationNew(I.InstrumentID) AS NewConfig
FROM   Trade.Instrument I WITH (NOLOCK)
WHERE  I.InstrumentID = 1001
```

### 8.3 Find instruments with history records
```sql
SELECT DISTINCT HIP.InstrumentID,
       I.DisplayName,
       I.InstrumentTypeID
FROM   History.InstrumentInsertParameters HIP WITH (NOLOCK)
JOIN   Trade.Instrument I WITH (NOLOCK) ON HIP.InstrumentID = I.InstrumentID
ORDER BY HIP.InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReturnInstruemtFirstConfigurationNew | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.ReturnInstruemtFirstConfigurationNew.sql*

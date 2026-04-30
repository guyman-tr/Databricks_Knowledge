# History.InstrumentInsertParameters

> Audit log storing the full XML configuration snapshot used when each instrument was created, capturing all initial parameters passed to the instrument insertion pipeline.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (CLUSTERED, NOT a PK - multiple rows per instrument possible) |
| **Partition** | No |
| **Indexes** | 1 (CLUSTERED on InstrumentID) |

---

## 1. Business Meaning

History.InstrumentInsertParameters is a standalone audit log (NOT a SQL Server temporal history table) that records the complete set of parameters used when each instrument was initially created in the trading system. Each row stores the full XML configuration document (ParametersValues) plus the timestamp when the instrument was inserted.

When a new trading instrument is onboarded, a comprehensive XML document is submitted to the instrument creation pipeline containing all configuration attributes: instrument name, currency IDs, margin requirements, fee structure, exchange, leverage limits, ticker symbols, provider tickers, and dozens of other parameters. This table persists that XML snapshot for audit and troubleshooting purposes - allowing operations teams to reconstruct exactly how an instrument was configured at creation time.

The computed column InstrumentCMDNew invokes `Trade.ReturnInstruemtFirstConfigurationNew(InstrumentID)` to re-derive the current configuration command from live data, providing a point-in-time comparison against the original ParametersValues XML.

5,698 rows representing instruments created over time. The table is on the [DICTIONARY] filegroup, consistent with instrument reference/configuration data.

---

## 2. Business Logic

### 2.1 Instrument Creation XML Schema

**What**: The ParametersValues XML encodes all parameters required to create a new instrument in the eToro trading system.

**Columns/Parameters Involved**: `ParametersValues`, `InstrumentID`

**Rules**:
- Root element `<Root>` contains individual `<FieldName Value="..."/>` child elements
- Key XML attributes observed: Name, ISINCode, UnitMargin, InstrumentID, BuyCurrencyID, SellCurrencyID, CopyMainpropertiesFromInstrument (source instrument for default settings), SymbolFull, Abbreviation, DisplayName, ExchangeID, IsMajor, IsRealAsset, CurrencyTypeID, PipDifferenceThreshold, MaxPositionUnits, Precision, MinOrderSizeForExecutionInEToroUnits, HBCDealSizeThresholdAlertInEToroUnits, HBCMaxDealSizeThresholdRejectInEToroUnits, ManualMaxDealSizeInEToroUnits, InstrumentTypeID, fee schedule columns (NonLeveraged/Leveraged Buy/Sell EndOfWeek/OverNight fees), isvalid, PriceSourceID, ShardID, Cusip, ProviderTicker_1 through ProviderTicker_10, VisibleInternallyOnly, MarketRangeValidationType, MarketRangePercentage, VolatilityThresholdTypeID, VolatilityRatePercentage, IsFuture, CFICodeas, DifferenceThresholdType, PercentageDifferenceThreshold
- NULL values in the source are stored as the string "NULL" within attribute values

### 2.2 Computed Configuration Comparison

**What**: InstrumentCMDNew is a computed column that invokes `Trade.ReturnInstruemtFirstConfigurationNew(InstrumentID)` to re-derive the current configuration command from live instrument data.

**Columns/Parameters Involved**: `InstrumentCMDNew`, `InstrumentID`

**Rules**:
- This column is computed at query time (not persisted)
- Enables comparison between the original XML (ParametersValues) and the current configuration (InstrumentCMDNew)
- Useful for detecting configuration drift - instruments whose current settings diverge from how they were initially created

---

## 3. Data Overview

5,698 rows. Table is populated by the instrument creation pipeline.

| InstrumentID | Sample ParametersValues (key fields) | InsertDate | Meaning |
|-------------|--------------------------------------|-----------|---------|
| 797 | Name=USD/ISK, CurrencyTypeID=1, ExchangeID=1, IsMajor=0, IsRealAsset=0, VisibleInternallyOnly=1 | 2026-02-05 | Dormant CFD instrument 797 created as an FX pair. VisibleInternallyOnly=1 means not shown to customers. CopyMainpropertiesFromInstrument=460 means default fees/settings were copied from instrument 460. |
| 794 | Name=Dormant CFD794, CurrencyTypeID=4, ExchangeID=3, IsMajor=0, IsRealAsset=0 | 2026-02-05 | A dormant index-type CFD instrument (CurrencyTypeID=4=Index). Not visible to customers. Used as a placeholder or template. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | YES | - | VERIFIED | Identifier of the instrument that was created. CLUSTERED INDEX key. Not declared NOT NULL (nullable). FK to Trade.Instrument (implicit). |
| 2 | ParametersValues | xml | YES | - | VERIFIED | Full XML document containing all configuration parameters submitted at instrument creation. Root element `<Root>` with child nodes per attribute (e.g., `<Name Value="EUR/USD"/>`). Includes fee schedules, margin parameters, provider tickers, exchange assignment, leverage limits, and instrument classification. See Section 2.1 for full attribute inventory. |
| 3 | InsertDate | datetime | YES | getutcdate() | VERIFIED | UTC timestamp when this audit row was inserted. DEFAULT getutcdate() captures the creation time automatically. |
| 4 | InstrumentCMDNew | computed AS Trade.ReturnInstruemtFirstConfigurationNew(InstrumentID) | - | - | VERIFIED | Computed (non-persisted) column. Re-derives the current instrument creation command from live data by invoking Trade.ReturnInstruemtFirstConfigurationNew. Enables real-time comparison against the original ParametersValues to detect configuration drift. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | The instrument whose creation parameters are logged. |
| InstrumentCMDNew | Trade.ReturnInstruemtFirstConfigurationNew | Computed column dependency | Function invoked to re-derive the configuration command at query time. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.InstrumentInsertParameters (table)
  - Trade.ReturnInstruemtFirstConfigurationNew (function) [via computed column]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ReturnInstruemtFirstConfigurationNew | Function | Called in computed column InstrumentCMDNew |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX | CLUSTERED | InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| df_Insertdate | DEFAULT | InsertDate = getutcdate() - auto-timestamps when the audit row is created |
| Filegroup [DICTIONARY] | Storage option | Both data and LOB (TEXTIMAGE) on the DICTIONARY filegroup |

---

## 8. Sample Queries

### 8.1 View the creation parameters for a specific instrument
```sql
SELECT InstrumentID, ParametersValues, InsertDate
FROM History.InstrumentInsertParameters WITH (NOLOCK)
WHERE InstrumentID = 1014;
```

### 8.2 Extract specific fields from the creation XML
```sql
SELECT InstrumentID, InsertDate,
       ParametersValues.value('(/Root/DisplayName/@Value)[1]', 'varchar(100)') AS DisplayName,
       ParametersValues.value('(/Root/ExchangeID/@Value)[1]', 'int') AS ExchangeID,
       ParametersValues.value('(/Root/CurrencyTypeID/@Value)[1]', 'int') AS CurrencyTypeID,
       ParametersValues.value('(/Root/UnitMargin/@Value)[1]', 'decimal(10,4)') AS UnitMargin
FROM History.InstrumentInsertParameters WITH (NOLOCK)
WHERE InstrumentID = 797;
```

### 8.3 Compare original creation params with current configuration
```sql
SELECT InstrumentID, InsertDate,
       ParametersValues.value('(/Root/DisplayName/@Value)[1]', 'varchar(100)') AS OriginalDisplayName,
       InstrumentCMDNew AS CurrentConfig
FROM History.InstrumentInsertParameters WITH (NOLOCK)
WHERE InstrumentID = 797;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InstrumentInsertParameters | Type: Table | Source: etoro/etoro/History/Tables/History.InstrumentInsertParameters.sql*

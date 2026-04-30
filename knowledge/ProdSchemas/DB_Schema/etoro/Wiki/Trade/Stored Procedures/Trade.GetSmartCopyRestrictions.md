# Trade.GetSmartCopyRestrictions

> Returns all copy-trade settlement restrictions with fully resolved dimension names (country, regulation, instrument type, exchange, instrument, unblock reason, restriction type). No parameters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary read endpoint for the **Smart Copy Restrictions** configuration. It reads every row from `Trade.CopyTradeSettlementRestrictions` - the table that defines which copy-trade settlement operations are blocked or permitted per country, regulation, instrument type, exchange, instrument, and instrument group - and resolves all foreign key IDs to human-readable names.

The output is used by trading operations, compliance, and risk management teams to review the full restriction matrix. It answers: "What copy-trade restrictions are currently active and what do they mean in plain terms?"

**Differences from `Trade.GetSmartCopyRestrictions_TRDOPS`**: This version excludes `AccountTypeID` / `AccountType` from the output. The `_TRDOPS` variant is the extended version for the trading operations team, which also shows the account type dimension.

**Restriction semantics** (`RestrictionTypeID` from `Dictionary.RestrictionType`):
- Values 2 and 3 dominate the data (~19,000 of ~20,000 rows). The restriction type determines whether the row represents a block or an allow-override.

**LEFT JOINs vs INNER JOIN**: All dimension lookups use LEFT JOIN (except `Dictionary.RestrictionType` which uses INNER JOIN). This means restrictions where CountryID, RegulationID, ExchangeID, InstrumentID, GroupID, or UnblockReasonId are NULL will still appear in the output (with NULL for the name columns). The INNER JOIN on Dictionary.RestrictionType means restrictions with unknown RestrictionTypeID are excluded.

---

## 2. Business Logic

### 2.1 Fully Enriched Restriction Readout

**What**: Resolves all IDs in CopyTradeSettlementRestrictions to human-readable names in a single query.

**Columns/Parameters Involved**: All columns from Trade.CopyTradeSettlementRestrictions, plus 8 name columns from Dictionary lookups

**Rules**:
- Source: `Trade.CopyTradeSettlementRestrictions WITH(NOLOCK)` -> no transaction isolation concerns for read-only display
- INNER JOIN `Dictionary.RestrictionType` -> filters out any rows with unknown RestrictionTypeID
- LEFT JOIN 6 dictionaries: Country, Regulation, CurrencyType (as InstrumentType), ExchangeInfo, InstrumentMetaData, BlockUnBlockReason, TradingInstrumentGroups
- No WHERE clause -> returns ALL restrictions
- No ORDER BY -> caller controls sorting

**Dimension resolution**:
```
InstrumentID         -> Trade.InstrumentMetaData.SymbolFull
GroupID              -> Dictionary.TradingInstrumentGroups.GroupName
InstrumentTypeID     -> Dictionary.CurrencyType.Name (as InstrumentType)
ExchangeID           -> Dictionary.ExchangeInfo.ExchangeDescription (as Exchange)
RestrictionTypeID    -> Dictionary.RestrictionType.RestrictionTypeName (INNER JOIN)
UnblockReasonId      -> Dictionary.BlockUnBlockReason.Reason (as RemovableByReason)
CountryID            -> Dictionary.Country.Name (as Country)
RegulationID         -> Dictionary.Regulation.Name (as Regulation)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | YES | - | CODE-BACKED | Specific instrument this restriction targets. NULL if restriction applies to all instruments in the group/type/exchange. FK to Trade.InstrumentMetaData. |
| 2 | SymbolFull | VARCHAR | YES | - | CODE-BACKED | Full symbol name of the instrument (e.g., "AAPL", "EURUSD"). From Trade.InstrumentMetaData. NULL if InstrumentID is NULL. |
| 3 | GroupID | INT | YES | - | CODE-BACKED | Instrument group this restriction targets. NULL if not group-scoped. FK to Dictionary.TradingInstrumentGroups. |
| 4 | GroupName | VARCHAR | YES | - | CODE-BACKED | Name of the instrument group. From Dictionary.TradingInstrumentGroups. NULL if GroupID is NULL. |
| 5 | InstrumentTypeID | INT | YES | - | CODE-BACKED | Instrument type this restriction targets (e.g., 5=Crypto, 6=ETFs, 10=Stocks). NULL if not type-scoped. FK to Dictionary.CurrencyType (same ID space). |
| 6 | InstrumentType | VARCHAR | YES | - | CODE-BACKED | Human-readable instrument type name (e.g., "Crypto", "ETFs"). From Dictionary.CurrencyType.Name. |
| 7 | ExchangeID | INT | YES | - | CODE-BACKED | Exchange this restriction targets. NULL if not exchange-scoped. FK to Dictionary.ExchangeInfo. |
| 8 | Exchange | VARCHAR | YES | - | CODE-BACKED | Exchange description (e.g., "NASDAQ", "NYSE"). From Dictionary.ExchangeInfo.ExchangeDescription. |
| 9 | RestrictionTypeID | INT | NO | - | CODE-BACKED | Type of restriction (block vs allow-override). INNER JOIN ensures only known types returned. FK to Dictionary.RestrictionType. Values: 0, 1, 2, 3 observed in live data; 2 and 3 dominate (~90%). |
| 10 | RestrictionType | VARCHAR | NO | - | CODE-BACKED | Human-readable restriction type name. From Dictionary.RestrictionType.RestrictionTypeName. |
| 11 | UnblockReasonId | INT | YES | - | CODE-BACKED | Reason that can override/remove this restriction. NULL if no override path. FK to Dictionary.BlockUnBlockReason. |
| 12 | RemovableByReason | VARCHAR | YES | - | CODE-BACKED | Human-readable unblock reason name. From Dictionary.BlockUnBlockReason.Reason. |
| 13 | CountryID | INT | YES | - | CODE-BACKED | Country this restriction targets. NULL if not country-scoped. FK to Dictionary.Country. |
| 14 | Country | VARCHAR | YES | - | CODE-BACKED | Country name. From Dictionary.Country.Name. |
| 15 | RegulationID | INT | YES | - | CODE-BACKED | Regulatory framework this restriction applies to. NULL if applies across regulations. FK to Dictionary.Regulation. |
| 16 | Regulation | VARCHAR | YES | - | CODE-BACKED | Regulation name (e.g., "ESMA", "FCA", "ASIC"). From Dictionary.Regulation.Name. |
| 17 | RegistrationDate | DATE/DATETIME | YES | - | CODE-BACKED | When this restriction becomes effective. Supports time-bounded restrictions. From Trade.CopyTradeSettlementRestrictions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All restriction columns | Trade.CopyTradeSettlementRestrictions | Reader | Primary source; NOLOCK; all rows returned |
| InstrumentID/SymbolFull | Trade.InstrumentMetaData | Reader (LEFT JOIN) | Resolves instrument symbol |
| GroupID/GroupName | Dictionary.TradingInstrumentGroups | Reader (LEFT JOIN, cross-schema) | Resolves group name |
| InstrumentTypeID/InstrumentType | Dictionary.CurrencyType | Reader (LEFT JOIN, cross-schema) | Resolves instrument type name |
| ExchangeID/Exchange | Dictionary.ExchangeInfo | Reader (LEFT JOIN, cross-schema) | Resolves exchange description |
| RestrictionTypeID/RestrictionType | Dictionary.RestrictionType | Reader (INNER JOIN, cross-schema) | Resolves restriction type name; excludes unknown types |
| UnblockReasonId/RemovableByReason | Dictionary.BlockUnBlockReason | Reader (LEFT JOIN, cross-schema) | Resolves unblock reason |
| CountryID/Country | Dictionary.Country | Reader (LEFT JOIN, cross-schema) | Resolves country name |
| RegulationID/Regulation | Dictionary.Regulation | Reader (LEFT JOIN, cross-schema) | Resolves regulation name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading ops / compliance tooling | (none) | Application call | Review of full copy-trade restriction matrix |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetSmartCopyRestrictions (procedure)
+-- Trade.CopyTradeSettlementRestrictions (table)
+-- Trade.InstrumentMetaData (table)
+-- Dictionary.Country (cross-schema)
+-- Dictionary.Regulation (cross-schema)
+-- Dictionary.CurrencyType (cross-schema)
+-- Dictionary.ExchangeInfo (cross-schema)
+-- Dictionary.RestrictionType (cross-schema)
+-- Dictionary.BlockUnBlockReason (cross-schema)
+-- Dictionary.TradingInstrumentGroups (cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CopyTradeSettlementRestrictions | Table | Source of all restriction rows; NOLOCK |
| Trade.InstrumentMetaData | Table | LEFT JOIN for SymbolFull |
| Dictionary.Country | Table (Dictionary schema) | LEFT JOIN for Country name |
| Dictionary.Regulation | Table (Dictionary schema) | LEFT JOIN for Regulation name |
| Dictionary.CurrencyType | Table (Dictionary schema) | LEFT JOIN for InstrumentType name (CurrencyTypeID = InstrumentTypeID) |
| Dictionary.ExchangeInfo | Table (Dictionary schema) | LEFT JOIN for Exchange description |
| Dictionary.RestrictionType | Table (Dictionary schema) | INNER JOIN for RestrictionType name |
| Dictionary.BlockUnBlockReason | Table (Dictionary schema) | LEFT JOIN for unblock reason name |
| Dictionary.TradingInstrumentGroups | Table (Dictionary schema) | LEFT JOIN for GroupName |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Compliance / ops tooling | External application | Full restriction matrix display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK on source tables | Isolation hint | READ UNCOMMITTED; acceptable for configuration display |
| INNER JOIN Dictionary.RestrictionType | Filter | Excludes rows with unknown RestrictionTypeID; ensures all returned rows have a valid type label |
| LEFT JOIN (all other lookups) | Design | NULL-safe: restrictions without a specific country/exchange/instrument still appear |
| No WHERE clause | Design | Returns complete restriction matrix; caller applies filtering |

---

## 8. Sample Queries

### 8.1 Get all copy-trade restrictions

```sql
EXEC Trade.GetSmartCopyRestrictions;
```

### 8.2 Filter results by country name

```sql
SELECT * FROM (
    EXEC Trade.GetSmartCopyRestrictions
) AS restrictions
WHERE Country = 'United States';
-- Note: wrap in a view or inline the query for filtering
```

### 8.3 Equivalent inline query

```sql
SELECT
    restriction.InstrumentID, imd.SymbolFull,
    restriction.GroupID, groups.GroupName,
    restriction.InstrumentTypeID, instrumentType.Name as InstrumentType,
    restriction.ExchangeID, exchangeInfo.ExchangeDescription AS Exchange,
    restriction.RestrictionTypeID, restrictionsNames.RestrictionTypeName AS RestrictionType,
    restriction.UnblockReasonId, reasons.Reason AS RemovableByReason,
    restriction.CountryID, country.Name AS Country,
    restriction.RegulationID, regulation.Name AS Regulation,
    restriction.RegistrationDate
FROM Trade.CopyTradeSettlementRestrictions restriction WITH(NOLOCK)
INNER JOIN Dictionary.RestrictionType restrictionsNames ON restriction.RestrictionTypeID = restrictionsNames.RestrictionTypeID
LEFT JOIN Dictionary.Country country WITH(NOLOCK) ON restriction.CountryID = country.CountryID
LEFT JOIN Dictionary.Regulation regulation WITH(NOLOCK) ON restriction.RegulationID = regulation.ID
LEFT JOIN Dictionary.CurrencyType instrumentType WITH(NOLOCK) ON restriction.InstrumentTypeID = instrumentType.CurrencyTypeID
LEFT JOIN Dictionary.ExchangeInfo exchangeInfo WITH(NOLOCK) ON restriction.ExchangeID = exchangeInfo.ExchangeID
LEFT JOIN Trade.InstrumentMetaData imd WITH(NOLOCK) ON restriction.InstrumentID = imd.InstrumentID
LEFT JOIN Dictionary.BlockUnBlockReason reasons ON restriction.UnblockReasonId = reasons.ID
LEFT JOIN Dictionary.TradingInstrumentGroups groups ON restriction.GroupID = groups.GroupID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetSmartCopyRestrictions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetSmartCopyRestrictions.sql*

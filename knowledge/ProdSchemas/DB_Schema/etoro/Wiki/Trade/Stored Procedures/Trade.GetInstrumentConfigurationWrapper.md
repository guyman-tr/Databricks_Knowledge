# Trade.GetInstrumentConfigurationWrapper

> Returns instrument configuration (precision, type, ticker, ISIN) for instruments on a specific liquidity provider, wrapping Trade.FunGetInstrumentConfiguration with ISIN enrichment.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID (result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns instrument configuration data for all instruments assigned to a specific liquidity provider (LP). It wraps the Trade.FunGetInstrumentConfiguration TVF and enriches its output with the ISINCode from Trade.InstrumentMetaData. ISIN codes are required for regulatory reporting and MiFID II compliance.

The procedure exists because the base function Trade.FunGetInstrumentConfiguration does not include ISIN codes. This wrapper adds the ISIN by joining to InstrumentMetaData, providing a single call for LP configuration + regulatory identifiers.

Data flow: caller passes @LPID (liquidity provider ID). The SP calls Trade.FunGetInstrumentConfiguration(@LPID) which returns instruments for that LP, then JOINs to Trade.InstrumentMetaData for ISINCode. Returns InstrumentID, Precision, InstrumentTypeID, Ticker, and ISINCode.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple function wrapper with ISIN enrichment. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LPID | INT | NO | - | CODE-BACKED | Liquidity Provider ID. Passed to Trade.FunGetInstrumentConfiguration to filter instruments. |
| 2 | InstrumentID (output) | INT | NO | - | CODE-BACKED | Financial instrument identifier. |
| 3 | Precision (output) | INT | - | - | CODE-BACKED | Decimal precision for rates. From Trade.FunGetInstrumentConfiguration. |
| 4 | InstrumentTypeID (output) | INT | - | - | CODE-BACKED | Asset class classification. From Trade.FunGetInstrumentConfiguration. |
| 5 | Ticker (output) | VARCHAR | - | - | CODE-BACKED | Instrument ticker symbol. From Trade.FunGetInstrumentConfiguration. |
| 6 | ISINCode (output) | VARCHAR | YES | - | CODE-BACKED | International Securities Identification Number. From Trade.InstrumentMetaData. Regulatory identifier for MiFID II. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.FunGetInstrumentConfiguration | FROM (function) | Source of instrument config for the given LP |
| (body) | Trade.InstrumentMetaData | JOIN | Source of ISINCode enrichment |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentConfigurationWrapper (procedure)
+-- Trade.FunGetInstrumentConfiguration (function)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FunGetInstrumentConfiguration | Function | FROM - returns instrument config for @LPID |
| Trade.InstrumentMetaData | Table | JOIN - provides ISINCode |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute for a liquidity provider

```sql
EXEC Trade.GetInstrumentConfigurationWrapper @LPID = 1;
```

### 8.2 Direct function call without ISIN

```sql
SELECT  * FROM Trade.FunGetInstrumentConfiguration(1);
```

### 8.3 Query with ISIN and instrument type name

```sql
SELECT  gic.InstrumentID, gic.Precision, gic.InstrumentTypeID,
        gic.Ticker, imd.ISINCode, it.InstrumentTypeName
FROM    Trade.FunGetInstrumentConfiguration(1) gic
JOIN    Trade.InstrumentMetaData imd WITH (NOLOCK) ON gic.InstrumentID = imd.InstrumentID
JOIN    Dictionary.InstrumentType it WITH (NOLOCK) ON gic.InstrumentTypeID = it.InstrumentTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentConfigurationWrapper | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentConfigurationWrapper.sql*

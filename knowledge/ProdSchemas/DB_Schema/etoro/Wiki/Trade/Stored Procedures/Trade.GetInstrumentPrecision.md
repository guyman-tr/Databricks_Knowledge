# Trade.GetInstrumentPrecision

> Returns the rate precision and above-dollar precision for every instrument from the primary provider configuration, enabling pip-to-rate conversions and price display formatting.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID + Precision + AboveDollarPrecision from Trade.ProviderToInstrument |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentPrecision is a parameterless bulk-read procedure that returns the decimal precision settings for ALL instruments from Trade.ProviderToInstrument. The `Precision` column defines how many decimal places an instrument's rate uses (e.g., 5 for EUR/USD = rates like 1.12345), while `AboveDollarPrecision` defines the number of significant digits above the decimal point for display formatting (relevant for high-pip-value instruments like JPY pairs).

This procedure exists because multiple services need instrument precision to convert between pips and rate values. A pip threshold of 10 pips on an instrument with Precision=5 translates to a rate delta of 10 / 10^5 = 0.00010. Without accurate precision, limit order execution, slippage calculations, and price display would use incorrect decimal scales.

The procedure is called by price services and limit execution rate services. In the application, the LimitExecutionRateService loads all precisions at startup via the instrument configuration repository and caches them in a Dictionary<int, int> for fast lookup during limit order threshold calculations. BI admins also have VIEW DEFINITION access for monitoring. (Source: trading-shared/Price.DomainServices)

---

## 2. Business Logic

### 2.1 Pip-to-Rate Conversion via Precision

**What**: Precision enables converting pip-based thresholds to rate-scale amounts for limit order execution.

**Columns/Parameters Involved**: `Precision`

**Rules**:
- Precision represents the number of decimal places in an instrument's rate (e.g., 5 for EURUSD, 3 for JPY crosses)
- Conversion formula: `rateAmount = pipThreshold / 10^Precision`
- Application caches all precisions at service startup for performance
- Used by LimitExecutionRateService.ConvertThresholdToRateScale() to determine if execution price exceeds the limit threshold

**Diagram**:
```
Instrument: EURUSD (Precision=5)
  Limit Rate:     1.12345
  Threshold:      10 pips
  Rate Threshold: 10 / 10^5 = 0.00010
  Buy limit cap:  1.12345 + 0.00010 = 1.12355

Instrument: EURJPY (Precision=3)
  Limit Rate:     130.123
  Threshold:      10 pips
  Rate Threshold: 10 / 10^3 = 0.010
  Buy limit cap:  130.123 + 0.010 = 130.133
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.ProviderToInstrument.InstrumentID | CODE-BACKED | The instrument identifier. FK to Trade.Instrument. Every instrument with a ProviderToInstrument row is returned. |
| R2 | Precision | int | Trade.ProviderToInstrument.Precision | VERIFIED | Number of decimal places in the instrument's rate. Used for pip-to-rate conversion: `rateAmount = pips / 10^Precision`. Application caches this in `Dictionary<int, int>` at startup for LimitExecutionRateService. (Source: trading-shared/Price.DomainServices/LimitExecutionRateService.cs) |
| R3 | AboveDollarPrecision | int | Trade.ProviderToInstrument.AboveDollarPrecision | CODE-BACKED | Number of significant digits above the decimal point for display formatting. Relevant for high-pip-value instruments (e.g., JPY pairs where AboveDollarPrecision=3). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.ProviderToInstrument | Read (SELECT) | Source table for all instrument precision data; reads entire table with NOLOCK |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| LimitExecutionRateService | GetInstrumentPrecisions() | Application consumer | Loads all precisions at startup; uses them for limit order threshold calculations (Source: trading-shared) |
| PROD\BIadmins | VIEW DEFINITION | Permission | BI admins can view procedure definition for monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentPrecision (procedure)
+-- Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | Read via SELECT - source of InstrumentID, Precision, AboveDollarPrecision |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.DomainServices.LimitExecutionRateService | Application service | Calls GetInstrumentPrecisions at initialization for limit order rate calculations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. The procedure performs no validation and returns all rows.

---

## 8. Sample Queries

### 8.1 Get all instrument precisions

```sql
EXEC Trade.GetInstrumentPrecision;
```

### 8.2 Find instruments with high precision (5+ decimal places)

```sql
SELECT  InstrumentID, Precision, AboveDollarPrecision
FROM    Trade.ProviderToInstrument WITH (NOLOCK)
WHERE   Precision >= 5
ORDER BY InstrumentID;
```

### 8.3 Verify precision values with instrument names

```sql
SELECT  PTI.InstrumentID,
        I.SymbolFull,
        PTI.Precision,
        PTI.AboveDollarPrecision
FROM    Trade.ProviderToInstrument PTI WITH (NOLOCK)
        INNER JOIN Trade.Instrument I WITH (NOLOCK) ON PTI.InstrumentID = I.InstrumentID
ORDER BY PTI.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repos / 3 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentPrecision | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentPrecision.sql*

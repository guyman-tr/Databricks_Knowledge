# Trade.GetInstrumentConfigurationsByPriceServerID

> Returns instrument configurations (precision, currencies) for all instruments assigned to a specific price server.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID (result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns core instrument configuration data for all instruments assigned to a specific price server. The price server is the infrastructure component that provides real-time price feeds. Each instrument is assigned to a price server, and this SP allows a price server to load its instrument list with the precision and currency pair needed for rate processing.

The procedure exists to support price server initialization. When a price server starts up, it needs to know which instruments it handles and their precision/currency configuration. The default @PriceServerID=100 likely represents the primary/default price server.

Data flow: caller passes @PriceServerID (defaults to 100). The SP joins Trade.Instrument with Trade.ProviderToInstrument on InstrumentID and filters by PriceServerID. Returns InstrumentID, Precision, BuyCurrencyID, and SellCurrencyID.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple filtered JOIN. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PriceServerID | INT | NO | 100 | CODE-BACKED | Price server to load instruments for. Default 100 (primary server). FK to price server infrastructure. |
| 2 | InstrumentID (output) | INT | NO | - | CODE-BACKED | Financial instrument identifier. |
| 3 | Precision (output) | INT | - | - | CODE-BACKED | Decimal precision for this instrument's rates (e.g., 2 for stocks, 5 for forex). From Trade.ProviderToInstrument. |
| 4 | BuyCurrencyID (output) | INT | - | - | CODE-BACKED | Base currency of the instrument pair (buy side). FK to Dictionary.Currency. From Trade.Instrument. |
| 5 | SellCurrencyID (output) | INT | - | - | CODE-BACKED | Quote currency of the instrument pair (sell side). FK to Dictionary.Currency. From Trade.Instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.Instrument | FROM | Source of BuyCurrencyID, SellCurrencyID, PriceServerID filter |
| (body) | Trade.ProviderToInstrument | JOIN | Source of Precision |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentConfigurationsByPriceServerID (procedure)
+-- Trade.Instrument (table)
+-- Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FROM - filtered by PriceServerID, provides currencies |
| Trade.ProviderToInstrument | Table | JOIN - provides Precision |

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

### 8.1 Execute for default price server

```sql
EXEC Trade.GetInstrumentConfigurationsByPriceServerID;
```

### 8.2 Execute for a specific price server

```sql
EXEC Trade.GetInstrumentConfigurationsByPriceServerID @PriceServerID = 200;
```

### 8.3 Join with currency names

```sql
SELECT  ti.InstrumentID, tpti.Precision,
        bc.CurrencyName AS BuyCurrency,
        sc.CurrencyName AS SellCurrency
FROM    Trade.Instrument ti WITH (NOLOCK)
JOIN    Trade.ProviderToInstrument tpti WITH (NOLOCK) ON ti.InstrumentID = tpti.InstrumentID
JOIN    Dictionary.Currency bc WITH (NOLOCK) ON ti.BuyCurrencyID = bc.CurrencyID
JOIN    Dictionary.Currency sc WITH (NOLOCK) ON ti.SellCurrencyID = sc.CurrencyID
WHERE   ti.PriceServerID = 100;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentConfigurationsByPriceServerID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentConfigurationsByPriceServerID.sql*

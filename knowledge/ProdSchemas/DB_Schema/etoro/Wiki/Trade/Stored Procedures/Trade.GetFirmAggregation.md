# Trade.GetFirmAggregation

> Returns firm-level buy/sell aggregation for Apex-linked customers on US exchanges (exchange IDs 4, 5), supporting reporting and exposure analysis.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Aggregation by CID, ApexAccountID, InstrumentID, Symbol |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure supports firm-level reporting for customers whose trading is linked to Apex (a clearing broker). It aggregates buy and sell activity across US exchanges (ExchangeID 4 and 5) for a given trade day. The output provides GrossNotionalValueOfBuy, NumberOfBuyShares, GrossNotionalValueOfSell, NumberOfSellShares, and NetValue per customer-instrument combination.

The procedure exists to support regulatory reporting, margin calculations, and exposure monitoring for Apex-cleared customers. Without it, firm-level aggregation would require ad-hoc queries across multiple tables.

Data flows from Trade.Position (for opens) and History.PositionSlim (for closes) on the specified day. The procedure joins Trade.InstrumentMetaData for symbols and Customer.CustomerStatic for ApexID mapping. CID-Apex relationship is validated before returning data.

---

## 2. Business Logic

### 2.1 Exchange Filtering for US Markets

**What**: Only positions on US exchanges (ExchangeID 4 and 5) are included in the aggregation.

**Columns/Parameters Involved**: `ExchangeID`, `CurrentTradeDay`

**Rules**:
- Open positions from Trade.Position and closed positions from History.PositionSlim are filtered to ExchangeID IN (4, 5)
- Non-US exchanges are excluded because this procedure serves Apex-linked firm reporting (US-focused)
- Activity is scoped to the @CurrentTradeDay parameter for day-level reporting

### 2.2 Optional Filtering by CID or ApexAccountID

**What**: Results can be filtered by specific customer or Apex account, or returned for all Apex-linked customers.

**Columns/Parameters Involved**: `@CID`, `@ApexAccountID`

**Rules**:
- When both NULL: returns aggregation for all Apex-linked customers
- When @CID provided: filters to that customer (validates CID-Apex relationship)
- When @ApexAccountID provided: filters to that Apex account
- Validation ensures the requested CID is linked to an Apex account

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | YES | NULL | CODE-BACKED | Optional filter. When provided, returns aggregation only for this customer. Must be linked to Apex. |
| 2 | @ApexAccountID | VARCHAR(50) | YES | NULL | CODE-BACKED | Optional filter. When provided, returns aggregation only for this Apex account. |
| 3 | @CurrentTradeDay | DATE | YES | NULL | CODE-BACKED | Trade day to aggregate. Defaults to current date when NULL. Scopes opens from Trade.Position and closes from History.PositionSlim. |
| 4 | CID | INT | NO | - | CODE-BACKED | Customer ID. Output column - the customer being aggregated. |
| 5 | ApexAccountID | VARCHAR(50) | NO | - | CODE-BACKED | Apex clearing account identifier. Maps from Customer.CustomerStatic. |
| 6 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. FK to Trade.Instrument. |
| 7 | Symbol | VARCHAR | NO | - | CODE-BACKED | Display symbol from Trade.InstrumentMetaData. |
| 8 | GrossNotionalValueOfBuy | MONEY | NO | - | CODE-BACKED | Total notional value of buy-side activity for the day. |
| 9 | NumberOfBuyShares | DECIMAL | NO | - | CODE-BACKED | Total number of shares/units bought. |
| 10 | GrossNotionalValueOfSell | MONEY | NO | - | CODE-BACKED | Total notional value of sell-side activity for the day. |
| 11 | NumberOfSellShares | DECIMAL | NO | - | CODE-BACKED | Total number of shares/units sold. |
| 12 | NetValue | MONEY | NO | - | CODE-BACKED | Net notional value (buy minus sell). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.Position | FROM | Open positions on the trade day |
| (body) | History.PositionSlim | FROM | Closed positions on the trade day |
| (body) | Trade.InstrumentMetaData | JOIN | Symbol lookup by InstrumentID |
| (body) | Customer.CustomerStatic | JOIN | ApexAccountID mapping for Apex-linked customers |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetFirmAggregation (procedure)
+-- Trade.Position (table)
+-- History.PositionSlim (table)
+-- Trade.InstrumentMetaData (table)
+-- Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | Table | FROM - open positions on CurrentTradeDay |
| History.PositionSlim | Table | FROM - closed positions on CurrentTradeDay |
| Trade.InstrumentMetaData | Table | JOIN - Symbol by InstrumentID |
| Customer.CustomerStatic | Table | JOIN - ApexAccountID for Apex-linked customers |

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

### 8.1 Execute for all Apex customers on today

```sql
EXEC Trade.GetFirmAggregation
    @CID = NULL,
    @ApexAccountID = NULL,
    @CurrentTradeDay = NULL;
```

### 8.2 Get aggregation for a specific customer on a date

```sql
EXEC Trade.GetFirmAggregation
    @CID = 12345,
    @ApexAccountID = NULL,
    @CurrentTradeDay = '2026-03-15';
```

### 8.3 Filter by Apex account for a trade day

```sql
EXEC Trade.GetFirmAggregation
    @CID = NULL,
    @ApexAccountID = 'APEX-ABC123',
    @CurrentTradeDay = '2026-03-15';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetFirmAggregation | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetFirmAggregation.sql*

# Trade.GetAllInterestRates

> Retrieves all CFD interest rates (overnight fees) from the Dictionary.InterestRate table, filtered to SettlementTypeID = 0 (CFD positions only).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns interest rate configuration for CFD instruments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the overnight fee (interest rate) configuration for CFD (Contract for Difference) positions. Overnight fees are daily charges applied to positions held past market close - they represent the cost of leveraged positions. Different instrument types have different rates for buy and sell positions, plus markup components.

The procedure exists because overnight fees are a core revenue mechanism for the platform and must be accurately configured. The trading engine uses these rates to calculate nightly fee deductions from open positions.

Data flows from `Dictionary.InterestRate` filtered to `SettlementTypeID = 0`, which represents CFD settlement types. Real stock positions (SettlementTypeID = 1) have different fee structures and are NOT included in this result set.

---

## 2. Business Logic

### 2.1 CFD-Only Filter

**What**: Only returns interest rates for CFD positions (SettlementTypeID = 0).

**Columns/Parameters Involved**: `SettlementTypeID`

**Rules**:
- `WHERE SettlementTypeID = 0` - only CFD settlement type rates
- SettlementTypeID = 0 is the default/CFD type in the system
- Real stock rates (SettlementTypeID = 1) require the TRDOPS variant procedure

### 2.2 Buy vs Sell Rate Structure

**What**: Each instrument type has separate overnight rates for buy and sell positions.

**Columns/Parameters Involved**: `InterestRateBuy`, `InterestRateSell`, `MarkupBuy`, `MarkupSell`

**Rules**:
- Total overnight fee = InterestRate + Markup for the respective direction
- Buy positions: charged InterestRateBuy + MarkupBuy
- Sell positions: charged InterestRateSell + MarkupSell
- Markups are the platform's fee component on top of the base interest rate

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. Output columns:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentTypeID | INT | NO | - | CODE-BACKED | FK to Dictionary.CurrencyType. Identifies which asset class this rate applies to (e.g., 1=Currencies, 2=Commodities, 5=Stocks). |
| 2 | InterestRateID | INT | NO | - | CODE-BACKED | Primary key of the interest rate record. |
| 3 | InterestRateName | NVARCHAR | YES | - | CODE-BACKED | Descriptive name for this rate configuration (e.g., "USD/EUR Overnight", "Crypto Weekend"). |
| 4 | InterestRateBuy | DECIMAL | YES | - | CODE-BACKED | Base overnight interest rate charged to long (buy) positions. Expressed as a daily rate. |
| 5 | InterestRateSell | DECIMAL | YES | - | CODE-BACKED | Base overnight interest rate charged to short (sell) positions. Expressed as a daily rate. |
| 6 | MarkupBuy | DECIMAL | YES | - | CODE-BACKED | Platform markup added to the buy interest rate. Platform revenue component of overnight fees. |
| 7 | MarkupSell | DECIMAL | YES | - | CODE-BACKED | Platform markup added to the sell interest rate. Platform revenue component of overnight fees. |
| 8 | UpdatedByUser | NVARCHAR | YES | - | CODE-BACKED | Username of the last person who modified this rate configuration. Audit trail for rate changes. |
| 9 | OverNightFeePatternID | INT | YES | - | CODE-BACKED | FK to overnight fee pattern. Defines when and how often fees are charged (e.g., daily, triple Wednesday for forex). |
| 10 | SettlementTypeID | INT | NO | - | CODE-BACKED | Settlement type filter. Always 0 in this procedure's results (CFD). See Trade.GetAllInterestRates_TRDOPS for all settlement types. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Dictionary.InterestRate | SELECT FROM | Source table for all overnight fee rates |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllInterestRates (procedure)
+-- Dictionary.InterestRate (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.InterestRate | Table | SELECT FROM with SettlementTypeID = 0 filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Trade.GetAllInterestRates;
```

### 8.2 Compare CFD vs Real stock rates
```sql
SELECT  SettlementTypeID, InstrumentTypeID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell
FROM    Dictionary.InterestRate WITH (NOLOCK)
ORDER BY SettlementTypeID, InstrumentTypeID;
```

### 8.3 Find instrument types with highest overnight markup
```sql
SELECT  ir.InstrumentTypeID, ct.Name, ir.MarkupBuy, ir.MarkupSell
FROM    Dictionary.InterestRate ir WITH (NOLOCK)
        INNER JOIN Dictionary.CurrencyType ct WITH (NOLOCK) ON ir.InstrumentTypeID = ct.CurrencyTypeID
WHERE   ir.SettlementTypeID = 0
ORDER BY ir.MarkupBuy + ir.MarkupSell DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllInterestRates | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllInterestRates.sql*

# Trade.GetAllInterestRates_TRDOPS

> Retrieves all interest rates (overnight fees) across ALL settlement types for the Trading Operations back-office tool.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns full interest rate configuration for all settlement types |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the Trading Operations (TRDOPS) variant of `Trade.GetAllInterestRates`. Unlike the standard version which only returns CFD rates (SettlementTypeID = 0), this version returns overnight fee rates for ALL settlement types - CFD, Real stocks, and any other settlement categories. The _TRDOPS suffix indicates this serves the internal operations management tool.

The procedure exists because operations teams need visibility into the complete fee configuration across all settlement types. They use this to audit fee structures, compare CFD vs real stock rates, and manage fee updates across the system.

Data flows from `Dictionary.InterestRate` with NOLOCK and no WHERE filter - returning the complete rate table. Also includes the `BeginTime` column not present in the standard variant, which shows when each rate configuration becomes effective.

---

## 2. Business Logic

### 2.1 Full Rate Visibility

**What**: Unlike GetAllInterestRates which filters to SettlementTypeID = 0 (CFD only), this returns ALL settlement types.

**Columns/Parameters Involved**: `SettlementTypeID`

**Rules**:
- No WHERE clause - returns rates for all settlement types (0=CFD, 1=Real, etc.)
- Uses NOLOCK for non-blocking reads from the operations tool
- Includes BeginTime column for rate schedule management

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. Output columns:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentTypeID | INT | NO | - | CODE-BACKED | FK to Dictionary.CurrencyType. Asset class this rate applies to. |
| 2 | InterestRateID | INT | NO | - | CODE-BACKED | Primary key of the interest rate record. |
| 3 | OverNightFeePatternID | INT | YES | - | CODE-BACKED | FK to overnight fee pattern. Defines the fee schedule (daily, triple Wednesday, etc.). |
| 4 | SettlementTypeID | INT | NO | - | CODE-BACKED | Settlement type: 0=CFD, 1=Real stocks. Determines which fee structure applies. Unlike GetAllInterestRates, all types are included. |
| 5 | InterestRateBuy | DECIMAL | YES | - | CODE-BACKED | Base overnight rate for long (buy) positions. Daily rate. |
| 6 | InterestRateSell | DECIMAL | YES | - | CODE-BACKED | Base overnight rate for short (sell) positions. Daily rate. |
| 7 | MarkupBuy | DECIMAL | YES | - | CODE-BACKED | Platform markup on buy overnight fees. Revenue component. |
| 8 | MarkupSell | DECIMAL | YES | - | CODE-BACKED | Platform markup on sell overnight fees. Revenue component. |
| 9 | BeginTime | DATETIME | YES | - | CODE-BACKED | Effective date/time for this rate configuration. Rates can be scheduled to take effect at a future time. Used by TRDOPS for rate change management. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Dictionary.InterestRate | SELECT FROM | Source table - all overnight fee rates, no filter |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllInterestRates_TRDOPS (procedure)
+-- Dictionary.InterestRate (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.InterestRate | Table | SELECT FROM - reads all rows, no filter |

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
EXEC Trade.GetAllInterestRates_TRDOPS;
```

### 8.2 Compare CFD vs Real stock rates for the same instrument type
```sql
SELECT  InstrumentTypeID, SettlementTypeID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell, BeginTime
FROM    Dictionary.InterestRate WITH (NOLOCK)
ORDER BY InstrumentTypeID, SettlementTypeID;
```

### 8.3 Find rates scheduled for future activation
```sql
SELECT  InterestRateID, InstrumentTypeID, SettlementTypeID, BeginTime
FROM    Dictionary.InterestRate WITH (NOLOCK)
WHERE   BeginTime > GETUTCDATE()
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.6/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllInterestRates_TRDOPS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllInterestRates_TRDOPS.sql*

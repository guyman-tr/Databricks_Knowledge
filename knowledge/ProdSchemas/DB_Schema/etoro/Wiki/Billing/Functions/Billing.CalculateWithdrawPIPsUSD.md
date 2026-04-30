# Billing.CalculateWithdrawPIPsUSD

> Scalar function that computes the exchange spread (PIPs in USD) for a withdrawal by retrieving exchange rate data from Billing.WithdrawToFunding and delegating to Billing.CalculateWithdrawPIPsUSD_Formula, applying the correct formula based on whether the currency pair is direct or reciprocal.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns MONEY - withdrawal PIPs in USD |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.CalculateWithdrawPIPsUSD is the **data-fetching wrapper** for the withdrawal PIPs calculation. It accepts a `WithdrawToFundingID` (the withdrawal processing record), retrieves exchange rates and the currency reciprocal flag, and delegates to `CalculateWithdrawPIPsUSD_Formula` for the calculation.

The withdrawal PIPs calculation differs from the deposit calculation because withdrawals have two formula variants based on whether the currency pair is quoted directly or reciprocally (`IsCurrencyReciprocal` / `IsReciprocal` from CurrencySettings). This reciprocal flag determines which branch of the formula executes in the underlying function.

PIPs on withdrawals represent eToro's spread revenue on the reverse currency conversion when a customer withdraws in a non-USD currency. A positive result indicates eToro earned spread on the conversion.

Referenced in three contexts:
- **BI_Withdraw_PIPS_Report**: Dedicated withdrawal PIPs revenue BI report
- **BI_Cashout_State_Report**: Full cashout lifecycle BI report (includes PIPs)
- **WithdrawService_GetWithdrawCashouts**: Operational query for active withdrawal/cashout records

---

## 2. Business Logic

### 2.1 WithdrawToFunding Data Retrieval + Formula Delegation

**What**: Fetches exchange rates, currency reciprocal flag, and amount from the withdrawal processing record, then calls the formula function.

**Columns/Parameters Involved**: `@WithdrawToFundingID`, Billing.WithdrawToFunding, Billing.CurrencySettings

**Rules**:
- Joins 2 tables: WithdrawToFunding -> CurrencySettings (on ProcessCurrencyID).
- Retrieves:
  - @ProcessCurrencyID: from Billing.WithdrawToFunding.ProcessCurrencyID (used only for CurrencySettings join)
  - @IsCurrencyReciprocal: from Billing.CurrencySettings.IsReciprocal (controls which formula branch executes)
  - @BaseExchangeRate: from Billing.WithdrawToFunding.BaseExchangeRate (mid-market rate)
  - @ExchangeRate: from Billing.WithdrawToFunding.ExchangeRate (actual applied rate)
  - @Amount: from Billing.WithdrawToFunding.Amount (withdrawal amount)
- Calls: `[Billing].[CalculateWithdrawPIPsUSD_Formula](@IsCurrencyReciprocal, @Amount, @BaseExchangeRate, @ExchangeRate)`
- Direct quote (IsReciprocal=0): `(-Amount/BaseRate + Amount/ExchangeRate) * BaseRate`
- Reciprocal quote (IsReciprocal=1): `(-Amount*BaseRate + Amount*ExchangeRate) / BaseRate`  [note: Formula uses 1/BaseRate approach]
- Returns NULL if @WithdrawToFundingID does not exist.

**Diagram**:
```
@WithdrawToFundingID
    |
Billing.WithdrawToFunding (BaseExchangeRate, ExchangeRate, Amount, ProcessCurrencyID)
JOIN Billing.CurrencySettings ON ProcessCurrencyID (reads IsReciprocal)
    |
CalculateWithdrawPIPsUSD_Formula(
    @IsCurrencyReciprocal, @Amount, @BaseExchangeRate, @ExchangeRate
)
    |
IsReciprocal=0: ((-Amount/BaseRate) + (Amount/ExchangeRate)) * BaseRate  [MONEY]
IsReciprocal=1: reciprocal-adjusted formula                               [MONEY]
```

---

## 3. Data Overview

N/A for Scalar Function. See Billing.CalculateWithdrawPIPsUSD_Formula for formula branch details.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingID | int | NO | - | VERIFIED | ID of the Billing.WithdrawToFunding record (the processed withdrawal leg). Uniquely identifies the withdrawal processing event. Drives the 2-table JOIN to retrieve exchange rates, amount, and currency settings. |
| RETURN | money | YES | - | VERIFIED | Exchange spread PIPs in USD for this withdrawal processing event. Formula branches on IsCurrencyReciprocal from Billing.CurrencySettings. Positive = eToro earned PIPs. NULL if @WithdrawToFundingID not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawToFundingID | Billing.WithdrawToFunding | Lookup (JOIN) | Reads BaseExchangeRate, ExchangeRate, Amount, ProcessCurrencyID. |
| Billing.WithdrawToFunding.ProcessCurrencyID | Billing.CurrencySettings | Lookup (JOIN) | Reads IsReciprocal flag to determine formula branch. |
| (all params) | Billing.CalculateWithdrawPIPsUSD_Formula | Caller | Delegates PIPs calculation to the formula function. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.BI_Withdraw_PIPS_Report | WithdrawToFundingID | Caller | Dedicated withdrawal PIPs revenue BI report. |
| Billing.BI_Cashout_State_Report | WithdrawToFundingID | Caller | Full cashout lifecycle BI report (includes PIPs column). |
| Billing.WithdrawService_GetWithdrawCashouts | WithdrawToFundingID | Caller | Operational query for withdrawal/cashout records. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CalculateWithdrawPIPsUSD (function)
├── Billing.WithdrawToFunding (table)
├── Billing.CurrencySettings (table)
└── Billing.CalculateWithdrawPIPsUSD_Formula (function)
    (pure formula - no table deps)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Reads BaseExchangeRate, ExchangeRate, Amount, ProcessCurrencyID for the withdrawal leg. |
| Billing.CurrencySettings | Table | Reads IsReciprocal to determine which formula branch to apply. |
| Billing.CalculateWithdrawPIPsUSD_Formula | Function | Performs the actual PIPs calculation (two branches: direct and reciprocal). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.BI_Withdraw_PIPS_Report | Stored Procedure | Withdrawal PIPs revenue reporting. |
| Billing.BI_Cashout_State_Report | Stored Procedure | Full cashout state BI report. |
| Billing.WithdrawService_GetWithdrawCashouts | Stored Procedure | Operational withdrawal/cashout query. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | NOT schema-bound. |
| Simpler dependency than deposit | Design | Only 2 tables (vs 4 for deposit) because withdrawal context is self-contained in WithdrawToFunding - no need to join through Funding/FundingType. |
| IsReciprocal from CurrencySettings | Design | The reciprocal flag comes from Billing.CurrencySettings.IsReciprocal (column named `IsReciprocal`), mapped to @IsCurrencyReciprocal. This controls the formula branch in the underlying function. |
| NULLIF/ISNULL guards | Formula | The formula function uses NULLIF to prevent division-by-zero on zero exchange rates - see CalculateWithdrawPIPsUSD_Formula for details. |

---

## 8. Sample Queries

### 8.1 Calculate PIPs for a specific withdrawal processing record

```sql
SELECT Billing.CalculateWithdrawPIPsUSD(98765) AS WithdrawPIPsUSD;
-- Positive = eToro earned spread on this withdrawal's currency conversion
```

### 8.2 PIPs alongside withdrawal details

```sql
SELECT
    wtf.ID AS WithdrawToFundingID,
    wtf.Amount,
    wtf.BaseExchangeRate,
    wtf.ExchangeRate,
    Billing.CalculateWithdrawPIPsUSD(wtf.ID) AS PIPs
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.CashoutID IN (
    SELECT CashoutID FROM Billing.Cashout WITH (NOLOCK)
    WHERE CID = 12345
)
ORDER BY wtf.ID DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
```

### 8.3 Total withdrawal PIPs by processing currency

```sql
SELECT
    cs.CurrencyID,
    SUM(Billing.CalculateWithdrawPIPsUSD(wtf.ID)) AS TotalPIPs
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN Billing.CurrencySettings cs WITH (NOLOCK) ON cs.CurrencyID = wtf.ProcessCurrencyID
WHERE wtf.CashoutStatusID = 5  -- Processed
GROUP BY cs.CurrencyID
ORDER BY TotalPIPs DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CalculateWithdrawPIPsUSD | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.CalculateWithdrawPIPsUSD.sql*

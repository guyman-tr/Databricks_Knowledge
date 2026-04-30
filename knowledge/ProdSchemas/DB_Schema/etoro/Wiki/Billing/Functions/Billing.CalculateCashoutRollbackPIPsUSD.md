# Billing.CalculateCashoutRollbackPIPsUSD

> Scalar function that computes the exchange fee component (PIPs) for a cashout rollback by retrieving the rollback amount and exchange fee from Billing.CashoutRollbackTracking and Billing.WithdrawToFunding, returning the fee as RollbackAmount * (ExchangeFee / 10^Precision).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns DECIMAL(18,6) - PIPs/exchange fee in USD |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.CalculateCashoutRollbackPIPsUSD calculates the exchange fee amount (PIPs) associated with a cashout rollback event. Unlike the withdrawal formula functions (which compute rate-spread PIPs), this function uses the exchange fee per unit of currency (from `Billing.CashoutRollbackTracking` and `Billing.WithdrawToFunding`) multiplied by the rollback amount. The result represents the fee component that must be reversed when a previously processed withdrawal is rolled back.

This function exists to support rollback reconciliation in `Billing.GetRollbackedPaymentOrdersReport` - the BI report for reversed payment processing orders. It retrieves the financial context from three tables (WithdrawToFunding, CurrencySettings, CashoutRollbackTracking) so the report doesn't have to implement the join logic inline.

Note the naming pattern: "Cashout" rollback (using `Billing.CashoutRollbackTracking`) vs "Withdraw" rollback (using `Billing.DepositRollbackTracking` or the formula functions). This suggests two separate rollback tracks: the older cashout system and the newer withdraw system.

---

## 2. Business Logic

### 2.1 Exchange Fee PIPs Formula (Cashout Rollback)

**What**: Computes the exchange fee component of a cashout rollback using a fee-per-unit approach rather than rate differential.

**Columns/Parameters Involved**: `@WithdrawToFundingID`, `@CashoutRollbackID`

**Rules**:
- Retrieves @ProcessingExchangeFee from Billing.WithdrawToFunding.ExchangeFee (original processing fee).
- Retrieves @RollbackExchangeFee from Billing.CashoutRollbackTracking.ExchangeFee (rollback-specific fee).
- Retrieves @RollbackAmountInCurrency from Billing.CashoutRollbackTracking.RollbackAmountInCurrency.
- Retrieves @ProcessingCurrencyPrecision from Billing.CurrencySettings.Precision (via WithdrawToFunding.ProcessCurrencyID).
- Fee fallback rule: if @RollbackExchangeFee = 0 AND @ProcessingExchangeFee != 0 -> use the original processing fee for the rollback calculation.
- Formula: `PIPs = @RollbackAmountInCurrency * (@RollbackExchangeFee / POWER(10, @ProcessingCurrencyPrecision))`

**Diagram**:
```
@WithdrawToFundingID (from Billing.WithdrawToFunding):
  ProcessingExchangeFee, ProcessCurrencyID
      |
@CashoutRollbackID (from Billing.CashoutRollbackTracking):
  RollbackExchangeFee, RollbackAmountInCurrency
      |
@ProcessingCurrencyPrecision (from Billing.CurrencySettings for ProcessCurrencyID):
  Precision
      |
Fee fallback: RollbackFee=0 AND ProcessingFee!=0 -> use ProcessingFee

PIPs = RollbackAmountInCurrency * (EffectiveFee / POWER(10, Precision))
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingID | int | NO | - | VERIFIED | ID of the Billing.WithdrawToFunding record (the processed withdrawal-to-funding leg). Used to retrieve the processing exchange fee and currency. |
| 2 | @CashoutRollbackID | int | NO | - | VERIFIED | RollbackID from Billing.CashoutRollbackTracking. Used to retrieve the rollback amount in currency and the rollback-specific exchange fee. |
| RETURN | decimal(18,6) | - | NO | - | VERIFIED | Exchange fee PIPs in USD for the rollback. Precision 6 decimal places. Formula: RollbackAmountInCurrency * (EffectiveExchangeFee / 10^CurrencyPrecision). Returns NULL if the JOIN yields no results (no matching WithdrawToFunding or CashoutRollbackTracking record). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawToFundingID | Billing.WithdrawToFunding | Lookup (JOIN) | Reads ExchangeFee and ProcessCurrencyID for the withdrawal leg. |
| @CashoutRollbackID | Billing.CashoutRollbackTracking | Lookup (JOIN) | Reads RollbackAmountInCurrency and ExchangeFee for the rollback event. |
| ProcessCurrencyID | Billing.CurrencySettings | Lookup (JOIN) | Reads Precision to determine decimal scaling for the fee formula. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetRollbackedPaymentOrdersReport | WithdrawToFundingID, CashoutRollbackID | Caller | BI report that calls this function per rollback row to compute the fee amount. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CalculateCashoutRollbackPIPsUSD (function)
├── Billing.WithdrawToFunding (table)
├── Billing.CurrencySettings (table)
└── Billing.CashoutRollbackTracking (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Reads ExchangeFee and ProcessCurrencyID for the withdrawal-to-funding record. |
| Billing.CurrencySettings | Table | Reads Precision for the processing currency (to scale the exchange fee). |
| Billing.CashoutRollbackTracking | Table | Reads RollbackAmountInCurrency and ExchangeFee for the rollback event. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetRollbackedPaymentOrdersReport | Stored Procedure | Calls this function per rollback to compute the PIPs/fee for the BI rollback report. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | NOT schema-bound. |
| Fee fallback | Logic | If rollback ExchangeFee=0 but processing ExchangeFee!=0, the processing fee is used as a fallback. This handles cases where the rollback was created without recording a specific fee (inherits the original processing fee). |

---

## 8. Sample Queries

### 8.1 Calculate PIPs for a specific cashout rollback

```sql
SELECT Billing.CalculateCashoutRollbackPIPsUSD(98765, 123) AS RollbackPIPsUSD;
-- @WithdrawToFundingID=98765, @CashoutRollbackID=123
```

### 8.2 Get rollback PIPs alongside rollback details

```sql
SELECT
    crt.RollbackID,
    crt.RollbackAmountInCurrency,
    crt.ExchangeFee AS RollbackFee,
    wtf.ExchangeFee AS OriginalFee,
    Billing.CalculateCashoutRollbackPIPsUSD(wtf.ID, crt.RollbackID) AS PIPsUSD
FROM Billing.CashoutRollbackTracking crt WITH (NOLOCK)
JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK) ON wtf.ID = crt.WithdrawToFundingID
ORDER BY crt.RollbackID DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
```

### 8.3 Summarize rollback PIPs by currency

```sql
SELECT
    cs.CurrencyID,
    SUM(Billing.CalculateCashoutRollbackPIPsUSD(wtf.ID, crt.RollbackID)) AS TotalRollbackPIPs
FROM Billing.CashoutRollbackTracking crt WITH (NOLOCK)
JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK) ON wtf.ID = crt.WithdrawToFundingID
JOIN Billing.CurrencySettings cs WITH (NOLOCK) ON cs.CurrencyID = wtf.ProcessCurrencyID
GROUP BY cs.CurrencyID
ORDER BY TotalRollbackPIPs DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CalculateCashoutRollbackPIPsUSD | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.CalculateCashoutRollbackPIPsUSD.sql*

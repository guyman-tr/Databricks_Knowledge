# Billing.GetRedeemNFTValidationData

> Pre-redemption eligibility check for NFT positions: computes the customer's net redeemable equity (realized equity minus in-process redemptions minus non-redeemable deposit amounts) and returns whether it is sufficient to cover the requested position value.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @Invested (customer + position value); returns one summary row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRedeemNFTValidationData` is the financial eligibility gate for NFT crypto redemptions. Before the system allows a customer to redeem an NFT position, it must verify that the customer has enough "clean" equity - equity backed by deposits that have fully aged and cleared - to cover the redemption. This prevents customers from redeeming value that comes from non-redeemable sources such as bonuses, very recent deposits, or funds that have not yet passed the anti-chargeback waiting period.

The procedure exists because the redeemability calculation is complex: not all deposits are redeemable (only specific funding types listed in `Billing.RedeemFundingSettings`), recent deposits have a sliding exclusion window, and there is a country-level configuration that changes how ACH deposits are treated. Without this validation, customers in regulated markets or with recent deposits could redeem value they do not actually own in cleared funds.

Data flow: the application calls this procedure with the customer's profile (@CID, @CountryID, @PlayerLevelID) and the position value to be redeemed (@Invested). The procedure returns two values: `RedeemableAmount` (either the customer's full redeemable equity if >= @Invested, or 0 if not eligible) and `NFTInvested` (the @Invested amount echoed back). A `RedeemableAmount = 0` means the customer fails the eligibility check. Authored over multiple iterations: Ran Ovadia (Nov 2018), Avraham Lahmi (Feb 2019), Oleg S. (Sep 2020), Alexei (Jun 2022 PTL-76 NFT type addition).

---

## 2. Business Logic

### 2.1 Redeemable Amount Calculation Engine

**What**: Computes the portion of a customer's deposits that qualify as redeemable - funds from approved payment methods that have aged past the anti-chargeback waiting period.

**Columns/Parameters Involved**: `@CID`, `@PlayerLevelID`, `Billing.Deposit`, `Billing.Funding`, `Billing.RedeemFundingSettings`, `BackOffice.CustomerMIMOAllTimeAggregatedData`

**Rules**:
- Only deposits with `PaymentStatusID=2` (Paid/Confirmed) are counted
- Only deposits from funding types listed in `Billing.RedeemFundingSettings` where `IsActive=1` and `PlayerLevelID=@PlayerLevelID` are included
- Time gate 1 (CancellationTimeInDays): the deposit must have been made at least RS.CancellationTimeInDays after the customer's FTD date (`GETUTCDATE() >= DATEADD(dd, RS.CancellationTimeInDays, @FTDDate)`)
- Time gate 2 (SlidingDaysToIgnore): the deposit must NOT be within the last RS.SlidingDaysToIgnore days (`BD.ModificationDate <= DATEADD(dd, -1 * RS.SlidingDaysToIgnore, GETUTCDATE())`)
- FTD date = `ModificationDate` of the row in `Billing.Deposit` where `IsFTD=1 AND CID=@CID`
- Deposit amounts are converted to USD using the stored `ExchangeRate`: `SUM(Amount * ExchangeRate)`
- `NotRedeemableAmount = AllTimeDeposits - FundingRedeemableAmount` - the portion of total historical deposits that does NOT qualify

**Diagram**:
```
AllTimeDeposits (BackOffice.CustomerMIMOAllTimeAggregatedData)
  = total USD value of all deposits ever made

FundingRedeemableAmount
  = SUM of paid deposits from redeemable funding types
      WHERE aged past CancellationTimeInDays from FTD
      AND not within SlidingDaysToIgnore days

NotRedeemableAmount = AllTimeDeposits - FundingRedeemableAmount
  = bonuses, very recent deposits, non-redeemable payment types
```

### 2.2 Country-Specific Redeemable Calculation (ACH Split)

**What**: When country settings are active for the customer's country+level, ACH deposits (FundingTypeID=29) are calculated separately and combined with other redeemable deposits. When country settings are inactive (most countries), only the standard `RedeemFundingSettings` filter is applied.

**Columns/Parameters Involved**: `@CountryID`, `@PlayerLevelID`, `Billing.RedeemCountrySettings`, `Billing.RedeemFundingSettings`

**Rules**:
- `@CountrySettingsActive = 1` when `Billing.RedeemCountrySettings` has an active row (IsActive=1) for (@PlayerLevelID, @CountryID)
- Currently: 245 of 251 countries are active in RedeemCountrySettings. 6 countries are blocked (US, Austria, Belgium, Denmark, Norway, Afghanistan)
- **When CountrySettingsActive=1 (most countries)**:
  - ACH path: FundingTypeID=29 deposits summed (no IsRedeemable filter - ACH handled by type match)
  - Non-ACH path: adds deposits where `Dictionary.FundingType.IsRedeemable=1` (broader filter includes more funding types)
  - Total = ACH amount + non-ACH redeemable amount
- **When CountrySettingsActive=0 (6 blocked countries)**:
  - Standard path: only deposits from `Billing.RedeemFundingSettings` (no IsRedeemable filter, no ACH split)
  - These countries follow the basic eligibility rules without the ACH split logic

### 2.3 In-Process Redemption Deduction

**What**: Any redemptions currently in progress for this customer are subtracted from the available redeemable equity to prevent double-redemption.

**Columns/Parameters Involved**: `Billing.Redeem`, `Trade.GetPositionData`, `Trade.CalcNetProfit`, `@RedeemInProcess`

**Rules**:
- Active redemption statuses included: 1 (PositionPending), 3 (Approved), 4 (ReadyToRedeem), 5 (PositionClosing), 6 (PositionClosed), 7 (TransactionInProcess), 21 (FailedToCancel), 100 (New)
- For each in-process redemption, value = MIN(AmountOnRequest, COALESCE(AmountOnClose, current P&L + original amount))
  - Uses conservative min to avoid over-deducting when market has moved favorably
  - P&L computed via `Trade.CalcNetProfit(IsBuy, InitForexRate, EndForexRate or live bid/ask, Units, conversion rate)`
- Total @RedeemInProcess = SUM of these conservative values across all active redemptions for @CID

### 2.4 Final Eligibility Decision

**What**: The final eligibility is a single comparison: is the net redeemable equity >= the position value being redeemed?

**Columns/Parameters Involved**: `RedeemableAmount`, `NFTInvested`, `@Invested`

**Rules**:
- `RedeemableAmount = MAX(0, RealizedEquity - RedeemInProcess - NotRedeemableAmount)`
- `RealizedEquity` from `Customer.CustomerMoney` (the customer's current account equity)
- If `RedeemableAmount >= @Invested`: return RedeemableAmount (customer is eligible; amount shows full available capacity)
- If `RedeemableAmount < @Invested`: return 0 (customer is NOT eligible for this redemption amount)
- `NFTInvested` = @Invested echoed back; the caller compares these two values to confirm eligibility

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. All deposit, redemption, and equity lookups are scoped to this customer. |
| 2 | @CountryID | INT | NO | - | CODE-BACKED | Customer's country of residence. Used to check `Billing.RedeemCountrySettings` for the country-specific calculation path (ACH split logic). |
| 3 | @PlayerLevelID | INT | NO | - | CODE-BACKED | Customer's VIP/player tier. Used to filter both `Billing.RedeemCountrySettings` and `Billing.RedeemFundingSettings` for tier-specific rules. |
| 4 | @Invested | DECIMAL(16,8) | YES | NULL | CODE-BACKED | The USD value of the NFT position the customer wants to redeem. Used as the eligibility threshold: if RedeemableAmount >= @Invested, the customer qualifies. Echoed back as `NFTInvested` in the result. NULL-safe (stored in @PositionPandL which can be NULL). |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 5 | RedeemableAmount | DECIMAL | NO | - | CODE-BACKED | The customer's available redeemable equity if they pass the eligibility check, or 0 if they fail. Formula: `IIF(MAX(0, RealizedEquity - RedeemInProcess - NotRedeemableAmount) >= @Invested, RedeemableAmount, 0)`. A value of 0 means the customer cannot redeem the requested amount. A positive value means the customer is eligible and shows the total capacity available. |
| 6 | NFTInvested | DECIMAL | YES | - | CODE-BACKED | Echo of @Invested. The USD value of the position being redeemed. The caller compares `RedeemableAmount` to `NFTInvested` to confirm eligibility: if `RedeemableAmount = 0` and `NFTInvested > 0`, the check failed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID / @CountryID / @PlayerLevelID | Billing.RedeemCountrySettings | Lookup | Determines which calculation path to use (ACH split vs standard) |
| @CID + FTD lookup | Billing.Deposit | SELECT (FTD date) | FTD date anchors both CancellationTimeInDays and SlidingDaysToIgnore windows |
| @CID deposits | Billing.Deposit + Billing.Funding + Billing.RedeemFundingSettings | JOIN | Computes FundingRedeemableAmount |
| FundingTypeID | Dictionary.FundingType | LEFT JOIN | IsRedeemable flag for non-ACH redeemable deposit path (country-active branch) |
| @CID | BackOffice.CustomerMIMOAllTimeAggregatedData | Lookup | AllTimeDeposits total |
| @CID | Customer.CustomerMoney | Lookup | RealizedEquity |
| @CID active redemptions | Billing.Redeem + Trade.GetPositionData | CTE JOIN | In-process redemption value deduction |
| P&L calculation | Trade.CalcNetProfit | Function call | Computes current position value for in-process redemptions |
| Conversion rate | Trade.GetMinorConversionRate | Function call | Currency conversion for P&L calculation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application NFT redemption service | @CID, @CountryID, @PlayerLevelID, @Invested | EXEC | Pre-redemption eligibility gate; result determines whether the redemption request is allowed to proceed |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRedeemNFTValidationData (procedure)
├── Billing.RedeemCountrySettings (table)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Billing.RedeemFundingSettings (table)
├── Dictionary.FundingType (table)
├── BackOffice.CustomerMIMOAllTimeAggregatedData (table, cross-schema)
├── Customer.CustomerMoney (table, cross-schema)
├── Billing.Redeem (table)
├── Trade.GetPositionData (view/table, cross-schema)
├── Trade.CurrencyPrice (table, cross-schema)
├── Trade.CalcNetProfit (function, cross-schema)
└── Trade.GetMinorConversionRate (function, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemCountrySettings | Table | Lookup: checks if country+level has active settings for ACH split path |
| Billing.Deposit | Table | FTD date lookup; redeemable deposit sum (two query paths) |
| Billing.Funding | Table | JOIN to get FundingTypeID for payment method classification |
| Billing.RedeemFundingSettings | Table | Config for CancellationTimeInDays, SlidingDaysToIgnore, eligible FundingTypes |
| Dictionary.FundingType | Table | LEFT JOIN for IsRedeemable flag (country-active branch) |
| BackOffice.CustomerMIMOAllTimeAggregatedData | Table | AllTimeDeposits total for the customer |
| Customer.CustomerMoney | Table | RealizedEquity for the customer |
| Billing.Redeem | Table | Active in-process redemptions for the customer |
| Trade.GetPositionData | View | Current position data (Amount, IsBuy, rates) for in-process redemptions |
| Trade.CurrencyPrice | Table | Live bid/ask prices for open position P&L calculation |
| Trade.CalcNetProfit | Function | P&L computation for in-process redemptions |
| Trade.GetMinorConversionRate | Function | Currency conversion rate for P&L calculation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application NFT redemption service | External | Calls this procedure as the financial eligibility gate before allowing a redemption to proceed |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RedeemableAmount floor | Business rule | `IIF((...) > 0, (...), 0)` - negative values are clamped to 0; negative equity doesn't reduce eligibility below 0 |
| Eligibility binary output | Business rule | Either return the full RedeemableAmount (eligible) or 0 (not eligible) - no partial eligibility |
| FTD dependency | Technical | @FTDDate can be NULL if customer has no FTD; DATEADD with NULL produces NULL, causing all time-gated deposits to be excluded (conservative fail-safe) |
| NOLOCK throughout | Concurrency | All table reads use NOLOCK for throughput; minor staleness is acceptable for eligibility pre-checks |
| Cross-schema reads | Architecture | Reads from BackOffice, Customer, Trade, and Dictionary schemas - requires broad permissions |

---

## 8. Sample Queries

### 8.1 Check NFT redemption eligibility for a customer
```sql
EXEC Billing.GetRedeemNFTValidationData
    @CID = 12345678,
    @CountryID = 74,         -- e.g., Germany
    @PlayerLevelID = 1,
    @Invested = 500.00;      -- Position value in USD
-- RedeemableAmount > 0: eligible; RedeemableAmount = 0: not eligible
```

### 8.2 Check country settings activation for a customer
```sql
SELECT
    CountryID,
    PlayerLevelID,
    IsActive,
    SysStartTime,
    SysEndTime
FROM Billing.RedeemCountrySettings WITH (NOLOCK)
WHERE CountryID = 74
  AND PlayerLevelID = 1;
```

### 8.3 Inspect a customer's redeemable deposit components
```sql
SELECT
    BD.DepositID,
    BD.CID,
    BD.Amount,
    BD.ExchangeRate,
    BD.Amount * BD.ExchangeRate AS AmountUSD,
    BD.ModificationDate,
    BF.FundingTypeID,
    RS.CancellationTimeInDays,
    RS.SlidingDaysToIgnore
FROM Billing.Deposit BD WITH (NOLOCK)
INNER JOIN Billing.Funding BF WITH (NOLOCK) ON BD.FundingID = BF.FundingID
INNER JOIN Billing.RedeemFundingSettings RS WITH (NOLOCK)
    ON BF.FundingTypeID = RS.FundingTypeID
    AND RS.PlayerLevelID = 1
    AND RS.IsActive = 1
WHERE BD.CID = 12345678
  AND BD.PaymentStatusID = 2
ORDER BY BD.ModificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PTL-76 (referenced in DDL comment, Alexei, 30/06/2022) | Jira | Added NFT redemption type support (@RedeemTypeID dimension) to the procedure (Jira unavailable for full details) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetRedeemNFTValidationData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRedeemNFTValidationData.sql*

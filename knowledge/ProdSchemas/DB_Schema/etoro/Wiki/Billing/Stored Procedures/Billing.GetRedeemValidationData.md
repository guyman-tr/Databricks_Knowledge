# Billing.GetRedeemValidationData

> Pre-redemption eligibility check for standard (non-NFT) crypto positions: computes the customer's net redeemable equity adjusted for the specific position's current P&L, and returns whether it is sufficient to cover the position's current value.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @PositionID (customer + position); returns one summary row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRedeemValidationData` is the financial eligibility gate for standard crypto redemptions. Before a customer can redeem (liquidate) a crypto trading position, this procedure verifies that their net redeemable equity - adjusted for the current market value of the position being redeemed - is sufficient. It is the standard-redemption equivalent of `Billing.GetRedeemNFTValidationData`, with two key differences: it accepts a specific PositionID (rather than a generic invested amount), and it derives the customer's country and player level automatically from `Customer.Customer` rather than requiring explicit parameters.

The procedure evaluates a multi-component formula: realized equity minus deposits committed to other in-process redemptions (excluding the current position) minus non-redeemable deposit amounts, plus the current position's P&L. The result must be >= the current position value for the redemption to proceed. Updated 31 Dec 2023 (Dor I) for a P&L calculation change.

Data flow: the caller (application redemption service) passes the customer ID and the position to redeem. The procedure returns `TotalWireDeposits` (either the full redeemable equity if eligible, or 0 if not) and `TotalRedeemedInvested` (the current position value). A `TotalWireDeposits > 0` confirms eligibility; `= 0` means the customer cannot redeem this position now.

---

## 2. Business Logic

### 2.1 Redeemable Amount Calculation Engine

**What**: Computes the fraction of the customer's deposit history that qualifies as redeemable (funds cleared of chargeback risk and aging requirements).

**Columns/Parameters Involved**: `@CID`, `Billing.Deposit`, `Billing.Funding`, `Billing.RedeemFundingSettings`, `Customer.Customer`, `BackOffice.CustomerMIMOAllTimeAggregatedData`

**Rules** (same core logic as `Billing.GetRedeemNFTValidationData` Section 2.1):
- Only PaymentStatusID=2 deposits from RedeemFundingSettings-listed funding types (IsActive=1, matching player level) count
- Two time gates: CancellationTimeInDays from FTD date AND not within SlidingDaysToIgnore recent days
- PlayerLevelID is fetched dynamically from `Customer.Customer WHERE CID = @CID` (vs. explicit param in NFT version)
- FundingRedeemableAmount amount in USD using `SUM(Amount * ExchangeRate)`
- NotRedeemableAmount = AllTimeDeposits (from BackOffice.CustomerMIMOAllTimeAggregatedData) - FundingRedeemableAmount

### 2.2 Country-Specific Calculation Path (ACH Split)

**What**: Same ACH split logic as `GetRedeemNFTValidationData` but country/level are looked up from `Customer.Customer` directly.

**Columns/Parameters Involved**: `Customer.Customer`, `Billing.RedeemCountrySettings`, `@CountrySettingsActive`

**Rules**:
- `@CountrySettingsActive = 1` when `Customer.Customer` JOIN `Billing.RedeemCountrySettings` finds an active row for the customer's actual CountryID + PlayerLevelID
- This avoids requiring the caller to pass country/level - the procedure resolves them at runtime
- ACH split logic (FundingTypeID=29 calculated separately, then combined with IsRedeemable=1 deposits) is identical to `GetRedeemNFTValidationData` Section 2.2

### 2.3 Position-Specific P&L Adjustment

**What**: The current unrealized P&L of the specific position being redeemed is added back to the redeemable amount, because the customer is about to receive that P&L as part of the redemption proceeds.

**Columns/Parameters Involved**: `@PositionID`, `@NetProfitPositionID`, `Trade.PositionForExternalUseWithPnL`

**Rules**:
- `@NetProfitPositionID = PnLInDollars FROM Trade.PositionForExternalUseWithPnL WHERE PartitionCol = @PositionID % 50 AND PositionID = @PositionID`
- PartitionCol filter (`@PositionID % 50`) is required because `PositionForExternalUseWithPnL` is partitioned on this column
- `@PositionPandL = MAX(0, @Invested + @NetProfitPositionID)` = current position value (floored at 0)
- `@RedeemableAmount = MAX(0, RealizedEquity - RedeemInProcess - NotRedeemableAmount + @NetProfitPositionID)` - the position P&L is added because it will become part of the customer's equity upon redemption
- The in-process deduction CTE explicitly excludes the @PositionID itself (`AND BR.PositionID <> @PositionID`) to avoid double-counting

### 2.4 Final Eligibility Decision

**What**: Eligibility is the comparison of redeemable equity against the current position value.

**Columns/Parameters Involved**: `TotalWireDeposits`, `TotalRedeemedInvested`

**Rules**:
- `TotalRedeemedInvested = @PositionPandL` = current position value (AmountOnRequest + unrealized P&L, floored at 0)
- `TotalWireDeposits = IIF(@RedeemableAmount >= @PositionPandL, @RedeemableAmount, 0)` - if eligible, returns the full redeemable capacity; if not, returns 0
- Column name `TotalWireDeposits` is misleading - it represents the eligibility check result (redeemable equity), not wire deposit totals specifically
- Caller checks: if TotalWireDeposits > 0 = eligible; if = 0 = not eligible

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Used for all deposit, redemption, and equity lookups. Country and player level are derived internally from `Customer.Customer`. |
| 2 | @PositionID | BIGINT | YES | NULL | CODE-BACKED | The trading position to be redeemed. Used to fetch the position's current P&L and to exclude it from the in-process redemption deduction sum. NULL is technically accepted but would result in no P&L adjustment and no PositionID exclusion. |
| 3 | @Invested | DECIMAL(16,8) | YES | NULL | CODE-BACKED | The original investment amount (AmountOnRequest) for the position being redeemed. Combined with @NetProfitPositionID to compute @PositionPandL (current value). NULL yields PositionPandL of 0 or NULL. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | TotalWireDeposits | DECIMAL | NO | - | CODE-BACKED | Despite the name, this is the eligibility result: the customer's net redeemable equity if they qualify, or 0 if they fail. Formula: `IIF(RedeemableAmount >= PositionPandL, RedeemableAmount, 0)`. A positive value confirms the customer is eligible; 0 means they cannot redeem this position at this time. (Naming is a legacy misnomer.) |
| 5 | TotalRedeemedInvested | DECIMAL | YES | - | CODE-BACKED | Current USD value of the position being redeemed: `MAX(0, @Invested + @NetProfitPositionID)`. Represents what the customer would receive (before fees) if the redemption proceeds. Caller compares this against TotalWireDeposits to confirm eligibility. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Lookup | Derives CountryID and PlayerLevelID for the country settings check |
| @CID / CountryID / PlayerLevelID | Billing.RedeemCountrySettings | JOIN | Determines which calculation path to use |
| @CID + FTD | Billing.Deposit | SELECT | FTD date and redeemable deposit sum |
| FundingTypeID | Billing.Funding | JOIN | Payment type classification |
| FundingTypeID | Billing.RedeemFundingSettings | JOIN | Aging and eligibility config |
| FundingTypeID | Dictionary.FundingType | LEFT JOIN | IsRedeemable flag (country-active branch) |
| @CID | BackOffice.CustomerMIMOAllTimeAggregatedData | Lookup | AllTimeDeposits |
| @CID | Customer.CustomerMoney | Lookup | RealizedEquity |
| @PositionID | Trade.PositionForExternalUseWithPnL | Lookup | Current position P&L |
| @CID active redemptions | Billing.Redeem + Trade.GetPositionDataForExternalUse | CTE JOIN | In-process redemption deduction |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application redemption service | @CID, @PositionID, @Invested | EXEC | Financial eligibility gate before allowing a standard crypto redemption |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRedeemValidationData (procedure)
├── Customer.Customer (table, cross-schema)
├── Billing.RedeemCountrySettings (table)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Billing.RedeemFundingSettings (table)
├── Dictionary.FundingType (table)
├── BackOffice.CustomerMIMOAllTimeAggregatedData (table, cross-schema)
├── Customer.CustomerMoney (table, cross-schema)
├── Trade.PositionForExternalUseWithPnL (view, cross-schema)
├── Billing.Redeem (table)
├── Trade.GetPositionDataForExternalUse (view, cross-schema)
└── Trade.CurrencyPrice (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Derives CountryID and PlayerLevelID for country settings check |
| Billing.RedeemCountrySettings | Table | Country-specific calculation path gate |
| Billing.Deposit | Table | FTD date lookup; redeemable deposit sum |
| Billing.Funding | Table | JOIN for FundingTypeID |
| Billing.RedeemFundingSettings | Table | Aging config per funding type and player level |
| Dictionary.FundingType | Table | IsRedeemable flag for country-active branch |
| BackOffice.CustomerMIMOAllTimeAggregatedData | Table | AllTimeDeposits total |
| Customer.CustomerMoney | Table | RealizedEquity |
| Trade.PositionForExternalUseWithPnL | View | Current position P&L (with PartitionCol filter) |
| Billing.Redeem | Table | In-process redemptions for this customer (excluding @PositionID) |
| Trade.GetPositionDataForExternalUse | View | Position data for in-process redemption value calculation |
| Trade.CurrencyPrice | Table | Live bid/ask for P&L of in-process positions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application redemption service | External | Calls as the eligibility gate before initiating a standard crypto redemption |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PartitionCol filter | Technical | `PartitionCol = @PositionID % 50` required for `Trade.PositionForExternalUseWithPnL` partition elimination |
| Self-exclusion | Business rule | In-process CTE excludes `BR.PositionID <> @PositionID` to avoid the target position appearing in the deduction sum |
| TotalWireDeposits naming | Legacy | Column name is misleading; it represents the eligibility verdict, not wire deposit data |
| NOLOCK throughout | Concurrency | All reads use NOLOCK |
| PlayerLevelID dynamic lookup | Design | Unlike the NFT version, this procedure queries `Customer.Customer` to get the player level, avoiding stale caller-supplied data |

---

## 8. Sample Queries

### 8.1 Check standard redemption eligibility for a position
```sql
EXEC Billing.GetRedeemValidationData
    @CID = 12345678,
    @PositionID = 9876543,
    @Invested = 250.00;
-- TotalWireDeposits > 0: eligible; = 0: not eligible
-- TotalRedeemedInvested: current position value
```

### 8.2 Compare standard vs NFT redemption eligibility checks (structure comparison)
```sql
-- Standard redemption (derives country/level from Customer.Customer):
EXEC Billing.GetRedeemValidationData @CID = 12345678, @PositionID = 987654, @Invested = 250.00;

-- NFT redemption (requires explicit @CountryID + @PlayerLevelID):
EXEC Billing.GetRedeemNFTValidationData @CID = 12345678, @CountryID = 74, @PlayerLevelID = 1, @Invested = 250.00;
```

### 8.3 View customer's redeemable equity context
```sql
SELECT
    cc.CID,
    cc.PlayerLevelID,
    cc.CountryID,
    cm.RealizedEquity,
    mim.TotalDeposit AS AllTimeDeposits
FROM Customer.Customer cc WITH (NOLOCK)
INNER JOIN Customer.CustomerMoney cm WITH (NOLOCK) ON cm.CID = cc.CID
LEFT JOIN BackOffice.CustomerMIMOAllTimeAggregatedData mim WITH (NOLOCK) ON mim.CID = cc.CID
WHERE cc.CID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Redeem Operations Migration Plan](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13273466659) | Confluence | Found via search (updated 2026-02-11, space MG) - page content restricted, no facts extracted |
| [HLD: Redeem service](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11685691393) | Confluence | High-level design document for Redeem service (updated 2025-02-10, space MG) - page content restricted, no facts extracted |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 2 Confluence found (content restricted) + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetRedeemValidationData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRedeemValidationData.sql*

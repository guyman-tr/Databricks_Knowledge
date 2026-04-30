# Review Needed: BI_DB_dbo.BI_DB_EY_Audit_Cashouts

## 1. Tier Verification

| # | Column | Tier | Review Item |
|---|--------|------|-------------|
| 9 | Amount | Tier 1 — History.Credit | Fact_CustomerAction.Amount is described as "Position size in currency" in FCA wiki, but for cashout ActionTypeIDs (8,11,12,13,37), Amount represents the cashout/refund amount from History.Credit, not a position size. The inherited description was adapted to clarify this context. Verify that Amount for cashout events indeed comes from History.Credit CreditAmount. |
| 5 | ActionType | Tier 2 | For ActionTypeID=8, 'Cashout' is hardcoded as a string literal rather than looked up from Dim_ActionType. Confirm this is intentional (it matches Dim_ActionType.Name for ID=8). |

## 2. Data Quality

| Item | Detail |
|------|--------|
| BaseExchangeRate/ExchangeFee as varchar | These columns store numeric values as varchar(50). This is a type mismatch vs their source (numeric(38,8) in BI_DB_DepositWithdrawFee). Downstream consumers must CAST before arithmetic. Consider ALTER to numeric type if this table is ever refactored. |
| Auto-backfill gap detection | The SP checks MAX(DateID) from `BI_DB_EY_Audit_Deposits` (the deposit sibling), not from `BI_DB_EY_Audit_Cashouts` itself. If deposits ran but cashouts failed, gaps in cashouts may not be detected. |
| PaymentMethod join path | PaymentMethod resolves through `Dim_BillingDepot.FundingTypeID → Dim_FundingType.Name`, not directly from `Fact_BillingWithdraw.FundingTypeID_Funding`. This means the payment method reflects the depot's configured funding type, which may differ from the actual funding instrument used. |

## 3. Missing Context

| Item | Detail |
|------|--------|
| BI_DB_EY_Audit_Deposits wiki | The sibling deposit table is referenced as an unresolved upstream in the bundle. Cross-reference when its wiki is available. |
| Downstream consumers | No views, SPs, or reports found consuming this table. Confirm with the EY audit team whether this feeds any external reporting tool. |

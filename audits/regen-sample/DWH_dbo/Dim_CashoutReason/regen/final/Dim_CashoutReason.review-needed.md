# Review Needed: DWH_dbo.Dim_CashoutReason

## Review Items

### 1. Downstream Fact Table References
- The upstream wiki lists `Billing.Withdraw` and `History.WithdrawAction` as primary consumers. The DWH equivalent fact tables (e.g., `Fact_BillingWithdraw`) should be verified as actual consumers of `CashoutReasonID` in this schema.

### 2. No DWH Surrogate Key
- Unlike many other Dim tables loaded by SP_Dictionaries_DL_To_Synapse (e.g., Dim_CashoutStatus has DWHCashoutStatusID), Dim_CashoutReason does NOT have a DWHCashoutReasonID column. This is by design in the DDL -- confirm no downstream joins expect one.

### 3. Typo in Production Data
- Row 18 Name = "Transfered by CryptoWallet" -- likely a typo for "Transferred". This exists in production Dictionary.CashoutReason and is inherited as-is. No action needed on DWH side.

---

*Tier summary: 2 Tier 1, 1 Tier 2, 0 Tier 3, 0 Tier 4*
*No Tier 4 columns -- all columns fully grounded in upstream wiki or SP code.*

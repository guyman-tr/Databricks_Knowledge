# Review Needed: BI_DB_dbo.BI_DB_PaymentSent_Results

## 1. Tier 2 Columns Without Upstream Wiki

The following columns are Tier 2 because their source external tables have no upstream wiki documentation in the bundle:

- **CID** — Read from External_etoro_Billing_Withdraw (fbd.[CID]). No wiki for Billing.Withdraw found. The SP joins Dim_Customer only for RegulationID, not to source CID. Confirm CID semantics match the platform-wide customer ID.
- **Amount$Withdraw** — From External_etoro_Billing_vWithdrawToFunding.Amount. No wiki for Billing.vWithdrawToFunding found. Confirm column semantics (is this always in the process currency, or could it be in account currency?).
- **WithdrawID** — From External_etoro_Billing_Withdraw.WithdrawID. No wiki for Billing.Withdraw found. Confirm this is the primary withdrawal request ID.
- **WithdrawProcessingID** — Renamed from External_etoro_Billing_vWithdrawToFunding.ID. Confirm this is the withdraw-to-funding processing record ID.
- **FundingID** — From External_etoro_Billing_vWithdrawToFunding.FundingID. Confirm this links to the funding instrument record.
- **Provider** — Renamed from External_etoro_Billing_Depot.Name. Confirm this is the payment provider/depot name.

## 2. Business Logic Questions

- **CAD effective exclusion (potential SP bug)**: The SP includes CAD (ProcessCurrencyID=7) in the #cashouts currency filter but the #final WHERE clause has four OR-branches (USD/EUR, AUD+CySEC, AUD+non-CySEC, GBP) — none of which match CAD. As a result, CAD rows are always excluded from the final output. This should be reviewed: was CAD intentionally excluded at the final stage, or was a WHERE-branch for CAD accidentally omitted?
- **Table emptiness**: Table was empty (0 rows) at time of documentation. This appears to be a valid operational state but should be confirmed — is the SP currently scheduled and running?

## 3. CashoutStatusID=6 Gap

The SP filters on CashoutStatusID=6 ("Payment Sent") in the history external table, but DWH Dim_CashoutStatus only contains IDs 0-4. Status ID 6 is a production-only value not in the DWH dimension. This is by design (the SP reads from production external tables, not DWH dims for this filter), but worth noting for analysts who may try to resolve the status via Dim_CashoutStatus.

## 4. UC Target

No Unity Catalog target identified. Confirm whether this operational monitoring table should be migrated to Databricks.

# Lineage: BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdraw

## Source Objects

| Source Object | Schema | Role | Wiki |
|--------------|--------|------|------|
| DWH_dbo.Fact_BillingWithdraw | DWH_dbo | Primary withdrawal fact — provides FundingID, CID, Amount_WithdrawToFunding, WithdrawID, ModificationDate, CashoutStatusID_Funding | [Fact_BillingWithdraw.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_BillingWithdraw.md) |
| DWH_dbo.Dim_Customer | DWH_dbo | Customer filter — IsValidCustomer=1, IsDepositor=1, VerificationLevelID>=2 | [Dim_Customer.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md) |
| BI_DB_dbo.External_etoro_Billing_Funding | BI_DB_dbo | Funding instrument metadata — provides IsBlocked flag | (no wiki) |
| BI_DB_dbo.SP_AML_Multiple_Accounts | BI_DB_dbo | Writer SP — Step 12 populates this table (TRUNCATE + INSERT) | (SP code in SSDT) |

## Column Lineage

| DWH Column | Source Object | Source Column | Transform | Tier |
|-----------|--------------|---------------|-----------|------|
| FundingID | DWH_dbo.Fact_BillingWithdraw | FundingID | Passthrough (grouping key for multi-account detection; filtered to FundingID NOT IN 1-7, HAVING COUNT(DISTINCT CID) >= 2) | Tier 1 — Billing.Withdraw |
| IsBlocked | BI_DB_dbo.External_etoro_Billing_Funding | IsBlocked | Intended: passthrough. **BUG**: SP Step 12 INSERT swaps IsBlocked and Total_Users column positions — this column actually receives the Total_Users COUNT value | Tier 3 — External_etoro_Billing_Funding (no upstream wiki) |
| Total_Users | DWH_dbo.Fact_BillingWithdraw | COUNT(DISTINCT CID) | ETL-computed: count of distinct customers using this FundingID for withdrawals. **BUG**: SP Step 12 INSERT swaps — this column actually receives the IsBlocked flag value | Tier 2 — SP_AML_Multiple_Accounts |
| Group_Type | DWH_dbo.Fact_BillingWithdraw | COUNT(DISTINCT CID) | ETL-computed: CASE bucket on user count (5-20, 21-50, 51-500, 500+). Computed correctly before the swap occurs | Tier 2 — SP_AML_Multiple_Accounts |
| Last_Withdraw_Date | DWH_dbo.Fact_BillingWithdraw | ModificationDate | ETL-computed: MAX(ModificationDate) across all withdrawals for this FundingID | Tier 2 — SP_AML_Multiple_Accounts |
| Total_Approved_Withdraw | DWH_dbo.Fact_BillingWithdraw | Amount_WithdrawToFunding | ETL-computed: SUM(Amount_WithdrawToFunding) WHERE CashoutStatusID_Funding=3 (Approved) | Tier 2 — SP_AML_Multiple_Accounts |
| Num_Approved_Withdraw | DWH_dbo.Fact_BillingWithdraw | WithdrawID | ETL-computed: COUNT(DISTINCT WithdrawID) WHERE CashoutStatusID_Funding=3 (Approved) | Tier 2 — SP_AML_Multiple_Accounts |
| UpdateDate | — | — | ETL-computed: GETDATE() at SP execution time | Tier 2 — SP_AML_Multiple_Accounts |

---
*Generated: 2026-04-28*

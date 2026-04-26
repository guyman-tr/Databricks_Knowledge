# Lineage: BI_DB_dbo.BI_DB_LargeCashoutReport

## Source Chain

| Hop | Object | Type | Role |
|-----|--------|------|------|
| 0 | BI_DB_LargeCashoutReport | Synapse Table | Documentation target |
| 1 | SP_LargeCashOutReport | Synapse SP | Primary writer — TRUNCATE + INSERT, daily |
| 2 | BI_DB_dbo.External_etoro_Billing_Withdraw | Synapse External Table | Live withdrawal queue — CID, RequestDate, Amount, CashoutStatusID, CashoutReasonID |
| 3 | DWH_dbo.Dim_Customer | Synapse Table | CustomerName (FirstName+LastName), AccountManagerID, eligibility filters |
| 3 | DWH_dbo.Dim_Manager | Synapse Table | AccountManager (FirstName+LastName) |
| 3 | DWH_dbo.Dim_Country | Synapse Table | Country name + Region label |
| 3 | DWH_dbo.V_Liabilities | Synapse View | CurrentEquity = Liabilities + ActualNWA at yesterday's DateID |
| 3 | BI_DB_dbo.External_etoro_BackOffice_CustomerAllTimeAggregatedData | Synapse External Table | TotalDeposits (all-time customer deposit aggregate) |
| 3 | #desk (hardcoded temp table) | SP construct | Region → Desk mapping (19 regions → 8 desks) |

## T1 Copy Verification

| Column | Source Wiki File | Source Description Used | Verified |
|--------|-----------------|------------------------|---------|
| CID | DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md row 4 | "Customer ID. FK to Customer.CustomerStatic" (Tier 1 — Billing.Withdraw) | ✓ |
| CustomerName | DWH_dbo/Tables/Dim_Customer.md rows 9-10 | FirstName + LastName "Tier 1 — Customer.CustomerStatic" | ✓ |
| RequestDate | DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md row 7 | "Timestamp when the customer submitted the withdrawal request" (Tier 1 — Billing.Withdraw) | ✓ |
| Amount | DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md row 8 | "Gross withdrawal amount in CurrencyID denomination" (Tier 1 — Billing.Withdraw) | ✓ |
| Country | DWH_dbo/Tables/Dim_Country.md row 4 | "Full country name in English. Unique per row." (Tier 1 — Dictionary.Country) | ✓ |

T1 columns: 5 / 14 total. Remaining 8 are Tier 2 (SP-derived), 1 Propagation.

## Upstream Production Sources

| Column(s) | Production Source | Via |
|-----------|------------------|-----|
| CID, RequestDate, Amount, CashoutStatusID, CashoutReasonID | etoro.Billing.Withdraw | External_etoro_Billing_Withdraw |
| CustomerName | Customer.CustomerStatic | DWH_dbo.Dim_Customer.FirstName + LastName |
| Country | Dictionary.Country | DWH_dbo.Dim_Country.Name |
| AccountManager | BackOffice.Manager | DWH_dbo.Dim_Manager.FirstName + LastName |
| Region | Dictionary.MarketingRegion | DWH_dbo.Dim_Country.Region |
| CashoutStatus | Dictionary.CashoutStatus (via ID) | SP: CashoutStatusID → 'Pending'/'InProcess' |
| AffiliateCO | Billing.Withdraw.CashoutReasonID | SP: CASE WHEN ID IN (14,15) THEN 1 ELSE 0 |
| Desk | SP hardcoded lookup | #desk table: Region → Desk string |
| DaysFromCoRequest | Computed | SP: business-days DATEDIFF from RequestDate to GETDATE() |
| CurrentEquity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA at yesterday |
| TotalDeposits | BackOffice.CustomerAllTimeAggregatedData | External_etoro_BackOffice_CustomerAllTimeAggregatedData.TotalDeposit |
| UpdateDate | ETL | GETDATE() |

## UC Target

`_Not_Migrated` — no entry found in `main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables`. Live compliance queue; contains PII — not a lake export candidate.

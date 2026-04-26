# Column Lineage: BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Cashouts

## Source Objects
| Source | Type | Relationship |
|--------|------|-------------|
| DWH_dbo.Fact_BillingWithdraw | Table | Primary source (withdrawal requests + payment legs) |
| DWH_dbo.Dim_Customer | Table | Customer validation (VerificationLevelID, IsValidCustomer) |
| DWH_dbo.Dim_Country | Table | Region lookup via customer CountryID |
| DWH_dbo.Dim_Regulation | Table | Regulation name lookup |
| DWH_dbo.Dim_FundingType | Table | FundingType name for SLA logic branching |

## Column Lineage
| # | Target Column | Source Table | Source Column | Transform |
|---|--------------|-------------|---------------|-----------|
| 1 | WithdrawID | Fact_BillingWithdraw | WithdrawID | Passthrough (bigint in target vs int in source) |
| 2 | CurrencyID | Fact_BillingWithdraw | CurrencyID | Passthrough |
| 3 | FundingTypeID | Fact_BillingWithdraw | FundingTypeID_Funding / FundingTypeID_Withdraw | CASE: IF FundingTypeID_Funding IS NULL THEN FundingTypeID_Withdraw ELSE FundingTypeID_Funding |
| 4 | CID | Fact_BillingWithdraw | CID | Passthrough |
| 5 | ManagerID | Fact_BillingWithdraw | ManagerID (implicit via Billing.Withdraw) | Passthrough |
| 6 | CashoutStatusID | Fact_BillingWithdraw | CashoutStatusID_Withdraw | Passthrough (always 3 due to filter) |
| 7 | RequestDate | Fact_BillingWithdraw | RequestDate | Passthrough |
| 8 | Amount | Fact_BillingWithdraw | Amount_Withdraw | Passthrough |
| 9 | Commission | Fact_BillingWithdraw | Commission | Passthrough |
| 10 | Approved | Fact_BillingWithdraw | Approved | Passthrough |
| 11 | IPAddress | Fact_BillingWithdraw | IPAddress (implicit) | Passthrough (bigint in target) |
| 12 | ModificationDate | Fact_BillingWithdraw | ModificationDate | Passthrough |
| 13 | Remark | — | — | Tier 3 — not clearly mapped in SP; possibly from Billing.Withdraw comment/remark field |
| 14 | Comment | Fact_BillingWithdraw | Comment | Passthrough |
| 15 | Fee | Fact_BillingWithdraw | Fee | Passthrough |
| 16 | FundingID | Fact_BillingWithdraw | FundingID | Passthrough (bigint in target vs int in source) |
| 17 | RequestorComments | — | — | Tier 3 — not clearly mapped; possibly from Billing.Withdraw |
| 18 | SessionID | Fact_BillingWithdraw | SessionID (implicit) | Passthrough |
| 19 | CashoutReasonID | Fact_BillingWithdraw | CashoutReasonID | Passthrough |
| 20 | SuggestedBonusDeductionAmount | — | — | Tier 3 — from Billing.Withdraw (not in Fact_BillingWithdraw wiki) |
| 21 | ActualBonusDeductionAmount | — | — | Tier 3 — from Billing.Withdraw (not in Fact_BillingWithdraw wiki) |
| 22 | ClientWithdrawReasonID | Fact_BillingWithdraw | ClientWithdrawReasonID | Passthrough |
| 23 | ClientWithdrawReasonComment | — | — | Tier 3 — from Billing.Withdraw (not in Fact_BillingWithdraw wiki) |
| 24 | ReqCyTime | Fact_BillingWithdraw | RequestDate | Alias (same value as RequestDate) |
| 25 | ModCyTime | Fact_BillingWithdraw | ModificationDate | Alias (same value as ModificationDate) |
| 26 | VerificationLevelID | Dim_Customer | VerificationLevelID | Lookup via CID = RealCID |
| 27 | RequestDay | Fact_BillingWithdraw | RequestDate | DATEPART(dw, RequestDate) |
| 28 | Month | Fact_BillingWithdraw | ModificationDate | DATEPART(month, ModificationDate) |
| 29 | Year | Fact_BillingWithdraw | ModificationDate | DATEPART(year, ModificationDate) |
| 30 | UserFeedbackIssue | — | — | Tier 3 — origin unclear; possibly from Billing.Withdraw |
| 31 | Region | Dim_Country | Region | Lookup via Dim_Customer.CountryID -> Dim_Country.CountryID |
| 32 | Regulation | Dim_Regulation | Name | Lookup via Dim_Customer.RegulationID -> Dim_Regulation.ID |
| 33 | ProcessMonth | Fact_BillingWithdraw | ProcessorValueDate | DATEPART(month, ProcessorValueDate) or ModificationDate |
| 34 | ProcessYear | Fact_BillingWithdraw | ProcessorValueDate | DATEPART(year, ProcessorValueDate) or ModificationDate |
| 35 | ProcessDay | Fact_BillingWithdraw | ProcessorValueDate | DATEPART(dw, ProcessorValueDate) or ModificationDate |
| 36 | HoursBetween | Fact_BillingWithdraw | RequestDate, ModificationDate | DATEDIFF(hh, RequestDate, ModificationDate) |
| 37 | SLA | — | — | ETL-computed: complex CASE logic based on date era, funding type, currency, regulation, day of week |
| 38 | SLA48 | — | — | ETL-computed: extended 2-day SLA threshold |
| 39 | UpdateDate | — | — | ETL-computed: GETDATE() at SP execution |
| 40 | WD_ID_SLA | Fact_BillingWithdraw | WithdrawID + SLA | MIN(SLA) across all funding legs per WithdrawID — 'OverallSLA' or 'OverallNotSLA' |
| 41 | WD_ID_SLA48 | Fact_BillingWithdraw | WithdrawID + SLA48 | MIN(SLA48) across all funding legs per WithdrawID — 'OverallSLA48' or 'OverallNotSLA48' |
| 42 | SLA5days | — | — | ETL-computed: 5-day extended SLA threshold |
| 43 | WD_ID_SLA5days | Fact_BillingWithdraw | WithdrawID + SLA5days | MIN(SLA5days) across all funding legs per WithdrawID |
| 44 | ModificationDateID | — | — | Not populated (NULL in all rows) — column exists in DDL but excluded from INSERT statement |

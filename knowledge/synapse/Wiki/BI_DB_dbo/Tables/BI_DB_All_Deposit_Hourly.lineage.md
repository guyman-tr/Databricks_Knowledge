# BI_DB_dbo.BI_DB_All_Deposit_Hourly — Column Lineage

## Source Objects

| Source | Type | Relationship |
|--------|------|-------------|
| (Unknown) | Unknown | No writer SP found in SSDT; table is fully orphaned |

## Column Lineage

All 117 columns are Tier 4 (inferred). No writer SP exists in the Synapse SSDT repo.

**Core Deposit Fields (columns 1-36)** — likely sourced from Billing.Deposit/Billing.Funding production tables via an on-prem ETL that was never re-implemented in Synapse.

**PSP Response Fields (columns 37-125)** — flattened payment service provider (PSP) response payload attributes. The `*AsString`, `*AsDecimal`, `*AsInteger` naming convention indicates these were dynamically extracted from JSON/XML payment gateway responses.

| # | Synapse Column | Source Table | Source Column | Transform | Confidence |
|---|---------------|-------------|---------------|-----------|------------|
| 1 | CID | Unknown | Unknown | Likely Billing.Deposit.CID or customer FK | Tier 4 |
| 2 | DepositID | Unknown | Unknown | Likely Billing.Deposit.ID or Billing.Funding.ID | Tier 4 |
| 3 | FundingType | Unknown | Unknown | Likely Dim_FundingType.Name (CC, Wire, PayPal, etc.) | Tier 4 |
| 4 | Amount In Orig Curr | Unknown | Unknown | Deposit amount in original currency | Tier 4 |
| 5 | Amount in $ | Unknown | Unknown | Deposit amount converted to USD | Tier 4 |
| 6 | Currency | Unknown | Unknown | Original deposit currency code | Tier 4 |
| 7 | ModificationDate | Unknown | Unknown | Last modification timestamp of the deposit record | Tier 4 |
| 8 | Deposit Time | Unknown | Unknown | Deposit creation/submission timestamp | Tier 4 |
| 9 | Month | Unknown | Unknown | Month extracted from deposit date | Tier 4 |
| 10 | Day | Unknown | Unknown | Day extracted from deposit date | Tier 4 |
| 11 | Year | Unknown | Unknown | Year extracted from deposit date | Tier 4 |
| 12 | PaymentStatus | Unknown | Unknown | Payment processing status (e.g., Approved, Declined, Pending) | Tier 4 |
| 13 | Country (customer) | Unknown | Unknown | Customer's registered country | Tier 4 |
| 14 | FirstDepositDate | Unknown | Unknown | Customer's first deposit date for FTD analysis | Tier 4 |
| 15 | Funnel | Unknown | Unknown | Customer acquisition funnel stage | Tier 4 |
| 16 | FunnelFrom | Unknown | Unknown | Source funnel for funnel transition tracking | Tier 4 |
| 17 | BINCountry | Unknown | Unknown | Country derived from card BIN (Bank Identification Number) | Tier 4 |
| 18 | Provider | Unknown | Unknown | Payment provider/PSP name | Tier 4 |
| 19 | CardType | Unknown | Unknown | Card type (Visa, Mastercard, etc.) | Tier 4 |
| 20 | CardSubType | Unknown | Unknown | Card sub-type (Debit, Credit, Prepaid) | Tier 4 |
| 21 | IsFTD | Unknown | Unknown | First-time deposit flag (1=FTD, 0=redeposit) | Tier 4 |
| 22 | Country By Reg IP | Unknown | Unknown | Country from registration IP geolocation | Tier 4 |
| 23 | Deposit Risk Status | Unknown | Unknown | Risk assessment status for the deposit | Tier 4 |
| 24 | RiskStatus | Unknown | Unknown | Overall risk classification | Tier 4 |
| 25 | External Transaction ID | Unknown | Unknown | PSP external transaction reference | Tier 4 |
| 26 | Region | Unknown | Unknown | Marketing/geographic region | Tier 4 |
| 27 | Affiliate ID | Unknown | Unknown | Referring affiliate ID | Tier 4 |
| 28 | Account Manager | Unknown | Unknown | Assigned account manager name | Tier 4 |
| 29 | BinCode | Unknown | Unknown | Card BIN code (first 6-8 digits) | Tier 4 |
| 30 | Bank name by Bincode | Unknown | Unknown | Issuing bank name resolved from BIN | Tier 4 |
| 31 | Regulation | Unknown | Unknown | Active regulatory jurisdiction | Tier 4 |
| 32 | DesignatedRegulation | Unknown | Unknown | Designated (original) regulatory jurisdiction | Tier 4 |
| 33 | MID | Unknown | Unknown | Merchant ID for the payment transaction | Tier 4 |
| 34 | UpdateDate | Unknown | Unknown | ETL last-update timestamp | Tier 5 |
| 35 | Response | Unknown | Unknown | Full PSP response text (varchar(max)) | Tier 4 |
| 36 | ModificationDateID | Unknown | Unknown | Integer date key for ModificationDate | Tier 4 |
| 37-125 | (PSP Response Fields) | Unknown | Unknown | Flattened PSP response attributes — see wiki Section 4 | Tier 4 |
| 126 | BaseExchangeRate | Unknown | Unknown | Exchange rate used for USD conversion | Tier 4 |
| 127 | Category | Unknown | Unknown | Deposit category classification | Tier 4 |
| 128 | DepotID | Unknown | Unknown | Depot/sub-account identifier | Tier 4 |

## Lineage Notes

- **Fully orphaned**: No stored procedure in the Synapse SSDT repo reads or writes this table
- **Not in OpsDB**: No orchestration entry exists
- **Not in Generic Pipeline**: No Bronze/lake mapping found
- **PSP payload pattern**: ~80 columns follow `{FieldName}AsString`/`AsDecimal`/`AsInteger` convention — dynamically extracted from payment gateway JSON/XML responses
- **Likely origin**: On-prem BI_DB hourly deposit monitoring report with full PSP response payload, never re-implemented in Synapse. Possibly replaced by Databricks payment analytics or direct PSP reporting integrations
- **Related tables**: BI_DB_AllDeposits_Tempalte has a similar structure (126 cols) — likely the template/master version

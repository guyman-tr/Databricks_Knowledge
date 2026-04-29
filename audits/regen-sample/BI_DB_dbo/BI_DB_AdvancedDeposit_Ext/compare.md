# Compare — `BI_DB_dbo.BI_DB_AdvancedDeposit_Ext`

**Bucket**: `slop`

**Verdict**: **WORSE**  (score delta -1.15; slop 47 -> 0 (delta -47))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.75 | 6.6 | -1.15 |
| Slop hits (`Tier 4 ... inferred`) | 47 | 0 | -47 |
| Element rows | 47 | 47 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 0 | 47 | +47 |
| T3 count | 0 | 0 | +0 |
| T4 count | 47 | 0 | -47 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 7 | 9 |
| completeness | 8 | 8 |
| data_evidence | 5 | 7 |
| shape_fidelity | 7 | 8 |
| tier_accuracy | 10 | 3 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `40` | 0.082 | 4 | 2 | Original acquisition funnel (may differ from current funnel if customer changed). (Tier 4 — inferred from column name) | Customer's originating registration funnel name. Dim-lookup from Dim_Funnel.Name (aliased df2) joined on Dim_Customer.FunnelFromID — identifies the marketing funnel that originally brought the custome |
| `39` | 0.087 | 4 | 2 | Registration funnel name at time of deposit. (Tier 4 — inferred from column name) | Deposit-level funnel name. Dim-lookup from Dim_Funnel.Name (aliased df) joined on fbd.FunnelID — identifies the marketing funnel associated with this specific deposit transaction. (Tier 2 — SP_H_Depos |
| `11` | 0.088 | 4 | 2 | Timestamp of the last modification to the deposit record. (Tier 4 — inferred from column name) | UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection. Passthrough from Fact_BillingDeposit.ModificationDate. (Tier 2 — SP_H_Deposits code analysi |
| `33` | 0.095 | 4 | 2 | Customer's marketing region. From Dim_Country. (Tier 4 — inferred from column name) | Marketing region name. Lookup from External_etoro_Dictionary_MarketingRegion.Name via Dim_Country.MarketingRegionID, where Dim_Country is joined via Dim_Customer.CountryID. (Tier 2 — SP_H_Deposits cod |
| `43` | 0.117 | 4 | 2 | Card network type (e.g., Visa, Mastercard, Amex). (Tier 4 — inferred from column name) | Card brand/network name. Dim-lookup from Dim_CardType.CarTypeName (note: source column has historical typo "CarTypeName" instead of "CardTypeName") joined on fbd.CardTypeIDAsInteger. (Tier 2 — SP_H_De |
| `3` | 0.127 | 4 | 2 | Funding record identifier. Links to Billing.Funding payment processing record. (Tier 4 — inferred from column name) | Payment instrument identifier (credit card, bank account, e-wallet) used for this deposit. Passthrough from Fact_BillingDeposit.FundingID. FK to Billing.Funding. (Tier 2 — SP_H_Deposits code analysis) |
| `13` | 0.132 | 4 | 2 | IP address of the depositor at transaction time, stored as numeric. PII field. (Tier 4 — inferred from column name) | Customer IP address at deposit time stored as a 32-bit integer. PII — used for fraud detection and geo-verification. Passthrough from Fact_BillingDeposit.IPAddress. (Tier 2 — SP_H_Deposits code analys |
| `19` | 0.137 | 4 | 2 | Whether this deposit is the customer's first-time deposit. 1=FTD, 0=subsequent. (Tier 4 — inferred from column name) | First Time Deposit flag. 1 = customer's first approved deposit; 0 = repeat deposit. Passthrough from Fact_BillingDeposit.IsFTD. DDL type narrowing: source is int, this DDL uses bit. (Tier 2 — SP_H_Dep |
| `46` | 0.15 | 4 | 2 | Payment processor/depot name handling the transaction. (Tier 4 — inferred from column name) | Human-readable depot/payment-processor name. Dim-lookup from Dim_BillingDepot.Name joined on fbd.DepotID. Identifies the acquirer or gateway configuration used for this deposit. (Tier 2 — SP_H_Deposit |
| `38` | 0.158 | 4 | 2 | Affiliate serial ID for attribution tracking. (Tier 4 — inferred from column name) | Affiliate (partner) ID under which the customer was acquired. Dim-lookup from Dim_Customer.AffiliateID (production origin: Customer.CustomerStatic.SerialID, renamed in DWH). NULL for direct/organic re |

## Top issues — regen wiki (per judge)

- [critical] `ALL 47 columns` — Defective upstream bundle reported 'NO UPSTREAM WIKI was resolvable' but wikis exist in the repo for Fact_BillingDeposit, Dim_PaymentStatus, Dim_Customer, Dim_Country, Dim_Funnel, Dim_CountryBin, Dim_CardType, Dim_BillingDepot, Dim_Affiliate. ~40 columns should be Tier 1 with verbatim descriptions but are all tagged Tier 2.
- [high] `DepositID` — Description paraphrases upstream. Upstream: 'Primary distribution key (HASH). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Clustered index key in DWH.' Wiki: 'Unique identifier for each deposit attempt.' Lost HASH distribution key, IDENTITY, clustered index key.
- [high] `PaymentStatusID` — Upstream has rich enum values: '1=New, 2=Approved (73%), 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE (10.2%). Full 39-value enum.' Wiki drops all enum values and distributions.
- [high] `Amount` — Upstream notes: 'As of 2025-04-17, capped via CASE expression in ETL to prevent extreme outlier values from distorting aggregations.' Wiki drops the ETL capping rule entirely.
- [high] `Country, Funnel, FunnelFrom, AcquisitionFunnel, PaymentStatus_Name` — Dim-lookup passthroughs cite SP relay (Tier 2 — SP_H_Deposits) instead of root dictionary origin. Country should be Tier 1 — Dictionary.Country, Funnel/FunnelFrom/AcquisitionFunnel should be Tier 1 — Dictionary.Funnel, PaymentStatus_Name should be Tier 1 — Dictionary.PaymentStatus.
- [medium] `RiskManagementStatusID` — Upstream has '69 distinct risk reason codes. Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation.' Wiki retains NULL semantics but drops all enum details.
- [medium] `Section 4 Elements` — No inline enum key=value pairs for PaymentStatus_Name or IsFTD despite upstream wikis documenting them. PaymentStatus has 7+ known values, IsFTD has binary 0/1 with ~60.6% FTD=1 distribution.

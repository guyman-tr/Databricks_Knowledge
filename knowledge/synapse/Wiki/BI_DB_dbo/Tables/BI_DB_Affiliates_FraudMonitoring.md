# BI_DB_dbo.BI_DB_Affiliates_FraudMonitoring

| Attribute | Value |
|-----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_M_Affiliates_FraudMonitoring |
| **SP Author** | Michail Vryoni (2024-03-04; updated 2025-10-08) |
| **Refresh Pattern** | DELETE WHERE RegisteredID=@StartDateID + INSERT (monthly replace — one month's cohort replaced per run) |
| **Frequency** | Monthly |
| **UC Target** | `_Not_Migrated` |
| **Distribution** | ROUND_ROBIN |
| **Index** | HEAP |
| **Row Count** | 33–380 rows per registration month (2025-11 to 2026-03 sample) |
| **Columns** | 31 |

---

## Summary

Monthly fraud monitoring table for affiliate-acquired customers. Contains customers who registered under an affiliate in a given calendar month AND whose affiliate triggered ≥3 of 5 primary fraud alert signals. Only fraudulent or suspicious affiliates appear — the vast majority of affiliates are excluded by the selection filter.

Grain: one row per customer per calendar month (keyed by registration month via RegisteredID). History is retained — monthly cohorts accumulate over time. The SP is idempotent for a given month: re-running deletes and re-inserts that month's rows.

---

## Business Context

Supports the Affiliate Fraud team's monthly review of suspicious affiliate activity patterns. The six fraud signals cover common affiliate-fraud playbooks: high-conversion cookie stuffing, low-value deposit farms, IP clustering, geographic clustering, rapid fund withdrawal, and low-trading churn patterns.

**Fraud Alert Signal Definitions**:

| Alert Column | Signal | Threshold | Fraud Pattern |
|-------------|--------|-----------|---------------|
| ConversionAlert | FTD conversion rate | Conversion > 70% | Implausibly high conversion (normal ~10–30%) — possible click fraud or forced registrations |
| FTDAAlert | Average first deposit | AvgFTDA < $50 USD | Minimal-deposit accounts — likely fake/bot registrations to claim signup bonuses |
| SameIPAlert | Shared IP clustering | %SameIP > 0 AND count > 1 | Multiple customers registered from the same IP — possible bulk registration |
| SameCountryIPAlert | IP-country clustering | %SameCountry > 30% | >30% of affiliate's customers have same registration IP country — geographic clustering |
| LowTradingAlert | Low-trading risk flag | %LowTrading > 20% | >20% of depositors have RiskStatusID 82 (withdraw with short-term trades) or 83 (low-trading ratio) — deposit-and-withdraw pattern |
| ChurnAlert | 10-day equity churn | %Churn > 20% | >20% of depositors had zero equity within 10 days of first deposit — rapid withdrawal after deposit |

**Selection filter**: Only affiliates where `ConversionAlert + FTDAAlert + SameIPAlert + SameCountryIPAlert + LowTradingAlert >= 3` are included. Note: **ChurnAlert is excluded from this sum** — it contributes to per-customer row data but does not count toward the selection threshold.

**Scale**: Very selective output — typically 2–10 suspicious affiliates per month (2025-11 to 2026-03), with 33–380 customer rows.

**Date handling**: If `@Date >= EOMONTH(GetDate(), -1)` (current or future month requested), the SP caps `@Date` to last month-end. This prevents partial-month processing.

---

## ETL / Refresh

**Pattern**: DELETE WHERE RegisteredID=@StartDateID followed by INSERT. Running for the same month twice replaces that month's data cleanly. The SP processes the full calendar month for `@Date` (first to last day of the month).

**Registration month scope**: Population = customers with `registered >= StartDate AND registered <= EndDate` (the calendar month boundaries), linked to `Dim_Affiliate.AccountActivated=1` affiliates.

**Churn definition**: A customer "churned" if their total equity (Liabilities + ActualNWA from V_Liabilities) was zero at any point within 10 days of their first deposit date. Sourced from V_Liabilities, which is a Synapse view.

**Low-trading risk definition** (from External_etoro_BackOffice_CustomerRisk):
- RiskStatusID = 82: `WithdrawWithShortTermTrades`
- RiskStatusID = 83: `WithdrawWithLowTradingRatio`

---

## Column Catalog

| # | Column | Type | Tier | Description |
|---|--------|------|------|-------------|
| 1 | AffiliateID | int NULL | T1 — Customer.CustomerStatic | Affiliate (partner) ID under which the customer was acquired. Sourced from BI_DB_CIDFirstDates.SerialID (= Dim_Customer.AffiliateID). FK to Dim_Affiliate and fiktivo affiliate system. |
| 2 | CID | int NULL | T1 — Customer.CustomerStatic | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. |
| 3 | GCID | int NULL | T1 — Customer.CustomerStatic | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. |
| 4 | registered | datetime NULL | T2 — SP_CIDFirstDates | Customer registration date. MIN(RegisteredDemo, RegisteredReal) — whichever happened first. Sourced from BI_DB_CIDFirstDates.registered. |
| 5 | RegisteredID | bigint NULL | T2 — SP_M_Affiliates_FraudMonitoring | Registration year-month as a YYYYMM integer. CAST(CONVERT(VARCHAR(6), registered, 112) AS INT). Used as the partition key for DELETE/INSERT monthly replacement. |
| 6 | Country | varchar(max) NULL | T2 — SP_CIDFirstDates | Customer's country of residence name. Resolved from Dim_Country.Name via BI_DB_CIDFirstDates.CountryID at the time of CIDFirstDates computation. |
| 7 | FirstDepositAmount | money NULL | T2 — SP_Dim_Customer | Amount of first successful deposit in USD. Sourced from BI_DB_CIDFirstDates.FirstDepositAmount (= Dim_Customer.FirstDepositAmount from CustomerFinanceDB.FirstTimeDeposits.FTDAmountInUsd). Default 0 for non-depositors. |
| 8 | IsFTD | int NULL | T2 — SP_M_Affiliates_FraudMonitoring | First-Time Depositor flag: 1 if the customer has a valid first deposit (YEAR(FirstDepositDate) ≠ 1900), 0 if no deposit (sentinel year 1900 in BI_DB_CIDFirstDates). |
| 9 | AvgFTDA | money NULL | T2 — SP_M_Affiliates_FraudMonitoring | Average first deposit amount in USD for depositing customers (IsFTD=1) registered under this affiliate in this country. AVG(FirstDepositAmount) per affiliate × country. NULL if no depositors from this affiliate-country combination. |
| 10 | Conversion | numeric(10,4) NULL | T2 — SP_M_Affiliates_FraudMonitoring | Affiliate's FTD conversion rate: SUM(IsFTD)*100.00/COUNT(DISTINCT CID) per affiliate. Percentage of registered customers who made a first deposit. Rounded to 4 decimal places. |
| 11 | IPCountry | varchar(max) NULL | T2 — SP_M_Affiliates_FraudMonitoring | Country name corresponding to the customer's registration IP address. Resolved from Dim_Country.Name via Dim_Customer.CountryIDByIP (IP geolocation). NULL if IP country is unknown. |
| 12 | #Aff_RegisteredClients | bigint NULL | T2 — SP_M_Affiliates_FraudMonitoring | Total number of customers who registered under this affiliate in the target calendar month. COUNT(DISTINCT CID) per affiliate. |
| 13 | NoOFClientsUnderSameIP | bigint NULL | T2 — SP_M_Affiliates_FraudMonitoring | Number of affiliate customers sharing the same registration IP address as this customer (when that IP has >1 customer registered under this affiliate). 0/NULL if the customer's IP is unique within the affiliate. |
| 14 | %SameIP | numeric(10,4) NULL | T2 — SP_M_Affiliates_FraudMonitoring | Percentage of the affiliate's registered customers who share an IP with at least one other customer. ROUND(SUM(NoOFClientsUnderSameIP)*100.00 / #Aff_RegisteredClients, 2). |
| 15 | NoOFClientsUnderSameCountryIP | bigint NULL | T2 — SP_M_Affiliates_FraudMonitoring | Number of affiliate customers sharing the same IP-geolocation country as this customer. COUNT(DISTINCT CID) per affiliate × IP country. |
| 16 | %SameCountry | numeric(10,4) NULL | T2 — SP_M_Affiliates_FraudMonitoring | Percentage of the affiliate's customers whose registration IP country matches this customer's IP country. ROUND(count / #Aff_RegisteredClients * 100, 2). |
| 17 | CIDChurn<10days | int NULL | T2 — SP_M_Affiliates_FraudMonitoring | Per-customer churn flag: 1 if this customer's total equity (V_Liabilities.Liabilities + ActualNWA) was 0 at any point within 10 days after their first deposit, 0 otherwise. Identifies rapid withdraw-after-deposit behavior. |
| 18 | #OfClientsChurn | bigint NULL | T2 — SP_M_Affiliates_FraudMonitoring | Total number of depositing customers under this affiliate who churned (zero equity within 10 days of first deposit) in the target month. COUNT(DISTINCT CID) from the churn group. |
| 19 | #OfDepositors | bigint NULL | T2 — SP_M_Affiliates_FraudMonitoring | Total number of customers under this affiliate who made at least one approved deposit (Fact_BillingDeposit.PaymentStatusID=2) in the target month. Denominator for %Churn and %LowTrading. |
| 20 | %Churn | numeric(10,4) NULL | T2 — SP_M_Affiliates_FraudMonitoring | Percentage of this affiliate's depositors who churned within 10 days. ROUND(#OfClientsChurn / #OfDepositors * 100, 2). |
| 21 | CIDLowTrading | int NULL | T2 — SP_M_Affiliates_FraudMonitoring | Per-customer low-trading flag: 1 if the customer has a BackOffice CustomerRisk entry with RiskStatusID=82 (WithdrawWithShortTermTrades) or 83 (WithdrawWithLowTradingRatio), 0 otherwise. Matched via GCID. |
| 22 | #OfClientsLowTrading | bigint NULL | T2 — SP_M_Affiliates_FraudMonitoring | Total number of this affiliate's depositing customers flagged with a low-trading risk status in the target month. COUNT(DISTINCT CID) from the low-trading group. |
| 23 | %LowTrading | numeric(10,4) NULL | T2 — SP_M_Affiliates_FraudMonitoring | Percentage of this affiliate's depositors with a low-trading risk flag. ROUND(#OfClientsLowTrading / #OfDepositors * 100, 2). |
| 24 | ConversionAlert | int NULL | T2 — SP_M_Affiliates_FraudMonitoring | Alert flag: 1 if the affiliate's Conversion rate > 70% (suspiciously high FTD rate). 0 otherwise. |
| 25 | FTDAAlert | int NULL | T2 — SP_M_Affiliates_FraudMonitoring | Alert flag: 1 if the affiliate's AvgFTDA < $50 USD (implausibly low average first deposit). 0 otherwise. |
| 26 | SameIPAlert | int NULL | T2 — SP_M_Affiliates_FraudMonitoring | Alert flag: 1 if %SameIP > 0 AND NoOFClientsUnderSameIP > 1 (multiple customers share a registration IP under this affiliate). 0 otherwise. |
| 27 | SameCountryIPAlert | int NULL | T2 — SP_M_Affiliates_FraudMonitoring | Alert flag: 1 if %SameCountry > 30% (geographic clustering of affiliate's customers by IP country). 0 otherwise. |
| 28 | LowTradingAlert | int NULL | T2 — SP_M_Affiliates_FraudMonitoring | Alert flag: 1 if %LowTrading > 20% of affiliate's depositors have low-trading risk flags. 0 otherwise. |
| 29 | ChurnAlert | int NULL | T2 — SP_M_Affiliates_FraudMonitoring | Alert flag: 1 if %Churn > 20% of affiliate's depositors churned within 10 days of first deposit. 0 otherwise. NOTE: ChurnAlert is NOT included in the ≥3 selection filter (only ConversionAlert+FTDAAlert+SameIPAlert+SameCountryIPAlert+LowTradingAlert are summed). |
| 30 | FTDYearMonth | int NULL | T2 — SP_M_Affiliates_FraudMonitoring | First deposit year-month as a YYYYMM integer. CASE: YEAR(FirstDepositDate)=1900 → NULL else CAST(CONVERT(VARCHAR(6), FirstDepositDate, 112) AS INT). NULL for non-depositors (IsFTD=0). Added in October 2025 update. |
| 31 | UpdateDate | datetime NULL | Propagation | ETL metadata: timestamp when this row was inserted by the ETL pipeline. |

---

## Data Quality / Known Issues

### ChurnAlert Not Counted in Selection Filter

`ChurnAlert` is computed and stored but is **not included** in the affiliate selection threshold:
```sql
WHERE ConversionAlert+FTDAAlert+SameIPAlert+SameCountryIPAlert+LowTradingAlert >= 3
-- ChurnAlert intentionally excluded from this sum
```

This means an affiliate could trigger ConversionAlert + FTDAAlert + ChurnAlert (3 signals) and NOT appear in the output. Downstream consumers should be aware that ChurnAlert alone cannot surface an affiliate — it is informational-only for affiliates already flagged by other signals.

### Column Names Contain Special Characters

Several columns have names that are not standard SQL identifiers: `#Aff_RegisteredClients`, `NoOFClientsUnderSameIP`, `%SameIP`, `%SameCountry`, `CIDChurn<10days`, etc. Always use square bracket quoting when referencing these columns in SQL: `[CIDChurn<10days]`, `[%SameIP]`.

### AvgFTDA Is Per Affiliate × Country (Not Just Per Affiliate)

`AvgFTDA` is computed as `AVG(FirstDepositAmount) GROUP BY AffiliateID, Country` — this is the average FTD amount for the affiliate's customers FROM A SPECIFIC COUNTRY, not across all countries. The FTDAAlert threshold ($50) is applied per-row (per customer, per affiliate-country pair), not at the affiliate level. Two rows for the same affiliate but different countries can have different AvgFTDA values.

### Heap Table — No Index

The table is a HEAP with no clustered index. Queries filtering on RegisteredID or AffiliateID will do full scans. Given the small table size (typically <5K rows total), this is acceptable but should be noted for future-proofing.

---

## Lineage

Full column-level lineage: [BI_DB_Affiliates_FraudMonitoring.lineage.md](./BI_DB_Affiliates_FraudMonitoring.lineage.md)

**Tier Summary**: 3 Tier 1, 27 Tier 2, 1 Propagation

**Upstream sources**:
- `BI_DB_dbo.BI_DB_CIDFirstDates` → registered, Country, FirstDepositAmount, IsFTD, FTDYearMonth, AffiliateID (SerialID), CID, GCID
- `DWH_dbo.Dim_Affiliate` → AccountActivated filter (active affiliates only)
- `DWH_dbo.Dim_Customer` → IP, CountryIDByIP (for IPCountry)
- `DWH_dbo.Dim_Country` → IPCountry name
- `DWH_dbo.Fact_BillingDeposit` → deposit approval dates (for #OfDepositors, churn window)
- `DWH_dbo.V_Liabilities` → Liabilities + ActualNWA (for 10-day equity churn)
- `BI_DB_dbo.External_etoro_BackOffice_CustomerRisk` → RiskStatusID 82/83 (LowTrading flag)

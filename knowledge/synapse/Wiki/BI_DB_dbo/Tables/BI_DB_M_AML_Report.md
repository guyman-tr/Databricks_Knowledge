# BI_DB_dbo.BI_DB_M_AML_Report

> 144.7M-row monthly AML snapshot table covering all verified eToro depositors. One row per customer per end-of-month date, enriched with regulatory jurisdiction, player status, AML risk scores, wire transfer activity, and AML sub-entity assignments. Rebuilt monthly via DELETE+INSERT per EOM partition. Covers 28 months (2023-12 to 2026-03). Same SP also writes the aggregated companion table BI_DB_M_AML_Report_AGG.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer + DWH_dbo.Dim_Customer + DWH_dbo.Dim_Country + DWH_dbo.Dim_Regulation + DWH_dbo.Dim_PlayerStatus + DWH_dbo.Dim_PlayerLevel + DWH_dbo.Dim_PlayerStatusReasons + DWH_dbo.Dim_ScreeningStatus + DWH_dbo.Fact_BillingDeposit + DWH_dbo.Fact_CustomerAction + DWH_dbo.Fact_RegulationTransfer + BI_DB_dbo.BI_DB_AML_SubEntity_Categorization + BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake via SP_M_AML_Report |
| **Refresh** | Monthly (EOM parameter). DELETE WHERE EOM + INSERT — replaces target month only, preserves history. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | Not Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Copy Strategy** | — |
| **Business Group** | compliance / AML |

---

## 1. Business Meaning

`BI_DB_M_AML_Report` is the primary AML (Anti-Money Laundering) monthly monitoring table for all verified eToro depositors. It provides a month-end snapshot of every eligible customer with the full set of attributes required for AML regulatory reporting: jurisdiction (Regulation, Country, AML_Sub_Entity), compliance status (PlayerStatus, PlayerStatusReason, ScreeningStatus), risk classification (RiskGroup, RiskScore), financial activity (Wire_Transactions, Wire_Amount, Is_Active), and KYC state (VerificationLevelID, HasWallet).

The population is all `IsValidCustomer=1, IsDepositor=1` customers in Fact_SnapshotCustomer at the EOM date, restricted to VerificationLevelID = 3 (fully KYC'd) or VerificationLevelID = 2 under CySEC regulation only. This excludes unverified (V0) and partially verified (V1) customers from AML reporting scope.

The table is consumed by the AML/Compliance team for monthly regulatory reporting, large wire transfer monitoring (threshold: $150,000 USD), and regulatory entity oversight (AML sub-entity assignments). The companion table `BI_DB_M_AML_Report_AGG` holds the same data grouped by dimension combination, where `CID` becomes a customer COUNT rather than a customer ID.

As of 2026-03-31 (latest EOM): ~5.7M customers per month snapshot. CySEC is the dominant regulation (57%). Most customers are Normal status (75%). Medium risk score dominates (91%).

---

## 2. Business Logic

### 2.1 Population Logic

Base: `Fact_SnapshotCustomer` at the EOM date (DateRangeID where @EndDateID BETWEEN FromDateID AND ToDateID), filtered to:
- `IsValidCustomer = 1`
- `IsDepositor = 1`
- `VerificationLevelID = 3` (fully KYC'd) **OR** `RegulationID = 1 (CySEC) AND VerificationLevelID = 2` (CySEC-specific intermediate KYC exception)

This population is consistent with `BI_DB_AML_SubEntity_Categorization` (which uses VerLevel ≥ 2). V0 (unverified) and V1 (partial) customers are always excluded.

### 2.2 Monthly Partitioning

Load pattern: `DELETE FROM BI_DB_M_AML_Report WHERE EOM = @EndOfMonth` followed by `INSERT`. This preserves all prior months of history and only refreshes the target month. The SP accepts a `@Date DATE` parameter; it computes EOMONTH of the previous calendar month if @Date ≥ EOMONTH(GETDATE(), -1). Current history: 28 EOM dates from 2023-12-31 to 2026-03-31.

### 2.3 Risk Classification (Dual Dimensions)

Two independent risk measures are included:
- **`RiskGroup`** (int): Country-level risk. `Dim_Country.RiskGroupID` via `fsc.CountryID`. Values: 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. This is country risk, not individual customer risk.
- **`RiskScore`** (varchar): Customer-level AML risk text from `External_RiskClassification_dbo_V_RiskClassificationDataLake`. Values: Low / Medium / High / NULL (no score yet). LEFT JOIN — NULL if no external risk score assigned.

### 2.4 Wire Activity Monitoring (AML Threshold)

`Wire_Transactions` and `Wire_Amount` count and sum wire deposits from `Fact_BillingDeposit` where:
- `FundingTypeID = 2` (wire transfer — deposits, NOT cashouts)
- `PaymentStatusID = 2` (approved)
- `AmountUSD >= 150,000` (large transaction AML threshold)
- Within the EOM month (`ModificationDateID BETWEEN @StartDateID AND @EndDateID`)

Only large wire deposits ≥ $150K are captured. Smaller wire deposits, card payments, e-wallets, and crypto deposits are excluded. 0 if no qualifying transactions (`ISNULL` to 0).

### 2.5 Active Customer Definition

`Is_Active = 1` if the customer appears in `Fact_CustomerAction` with `ActionTypeID IN (1,2,3,4,5,6,7,8,39,40,42,43)` (trading, deposit, cashout actions) within the 12 months before the EOM date. **Note:** The SP comment reads "past 3 months" but the code uses `DATEADD(MONTH, -12, @Date)` — the actual window is 12 months.

### 2.6 EEA/EU Classification

`Is_EEA_EU_Country = 1` if the customer's `DWHCountryID` appears in a hardcoded list of 37 EU/EEA country IDs embedded in the SP (e.g., Germany=79, France=57, etc.). Not driven by a dimension table or flag column — list changes require SP modification.

### 2.7 Regulation Change Tracking

`Prev_Regulation`: If the customer had a regulation transfer in the EOM month (from `Fact_RegulationTransfer`), the most recent `FromRegulation` name is captured via ROW_NUMBER by Occurred DESC. Transfers involving NFA, BVI, or eToroUS (DWHRegulationID IN 3, 5, 6) are excluded. NULL if no regulation change in the month.

### 2.8 AML Sub-Entity

`AML_Sub_Entity` is a LEFT JOIN to `BI_DB_AML_SubEntity_Categorization` on CID. The sub-entity values are a comma-separated string of applicable eToro legal entities (eToro_Germany, eToro_Gibraltar, eToro_Money_UK, eToro_Money_Malta). Since BI_DB_AML_SubEntity_Categorization is a daily-rebuilt snapshot, the sub-entity in M_AML_Report reflects the customer's classification at the time the SP ran, not necessarily their sub-entity at the EOM date. For current-month rows this is equivalent; for historical months, sub-entity may drift.

### 2.9 Is_FTD Flag

`Is_FTD = 1` if `Dim_Customer.FirstDepositDate` falls within the EOM month (`>= @StartDateTime AND < @EndDateTime`). Identifies customers who made their first deposit during the snapshot month.

---

## 3. Data Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Sourced from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Regulation | varchar(250) | YES | Regulatory framework under which the customer is classified at EOM. Text name from Dim_Regulation via Fact_SnapshotCustomer.RegulationID. Dominant: CySEC, FCA, ASIC & GAML, FinCEN+FINRA. (Tier 2 — SP_M_AML_Report) |
| 3 | Country | varchar(250) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country.Name. (Tier 1 — Dictionary.Country) |
| 4 | PlayerStatus | varchar(250) | YES | Player account status text at EOM. Sourced from Dim_PlayerStatus via Fact_SnapshotCustomer.PlayerStatusID. Dominant: Normal, Blocked, Block Deposit & Trading. (Tier 2 — SP_M_AML_Report) |
| 5 | PlayerStatusReason | varchar(250) | YES | Reason text for the player status restriction. Sourced from Dim_PlayerStatusReasons via Fact_SnapshotCustomer.PlayerStatusReasonID. LEFT JOIN — NULL for unrestricted customers or when no reason is set. (Tier 2 — SP_M_AML_Report) |
| 6 | Club | varchar(250) | YES | Customer loyalty/VIP tier at EOM. Sourced from Dim_PlayerLevel via Fact_SnapshotCustomer.PlayerLevelID. Values: Bronze, Silver, Gold, Platinum, Diamond. (Tier 2 — SP_M_AML_Report) |
| 7 | RiskGroup | int | YES | Granular country risk classification. 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. More nuanced than binary IsHighRiskCountry. IsHighRiskCountry is derived from this column. Passthrough from Dim_Country.RiskGroupID. Renamed from RiskGroupID. (Tier 1 — Dictionary.Country) |
| 8 | RiskScore | varchar(250) | YES | Customer-level AML risk classification from external risk scoring system. Values: Low, Medium (dominant), High, NULL (no score). Sourced from External_RiskClassification_dbo_V_RiskClassificationDataLake. LEFT JOIN — NULL if no score assigned. (Tier 2 — SP_M_AML_Report) |
| 9 | Is_FTD | int | YES | 1 if the customer made their first deposit during the EOM month (FirstDepositDate within month range); 0 otherwise. (Tier 2 — SP_M_AML_Report) |
| 10 | ScreeningStatus | varchar(250) | YES | Compliance screening result text. Sourced from Dim_ScreeningStatus via Dim_Customer.ScreeningStatusID. Values: NoMatch (dominant), PendingInvestigation, PEP, RiskMatch, SanctionsMatch, MultipleMatch, Unknown. NULL if no screening record. (Tier 2 — SP_M_AML_Report) |
| 11 | HasWallet | int | YES | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. (Tier 1 — BackOffice.Customer) |
| 12 | Is_Active | int | YES | 1 if the customer had any trading, deposit, or cashout activity (ActionTypeIDs 1–8, 39–40, 42–43) in Fact_CustomerAction within 12 months before EOM. 0 otherwise. See Section 2.5 for comment/code discrepancy. (Tier 2 — SP_M_AML_Report) |
| 13 | Wire_Transactions | int | YES | Count of approved wire deposit transactions ≥ $150,000 USD (FundingTypeID=2, PaymentStatusID=2) within the EOM month. 0 if none. AML large-transaction threshold monitoring. (Tier 2 — SP_M_AML_Report) |
| 14 | Wire_Amount | money | YES | Total USD amount of approved wire deposits ≥ $150,000 in the EOM month. 0.00 if none. Paired with Wire_Transactions. (Tier 2 — SP_M_AML_Report) |
| 15 | Prev_Regulation | varchar(250) | YES | Name of the customer's previous regulation before any regulation transfer in the EOM month. Most recent change only (ROW_NUMBER). NULL if no regulation change occurred in the month. Transfers involving NFA, BVI, eToroUS excluded. (Tier 2 — SP_M_AML_Report) |
| 16 | EOM | date | YES | End-of-month snapshot date (EOMONTH of the @Date parameter). Partition key for monthly history. Range: 2023-12-31 to 2026-03-31 (28 months). (Tier 5 — ETL metadata) |
| 17 | UpdateDate | datetime | YES | ETL insert timestamp (GETDATE() at run time). All rows in a given month's refresh share the same UpdateDate batch value. (Tier 5 — ETL metadata) |
| 18 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. This table: only values 2 and 3 present (SP population filter). (Tier 1 — BackOffice.Customer) |
| 19 | Is_EEA_EU_Country | int | YES | 1 if the customer's country is in the EU/EEA, based on a hardcoded list of 37 DWHCountryIDs in the SP. 0 otherwise. Not driven by a Dim_Country flag. (Tier 2 — SP_M_AML_Report) |
| 20 | AML_Sub_Entity | varchar(max) | YES | ETL-computed comma-separated list of eToro AML sub-entities this customer qualifies for. Possible values (may be combined): eToro_Germany, eToro_Gibraltar, eToro_Money_UK, eToro_Money_Malta. NULL if no entity label applies. Use LIKE '%value%' for filtering. Sourced from BI_DB_AML_SubEntity_Categorization via LEFT JOIN. (Tier 2 — SP_M_AML_Report) |

---

## 4. Sample Rows

Sample from most recent EOM (2026-03-31), 10 rows:

| CID | Regulation | Country | PlayerStatus | RiskGroup | RiskScore | Is_FTD | ScreeningStatus | HasWallet | Is_Active | Wire_Transactions | Wire_Amount | EOM |
|-----|-----------|---------|-------------|-----------|-----------|--------|----------------|-----------|-----------|-------------------|-------------|-----|
| 20267543 | CySEC | Romania | Normal | 0 | Medium | 0 | NoMatch | 1 | 1 | 0 | 0 | 2024-02-29 |
| 20842375 | CySEC | Romania | Normal | 0 | Medium | 0 | NoMatch | 0 | 0 | 0 | 0 | 2023-12-31 |
| 22674388 | FCA | Philippines | Normal | 2 | Medium | 0 | NoMatch | 0 | 0 | 0 | 0 | 2024-05-31 |
| 2077664 | CySEC | India | Trade & MIMO Blocked | 2 | Medium | 0 | NoMatch | 0 | 0 | 0 | 0 | 2023-12-31 |

_Note: TOP 10 sample rows as returned from live query. UpdateDate range: 2025-01-07 to 2026-04-01._

---

## 5. Lineage at a Glance

See `BI_DB_M_AML_Report.lineage.md` for full column-level lineage.

**ETL Summary:**
- Writer SP: `BI_DB_dbo.SP_M_AML_Report`
- Pattern: DELETE WHERE EOM + INSERT (monthly partition refresh)
- Also writes: `BI_DB_M_AML_Report_AGG` (aggregated companion; CID = COUNT in AGG)
- Source tables: 13 source objects (see lineage file)

---

## 6. Related Objects

| Object | Schema | Relationship |
|--------|--------|-------------|
| BI_DB_M_AML_Report_AGG | BI_DB_dbo | Companion aggregate table written by the same SP. CID = COUNT(customers) per dimension group. |
| SP_M_AML_Report | BI_DB_dbo | Writer SP for both M_AML_Report and M_AML_Report_AGG. |
| BI_DB_AML_SubEntity_Categorization | BI_DB_dbo | Source for AML_Sub_Entity (LEFT JOIN on CID). Daily snapshot — sub-entity reflects current state, not historical EOM state. |
| External_RiskClassification_dbo_V_RiskClassificationDataLake | BI_DB_dbo | Source for RiskScore. External AML risk classification feed. |
| Fact_SnapshotCustomer | DWH_dbo | Base population: one row per customer per date range. IsValidCustomer + IsDepositor filter. |
| Fact_BillingDeposit | DWH_dbo | Source for Wire_Transactions and Wire_Amount (FundingTypeID=2, ≥$150K). |
| Fact_CustomerAction | DWH_dbo | Source for Is_Active flag (12-month lookback window). |
| Fact_RegulationTransfer | DWH_dbo | Source for Prev_Regulation (transfers in EOM month). |

---

## 7. Change History

| Date | Author | Change |
|------|--------|--------|
| — | — | Original creation date unknown (no DDL comment). SP last modified unknown — no version comment. |
| 2023-12-31 | ETL | Earliest data: first EOM partition. |
| 2026-03-31 | ETL | Latest EOM partition in current dataset. |

---

## 8. Open Questions / Caveats

1. **Is_Active Window Discrepancy**: SP comment says "past 3 months" but code uses `DATEADD(MONTH, -12, @Date)` (12 months). Confirm intended window with SP owner.

2. **AML_Sub_Entity Historical Fidelity**: LEFT JOIN to BI_DB_AML_SubEntity_Categorization (daily rebuild). Sub-entity in historical EOM rows may not reflect the customer's sub-entity at that EOM date.

3. **Is_EEA_EU_Country Hardcoded**: Based on 37 hardcoded DWHCountryIDs in SP. Not derived from a Dim_Country flag. List may be stale if country classifications changed.

4. **Wire Threshold ($150K)**: The large wire threshold is hardcoded in the SP. Confirm this is still the current AML reporting threshold.

5. **RiskGroup = Country Risk**: `RiskGroup` maps to `Dim_Country.RiskGroupID` — it is the country-level risk classification, not an individual customer risk score. Analysts should not confuse this with `RiskScore` (customer-level AML score).

6. **RiskScore NULL**: ~0.1% of rows have NULL RiskScore (not classified in external risk system). These are not the same as "Low" risk.

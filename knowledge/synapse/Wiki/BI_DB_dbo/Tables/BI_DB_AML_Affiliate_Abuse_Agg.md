# BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Agg

> Monthly aggregation of cashout, deposit, and trading activity per affiliate channel (Jan 2023–Dec 2024) — 20,627 rows. Part of the AML Affiliate Abuse monitoring suite written by SP_AML_Affiliate_Abuse (disabled 2024-12-31); data is frozen.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_BillingWithdraw + Fact_BillingDeposit + Dim_Position (via #Aff_acivated) |
| **Refresh** | DISABLED (SP_AML_Affiliate_Abuse disabled 2024-12-31 per BI team request) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Writer SP** | SP_AML_Affiliate_Abuse |
| **UC Target** | Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **OpsDB Priority** | Not in OpsDB |

---

## 1. Business Meaning

`BI_DB_AML_Affiliate_Abuse_Agg` is a monthly rollup of cashout, deposit, and trading activity for each affiliate channel participating in the AML Affiliate Abuse monitoring programme. The table was part of a suite designed to detect anomalous financial behaviour (high cashout ratios, unapproved transaction spikes, low trading activity) among customers referred by specific affiliate channels — a pattern associated with money laundering via affiliate referral networks.

The population is restricted to **activated affiliates** (AccountActivated=1) with SubChannelID in (20,31,39,40,41,42,44) — covering: Affiliate, Mobile Acquisition, Media Performance, Content Partnerships, and related channels — active since January 2023. For each such affiliate, the SP aggregates monthly counts of: (a) approved/unapproved cashouts from `Fact_BillingWithdraw`, (b) approved/unapproved deposits from `Fact_BillingDeposit`, and (c) unique customers with any open trade from `Dim_Position`.

**The SP was permanently disabled on 2024-12-31** at the request of Lior Ben Dor from the BI team. The table contains **20,627 rows** spanning Year 2023–2024 and is now a frozen historical snapshot. No further refreshes will occur.

The ETL pipeline:

```
BI_DB_dbo.BI_DB_MarketingMonthlyRawData (AccountActivated=1, YearMonthID>=202301)
  JOIN DWH_dbo.Dim_Affiliate (SubChannelID IN 20,31,39,40,41,42,44)
  |-- #Aff_acivated (activated affiliate pool) ---|
  v
JOIN Dim_Customer → Fact_BillingWithdraw + Fact_BillingDeposit + Dim_Position
  |-- Monthly CO/Deposit/Position aggregation (since 2023-01-01) ---|
  v
BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Agg (20,627 rows, frozen 2024-12-31)
```

---

## 2. Business Logic

### 2.1 Approved vs. Unapproved Transaction Counts

**What**: Separates financial transactions by approval status for AML risk assessment.

**Columns Involved**: Approved_CO, Unapproved_CO, Approved_Deposits, Unapproved_Deposits

**Rules**:
- `Approved_CO`: COUNT DISTINCT WithdrawID WHERE CashoutStatusID_Funding=3 (approved)
- `Unapproved_CO`: COUNT DISTINCT WithdrawID WHERE CashoutStatusID_Funding≠3 (pending/rejected)
- `Approved_Deposits`: COUNT DISTINCT DepositID WHERE PaymentStatusID=2 (approved)
- `Unapproved_Deposits`: COUNT DISTINCT DepositID WHERE PaymentStatusID≠2 (pending/rejected)
- High ratio of Unapproved_CO to Approved_CO may indicate money mule activity

### 2.2 Channel Scope

**What**: Only 5 channel types are in scope for this AML monitoring.

**Columns Involved**: AffiliateID, Channel

**Rules**:
- `Channel` values present: Affiliate (dominant), Media Performance, Mobile Acquisition, Media Programmatic, Content Partnerships
- SubChannelID filter in SP: 20=Affiliate, 31=Mobile Acquisition, 39=Media Performance, 40=Content Partnerships, 41/42/44=other performance channels
- Organic, SEM, SEO affiliates are excluded

### 2.3 Grain

**What**: One row per affiliate × channel × year × month.

**Columns Involved**: AffiliateID, Channel, Year, Month

**Rules**:
- A single AffiliateID can have multiple Channel rows if it spans multiple channels
- Year range in data: 2023–2024; Month: 1–12
- Transactions after 2023-01-01 only (SP WHERE clause filters dates)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. No distribution key — rows spread across all distributions. No index. Full scan required for all queries. Small table (20,627 rows) — performance is not a concern.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Cashout/deposit ratio for an affiliate | `SELECT AffiliateID, SUM(Approved_CO)/NULLIF(SUM(Approved_Deposits),0) FROM BI_DB_AML_Affiliate_Abuse_Agg GROUP BY AffiliateID` |
| Monthly trend for a specific affiliate | `WHERE AffiliateID = @id ORDER BY Year, Month` |
| Affiliates with high unapproved CO | `WHERE Unapproved_CO > Approved_CO` |
| All data for a channel | `WHERE Channel = 'Affiliate' ORDER BY Year, Month` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_AML_Affiliate_Abuse_Aff_data | ON AffiliateID AND Channel | Add contract details to monthly agg |
| BI_DB_AML_Affiliate_Abuse_Users | ON AffiliateID AND Channel | Get CID-level detail for flagged affiliate |
| DWH_dbo.Dim_Affiliate | ON AffiliateID | Add affiliate name, contact info |

### 3.4 Gotchas

- **Data is frozen**: No refreshes since 2024-12-31. Do NOT use for current monitoring.
- **V_Liabilities NOT used here**: Equity data is in `BI_DB_AML_Affiliate_Abuse_Users`, not this table.
- **Multi-channel affiliates**: A single AffiliateID may appear under multiple Channel values; always GROUP BY AffiliateID if aggregating totals.
- **NULL rows in agg**: If an affiliate had no CO/deposits/trades in a given month, the FULL OUTER JOIN-like logic via separate temp tables may produce NULL values — these represent zero activity months only if they appear in the CO leg.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream DWH_dbo wiki (canonical source for BI_DB) |
| Tier 2 | Derived from SP code analysis or intermediate DWH dimension |
| Tier 3 | Inferred from DDL, column name, or context |
| Tier 5 | ETL infrastructure — canonical description applies universally |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliateID | int | YES | Unique affiliate partner identifier from AffWizz system. Primary key of `Dim_Affiliate`. Identifies the affiliate whose customers' activity is aggregated here. (Tier 2 — SP_AML_Affiliate_Abuse via BI_DB_MarketingMonthlyRawData) |
| 2 | Channel | varchar(500) | YES | Marketing channel classification. Values: Affiliate, Media Performance, Mobile Acquisition, Media Programmatic, Content Partnerships. Passthrough from BI_DB_MarketingMonthlyRawData. (Tier 2 — SP_AML_Affiliate_Abuse via BI_DB_MarketingMonthlyRawData) |
| 3 | Year | int | YES | Calendar year (2023 or 2024). Extracted from transaction dates (Fact_BillingWithdraw.RequestDate / Fact_BillingDeposit.ModificationDate / Dim_Position.OpenOccurred). (Tier 2 — SP_AML_Affiliate_Abuse) |
| 4 | Month | int | YES | Calendar month (1–12). Extracted from transaction dates. (Tier 2 — SP_AML_Affiliate_Abuse) |
| 5 | Approved_CO | int | YES | Count of distinct approved cashouts (CashoutStatusID_Funding=3) per affiliate × channel × year × month. From Fact_BillingWithdraw for customers in the affiliate's portfolio. NULL if no records in CO leg. (Tier 2 — SP_AML_Affiliate_Abuse via Fact_BillingWithdraw) |
| 6 | Unapproved_CO | int | YES | Count of distinct unapproved/rejected cashouts (CashoutStatusID_Funding≠3) per affiliate × channel × year × month. High value relative to Approved_CO is an AML risk indicator. NULL if no records. (Tier 2 — SP_AML_Affiliate_Abuse via Fact_BillingWithdraw) |
| 7 | Approved_Deposits | int | YES | Count of distinct approved deposits (PaymentStatusID=2) per affiliate × channel × year × month. From Fact_BillingDeposit. NULL if no records in deposit leg. (Tier 2 — SP_AML_Affiliate_Abuse via Fact_BillingDeposit) |
| 8 | Unapproved_Deposits | int | YES | Count of distinct unapproved/pending deposits (PaymentStatusID≠2) per affiliate × channel × year × month. (Tier 2 — SP_AML_Affiliate_Abuse via Fact_BillingDeposit) |
| 9 | Has_Open_Trade | int | YES | Count of distinct customers (RealCID) who opened at least one position (Dim_Position.OpenOccurred≥2023-01-01) during this affiliate × channel × year × month period. (Tier 2 — SP_AML_Affiliate_Abuse via Dim_Position) |
| 10 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. All rows show 2024-12-31 — the date the SP was last run before being disabled. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| AffiliateID | BI_DB_MarketingMonthlyRawData | AffiliateID | passthrough |
| Channel | BI_DB_MarketingMonthlyRawData | Channel | passthrough |
| Year, Month | Fact_BillingWithdraw / Fact_BillingDeposit / Dim_Position | date fields | YEAR() / MONTH() extract |
| Approved_CO | Fact_BillingWithdraw | WithdrawID | COUNT DISTINCT WHERE CashoutStatusID_Funding=3 |
| Unapproved_CO | Fact_BillingWithdraw | WithdrawID | COUNT DISTINCT WHERE ≠3 |
| Approved_Deposits | Fact_BillingDeposit | DepositID | COUNT DISTINCT WHERE PaymentStatusID=2 |
| Unapproved_Deposits | Fact_BillingDeposit | DepositID | COUNT DISTINCT WHERE ≠2 |
| Has_Open_Trade | Dim_Position | PositionID | COUNT DISTINCT CID |
| UpdateDate | ETL | — | GETDATE() |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_MarketingMonthlyRawData (AccountActivated=1, YearMonthID>=202301)
  |-- JOIN Dim_Affiliate SubChannelID IN (20,31,39,40,41,42,44) ---|
  v
#Aff_acivated (2,670 distinct affiliates across 5 channels)
  |-- Step 07: JOIN Dim_Customer → Fact_BillingWithdraw (CO monthly agg) ---|
  |-- Step 07: JOIN Dim_Customer → Fact_BillingDeposit (Deposit monthly agg) ---|
  |-- Step 07: JOIN Dim_Customer → Dim_Position (Trade monthly agg) ---|
  v
#final_agg_data (CO + Deposit + Position merge)
  |-- TRUNCATE + INSERT (SP disabled 2024-12-31) ---|
  v
BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Agg (20,627 rows, frozen)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AffiliateID | DWH_dbo.Dim_Affiliate | Affiliate partner master |
| AffiliateID + CID | BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Users | CID-level companion table |
| AffiliateID | BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Aff_data | Affiliate marketing data companion |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers (SP was disabled; AML monitoring suite decommissioned).

---

## 7. Sample Queries

### Monthly cashout ratio by affiliate (identify potential laundering affiliates)

```sql
SELECT
    AffiliateID,
    Channel,
    Year,
    Month,
    Approved_CO,
    Approved_Deposits,
    CAST(Approved_CO AS FLOAT) / NULLIF(Approved_Deposits, 0) AS CO_Dep_Ratio,
    Has_Open_Trade
FROM [BI_DB_dbo].[BI_DB_AML_Affiliate_Abuse_Agg]
WHERE Approved_Deposits > 10
ORDER BY CO_Dep_Ratio DESC
```

### Affiliates with high unapproved deposit rate in 2024

```sql
SELECT
    AffiliateID,
    Channel,
    SUM(Approved_Deposits) AS total_approved,
    SUM(Unapproved_Deposits) AS total_unapproved,
    CAST(SUM(Unapproved_Deposits) AS FLOAT) / NULLIF(SUM(Approved_Deposits + Unapproved_Deposits), 0) AS unapproved_rate
FROM [BI_DB_dbo].[BI_DB_AML_Affiliate_Abuse_Agg]
WHERE Year = 2024
GROUP BY AffiliateID, Channel
HAVING SUM(Approved_Deposits + Unapproved_Deposits) > 50
ORDER BY unapproved_rate DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. The AML Affiliate Abuse suite was internally tracked — refer to BI team communications with Lior Ben Dor (2024-12-31 disable request).

---

*Generated: 2026-04-23 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 0 T1, 9 T2, 0 T3, 0 T4, 1 T5 | Elements: 10/10*
*Object: BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Agg | Type: Table | Production Source: SP_AML_Affiliate_Abuse (DISABLED 2024-12-31)*

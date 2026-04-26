# BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Aff_data

> Monthly affiliate performance marketing metrics (Jan 2023–Dec 2024) by affiliate × channel — 37,933 rows. Part of the AML Affiliate Abuse monitoring suite; provides contract, cost, and revenue context alongside the AML risk signals. Written by SP_AML_Affiliate_Abuse (disabled 2024-12-31); data is frozen.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_MarketingMonthlyRawData + DWH_dbo.Dim_Affiliate |
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

`BI_DB_AML_Affiliate_Abuse_Aff_data` is the contract and profitability companion table for the AML Affiliate Abuse monitoring suite. Where `BI_DB_AML_Affiliate_Abuse_Agg` tracks financial transaction risk signals (cashout ratios, deposit patterns) and `BI_DB_AML_Affiliate_Abuse_Users` tracks CID-level risk profiles, this table provides the **marketing economics context**: what contract type governs each affiliate, how much they were paid, and whether the affiliate partnership was profitable for the company.

The table contains **37,933 rows** spanning YearMonthID 202301–202412, one row per affiliate × channel × subchannel × year-month × contract type. It is sourced entirely from `BI_DB_MarketingMonthlyRawData` — the main affiliate performance data mart — filtered to the same 5-channel scope as the rest of the suite.

An affiliate with high AML risk signals (many unapproved cashouts, IP clustering) can be cross-referenced here to understand: (a) their contract terms (CPA vs RevShare), (b) whether the company actually profited from their referrals, and (c) who the contact is for escalation.

**The SP was permanently disabled on 2024-12-31** at the request of Lior Ben Dor from the BI team. The table is a frozen historical snapshot.

The ETL pipeline:

```
BI_DB_dbo.BI_DB_MarketingMonthlyRawData (AccountActivated=1, YearMonthID>=202301)
  |-- JOIN DWH_dbo.Dim_Affiliate ON AffiliateID (SubChannelID filter) ---|
  v
GROUP BY AffiliateID, Channel, SubChannel, YearMonthID, ContractType, ContractName, Contact
  |-- SUM(SameDayFTD, TotalDeposit, FTDs, Registration, TotalCost, NetRevenues) ---|
  v
Profitability = NetRevenues - TotalCost
  |-- TRUNCATE + INSERT (SP disabled 2024-12-31) ---|
  v
BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Aff_data (37,933 rows, frozen)
```

---

## 2. Business Logic

### 2.1 Profitability Calculation

**What**: Net commercial value of each affiliate partnership per month.

**Columns Involved**: NetRevenues, TotalCost, Profitability

**Rules**:
- `Profitability` = ISNULL(NetRevenues, 0) - ISNULL(TotalCost, 0)
- Positive = affiliate partnership generated net revenue for the company
- Negative = company paid out more than it earned from the affiliate's customers
- This is the key economic counterpart to the AML risk signals: a negative-profitability affiliate with high cashout ratios is a maximum risk combination

### 2.2 Contract Type Classification

**What**: Classifies the commercial arrangement governing each affiliate's compensation.

**Columns Involved**: ContractType, ContractName

**Rules**:
- ContractType codes (from Dim_Affiliate): 0=N/A, 2=CPA (Cost Per Acquisition), 3=RevShare (Revenue Share), 4=Hybrid (CPA+RevShare), 6=eCost, 7=Zero Commission, 8=CPL/CPR
- ContractName: free-text name of the specific contract variant (e.g., "CPA $200 Standard")
- An affiliate can appear under different ContractType rows if their contract changed across months

### 2.3 Grain

**What**: One row per affiliate × channel × subchannel × year-month × contract type combination.

**Columns Involved**: AffiliateID, Channel, SubChannel, YearMonthID, ContractType, ContractName

**Rules**:
- YearMonthID format: YYYYMM integer (e.g., 202301 = January 2023)
- A single AffiliateID can span multiple Channel values
- Multiple ContractType values per affiliate/month if contract changed mid-month or if affiliate has multiple concurrent contracts

### 2.4 Channel Scope

**What**: Only 5 affiliate channel types are monitored.

**Columns Involved**: Channel, SubChannel

**Rules**:
- SubChannelID IN (20, 31, 39, 40, 41, 42, 44) — Affiliate, Mobile Acquisition, Media Performance, Content Partnerships, and related performance channels
- Organic, SEM, SEO channels are excluded from the AML monitoring suite

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. 37,933 rows — small table, full scan is fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly profitability for an affiliate | `WHERE AffiliateID = @id ORDER BY YearMonthID` |
| Affiliates with net negative profitability | `GROUP BY AffiliateID, SUM(Profitability) HAVING SUM(Profitability) < 0` |
| FTD count by affiliate channel | `GROUP BY AffiliateID, Channel, SUM(FTDs)` |
| Affiliate contact info for escalation | `SELECT DISTINCT AffiliateID, Contact, ContractType WHERE AffiliateID = @id` |
| Total cost paid to affiliates by month | `GROUP BY YearMonthID, SUM(TotalCost)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_AML_Affiliate_Abuse_Agg | ON AffiliateID, Channel | Add AML risk signals to profitability view |
| BI_DB_AML_Affiliate_Abuse_Users | ON AffiliateID, Channel | Get CID-level detail for affiliate customers |
| DWH_dbo.Dim_Affiliate | ON AffiliateID | Additional affiliate metadata (manager, tier) |

### 3.4 Gotchas

- **Data is frozen**: No refreshes since 2024-12-31.
- **ISNULL(x,0) in SUM**: All financial metrics treat NULL as 0 — an affiliate with missing data shows 0, not NULL. Absence of data may be masked.
- **YearMonthID is int, not date**: To filter by date range use `YearMonthID BETWEEN 202301 AND 202312`, not date comparisons.
- **ContractName is free text**: No controlled vocabulary. Do not rely on it for grouping — use ContractType code instead.
- **Profitability can be negative**: Does not indicate a data error. RevShare contracts where customers lost money would show negative NetRevenues.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis or upstream DWH dimension |
| Tier 5 | ETL infrastructure — canonical description applies universally |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliateID | int | YES | Unique affiliate partner identifier from AffWizz system. Primary key of Dim_Affiliate. Groups marketing performance metrics by affiliate. (Tier 2 — SP_AML_Affiliate_Abuse Step 02 via BI_DB_MarketingMonthlyRawData) |
| 2 | Channel | varchar(500) | YES | Marketing channel classification. Values: Affiliate, Media Performance, Mobile Acquisition, Media Programmatic, Content Partnerships. Passthrough from BI_DB_MarketingMonthlyRawData. (Tier 2 — SP_AML_Affiliate_Abuse Step 02) |
| 3 | SubChannel | varchar(500) | YES | Sub-classification within the Channel. More granular than Channel (e.g., specific sub-network or placement type). Passthrough from BI_DB_MarketingMonthlyRawData. (Tier 2 — SP_AML_Affiliate_Abuse Step 02) |
| 4 | YearMonthID | int | YES | Year-month identifier in YYYYMM format (e.g., 202301). Used for time-series analysis. Range: 202301–202412. (Tier 2 — SP_AML_Affiliate_Abuse Step 02) |
| 5 | ContractType | int | YES | Commercial contract type code. 0=N/A, 2=CPA, 3=RevShare, 4=Hybrid, 6=eCost, 7=Zero Commission, 8=CPL/CPR. Drives how the affiliate is compensated. (Tier 2 — SP_AML_Affiliate_Abuse Step 02 via Dim_Affiliate) |
| 6 | ContractName | varchar(500) | YES | Free-text name of the affiliate's specific contract variant. No controlled vocabulary. Use ContractType for grouping; ContractName for display only. (Tier 2 — SP_AML_Affiliate_Abuse Step 02 via Dim_Affiliate) |
| 7 | SameDayFTD | int | YES | Count of customers who made their first deposit on the same day they registered, summed for this affiliate × channel × month. AML relevance: immediate depositors in bulk may indicate prepared accounts. (Tier 2 — SP_AML_Affiliate_Abuse Step 02 via BI_DB_MarketingMonthlyRawData) |
| 8 | TotalDeposit | float | YES | Total deposit amount (monetary) for customers of this affiliate × channel × month. ISNULL→0 in aggregation. (Tier 2 — SP_AML_Affiliate_Abuse Step 02 via BI_DB_MarketingMonthlyRawData) |
| 9 | FTDs | int | YES | Count of First-Time Depositors (renamed from FTD column in source). Total new depositing customers for this affiliate × channel × month. (Tier 2 — SP_AML_Affiliate_Abuse Step 02 via BI_DB_MarketingMonthlyRawData) |
| 10 | Registration | int | YES | Count of new customer registrations for this affiliate × channel × month. Includes non-depositors. (Tier 2 — SP_AML_Affiliate_Abuse Step 02 via BI_DB_MarketingMonthlyRawData) |
| 11 | TotalCost | float | YES | Total commission/cost paid to the affiliate for this month, aggregated by affiliate × channel × contract. Used in Profitability denominator. ISNULL→0. (Tier 2 — SP_AML_Affiliate_Abuse Step 02 via BI_DB_MarketingMonthlyRawData) |
| 12 | NetRevenues | float | YES | Net revenue generated by this affiliate's customers for this month. ISNULL→0. May be negative if customers' trading losses were borne by the company under RevShare. (Tier 2 — SP_AML_Affiliate_Abuse Step 02 via BI_DB_MarketingMonthlyRawData) |
| 13 | Profitability | float | YES | Net commercial value: NetRevenues - TotalCost. Positive = profitable partnership; negative = loss-making month. Computed in SP Step 02. (Tier 2 — SP_AML_Affiliate_Abuse Step 02) |
| 14 | Contact | varchar(500) | YES | Primary contact information for the affiliate (email or name). Used for escalation when AML risk signals are flagged. Passthrough from BI_DB_MarketingMonthlyRawData. (Tier 2 — SP_AML_Affiliate_Abuse Step 02 via Dim_Affiliate) |
| 15 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted. All rows show 2024-12-31 — the date the SP was last run before being disabled. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| AffiliateID | BI_DB_MarketingMonthlyRawData | AffiliateID | passthrough |
| Channel | BI_DB_MarketingMonthlyRawData | Channel | passthrough |
| SubChannel | BI_DB_MarketingMonthlyRawData | SubChannel | passthrough |
| YearMonthID | BI_DB_MarketingMonthlyRawData | YearMonthID | passthrough |
| ContractType | BI_DB_MarketingMonthlyRawData | ContractType | passthrough |
| ContractName | BI_DB_MarketingMonthlyRawData | ContractName | passthrough |
| SameDayFTD | BI_DB_MarketingMonthlyRawData | SameDayFTD | SUM(ISNULL(x,0)) |
| TotalDeposit | BI_DB_MarketingMonthlyRawData | TotalDeposit | SUM(ISNULL(x,0)) |
| FTDs | BI_DB_MarketingMonthlyRawData | FTD | SUM(ISNULL(x,0)); renamed FTD→FTDs |
| Registration | BI_DB_MarketingMonthlyRawData | Registration | SUM(ISNULL(x,0)) |
| TotalCost | BI_DB_MarketingMonthlyRawData | TotalCost | SUM(ISNULL(x,0)) |
| NetRevenues | BI_DB_MarketingMonthlyRawData | NetRevenues | SUM(ISNULL(x,0)) |
| Profitability | SP computation | NetRevenues, TotalCost | ISNULL(NetRevenues,0) - ISNULL(TotalCost,0) |
| Contact | BI_DB_MarketingMonthlyRawData | Contact | passthrough |
| UpdateDate | ETL | — | GETDATE() |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_MarketingMonthlyRawData (AccountActivated=1, YearMonthID>=202301)
  |-- JOIN DWH_dbo.Dim_Affiliate ON AffiliateID (SubChannelID IN 20,31,39,40,41,42,44) ---|
  v
GROUP BY AffiliateID, Channel, SubChannel, YearMonthID, ContractType, ContractName, Contact
  |-- SUM all financial metrics (ISNULL→0) ---|
  |-- Profitability = NetRevenues - TotalCost ---|
  v
#Aff_data
  |-- TRUNCATE + INSERT (SP disabled 2024-12-31) ---|
  v
BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Aff_data (37,933 rows, frozen)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AffiliateID | DWH_dbo.Dim_Affiliate | Affiliate partner master (contract details) |
| AffiliateID + Channel | BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Agg | Monthly AML risk signals for same affiliate |
| AffiliateID + Channel | BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Users | CID-level risk profiles for same affiliate |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers (SP was disabled; AML monitoring suite decommissioned).

---

## 7. Sample Queries

### Affiliates with negative profitability paired with AML risk

```sql
SELECT
    ad.AffiliateID,
    ad.Channel,
    SUM(ad.Profitability) AS total_profitability,
    SUM(ad.TotalCost) AS total_cost,
    SUM(ad.FTDs) AS total_ftds,
    ad.Contact
FROM [BI_DB_dbo].[BI_DB_AML_Affiliate_Abuse_Aff_data] ad
GROUP BY ad.AffiliateID, ad.Channel, ad.Contact
HAVING SUM(ad.Profitability) < 0
ORDER BY total_profitability ASC
```

### Monthly revenue trend for a specific affiliate

```sql
SELECT
    YearMonthID,
    ContractType,
    FTDs,
    Registration,
    NetRevenues,
    TotalCost,
    Profitability
FROM [BI_DB_dbo].[BI_DB_AML_Affiliate_Abuse_Aff_data]
WHERE AffiliateID = @affiliate_id
ORDER BY YearMonthID
```

### SameDayFTD concentration (potential prepared-account signal)

```sql
SELECT
    AffiliateID,
    Channel,
    SUM(SameDayFTD) AS total_same_day_ftd,
    SUM(FTDs) AS total_ftd,
    CAST(SUM(SameDayFTD) AS FLOAT) / NULLIF(SUM(FTDs), 0) AS same_day_ratio
FROM [BI_DB_dbo].[BI_DB_AML_Affiliate_Abuse_Aff_data]
GROUP BY AffiliateID, Channel
HAVING SUM(FTDs) > 10
ORDER BY same_day_ratio DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. The AML Affiliate Abuse suite was internally tracked — refer to BI team communications with Lior Ben Dor (2024-12-31 disable request).

---

*Generated: 2026-04-23 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 0 T1, 14 T2, 0 T3, 0 T4, 1 T5 | Elements: 15/15*
*Object: BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Aff_data | Type: Table | Production Source: SP_AML_Affiliate_Abuse (DISABLED 2024-12-31)*

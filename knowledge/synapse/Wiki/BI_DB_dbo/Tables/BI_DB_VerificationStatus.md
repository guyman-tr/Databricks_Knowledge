---
schema: BI_DB_dbo
table: BI_DB_VerificationStatus
documented: true
batch: 37
quality_score: 9.0
---

# BI_DB_VerificationStatus

## 1. Business Meaning

Rolling 6-month cohort view of **KYC verification, cashout behavior, and deposit activity** for recently acquired customers (first-time depositors). Refreshed daily with a full TRUNCATE + INSERT. Tracks whether new customers completed identity verification, how quickly they verified, whether they cashed out, and how much they deposited in their first 14 days.

Primary use cases: KYC compliance monitoring, acquisition quality analysis, early churn detection (cashout within the FTD cohort), and channel/affiliate performance by verification rate.

| Property | Value |
|----------|-------|
| Grain | One row per `RealCID` (customer) |
| Population | Valid customers (IsValidCustomer=1) with FTD in rolling ~6-month window |
| Population window | Start-of-month 6 months ago through 15 days before today |
| Row count | ~223,915 (as of 2026-04-22; window: 2025-10-01 – 2026-04-07) |
| Distribution | ROUND_ROBIN |
| Index | HEAP |
| ETL pattern | TRUNCATE + INSERT daily (full refresh — not incremental) |
| Verified rate | ~96.6% in current cohort |
| With cashout rate | ~41.4% in current cohort |

---

## 2. Business Logic

### 2.1 Rolling FTD Cohort Window

The population is **always the last ~6 months of FTDs**, not a fixed historical snapshot:

```
Window start (@ftd_sd): First day of the month 6 months before GETDATE()
Window end (@ftd_ed):   GETDATE() - 15 days
```

Because the table is fully truncated and rebuilt each day, older cohorts age out automatically — customers whose FTD was more than 6 months ago disappear from the table. This is not a historical record; it is a current-state view of the recent FTD cohort.

### 2.2 Verification Status

`Verified = 1` means the customer reached `VerificationLevelID = 3` (full KYC) at least once in their `Fact_SnapshotCustomer` history. `VerificationDate` is the first date they reached level 3.

`PVDate` = first date the customer had `PlayerStatusID = 13` ("Pending Verification") — the status assigned when a customer has submitted documents and is awaiting review. This is distinct from `VerificationDate` (when they passed review).

KYC verification level hierarchy (from Dim_Customer / Fact_SnapshotCustomer):
- 0 = Unverified
- 1 = Partial (e.g., email confirmed)
- 2 = Intermediate
- 3 = Fully verified ← `Verified = 1` threshold

### 2.3 Cashout Tracking

`DidCO = 1` if the customer made at least one non-zero cashout (`Fact_CustomerAction.ActionTypeID = 8`) with `DateID >= @ftd_sdID` (within the same 6-month lookback window). `CO` = total cashout amount.

### 2.4 First 14 Days Deposit

`First14DaysDeposit` = SUM of deposit amounts (`ActionTypeID = 7`) where `DATEDIFF(DAY, FirstDepositDate, Occurred) <= 14`. This captures the initial deposit commitment within the customer's first 2 weeks, a common early-life value indicator.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP. No distribution key means joins on `RealCID` will cause data movement. For best performance, join with HASH-distributed tables using CTEs or materialize the join result into a temp table first.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Verification rate by channel | `GROUP BY Channel, Verified` — `AVG(Verified)` for rate |
| Verification funnel (PV→verified) | `WHERE PVDate IS NOT NULL GROUP BY CASE WHEN Verified=1 THEN 'Verified' ELSE 'Pending' END` |
| First 14-day deposit by affiliate | `GROUP BY AffiliateID, SUM(First14DaysDeposit)` |
| Cash-out rate by region | `GROUP BY Region, SUM(DidCO)` |
| KYC turnaround time | `AVG(DATEDIFF(DAY, FirstDepositDate, VerificationDate)) WHERE Verified=1` |

### 3.3 Gotchas

- **This table is a rolling window, not historical.** Customers whose FTD was more than 6 months ago are absent. Do not use for trend analysis — the population changes every day as new FTDs enter and old ones age out.
- **`VerificationDate` can be before `FirstDepositDate`.** The SP looks at all `Fact_SnapshotCustomer` history, not just the period after FTD. A customer who verified before making their first deposit (unusual but possible) will have `VerificationDate < FirstDepositDate`.
- **SELECT DISTINCT may mask multi-cashout counting.** The final INSERT uses `SELECT DISTINCT`, which deduplicates on `RealCID`. However, the multi-way LEFT JOIN structure can produce fan-out in intermediate steps. Always interpret `CO` as the final aggregated value from `#co`, not a row count.
- **`IsAddressProof` / `IsIDProof` can be NULL** near the window cutoff. The #uploaded sub-query uses a slightly different date boundary than the main population — customers with FTD very close to `@ftd_ed` may have NULL for these fields.
- **Hourly sibling table.** `BI_DB_VerificationStatus30Days` (written by `SP_H_VerificationStatus30Days`, Priority=0, Hourly) covers a narrower 30-day window with hourly freshness. Use that for real-time KYC monitoring; use this table for the full 6-month FTD cohort view.
- **`PVDate` NULLs are common.** Many customers go directly from unverified to verified without a "Pending Verification" state. `PVDate IS NULL` does not mean they never submitted documents — it means they were never in PlayerStatusID=13 specifically.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — DWH_dbo wiki verbatim | (Tier 1 — DWH_dbo wiki, `{source}`) |
| Tier 2 — SP ETL code | (Tier 2 — SP_VerificationStatus) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | NOT NULL | Real customer identifier. Primary key for this table (one row per customer). Joins to `DWH_dbo.Dim_Customer.RealCID`. (Tier 1 — DWH_dbo wiki, Dim_Customer) |
| 2 | FirstDepositDate | datetime | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. The population filter key — determines which 6-month cohort this customer belongs to. (Tier 1 — DWH_dbo wiki, Dim_Customer) |
| 3 | AffiliateID | int | YES | Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 — DWH_dbo wiki, Dim_Customer) |
| 4 | SubChannel | varchar(100) | YES | Granular sub-channel name within the parent Channel. Human-readable label for SubChannelID. Examples: 'Google Brand', 'Google Search', 'FB', 'Taboola', 'Twitter', 'Outbrain', 'Bing Search', 'Direct', 'SEO', 'Affiliate', 'IBs'. Sourced via Dim_Affiliate → Dim_Channel. (Tier 1 — DWH_dbo wiki, Dim_Channel) |
| 5 | Channel | varchar(50) | YES | Top-level marketing channel category. Derived from AffWizz MarketingExpense.MarketingExpenseName with overrides: 'Introducing Agents' → 'Affiliate', AffiliateID IN (56662,56663) → 'Direct'. Common values: Direct, SEM, SEO, Affiliate, Mobile Acquisition, Friend Referral, Media Programmatic, TV, Social Organic. Sourced via Dim_Affiliate → Dim_Channel. (Tier 1 — DWH_dbo wiki, Dim_Channel) |
| 6 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Sourced from `DWH_dbo.Dim_Country.Name` (aliased as `Country`). (Tier 1 — DWH_dbo wiki, Dim_Country) |
| 7 | Region | varchar(50) | YES | Marketing region label for this country. Loaded from Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. Up to 21 distinct values (e.g., "ROW", "Africa", "French", "Arabic"). Used for marketing campaign grouping. |
| 8 | Verified | int | YES | 1 if the customer has reached KYC VerificationLevelID=3 (fully verified) at any point in their `Fact_SnapshotCustomer` history; 0 otherwise. Computed as `MAX(CASE WHEN VerificationLevelID=3 THEN 1 ELSE 0 END)`. (Tier 2 — SP_VerificationStatus) |
| 9 | VerificationDate | date | YES | First date the customer reached full KYC verification (VerificationLevelID=3). Sourced from `MIN(Dim_Date.FullDate WHERE VerificationLevelID=3)`. NULL if `Verified=0`. Note: can precede `FirstDepositDate`. (Tier 2 — SP_VerificationStatus) |
| 10 | PVDate | date | YES | First date the customer was in "Pending Verification" status (PlayerStatusID=13). This is when documents were submitted and verification was awaiting review. NULL if the customer never entered this specific status. Sourced from `MIN(Dim_Date.FullDate WHERE PlayerStatusID=13)`. (Tier 2 — SP_VerificationStatus) |
| 11 | DidCO | int | YES | 1 if the customer made at least one non-zero cashout (ActionTypeID=8) with `DateID >= @ftd_sdID`; 0 otherwise. (Tier 2 — SP_VerificationStatus) |
| 12 | CO | decimal(11,2) | YES | Total cashout amount (USD) for cashouts with `DateID >= @ftd_sdID`. 0 if no cashouts. (Tier 2 — SP_VerificationStatus) |
| 13 | First14DaysDeposit | decimal(20,2) | YES | Sum of all deposit amounts (ActionTypeID=7) within the customer's first 14 days after `FirstDepositDate`. NULL if no deposits in that window. Measures early-life deposit commitment. (Tier 2 — SP_VerificationStatus) |
| 14 | IsAddressProof | int | YES | Whether address proof document is on file (1/0). Updated from BackOffice.CustomerDocument. NULL for customers near the cohort cutoff date. (Tier 1 — DWH_dbo wiki, Dim_Customer) |
| 15 | IsIDProof | int | YES | Whether ID proof document is on file (1/0). Updated from BackOffice.CustomerDocument. NULL for customers near the cohort cutoff date. (Tier 1 — DWH_dbo wiki, Dim_Customer) |
| 16 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to GETDATE() on each daily TRUNCATE+INSERT. (Tier 2 — ETL metadata) |
| 17 | PendingClosureStatusID | int | YES | Status in the pending closure workflow. Default=1 (no pending closure). Updated when customer requests account closure. From `DWH_dbo.Dim_Customer` (current snapshot). (Tier 1 — DWH_dbo wiki, Dim_Customer) |
| 18 | PlayerStatusReasonID | int | YES | Reason code for current PlayerStatusID. Provides the why behind a non-Active status. From `DWH_dbo.Dim_Customer` (current snapshot). (Tier 1 — DWH_dbo wiki, Dim_Customer) |
| 19 | PlayerStatusID | int | YES | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Normal (97.5% of accounts); other values indicate restricted, closed, banned, or special states. From `DWH_dbo.Dim_Customer` (current snapshot). (Tier 1 — DWH_dbo wiki, Dim_Customer) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | Passthrough — also population filter |
| AffiliateID | DWH_dbo.Dim_Customer | AffiliateID | Passthrough |
| SubChannel | DWH_dbo.Dim_Channel | SubChannel | Passthrough via Dim_Affiliate.SubChannelID |
| Channel | DWH_dbo.Dim_Channel | Channel | Passthrough via Dim_Affiliate.SubChannelID |
| Country | DWH_dbo.Dim_Country | Name | Passthrough, aliased Country |
| Region | DWH_dbo.Dim_Country | Region | Passthrough |
| Verified | DWH_dbo.Fact_SnapshotCustomer | VerificationLevelID | MAX(1 if level=3) over history |
| VerificationDate | DWH_dbo.Fact_SnapshotCustomer + Dim_Date | VerificationLevelID, FullDate | MIN(FullDate) where level=3 |
| PVDate | DWH_dbo.Fact_SnapshotCustomer + Dim_Date | PlayerStatusID, FullDate | MIN(FullDate) where PlayerStatusID=13 |
| DidCO | DWH_dbo.Fact_CustomerAction | Amount, ActionTypeID=8 | MAX(Amount!=0) |
| CO | DWH_dbo.Fact_CustomerAction | Amount, ActionTypeID=8 | ISNULL(SUM, 0) |
| First14DaysDeposit | DWH_dbo.Fact_CustomerAction | Amount, ActionTypeID=7 | SUM within 14 days of FTD |
| IsAddressProof | DWH_dbo.Dim_Customer | IsAddressProof | Passthrough (via #uploaded) |
| IsIDProof | DWH_dbo.Dim_Customer | IsIDProof | Passthrough (via #uploaded) |
| PendingClosureStatusID | DWH_dbo.Dim_Customer | PendingClosureStatusID | Passthrough |
| PlayerStatusReasonID | DWH_dbo.Dim_Customer | PlayerStatusReasonID | Passthrough |
| PlayerStatusID | DWH_dbo.Dim_Customer | PlayerStatusID | Passthrough |
| UpdateDate | — | — | GETDATE() |

---

## 6. Relationships

| Related Object | Relationship | Join |
|---------------|-------------|------|
| DWH_dbo.Dim_Customer | Primary source | `Dim_Customer.RealCID = RealCID` |
| DWH_dbo.Dim_Channel | Acquisition channel | `Dim_Channel.SubChannelID = Dim_Affiliate.SubChannelID` |
| DWH_dbo.Dim_Country | Country / region | `Dim_Country.CountryID = Dim_Customer.CountryID` |
| DWH_dbo.Fact_SnapshotCustomer | Verification history | `Fact_SnapshotCustomer.RealCID = RealCID` |
| DWH_dbo.Fact_CustomerAction | Deposits & cashouts | `Fact_CustomerAction.RealCID = RealCID AND ActionTypeID IN (7,8)` |
| BI_DB_dbo.BI_DB_VerificationStatus30Days | Hourly sibling (30-day window) | Parallel table, Priority=0 |

---

## 7. Sample Queries

### Verification rate by channel
```sql
SELECT Channel,
       COUNT(*) AS Total,
       SUM(Verified) AS Verified,
       CAST(SUM(Verified) AS FLOAT) / COUNT(*) AS VerificationRate
FROM BI_DB_dbo.BI_DB_VerificationStatus
GROUP BY Channel
ORDER BY VerificationRate DESC;
```

### Average days to verify by region
```sql
SELECT Region,
       AVG(DATEDIFF(DAY, CAST(FirstDepositDate AS DATE), VerificationDate)) AS AvgDaysToVerify
FROM BI_DB_dbo.BI_DB_VerificationStatus
WHERE Verified = 1
  AND VerificationDate >= CAST(FirstDepositDate AS DATE)
GROUP BY Region;
```

### First 14-day deposit by deposit tier
```sql
SELECT DepositTier = CASE WHEN First14DaysDeposit IS NULL THEN 'No deposit'
                          WHEN First14DaysDeposit <= 100 THEN '<=100'
                          WHEN First14DaysDeposit <= 500 THEN '101-500'
                          ELSE '>500' END,
       COUNT(*) AS Customers
FROM BI_DB_dbo.BI_DB_VerificationStatus
GROUP BY CASE WHEN First14DaysDeposit IS NULL THEN 'No deposit'
              WHEN First14DaysDeposit <= 100 THEN '<=100'
              WHEN First14DaysDeposit <= 500 THEN '101-500'
              ELSE '>500' END;
```

---

## 8. Atlassian / External References

No Jira tickets or Confluence pages identified for this table during documentation.

---

*Generated: 2026-04-22 | Batch 37 | Quality: 9.0/10*

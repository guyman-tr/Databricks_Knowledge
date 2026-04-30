# AffiliateCommission.ClosedPositionDailySummary

> Pre-aggregated daily summary of closed position commissions per affiliate, customer, and tier - optimized for fast reporting by the affiliate summary report system.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | AffiliateID + CommissionDate + CID + Tier (composite logical key) |
| **Partition** | Yes - PS_Mod100 on PartitionCol (AffiliateID % 100) |
| **Indexes** | 5 active (1 clustered + 4 NC) |

---

## 1. Business Meaning

ClosedPositionDailySummary is a pre-aggregated reporting table that stores daily commission totals per affiliate, customer, tier, and country combination. It exists purely for performance optimization - the affiliate summary report (AffiliateReport.ReportSummaryByAffiliate) reads from this table instead of scanning the much larger ClosedPosition + ClosedPositionCommission tables directly.

This table was created in July 2022 to address performance issues in affiliate reporting. Without it, every report request would need to join ClosedPosition with ClosedPositionCommission and aggregate on the fly across hundreds of thousands of rows. The daily summary reduces this to a compact 102K-row table covering 275 affiliates.

Data is populated by the AggregateClosedPositionDailyData stored procedure, which runs daily. It inserts new aggregated rows for positions closed since the last aggregation, and also retroactively fixes the Paid status for the prior 3 months (since commissions may be marked as paid after the initial aggregation). The Total column represents net commission: Amount minus HedgeCommission.

---

## 2. Business Logic

### 2.1 Daily Aggregation Logic

**What**: Positions are grouped by affiliate, customer, date, tier, country, and payment status into daily summary rows.

**Columns/Parameters Involved**: `AffiliateID`, `CommissionDate`, `CID`, `Tier`, `Commission`, `Total`

**Rules**:
- Commission = SUM of ClosedPositionCommission.Commission for all positions in the group
- Total = SUM of (ClosedPosition.Amount - ClosedPosition.HedgeCommission) for all positions in the group
- CommissionDate and TrackingDate are truncated to date (no time component)
- Aggregation runs from the day after the last existing CommissionDate to today's midnight
- Uses OPTION(RECOMPILE) for optimal query plan with variable date ranges

**Diagram**:
```
ClosedPosition + ClosedPositionCommission
  |
  | AggregateClosedPositionDailyData (daily batch)
  | GROUP BY AffiliateID, CID, Tier, Date, Country, Paid, PaymentID, Valid
  |
  v
ClosedPositionDailySummary
  |
  v
AffiliateReport.ReportSummaryByAffiliate (fast reads)
```

### 2.2 Retroactive Paid Status Fix

**What**: The batch job fixes the Paid flag for commissions that were paid after initial aggregation.

**Columns/Parameters Involved**: `Paid`, `PaymentID`, `Valid`

**Rules**:
- Scans the last 3 months of source data for commissions where Paid = 1
- Matches against summary rows on all dimension columns (AffiliateID, CID, Tier, CommissionDate, TrackingDate, Total, CountryID)
- Updates Paid from 0 to 1 and sets the PaymentID and Valid from the source
- This handles the common case where a commission is calculated (Paid=0) and later included in a payment batch (Paid=1)

---

## 3. Data Overview

| AffiliateID | CommissionDate | CID | Commission | Tier | Total | CountryID | Paid | Meaning |
|---|---|---|---|---|---|---|---|---|
| 3 | 2026-03-31 | 25589898 | 0 | 1 | 0 | 196 | 0 | Daily summary for affiliate 3, customer 25589898, tier 1. Zero commission - position(s) generated no commission. Country 196. Unpaid. |
| 3 | 2026-03-31 | 25589913 | 0 | 1 | 0 | 196 | 0 | Same affiliate and date, different customer. Pattern of zero-commission positions common in this environment. |
| 3 | 2026-03-31 | 25589926 | 0 | 1 | 0 | 196 | 0 | Continued batch of Tier 1 summaries for affiliate 3. All from country 196, all zero-commission. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | Identifier of the affiliate earning commissions. Source: ClosedPositionCommission.AffiliateID. Used as the primary partition key (PartitionCol = AffiliateID % 100) and first column in the clustered index. |
| 2 | PartitionCol | computed (int) | NO | AffiliateID % 100, PERSISTED | CODE-BACKED | Computed partition column. Formula: AffiliateID modulo 100. Distributes data across 100 partitions on PS_Mod100 scheme. PERSISTED for index use. Enables partition elimination when querying by AffiliateID. |
| 3 | CommissionDate | date | NO | - | CODE-BACKED | Date portion of the position's commission date (time truncated). Source: CAST(ClosedPosition.CommissionDate AS DATE). Used with AffiliateID in the clustered index for efficient date-range reporting. |
| 4 | CID | bigint | NO | - | CODE-BACKED | Customer ID of the trader. Source: ClosedPosition.CID. Each row represents one affiliate-customer-tier-date combination. |
| 5 | Commission | float | YES | - | CODE-BACKED | Total commission earned by this affiliate for this customer on this date at this tier. Source: SUM(ClosedPositionCommission.Commission). NULL possible if no commission rows exist (unlikely in practice). |
| 6 | Tier | int | NO | - | CODE-BACKED | Commission tier level. Source: ClosedPositionCommission.Tier. 1 = direct referrer, 2+ = upstream affiliates. Part of the grouping key. |
| 7 | TrackingDate | date | NO | - | CODE-BACKED | Date when the positions were first tracked by the commission system (time truncated). Source: CAST(ClosedPosition.TrackingDate AS DATE). Indexed for tracking-based report queries. |
| 8 | Total | decimal(38,6) | YES | - | CODE-BACKED | Net commission-eligible amount. Computed as SUM(Amount - HedgeCommission) from ClosedPosition. Represents the total spread/commission value net of hedge costs. NULL possible for edge cases. |
| 9 | CountryID | bigint | NO | - | CODE-BACKED | Country of the customer. Source: ClosedPosition.CountryID. Part of the grouping key for geography-based reporting. |
| 10 | Paid | bit | NO | - | CODE-BACKED | Whether the commission has been paid to the affiliate. Source: ClosedPositionCommission.Paid. Initially 0, updated to 1 by the retroactive fix in AggregateClosedPositionDailyData (3-month lookback). |
| 11 | PaymentID | int | YES | - | CODE-BACKED | Payment batch identifier. Source: ClosedPositionCommission.PaymentID. NULL or 0 when unpaid; populated with the batch ID when paid. Updated by the retroactive paid fix. |
| 12 | Valid | bit | YES | - | CODE-BACKED | Whether the underlying positions are valid for commission. Source: ClosedPosition.Valid. Added in PART-3602 (Jun 2024). Updated by the retroactive fix. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | AffiliateCommission.ClosedPositionCommission | Implicit | Aggregated from commission records |
| CID | AffiliateCommission.ClosedPosition | Implicit | Customer from position records |
| CountryID | External country reference | Implicit | Geographic dimension |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.AggregateClosedPositionDailyData | INSERT/UPDATE | Writer/Modifier | Daily batch populates and fixes paid status |
| AffiliateReport.ReportSummaryByAffiliate | SELECT | Reader | Primary consumer - fast affiliate reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (aggregated data, not FK-bound).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.AggregateClosedPositionDailyData | Stored Procedure | Writer - daily aggregation batch |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CPK_ClosedPositionDailySummary | CLUSTERED | AffiliateID, PartitionCol, CommissionDate | - | - | Active |
| IX_ClosedPositionDailySummary_CommissionDateAffiliateID | NC | CommissionDate, Tier, PartitionCol | - | - | Active |
| IX_ClosedPositionDailySummary_CommissionDateTier | NC | CommissionDate, Tier | CID, Commission, Total | - | Active |
| IX_ClosedPositionDailySummary_TrackingDateAffiliateID | NC | TrackingDate, Tier, PartitionCol | - | - | Active |
| IX_ClosedPositionDailySummary_TrackingDateTier_Covering | NC | TrackingDate, Tier, PartitionCol | AffiliateID, CID, Commission, Total | - | Active |

### 7.2 Constraints

None beyond NOT NULL. No PK constraint defined (clustered index without UNIQUE). All indexes use PAGE compression. Partitioned on PS_Mod100(PartitionCol).

---

## 8. Sample Queries

### 8.1 Daily commission totals per affiliate
```sql
SELECT AffiliateID, CommissionDate,
       SUM(Commission) AS TotalCommission,
       SUM(Total) AS NetTotal,
       COUNT(DISTINCT CID) AS UniqueCustomers
FROM AffiliateCommission.ClosedPositionDailySummary WITH (NOLOCK)
WHERE CommissionDate >= '2026-03-01'
GROUP BY AffiliateID, CommissionDate
ORDER BY CommissionDate DESC, TotalCommission DESC;
```

### 8.2 Unpaid commission summary by affiliate
```sql
SELECT AffiliateID,
       SUM(Commission) AS UnpaidCommission,
       COUNT(*) AS UnpaidRows
FROM AffiliateCommission.ClosedPositionDailySummary WITH (NOLOCK)
WHERE Paid = 0 AND Valid = 1
GROUP BY AffiliateID
ORDER BY UnpaidCommission DESC;
```

### 8.3 Commission by country and tier
```sql
SELECT CountryID, Tier,
       SUM(Commission) AS TotalCommission,
       COUNT(DISTINCT AffiliateID) AS AffiliateCount
FROM AffiliateCommission.ClosedPositionDailySummary WITH (NOLOCK)
WHERE CommissionDate >= DATEADD(month, -1, GETUTCDATE())
  AND Valid = 1
GROUP BY CountryID, Tier
ORDER BY TotalCommission DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-3602](https://etoro-jira.atlassian.net/browse/PART-3602) | Jira | Added Valid column, removed OriginalCID/BannerID/AffiliateCampaign from daily summary (Jun 2024) |
| [PART-2440](https://etoro-jira.atlassian.net/browse/PART-2440) | Jira | Added support for new CPA revenue in aggregation (Nov 2023) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ClosedPositionDailySummary | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.ClosedPositionDailySummary.sql*

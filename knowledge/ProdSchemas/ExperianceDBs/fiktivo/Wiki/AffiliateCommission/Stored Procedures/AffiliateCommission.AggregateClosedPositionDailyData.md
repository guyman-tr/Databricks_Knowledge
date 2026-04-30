# AffiliateCommission.AggregateClosedPositionDailyData

> Daily batch procedure that aggregates closed position commissions into a pre-computed summary table for fast affiliate reporting, and retroactively fixes paid status for the prior 3 months.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Populates ClosedPositionDailySummary |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AggregateClosedPositionDailyData is a daily batch job that pre-computes aggregated commission data from the ClosedPosition and ClosedPositionCommission tables into the ClosedPositionDailySummary table. This aggregation exists purely for reporting performance - the affiliate summary report (AffiliateReport.ReportSummaryByAffiliate) reads from the compact summary table instead of scanning and grouping the much larger source tables on each request.

Without this procedure, every affiliate report request would need to join ClosedPosition with ClosedPositionCommission and perform aggregation across hundreds of thousands of rows. The daily summary reduces this to a pre-computed table that can be queried directly.

The procedure performs two distinct operations each run: (1) INSERT new aggregated rows for positions closed since the last aggregation date, and (2) UPDATE the Paid status for rows in the prior 3 months where commissions have been marked as paid after the initial aggregation. This retroactive fix is necessary because commission payments happen asynchronously - a commission aggregated today may not be paid until weeks later.

---

## 2. Business Logic

### 2.1 Incremental Daily Aggregation

**What**: New daily summary rows are inserted only for positions closed since the last aggregation, avoiding full table rescans.

**Columns/Parameters Involved**: `CommissionDate`, `@V_LastCommissionDate`, `@V_MidNightDate`

**Rules**:
- The procedure determines the starting point by reading MAX(CommissionDate) + 1 day from ClosedPositionDailySummary
- The end boundary is today's date at midnight (cast to DATE, no time component)
- Positions are grouped by AffiliateID, CID, Tier, CommissionDate (date only), TrackingDate (date only), CountryID, Paid, PaymentID, and Valid
- Commission = SUM(ClosedPositionCommission.Commission) per group
- Total = SUM(ClosedPosition.Amount - ClosedPosition.HedgeCommission) per group, representing net commission-eligible revenue
- Uses OPTION(RECOMPILE) for optimal query plan with variable date ranges

**Diagram**:
```
ClosedPosition + ClosedPositionCommission
  |
  | JOIN on ClosedPositionID
  | WHERE CommissionDate >= LastAggDate AND < Today
  | GROUP BY Affiliate, CID, Tier, Date, Country, Paid, PaymentID, Valid
  |
  v
INSERT INTO ClosedPositionDailySummary
```

### 2.2 Retroactive Paid Status Fix (3-Month Window)

**What**: Commissions paid after initial aggregation get their Paid flag corrected in the summary table.

**Columns/Parameters Involved**: `Paid`, `PaymentID`, `Valid`

**Rules**:
- Scans the last 3 months of ClosedPositionCommission where Paid = 1
- Aggregates into a temp table (#temp3Mon) with the same grouping as the daily insert
- Joins to ClosedPositionDailySummary on the full composite key (AffiliateID, CID, Commission, Tier, CommissionDate, TrackingDate, Total, CountryID)
- Only updates rows where the summary has Paid = 0 (not yet marked as paid)
- Updates Paid to 1, sets PaymentID and Valid from the source data
- The ISNULL(D.PaymentID, T.PaymentID) = T.PaymentID condition handles both NULL and matching PaymentIDs

**Diagram**:
```
ClosedPositionCommission (Paid=1, last 3 months)
  |
  | JOIN ClosedPosition, aggregate
  v
#temp3Mon (paid commission summaries)
  |
  | JOIN ClosedPositionDailySummary WHERE Paid=0
  v
UPDATE Paid=1, PaymentID, Valid
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input or output parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @V_LastCommissionDate | datetime (local) | - | - | CODE-BACKED | Start boundary for incremental aggregation. Set to MAX(CommissionDate) + 1 day from ClosedPositionDailySummary. Ensures only new positions since last run are aggregated. |
| 2 | @V_MidNightDate | date (local) | - | - | CODE-BACKED | End boundary for aggregation. Set to today's date (GETUTCDATE cast to DATE). Positions with CommissionDate on or after today are excluded to avoid partial-day data. |
| 3 | @StartDate | datetime (local) | - | - | CODE-BACKED | Start of the 3-month lookback window for retroactive paid status fixes. Set to DATEADD(month, -3, today's date). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.ClosedPosition | READ (SELECT) | Source of position financial data (Amount, HedgeCommission, CommissionDate, TrackingDate, CountryID, Valid) for aggregation |
| - | AffiliateCommission.ClosedPositionCommission | READ (SELECT) | Source of per-affiliate commission amounts (AffiliateID, Commission, Tier, Paid, PaymentID) for aggregation |
| - | AffiliateCommission.ClosedPositionDailySummary | WRITE (INSERT, UPDATE, READ) | Target table - receives aggregated daily summaries and retroactive paid status updates |

### 5.2 Referenced By (other objects point to this)

No callers found in the AffiliateCommission schema. This procedure is likely invoked by an external SQL Agent job or scheduled task.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.AggregateClosedPositionDailyData (procedure)
+-- AffiliateCommission.ClosedPosition (table)
+-- AffiliateCommission.ClosedPositionCommission (table)
+-- AffiliateCommission.ClosedPositionDailySummary (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPosition | Table | JOINed to ClosedPositionCommission on ClosedPositionID; provides Amount, HedgeCommission, CommissionDate, TrackingDate, CountryID, CID, Valid |
| AffiliateCommission.ClosedPositionCommission | Table | JOINed to ClosedPosition; provides AffiliateID, Commission, Tier, Paid, PaymentID |
| AffiliateCommission.ClosedPositionDailySummary | Table | Target for INSERT (new daily aggregations) and UPDATE (paid status fixes); also READ for MAX(CommissionDate) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (External scheduler) | SQL Agent Job | Executes this procedure daily |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the daily aggregation
```sql
EXEC [AffiliateCommission].[AggregateClosedPositionDailyData]
```

### 8.2 Check the last aggregation date
```sql
SELECT MAX(CommissionDate) AS LastAggregatedDate
FROM [AffiliateCommission].[ClosedPositionDailySummary] WITH (NOLOCK)
```

### 8.3 Verify aggregation accuracy for a specific date
```sql
-- Compare raw vs aggregated totals for a given date
SELECT
    saleC.AffiliateID,
    CAST(sale.CommissionDate AS date) AS CommissionDate,
    SUM(saleC.Commission) AS RawCommission,
    SUM(sale.Amount - sale.HedgeCommission) AS RawTotal
FROM [AffiliateCommission].[ClosedPositionCommission] AS saleC WITH (NOLOCK)
INNER JOIN [AffiliateCommission].[ClosedPosition] AS sale WITH (NOLOCK)
    ON saleC.ClosedPositionID = sale.ClosedPositionID
WHERE CAST(sale.CommissionDate AS date) = '2026-04-10'
GROUP BY saleC.AffiliateID, CAST(sale.CommissionDate AS date)
ORDER BY saleC.AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found for this object. Jira MCP returned 410 errors (project unavailable).

DDL comments reference the following tickets:
- PART-3602: Added Valid column to daily table, removed OriginalCID, BannerID, AffiliateCampaign fields (2024-11-06)
- PART-2440: Added support for new CPA revenue model (2023-11-28)
- Unlabeled fix: Fixed Paid column retroactive update for previous 3 months (2023-03-13)
- Creation: New SP created to populate ClosedPositionDailySummary for report performance (2022-07-24)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.AggregateClosedPositionDailyData | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.AggregateClosedPositionDailyData.sql*

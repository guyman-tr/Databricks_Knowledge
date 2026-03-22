# Dealing_CIDs_CommissionsAndFails_PIs

## 1. Business Meaning

Daily snapshot of the **top 20 Popular Investor (PI) customers by total commission** earned by eToro on a given date. Identical structure and logic to `Dealing_CIDs_CommissionsAndFails` but filtered to customers with `GuruStatusID IN (5, 6)` — the Popular Investor designation.

Popular Investors are eToro users who have qualified for the PI program (based on AUM, follower count, performance, etc.). They receive special compensation from eToro related to their copiers' activity. Monitoring their commission and fail metrics separately helps the PI program team track execution quality for this high-profile segment.

**Contains PII:** `CID` (customer ID) and `UserName`. Handle under data classification policy.

**Scale and activity:** 2023-05-29 to 2026-03-10, **active daily pipeline**. ~217 unique PIs have appeared since May 2023. Typically fewer than 20 rows per day (there may be fewer than 20 active PIs on some days).

**Coverage start:** Added 2023-05-29 — two months after the base table was first created.

## 2. Business Logic

All logic is identical to `Dealing_CIDs_CommissionsAndFails` with one addition:

**PI filter:** `GuruStatusID IN (5, 6)` in `#Commissions_Data_PIs`:
```sql
WHERE isnull(tdcn.GuruStatusID, tdf.GuruStatusID) IN (5,6)
order by TotalCommission desc
```

This filters the FULL OUTER JOIN result to only Popular Investor-flagged customers before selecting the top 20. The result is: the top 20 PIs by commission on each date.

**GuruStatusID meanings:**
- 5 = Popular Investor (standard)
- 6 = Popular Investor (higher tier — Platinum Plus or equivalent)

The commission attribution formula and Ratio calculation are identical to the non-PI table.

## 3. Query Advisory

**Distribution:** HASH(CID). JOINs on CID efficient.

**Very small population:** Only 217 unique PIs have ever appeared (2023-2026). Some days have fewer than 20 rows if fewer than 20 PIs had activity above zero commission threshold.

**Compare to non-PI table:** To find non-PI high earners, SELECT from CommissionsAndFails WHERE CID NOT IN (SELECT CID FROM CommissionsAndFails_PIs).

```sql
-- PI fail rate trend by regulation
SELECT YEAR(Date) yr, MONTH(Date) mo, Regulation,
    AVG(Ratio) AS avg_fail_rate,
    SUM(TotalCommission) AS total_commission_usd,
    COUNT(DISTINCT CID) AS unique_pi_cids
FROM Dealing_dbo.Dealing_CIDs_CommissionsAndFails_PIs
GROUP BY YEAR(Date), MONTH(Date), Regulation
ORDER BY yr DESC, mo DESC

-- Current top PIs with high fail rate
SELECT Date, CID, UserName, GuruStatus, TotalCommission, Count_Fails, Ratio
FROM Dealing_dbo.Dealing_CIDs_CommissionsAndFails_PIs
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_CIDs_CommissionsAndFails_PIs)
ORDER BY Ratio DESC
```

## 4. Elements

Identical column set to `Dealing_CIDs_CommissionsAndFails`. See that table for full descriptions.

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date for which the top-20 PIs are calculated. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| CID | int | Popular Investor customer ID. PII. GuruStatusID IN (5,6). (Tier 1 — upstream wiki, Customer.CustomerStatic) |
| UserName | varchar | PI login username. PII. (Tier 1 — upstream wiki, Customer.CustomerStatic) |
| Region | varchar | PI's geographic region from Dim_Country. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| PlayerLevelID | int | Customer experience tier. For PIs typically 4+ (Popular Investor or higher). (Tier 1 — upstream wiki, Customer.CustomerStatic) |
| PlayerLevel | varchar | PlayerLevelID text from Dim_PlayerLevel. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| GuruStatus | varchar | PI status tier label (e.g., "Popular Investor", "Platinum Plus"). Always non-null for GuruStatusID IN (5,6). (Tier 2 — SP_CommissionsAndFails_PerCID) |
| Regulation | varchar | PI's regulatory jurisdiction. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| NOP | money | Net Open Position value in USD at end of day. Sum of all open positions. From BI_DB_PositionPnL. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| Count_Fails | int | Number of failed trade attempts on this date. NULL = 0 fails. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| TotalCommission | money | Commission earned from this PI's positions on this date. Same date-attribution formula as non-PI table. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| Success_Positions | int | Count of positions active on this date (opened or closed today). (Tier 2 — SP_CommissionsAndFails_PerCID) |
| Ratio | float | Fail rate: `Count_Fails / Success_Positions`. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| UpdateDate | datetime | Row insertion timestamp. (Tier 2 — SP_CommissionsAndFails_PerCID) |

## 5. Lineage

Same sources as `Dealing_CIDs_CommissionsAndFails`. The PI variant uses `#Commissions_Data_PIs` which adds `WHERE GuruStatusID IN (5,6)` before selecting TOP 20.

**ETL:** `Dealing_dbo.SP_CommissionsAndFails_PerCID` → `Dealing_dbo.Dealing_CIDs_CommissionsAndFails_PIs`

**Coverage:** 2023-05-29 to present (active).

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_CIDs_CommissionsAndFails` | Parent table; non-PI version; available from 2022-12-01 |
| `Dealing_dbo.Dealing_FailReasons_Top20_PIs` | Fail reasons for exactly these top-20 PIs (no HedgeServerID dimension) |
| `DWH_dbo.Dim_Customer` | JOIN on CID for current PI attributes |

## 7. Sample Queries

```sql
-- PIs with consistently high fail rates over 3 months
SELECT CID, UserName, GuruStatus,
    COUNT(*) AS days_in_top20,
    AVG(TotalCommission) AS avg_daily_commission,
    AVG(Ratio) AS avg_fail_rate,
    MAX(Count_Fails) AS max_single_day_fails
FROM Dealing_dbo.Dealing_CIDs_CommissionsAndFails_PIs
WHERE Date >= DATEADD(MONTH, -3, GETDATE())
GROUP BY CID, UserName, GuruStatus
HAVING AVG(Ratio) > 0.05
ORDER BY avg_fail_rate DESC

-- Compare PI vs non-PI average commission per day
SELECT a.Date,
    AVG(a.TotalCommission) AS avg_non_pi_commission,
    AVG(b.TotalCommission) AS avg_pi_commission
FROM Dealing_dbo.Dealing_CIDs_CommissionsAndFails a
LEFT JOIN Dealing_dbo.Dealing_CIDs_CommissionsAndFails_PIs b ON a.Date=b.Date
WHERE a.Date >= '2025-01-01'
GROUP BY a.Date
ORDER BY a.Date DESC
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.

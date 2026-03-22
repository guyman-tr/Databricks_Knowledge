# Dealing_CIDs_CommissionsAndFails

## 1. Business Meaning

Daily snapshot of the **top 20 customers by total commission** earned by eToro on a given date. For each of these 20 customers, records their commission earned, Net Open Position (NOP) value, number of failed trade attempts, number of successful trades, and fail rate (`Ratio`).

Produced by `SP_CommissionsAndFails_PerCID`. Used for daily monitoring of high-value traders' activity quality — large commission generators who also have high fail rates may indicate UX friction, risk management issues, or unusual trading patterns.

**Contains PII:** `CID` (customer ID) and `UserName`. Handle under data classification policy.

**Scale and activity:** 2022-12-01 to 2026-03-10, **active daily pipeline**. ~20 rows per date = 44,160 total rows across 3+ years, 12,157 unique CIDs (same customer can appear on multiple days).

**Companion table:** `Dealing_CIDs_CommissionsAndFails_PIs` — identical structure, filtered to Popular Investors (GuruStatusID IN (5,6)) only.

## 2. Business Logic

### 2.1 Commission Date Attribution

Commission is attributed to a date using a three-case formula:

| Open/Close Pattern | TotalCommission Formula | Explanation |
|-------------------|------------------------|-------------|
| `OpenDateID=@DateID AND CloseDateID=@DateID` | `FullCommissionOnClose` | Same-day round-trip: use close commission (captures full round-trip) |
| `OpenDateID<@DateID AND CloseDateID=@DateID` | `FullCommissionOnClose - FullCommissionByUnits` | Closing a previously opened position: net of partial-open commission already booked |
| `OpenDateID=@DateID AND (CloseDateID>@DateID OR CloseDateID=0)` | `FullCommissionByUnits` | Opening a new position, still open: book the opening commission |
| All other | `0` | Open position from prior day still open — no commission attributed today |

This ensures each dollar of commission is attributed to exactly one date (either open or close day).

### 2.2 Selection Criteria: TOP 20 by TotalCommission

Only the top 20 CIDs by TotalCommission across all valid customers are captured per day. This means:
- High-volume, high-frequency traders dominate
- A customer not in the top 20 on a given day has no record for that day
- `Count_Fails` can be > 0 even for a customer with 0 commission (FULL OUTER JOIN with fails data)

### 2.3 NOP (Net Open Position)

NOP is sourced from `BI_DB_dbo.BI_DB_PositionPnL.NOP` — the mark-to-market P&L value of all open positions at end of day. A customer with a large NOP has significant open exposure.

### 2.4 Success_Positions Count

Counts positions where `OpenDateID = @DateID OR CloseDateID = @DateID` (positions active on that date), filtered to `IsValidCustomer=1`. This is the denominator for `Ratio`.

### 2.5 Fail Rate Ratio

```
Ratio = Count_Fails / Success_Positions
```

High ratio means many failed attempts relative to successful trades. A Ratio of 0.09 (from live data) means ~1 fail per 11 successful trades.

### 2.6 Player Level and GuruStatus

`PlayerLevelID` from Dim_Customer: 1=Standard, 4=Popular Investor, 7=VIP, 6=Platinum Plus, etc. `GuruStatus` and `GuruStatusID` from Dim_GuruStatus — additional Popular Investor tier information. These are included to identify if high-commission, high-fail customers are premium customers.

## 3. Query Advisory

**Distribution:** HASH(CID). JOINs on CID will be efficient.

**Only 20 rows per day:** This table is **not** a complete picture of all commission activity. For total commission analysis, use `BI_DB_dbo.BI_DB_PositionPnL` or `DWH_dbo.Dim_Position`.

**PII note:** `CID` and `UserName` are present. Apply appropriate access controls.

**Temporal analysis tip:** To find recurrently problematic customers, join across dates using CID.

```sql
-- Customers appearing most often in top-20 (chronic high-commission traders)
SELECT CID, UserName, PlayerLevel, GuruStatus, COUNT(*) AS days_in_top20,
    AVG(TotalCommission) AS avg_daily_commission,
    AVG(Ratio) AS avg_fail_rate
FROM Dealing_dbo.Dealing_CIDs_CommissionsAndFails
WHERE Date >= '2025-01-01'
GROUP BY CID, UserName, PlayerLevel, GuruStatus
ORDER BY days_in_top20 DESC

-- Latest day: top 20 with fail rate >10%
SELECT Date, CID, UserName, Regulation, TotalCommission, Count_Fails, Success_Positions, Ratio
FROM Dealing_dbo.Dealing_CIDs_CommissionsAndFails
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_CIDs_CommissionsAndFails)
  AND Ratio > 0.1
ORDER BY TotalCommission DESC
```

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date for which the top-20 is calculated. Equals `@Date` SP parameter. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| CID | int | Customer ID. PII — FK to `DWH_dbo.Dim_Customer.RealCID`. One of the top 20 by TotalCommission for this date. (Tier 1 — upstream wiki, Customer.CustomerStatic) |
| UserName | varchar | Customer login username. PII. From Dim_Customer. (Tier 1 — upstream wiki, Customer.CustomerStatic) |
| Region | varchar | Customer's geographic region (e.g., "Arabic GCC", "Western Europe"). From Dim_Country via Dim_Customer.CountryID. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| PlayerLevelID | int | Customer experience/permission tier. FK to Dim_PlayerLevel. 1=Standard, 4=Popular Investor, 6=Platinum Plus, 7=VIP. (Tier 1 — upstream wiki, Customer.CustomerStatic) |
| PlayerLevel | varchar | PlayerLevelID label text from Dim_PlayerLevel. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| GuruStatus | varchar | Popular Investor status name from Dim_GuruStatus. "No" if not a PI. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| Regulation | varchar | Customer's regulatory jurisdiction. From Dim_Regulation via Dim_Customer.RegulationID. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| NOP | money | Net Open Position value in USD at end of day for all open positions. From `BI_DB_dbo.BI_DB_PositionPnL.NOP` matched by PositionID and DateID. Sum across all positions. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| Count_Fails | int | Number of failed trade attempts on this date. From `CopyFromLake.PositionFailReal_History_PositionFail_DWH`. Excludes 'Open Open Position cannot be opened' failures. NULL if no fails. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| TotalCommission | money | Commission earned by eToro from this customer's positions on this date. Date-attribution formula: opens → FullCommissionByUnits; same-day close → FullCommissionOnClose; prior-open close → FullCommissionOnClose−FullCommissionByUnits. Always ≥ 0. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| Success_Positions | int | Count of positions where OpenDateID=@DateID OR CloseDateID=@DateID (active positions on this date). Denominator for Ratio. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| Ratio | float | Fail rate: `Count_Fails / Success_Positions`. 0 if Success_Positions=0. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE()). Not a business date. (Tier 2 — SP_CommissionsAndFails_PerCID) |

## 5. Lineage

| Source | Role |
|--------|------|
| `DWH_dbo.Dim_Position` | Positions (commissions, dates, CID, InstrumentID) |
| `DWH_dbo.Dim_Customer` | Customer metadata (UserName, PlayerLevelID, GuruStatusID, RegulationID, CountryID) |
| `DWH_dbo.Dim_Instrument` | InstrumentName, InstrumentType |
| `DWH_dbo.Dim_Regulation` | Regulation text |
| `DWH_dbo.Dim_Country` | Region, Country |
| `DWH_dbo.Dim_PlayerLevel` | PlayerLevel text |
| `DWH_dbo.Dim_GuruStatus` | GuruStatus text |
| `BI_DB_dbo.BI_DB_PositionPnL` | NOP (Net Open Position value) |
| `CopyFromLake.PositionFailReal_History_PositionFail_DWH` | Fail records (Count_Fails) |
| `Dealing_staging.External_Etoro_Dictionary_FailType` | FailType description |

**ETL:** `Dealing_dbo.SP_CommissionsAndFails_PerCID` → `Dealing_dbo.Dealing_CIDs_CommissionsAndFails`

**Coverage:** 2022-12-01 to present (active).

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_CIDs_CommissionsAndFails_PIs` | Same structure, filtered to GuruStatusID IN (5,6); PI-only subset |
| `Dealing_dbo.Dealing_FailReasons` | Companion table: fail reasons summarized by FailReason × HedgeServerID (not per CID) |
| `DWH_dbo.Dim_Customer` | JOIN on CID for current customer attributes |
| `BI_DB_dbo.BI_DB_PositionPnL` | Source of NOP |

## 7. Sample Queries

```sql
-- High fail rate customers in the last 30 days
SELECT CID, UserName, Regulation, GuruStatus,
    COUNT(*) AS days_in_top20,
    AVG(TotalCommission) AS avg_daily_commission_usd,
    AVG(Ratio) AS avg_fail_rate,
    MAX(Ratio) AS max_fail_rate
FROM Dealing_dbo.Dealing_CIDs_CommissionsAndFails
WHERE Date >= DATEADD(DAY, -30, GETDATE())
GROUP BY CID, UserName, Regulation, GuruStatus
HAVING AVG(Ratio) > 0.05
ORDER BY avg_fail_rate DESC

-- Daily commission trend by region
SELECT Date, Region,
    SUM(TotalCommission) AS total_commission_usd,
    COUNT(DISTINCT CID) AS unique_cids
FROM Dealing_dbo.Dealing_CIDs_CommissionsAndFails
WHERE Date >= '2025-01-01'
GROUP BY Date, Region
ORDER BY Date DESC, total_commission_usd DESC
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.

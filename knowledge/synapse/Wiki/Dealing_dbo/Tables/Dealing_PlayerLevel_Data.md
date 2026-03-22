# Dealing_PlayerLevel_Data

## 1. Business Meaning

Daily summary of trading activity aggregated by PlayerLevel tier — commissions earned, net open positions (NOP), fail counts, and fail-to-success ratio for each customer tier. Part of the `SP_CommissionsAndFails_PerCID` pipeline, this table provides a tier-level view of platform health and revenue.

Each row represents one (Date, PlayerLevel) combination. There are 6 possible tiers (Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond) but not all tiers appear on every day.

**Scale and activity:** December 2023 to 2026-03-10. 5,589 rows total. Active daily pipeline. On 2026-03-10:
- Platinum Plus ($917K TotalCommission, $102M NOP — highest-value tier)
- 5 distinct PlayerLevel tiers observed
- Full-population coverage (not PI-filtered)

**No PII:** Aggregate by tier — no CID or UserName.

## 2. Business Logic

### 2.1 TotalCommission Attribution Formula

The commission for each position is attributed to the date when the relevant event occurred:

```sql
TotalCommission = SUM(
  CASE
    WHEN OpenDateID = @DateID AND CloseDateID = @DateID
      THEN FullCommissionOnClose          -- opened and closed same day: full close commission
    WHEN OpenDateID < @DateID AND CloseDateID = @DateID
      THEN FullCommissionOnClose - FullCommissionByUnits  -- closed today (opened earlier): net of open commission already counted
    WHEN OpenDateID = @DateID AND CloseDateID > @DateID
      THEN FullCommissionByUnits          -- opened today (still open): open commission only
    ELSE 0                                -- position active but no event today
  END
)
```

This ensures no double-counting: each commission dollar is attributed exactly once to either the open date or the close date.

### 2.2 NOP Aggregation

```sql
NOP = SUM(pnl.NOP)  -- from BI_DB_PositionPnL where DateID = @DateID
```

LEFT JOINed on PositionID + DateID. Represents the total Net Open Position value in USD for all open positions held by clients in each tier.

### 2.3 Fail Count and Ratio

```sql
Count_Fails = SUM(f.Count_Fails)  -- from #TotalData_Fails grouped by PlayerLevel
Success_Positions = SUM(d.Success_Positions)  -- positions opened or closed on @Date
Ratio = SUM(Count_Fails) / SUM(Success_Positions)
```

Ratio is the fail-to-success rate. A higher ratio indicates more execution problems relative to successful trades — useful for identifying which tier is experiencing execution quality issues.

### 2.4 PlayerLevel Tiers

| PlayerLevelID | Tier | Notes |
|---------------|------|-------|
| 1 | Bronze | Default tier, lowest |
| 5 | Silver | |
| 3 | Gold | |
| 2 | Platinum | |
| 6 | Platinum Plus | High-value PIs, largest NOP |
| 7 | Diamond | Top tier |

### 2.5 Coverage Period

Table starts December 2023. Prior to this period, the PlayerLevel breakdown was not maintained in this format.

## 3. Query Advisory

**Distribution:** ROUND_ROBIN, 5,589 rows. Very small table — fast full scans.

**5–6 rows per date maximum** (one per tier). Never more than the number of active tiers on a given day.

```sql
-- Commission and NOP by tier for a specific date
SELECT Date, PlayerLevel, PlayerLevelID,
    TotalCommission, NOP, Count_Fails, Success_Positions, Ratio
FROM Dealing_dbo.Dealing_PlayerLevel_Data
WHERE Date = '2026-03-10'
ORDER BY TotalCommission DESC

-- Fail ratio trend by tier (monthly average)
SELECT YEAR(Date) yr, MONTH(Date) mo, PlayerLevel,
    AVG(Ratio) AS avg_fail_ratio,
    SUM(TotalCommission) AS monthly_commission
FROM Dealing_dbo.Dealing_PlayerLevel_Data
WHERE Date >= '2025-01-01'
GROUP BY YEAR(Date), MONTH(Date), PlayerLevel
ORDER BY yr DESC, mo DESC, avg_fail_ratio DESC
```

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date. Equals `@Date` SP parameter. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| PlayerLevelID | int | Integer tier ID (1=Bronze, 5=Silver, 3=Gold, 2=Platinum, 6=Platinum Plus, 7=Diamond). (Tier 2 — Dim_Customer passthrough) |
| PlayerLevel | varchar | Human-readable tier label. Joined from `DWH_dbo.Dim_PlayerLevel`. (Tier 2 — join-enriched) |
| TotalCommission | decimal | Sum of commissions attributed to this tier on this date, in USD. Uses open/close attribution formula. (Tier 2 — ETL-computed from Dim_Position) |
| NOP | decimal | Sum of Net Open Position values in USD for all open positions in this tier on this date. (Tier 2 — ETL-computed from BI_DB_PositionPnL) |
| Count_Fails | int | Total failed position attempts by clients in this tier on this date. (Tier 2 — ETL-computed from PositionFail) |
| Success_Positions | int | Count of successful trade actions (opens or closes) by clients in this tier on this date. (Tier 2 — ETL-computed from Dim_Position) |
| Ratio | float | Fail-to-success ratio: `Count_Fails / Success_Positions`. Higher = more problematic. (Tier 2 — ETL-computed) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE()). Not a business date. (Tier 2 — SP_CommissionsAndFails_PerCID) |

## 5. Lineage

| Source | Role |
|--------|------|
| `DWH_dbo.Dim_Position` | Commission attribution (FullCommissionOnClose, FullCommissionByUnits) |
| `BI_DB_dbo.BI_DB_PositionPnL` | NOP values per position |
| `CopyFromLake.PositionFailReal_History_PositionFail_DWH` | Fail counts |
| `DWH_dbo.Dim_Customer` | PlayerLevelID per CID |
| `DWH_dbo.Dim_PlayerLevel` | PlayerLevel text label |

**ETL:** `Dealing_dbo.SP_CommissionsAndFails_PerCID` → `Dealing_dbo.Dealing_PlayerLevel_Data`

**Coverage:** December 2023 to present (active).

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_PlayerLevel_Data_PIs` | PI-filtered counterpart — same structure, Popular Investor subset only |
| `Dealing_dbo.Dealing_PlayerLevel_Fails` | Fail reasons broken down by PlayerLevel (not commission/NOP) |
| `Dealing_dbo.Dealing_CommissionsAndFails` | Top-20 per-CID version — individual client breakdown |

## 7. Sample Queries

```sql
-- Top tier by NOP and commission (single date)
SELECT PlayerLevel, TotalCommission, NOP, Count_Fails, Ratio
FROM Dealing_dbo.Dealing_PlayerLevel_Data
WHERE Date = '2026-03-10'
ORDER BY NOP DESC

-- Year-over-year commission comparison by tier
SELECT PlayerLevel,
    SUM(CASE WHEN YEAR(Date) = 2025 THEN TotalCommission ELSE 0 END) AS commission_2025,
    SUM(CASE WHEN YEAR(Date) = 2026 THEN TotalCommission ELSE 0 END) AS commission_2026_ytd
FROM Dealing_dbo.Dealing_PlayerLevel_Data
WHERE Date >= '2025-01-01'
GROUP BY PlayerLevel
ORDER BY commission_2025 DESC
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.

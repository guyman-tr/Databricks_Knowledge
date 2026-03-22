# Dealing_PlayerLevel_Fails

## 1. Business Meaning

Daily count of failed trade attempts grouped by PlayerLevel tier and standardized fail reason. Combines the tier dimension of `Dealing_PlayerLevel_Data` with the fail reason classification of `Dealing_FailReasons` — showing which tier is experiencing which type of failure.

Each row represents a (Date, PlayerLevel, FailReason) combination with the count of fails. Full customer population (not PI-filtered).

**Scale and activity:** Written by `SP_CommissionsAndFails_PerCID`. On 2026-03-10: Gold tier leads with 152K "Min Position Amount" fails — consistent with Gold being a high-volume mid-tier with active CopyTrading. "Min Position Amount" is by far the most common reason across all tiers.

**No PII:** Pure aggregate — no CID or UserName.

## 2. Business Logic

### 2.1 Population and Classification

The SP applies the same 28-bucket fail reason classification as `Dealing_FailReasons`, then groups by (PlayerLevelID, PlayerLevel, FailReason2):

```sql
SELECT Date = @Date,
    PlayerLevelID = b.PlayerLevelID,
    PlayerLevel = pl.Name,
    FailReason = m.FailReason2,
    Count_Fails = COUNT(*),
    UpdateDate = GETDATE()
FROM #Merge_Fails m  -- 28-bucket classification applied
JOIN DWH_dbo.Dim_Customer b ON m.CID = b.CID
LEFT JOIN DWH_dbo.Dim_PlayerLevel pl ON b.PlayerLevelID = pl.PlayerLevelID
GROUP BY b.PlayerLevelID, pl.Name, m.FailReason2
```

Full population — no GuruStatusID filter.

### 2.2 Fail Reason Standardization

Same 28-bucket CASE WHEN classification as `Dealing_FailReasons`. See that table for the full pattern list. The dominant bucket across all tiers is "Min Position Amount" — automated copy-trading size rejections.

### 2.3 Tier × Reason Cross-dimension

This table enables cross-analysis: which fail reasons affect high-value tiers disproportionately? For example:
- Bronze: high "Min Position Amount" and "Insufficient Funds" (small, under-funded accounts)
- Platinum Plus/Diamond: "Other" dominates (execution-level failures, not validation failures)

## 3. Query Advisory

**Distribution:** ROUND_ROBIN. Small table — fast full scans.

**Multiple rows per tier per date** — one per (PlayerLevel, FailReason) combination. Sum across FailReasons to get tier totals.

```sql
-- Fail reason distribution by tier on a specific date
SELECT PlayerLevel, FailReason, Count_Fails
FROM Dealing_dbo.Dealing_PlayerLevel_Fails
WHERE Date = '2026-03-10'
ORDER BY PlayerLevel, Count_Fails DESC

-- Total fails per tier (aggregating all fail reasons)
SELECT Date, PlayerLevel,
    SUM(Count_Fails) AS total_fails
FROM Dealing_dbo.Dealing_PlayerLevel_Fails
WHERE Date = '2026-03-10'
GROUP BY Date, PlayerLevel
ORDER BY total_fails DESC
```

**Join to Dealing_PlayerLevel_Data for fail rate context:**

```sql
SELECT f.Date, f.PlayerLevel,
    f.FailReason, f.Count_Fails,
    d.Success_Positions,
    CAST(f.Count_Fails AS FLOAT) / NULLIF(d.Success_Positions, 0) AS reason_fail_rate
FROM Dealing_dbo.Dealing_PlayerLevel_Fails f
JOIN Dealing_dbo.Dealing_PlayerLevel_Data d
    ON f.Date = d.Date AND f.PlayerLevelID = d.PlayerLevelID
WHERE f.Date = '2026-03-10'
ORDER BY reason_fail_rate DESC
```

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date. Equals `@Date` SP parameter. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| PlayerLevelID | int | Integer tier ID (1=Bronze, 5=Silver, 3=Gold, 2=Platinum, 6=Platinum Plus, 7=Diamond). (Tier 2 — Dim_Customer passthrough) |
| PlayerLevel | varchar | Human-readable tier label. Joined from `DWH_dbo.Dim_PlayerLevel`. (Tier 2 — join-enriched) |
| FailReason | varchar | Standardized fail reason from 28-bucket CASE WHEN classification. "Other" = unmatched. (Tier 2 — ETL-computed) |
| Count_Fails | int | Count of fails with this FailReason in this PlayerLevel tier on this date. (Tier 2 — ETL-computed) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE()). Not a business date. (Tier 2 — SP_CommissionsAndFails_PerCID) |

## 5. Lineage

| Source | Role |
|--------|------|
| `CopyFromLake.PositionFailReal_History_PositionFail_DWH` | Raw fail records with CID for tier join |
| `DWH_dbo.Dim_Customer` | PlayerLevelID per CID |
| `DWH_dbo.Dim_PlayerLevel` | PlayerLevel text label |

**ETL:** `Dealing_dbo.SP_CommissionsAndFails_PerCID` → `Dealing_dbo.Dealing_PlayerLevel_Fails`

**Coverage:** Derived from SP runtime — check MAX(Date) for current coverage.

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_PlayerLevel_Fails_PIs` | PI-filtered counterpart — same structure, Popular Investor subset |
| `Dealing_dbo.Dealing_PlayerLevel_Data` | Commission + NOP + total fail count by tier (no reason breakdown) |
| `Dealing_dbo.Dealing_FailReasons` | Full-population fail reasons (no tier dimension) |

## 7. Sample Queries

```sql
-- Most impactful fail reasons by tier (last 30 days)
SELECT PlayerLevel, FailReason,
    SUM(Count_Fails) AS monthly_fails
FROM Dealing_dbo.Dealing_PlayerLevel_Fails
WHERE Date >= DATEADD(DAY, -30, GETDATE())
GROUP BY PlayerLevel, FailReason
ORDER BY PlayerLevel, monthly_fails DESC

-- Tier fail trend (week-over-week change in top fail reason)
SELECT PlayerLevel,
    SUM(CASE WHEN Date >= DATEADD(DAY, -7, GETDATE()) THEN Count_Fails ELSE 0 END) AS last_7d,
    SUM(CASE WHEN Date BETWEEN DATEADD(DAY, -14, GETDATE()) AND DATEADD(DAY, -8, GETDATE()) THEN Count_Fails ELSE 0 END) AS prior_7d
FROM Dealing_dbo.Dealing_PlayerLevel_Fails
WHERE Date >= DATEADD(DAY, -14, GETDATE())
  AND FailReason = 'Min Position Amount'
GROUP BY PlayerLevel
ORDER BY last_7d DESC
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.

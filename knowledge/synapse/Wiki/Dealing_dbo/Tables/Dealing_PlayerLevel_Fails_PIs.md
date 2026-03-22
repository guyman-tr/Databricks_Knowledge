# Dealing_PlayerLevel_Fails_PIs

## 1. Business Meaning

Daily count of PI (Popular Investor) failed trade attempts grouped by PlayerLevel tier and standardized fail reason. The PI-restricted counterpart of `Dealing_PlayerLevel_Fails` — same structure and classification, filtered to `GuruStatusID IN (5,6)`.

Each row represents a (Date, PlayerLevel, FailReason) combination for PI clients only. Because PIs are a very small, high-tier population, this table is extremely sparse: typically only Diamond and Platinum Plus tiers appear, and most fail reasons show 0 or very few occurrences.

**Scale and activity:** Active daily pipeline. Written by `SP_CommissionsAndFails_PerCID`. In observed data, only "Other" fail reason appears for Diamond and Platinum Plus PIs — consistent with the PI profile (well-funded, large positions → no size-validation failures; execution-level hedge rejections fall into "Other").

**No PII:** Pure aggregate — no CID or UserName.

## 2. Business Logic

### 2.1 PI Filter

Identical to `Dealing_PlayerLevel_Fails` but scoped to `GuruStatusID IN (5,6)`:

```sql
-- #PlayerLevel_Fails_PIs in SP
SELECT Date = @Date,
    PlayerLevelID = b.PlayerLevelID,
    PlayerLevel = pl.Name,
    FailReason = m.FailReason2,
    Count_Fails = COUNT(*),
    UpdateDate = GETDATE()
FROM #Merge_Fails m
JOIN DWH_dbo.Dim_Customer b ON m.CID = b.CID
  AND b.GuruStatusID IN (5,6)   -- PI filter
LEFT JOIN DWH_dbo.Dim_PlayerLevel pl ON b.PlayerLevelID = pl.PlayerLevelID
GROUP BY b.PlayerLevelID, pl.Name, m.FailReason2
```

### 2.2 Expected Sparsity

On most days, this table will have very few rows. The entire PI population is small, and PI clients rarely hit size-validation failures. The "Other" bucket dominates because hedge-server-level execution failures are common at institutional-scale position sizes.

### 2.3 UpdateDate Constraint

Unlike the `Dealing_PlayerLevel_Fails` table (UpdateDate NULL), this table has `UpdateDate NOT NULL` in the DDL — the SP must always write a non-NULL GETDATE() value.

## 3. Query Advisory

**Distribution:** ROUND_ROBIN. Very small table — essentially negligible cost.

**Expect only "Other" and a few other categories.** Reports expecting a rich fail-reason breakdown at the PI tier level should use `Dealing_FailReasons_PIs` (more granular, includes HedgeServerID dimension) or `Dealing_Fails_PI` (row-level with HedgeFailReason).

```sql
-- All PI tier fail reasons for a date
SELECT Date, PlayerLevel, FailReason, Count_Fails
FROM Dealing_dbo.Dealing_PlayerLevel_Fails_PIs
WHERE Date = '2026-03-10'
ORDER BY Count_Fails DESC

-- PI vs full-population fail comparison by tier and reason
SELECT f.Date, f.PlayerLevel, f.FailReason,
    f.Count_Fails AS all_fails,
    fp.Count_Fails AS pi_fails
FROM Dealing_dbo.Dealing_PlayerLevel_Fails f
LEFT JOIN Dealing_dbo.Dealing_PlayerLevel_Fails_PIs fp
    ON f.Date = fp.Date
    AND f.PlayerLevelID = fp.PlayerLevelID
    AND f.FailReason = fp.FailReason
WHERE f.Date = '2026-03-10'
ORDER BY f.Count_Fails DESC
```

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date. Equals `@Date` SP parameter. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| PlayerLevelID | int | Integer tier ID. Typically only 6 (Platinum Plus) and 7 (Diamond) present in PI data. (Tier 2 — Dim_Customer passthrough, PI subset) |
| PlayerLevel | varchar | Human-readable tier label. (Tier 2 — join-enriched from Dim_PlayerLevel) |
| FailReason | varchar | Standardized fail reason (28-bucket classification). PI population; typically "Other" dominates. (Tier 2 — ETL-computed, PI subset) |
| Count_Fails | int | Count of PI fails with this FailReason in this tier on this date. Low values (0–34 range). (Tier 2 — ETL-computed) |
| UpdateDate | datetime NOT NULL | Row insertion timestamp (GETDATE()). NOT NULL constraint. (Tier 2 — SP_CommissionsAndFails_PerCID) |

## 5. Lineage

| Source | Role |
|--------|------|
| `CopyFromLake.PositionFailReal_History_PositionFail_DWH` | Raw fail records |
| `DWH_dbo.Dim_Customer` | PlayerLevelID and GuruStatusID for PI filter |
| `DWH_dbo.Dim_PlayerLevel` | PlayerLevel text label |

**ETL:** `Dealing_dbo.SP_CommissionsAndFails_PerCID` → `Dealing_dbo.Dealing_PlayerLevel_Fails_PIs`

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_PlayerLevel_Fails` | Full-population counterpart — same structure, all customers |
| `Dealing_dbo.Dealing_FailReasons_PIs` | PI fail reasons with HedgeServerID dimension (no tier split) |
| `Dealing_dbo.Dealing_Fails_PI` | Row-level PI fail detail with HedgeFailReason for "Other" breakdown |
| `Dealing_dbo.Dealing_PlayerLevel_Data_PIs` | Commission + NOP for PI tiers (complementary aggregate) |

## 7. Sample Queries

```sql
-- PI fail summary by tier (monthly)
SELECT YEAR(Date) yr, MONTH(Date) mo, PlayerLevel,
    SUM(Count_Fails) AS monthly_pi_tier_fails
FROM Dealing_dbo.Dealing_PlayerLevel_Fails_PIs
WHERE Date >= '2025-01-01'
GROUP BY YEAR(Date), MONTH(Date), PlayerLevel
ORDER BY yr DESC, mo DESC

-- Days with any PI fails by tier and reason
SELECT Date, PlayerLevel, FailReason, Count_Fails
FROM Dealing_dbo.Dealing_PlayerLevel_Fails_PIs
WHERE Count_Fails > 0
ORDER BY Date DESC, Count_Fails DESC
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.

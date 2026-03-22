# Dealing_FailReasons

## 1. Business Meaning

Daily count of failed trade attempts grouped by standardized fail reason and hedge server. Written by `SP_CommissionsAndFails_PerCID` as part of the same pipeline that produces the CommissionsAndFails tables — this table covers the **entire customer base** (not just top 20), aggregating all position fail records for the day.

Each row represents a (FailReason, HedgeServerID) combination with the count of fails on that date. NULL HedgeServerID means the failure was not tied to a specific server (platform-level or validation failure).

**Scale and activity:** 2022-12-01 to 2026-03-10, **active daily pipeline**. 109K rows total, 32 standardized fail reason categories, 56 distinct HedgeServerIDs. Typical high-volume day: `Min Position Amount` = 100K–300K failures per day — most are automated bots or copy trading rejections, not user errors.

**No PII:** This is a pure aggregate — no CID or UserName.

## 2. Business Logic

### 2.1 Fail Reason Standardization

Raw fail messages from `CopyFromLake.PositionFailReal_History_PositionFail_DWH` are long free-text strings. The SP normalizes them using ~28 LIKE patterns in `#Merge_Fails`:

```sql
CASE
  WHEN FailReason LIKE '%insufficient funds%' OR FailReason LIKE '%InsufficientFunds%'
    THEN 'Insufficient Funds for the Position'
  WHEN FailReason LIKE '%MinPositionAmount%'
    THEN 'Min Position Amount'
  WHEN FailReason LIKE '%Restricted By SmartCopy%'
    THEN 'Restricted By SmartCopy'
  ...
  ELSE 'Other'
END AS FailReason2
```

The standardized label is stored in `FailReason`. Excluded: `'Open Open Position cannot be opened'` (removed 2023-07-04 at Kyriakos's request).

### 2.2 Aggregation

```sql
SELECT FailReason2 AS FailReason, HedgeServerID, COUNT(*) AS Count_Fails
FROM #Merge_Fails
GROUP BY FailReason2, HedgeServerID
```

This produces one row per (FailReason, HedgeServerID) combination. The same FailReason can appear multiple times if it occurred on different servers.

### 2.3 Most Common Fail Reasons (from live data)

| Category | Typical Daily Count | Meaning |
|----------|--------------------|---------|
| Min Position Amount | 100K–300K | Position size below instrument minimum |
| Other | 100K–175K | Unmatched raw fail messages |
| Restricted By SmartCopy | 50K+ | CopyTrading size/ratio restrictions |
| Initial Position Amount is under the minimum | 50K+ | Similar to Min Position Amount — older message format |
| Insufficient Funds | High | Customer lacks margin |
| Exceeds User Max Leverage | Medium | Leverage limit hit |

## 3. Query Advisory

**Distribution:** ROUND_ROBIN, 109K rows. Very small table — full scans are fast.

**Multiple rows per FailReason per day:** If HedgeServerID is part of your filter, note that NULL means server-independent failures. To get total count per fail reason regardless of server, SUM across all HedgeServerID values:

```sql
-- Total fail counts by reason for a date (ignoring server)
SELECT Date, FailReason, SUM(Count_Fails) AS total_fails
FROM Dealing_dbo.Dealing_FailReasons
WHERE Date = '2026-03-10'
GROUP BY Date, FailReason
ORDER BY total_fails DESC
```

**Comparison with CommissionsAndFails:** `Dealing_FailReasons` has global counts. `Dealing_CIDs_CommissionsAndFails.Count_Fails` has per-CID counts for only the top 20.

```sql
-- Trending top 5 fail reasons by month
SELECT YEAR(Date) yr, MONTH(Date) mo, FailReason,
    SUM(Count_Fails) AS monthly_fails
FROM Dealing_dbo.Dealing_FailReasons
WHERE Date >= '2025-01-01'
GROUP BY YEAR(Date), MONTH(Date), FailReason
ORDER BY yr DESC, mo DESC, monthly_fails DESC
```

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date of the fail records. Equals `@Date` SP parameter. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| FailReason | varchar | Standardized fail reason label, derived from raw fail message via ~28 LIKE patterns. "Other" = unmatched. 32 distinct values observed. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| Count_Fails | int | Number of position fail attempts with this FailReason on this HedgeServerID on this date. Can be very large (100K+/day for top reasons). (Tier 2 — SP_CommissionsAndFails_PerCID) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE()). Not a business date. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| HedgeServerID | int | Hedge server that processed the request. NULL = failure occurred before reaching a specific server (platform/validation-layer rejection). 56 distinct values observed. (Tier 2 — SP_CommissionsAndFails_PerCID) |

## 5. Lineage

| Source | Role |
|--------|------|
| `CopyFromLake.PositionFailReal_History_PositionFail_DWH` | Raw fail records (CID, FailTypeID, FailReason text, HedgeServerID, FailOccurred) |
| `Dealing_staging.External_Etoro_Dictionary_FailType` | FailType text lookup |
| `DWH_dbo.Dim_Customer` | IsValidCustomer filter on CID |

**ETL:** `Dealing_dbo.SP_CommissionsAndFails_PerCID` → `Dealing_dbo.Dealing_FailReasons`

**Coverage:** 2022-12-01 to present (active).

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_FailReasons_Top20` | Same structure but restricted to fails by the top-20 commission CIDs only (no HedgeServerID dimension) |
| `Dealing_dbo.Dealing_FailReasons_Top20_PIs` | Restricted to fails by top-20 PI CIDs only |
| `Dealing_dbo.Dealing_CIDs_CommissionsAndFails` | Per-CID fail counts (top 20 only); for granular investigation of specific customers |
| `Dealing_dbo.Dealing_PlayerLevel_Fails` | Fail reasons grouped by PlayerLevel (not HedgeServerID) |

## 7. Sample Queries

```sql
-- Daily total fails by standardized reason (last 7 days)
SELECT Date, FailReason,
    SUM(Count_Fails) AS total_fails,
    COUNT(DISTINCT CASE WHEN HedgeServerID IS NOT NULL THEN HedgeServerID END) AS server_count
FROM Dealing_dbo.Dealing_FailReasons
WHERE Date >= DATEADD(DAY, -7, GETDATE())
GROUP BY Date, FailReason
ORDER BY Date DESC, total_fails DESC

-- Server-specific fail spike analysis (find servers with anomalous fails)
SELECT HedgeServerID,
    SUM(Count_Fails) AS total_fails,
    COUNT(DISTINCT FailReason) AS reason_variety
FROM Dealing_dbo.Dealing_FailReasons
WHERE Date BETWEEN '2026-02-01' AND '2026-03-10'
  AND HedgeServerID IS NOT NULL
GROUP BY HedgeServerID
ORDER BY total_fails DESC
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.

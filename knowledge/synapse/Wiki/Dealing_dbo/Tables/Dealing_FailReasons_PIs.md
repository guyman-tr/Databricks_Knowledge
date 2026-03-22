# Dealing_FailReasons_PIs

## 1. Business Meaning

Daily count of failed trade attempts by Popular Investors (PIs), grouped by standardized fail reason and hedge server. The PI-restricted counterpart of `Dealing_FailReasons` — identical structure but the source population is filtered to `GuruStatusID IN (5,6)` (Popular Investor tier) only.

Each row represents a (FailReason, HedgeServerID) combination with the count of PI fails on that date. Because PIs are a small, high-quality subset of all traders, volumes here are dramatically lower than the full-population table.

**Scale and activity:** May 2023 to 2026-03-10, **active daily pipeline**. 1,312 rows total. On 2026-03-10: only 34 total PI fails recorded across all categories and servers — orders of magnitude lower than the 100K+ seen in `Dealing_FailReasons`. Typical PI fail reasons trend toward execution failures ("Other") rather than size-validation failures ("Min Position Amount") because PIs operate larger, well-funded positions.

**No PII:** Pure aggregate — no CID or UserName.

## 2. Business Logic

### 2.1 PI Filter

Written by the same `SP_CommissionsAndFails_PerCID` run that produces `Dealing_FailReasons`. The PI subset is extracted via:

```sql
WHERE GuruStatusID IN (5,6)  -- Popular Investors only
```

where `GuruStatusID` comes from `DWH_dbo.Dim_Customer`. This filter is applied in the `#Fails_Data_PIs` temp table before the fail-reason aggregation.

### 2.2 Fail Reason Standardization

Same 28-bucket LIKE classification as `Dealing_FailReasons` (see that table for the full CASE WHEN pattern). Raw fail messages are normalized into canonical labels such as "Min Position Amount", "Insufficient Funds for the Position", "Restricted By SmartCopy", etc. Unmatched messages → "Other".

### 2.3 Aggregation

```sql
SELECT FailReason2 AS FailReason, HedgeServerID, COUNT(*) AS Count_Fails
FROM #Merge_Fails
WHERE GuruStatusID IN (5,6)
GROUP BY FailReason2, HedgeServerID
```

### 2.4 Typical PI Fail Profile

Because PIs maintain large funded positions, "Min Position Amount" and "Insufficient Funds" are rare. Most PI fails fall into "Other" (execution-level or hedge-server routing failures). Very sparse days (0–5 rows) are normal during quiet market conditions.

## 3. Query Advisory

**Distribution:** ROUND_ROBIN, 1,312 rows. Tiny table.

**Compare to full-population table** — always cross-reference with `Dealing_FailReasons` to compute PI fail share:

```sql
-- PI fail share of total fails by reason (2026-03-10)
SELECT fr.FailReason,
    SUM(fr.Count_Fails) AS total_fails,
    SUM(frp.Count_Fails) AS pi_fails,
    CAST(SUM(frp.Count_Fails) AS FLOAT) / NULLIF(SUM(fr.Count_Fails), 0) AS pi_share
FROM Dealing_dbo.Dealing_FailReasons fr
LEFT JOIN Dealing_dbo.Dealing_FailReasons_PIs frp
    ON fr.Date = frp.Date AND fr.FailReason = frp.FailReason
WHERE fr.Date = '2026-03-10'
GROUP BY fr.FailReason
ORDER BY total_fails DESC
```

**NULL HedgeServerID:** Platform-level rejections before server routing. Same semantics as the parent `Dealing_FailReasons` table.

```sql
-- PI fail trend by month
SELECT YEAR(Date) yr, MONTH(Date) mo,
    SUM(Count_Fails) AS pi_fails
FROM Dealing_dbo.Dealing_FailReasons_PIs
WHERE Date >= '2025-01-01'
GROUP BY YEAR(Date), MONTH(Date)
ORDER BY yr DESC, mo DESC
```

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date of the fail records. Equals `@Date` SP parameter. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| FailReason | varchar | Standardized fail reason label from the 28-bucket CASE WHEN classification. PI population only. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| Count_Fails | int | Count of PI position fails with this FailReason on this HedgeServerID on this date. Very low values (0–34 on a typical day). (Tier 2 — SP_CommissionsAndFails_PerCID) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE()). Not a business date. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| HedgeServerID | int | Hedge server that processed the request. NULL = platform-level rejection before server routing. (Tier 2 — SP_CommissionsAndFails_PerCID) |

## 5. Lineage

| Source | Role |
|--------|------|
| `CopyFromLake.PositionFailReal_History_PositionFail_DWH` | Raw fail records with GuruStatusID for PI filter |
| `DWH_dbo.Dim_Customer` | GuruStatusID lookup for PI filter |
| `Dealing_staging.External_Etoro_Dictionary_FailType` | FailType text lookup |

**ETL:** `Dealing_dbo.SP_CommissionsAndFails_PerCID` → `Dealing_dbo.Dealing_FailReasons_PIs`

**Coverage:** May 2023 to present (active).

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_FailReasons` | Full-population counterpart — same structure, all customers |
| `Dealing_dbo.Dealing_FailReasons_Top20_PIs` | Top-20 PI CIDs by commission — fail reasons for the highest-value PIs |
| `Dealing_dbo.Dealing_PlayerLevel_Fails_PIs` | Fail reasons by PlayerLevel tier for PI population |
| `Dealing_dbo.Dealing_Fails_PI` | Row-level PI fail detail (not aggregated; 3.97B rows) |

## 7. Sample Queries

```sql
-- All PI fails on a specific date with server breakdown
SELECT Date, FailReason, HedgeServerID, Count_Fails
FROM Dealing_dbo.Dealing_FailReasons_PIs
WHERE Date = '2026-03-10'
ORDER BY Count_Fails DESC

-- Monthly PI fail volume trend
SELECT YEAR(Date) yr, MONTH(Date) mo,
    SUM(Count_Fails) AS total_pi_fails,
    COUNT(DISTINCT FailReason) AS distinct_reasons
FROM Dealing_dbo.Dealing_FailReasons_PIs
GROUP BY YEAR(Date), MONTH(Date)
ORDER BY yr DESC, mo DESC
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.

---
object: Dealing_dbo.Dealing_Latency_SuspiciousCIDs
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 8.5
status: active
---

# Dealing_Latency_SuspiciousCIDs

## 1. Purpose

Identifies clients (CIDs) who opened and closed positions within ≤10 minutes on instruments that experienced price feed latency ≥3 seconds on that date. Cross-references `Dealing_OccurredAtProvider_Latency_Instrument` (which instruments had delayed price feeds) with `DWH_dbo.Dim_Position` (which clients traded those instruments during the delay window). Used for compliance and risk monitoring — these clients may have benefited from stale price data. Produced by `SP_Latency_SuspiciousCIDs` (OpsDB-tracked, Priority 0).

> **✅ ACTIVE pipeline.** 459,907 rows. 2022-08-31 – 2026-03-10.

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 459,907 |
| **Date range** | 2022-08-31 – 2026-03-10 ✅ ACTIVE |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on Date ASC |
| **Date type** | datetime (not date) |

## 3. ETL / Writer

| Property | Value |
|----------|-------|
| **Writer SP** | `Dealing_dbo.SP_Latency_SuspiciousCIDs` |
| **Frequency** | Daily |
| **OpsDB tracked** | ✅ Yes — Priority 0, SB_Daily |
| **Load mode** | DELETE WHERE Date = @Date, then INSERT |
| **Also writes** | `Dealing_Latency_SuspiciousCIDs_Email` (TRUNCATE + INSERT each run) |

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | datetime | Date of the price feed latency event (from OccurredAtProvider). Note: datetime not date. (Tier 2 — SP_Latency_SuspiciousCIDs) |
| CID | int | Client identifier who traded the instrument during the latency window. (Tier 2 — DWH_dbo.Dim_Position) |
| PositionID | bigint | Position identifier. (Tier 2 — DWH_dbo.Dim_Position) |
| InstrumentID | int | Instrument that had price feed latency ≥3s and was traded by this CID. (Tier 2 — DWH_dbo.Dim_Position / Dealing_OccurredAtProvider_Latency_Instrument) |
| HedgeServerID | int | Hedge server routing this position. (Tier 2 — DWH_dbo.Dim_Position) |
| InitDateTime | datetime | Position open timestamp. (Tier 2 — DWH_dbo.Dim_Position) |
| EndDateTime | datetime | Position close timestamp. (Tier 2 — DWH_dbo.Dim_Position) |
| NetProfit | decimal(16,8) | Net profit/loss on this position. (Tier 2 — DWH_dbo.Dim_Position) |
| Duration | int | Position duration in seconds: DATEDIFF(ss, InitDateTime, EndDateTime). Filter: ≤ 600 seconds (10 min). (Tier 2 — computed) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated. Populated even on empty days. (Tier 1 — ETL metadata canonical) |

## 5. Business Rules & Relationships

- **Dual filter**: Only positions where (1) the instrument had ≥3s price feed latency that day (per `Dealing_OccurredAtProvider_Latency_Instrument`) AND (2) position duration ≤ 600 seconds (10 minutes).
- **Empty-day handling**: When no suspicious CIDs found (`CountINT = 0`), SP inserts a NULL sentinel row to preserve `UpdateDate` tracking — rows with all NULLs except `UpdateDate` should be excluded from analysis.
- **`Dealing_Latency_SuspiciousCIDs_Email`**: Companion table refreshed (TRUNCATE + INSERT) on each SP run — always contains the current rolling window. Used for automated email alerts.
- **OpsDB-tracked**: This is one of the few Dealing_dbo latency tables in OpsDB (Priority 0 = critical). Runs via SB_Daily scheduler.
- **Active despite feed disruption**: `SP_Latency_SuspiciousCIDs` runs independently and continues operating even though `OccurredAtProvider_Latency` tables stopped Jan 11, 2025 — the SP likely handles empty cross-reference gracefully.
- **`Date` is datetime**: Filter using range or CAST to date for day-level joins.

## 6. Query Notes

```sql
-- Suspicious CIDs with profitable short trades on delay days
SELECT Date, CID, COUNT(*) AS SuspiciousPositions,
       SUM(NetProfit) AS TotalProfit, AVG(Duration) AS AvgDuration_s
FROM [Dealing_dbo].[Dealing_Latency_SuspiciousCIDs]
WHERE UpdateDate IS NOT NULL AND CID IS NOT NULL  -- exclude sentinel rows
  AND CAST(Date AS date) >= '2024-01-01'
  AND NetProfit > 0
GROUP BY Date, CID
HAVING COUNT(*) >= 3
ORDER BY TotalProfit DESC
```

## 7. Production Lineage

DWH-computed analytics. Joins DWH_dbo.Dim_Position with OccurredAtProvider latency results. No upstream production wiki.

## 8. Known Issues & Notes

- **NULL sentinel rows**: Empty days insert NULL rows — always filter `WHERE CID IS NOT NULL`.
- **`Date` is datetime** — use CAST for day-level aggregation.
- **`OccurredAtProvider` data gap**: Since Jan 11, 2025 feed disruption, the SP's cross-reference source is stale. Recent "suspicious CID" results may reflect stale delay data from before the disruption.

---
*Quality score: 8.5/10 | Documented: 2026-03-21 | Writer: SP_Latency_SuspiciousCIDs*

# Dealing_PlayerLevel_Data_PIs

## 1. Business Meaning

Daily summary of Popular Investor (PI) trading activity aggregated by PlayerLevel tier — commissions, NOP, fail counts, and fail-to-success ratio, scoped exclusively to PI clients (`GuruStatusID IN (5,6)`). The PI-filtered counterpart of `Dealing_PlayerLevel_Data`.

Because PIs are the highest-profile clients on the platform and tend to occupy top tiers, this table typically shows data only for Diamond (PlayerLevelID=7) and Platinum Plus (PlayerLevelID=6) — PIs rarely appear in Bronze or Silver.

**Scale and activity:** December 2023 to 2026-03-10. Active daily pipeline. Written by the same `SP_CommissionsAndFails_PerCID` run as `Dealing_PlayerLevel_Data`. Row count is much smaller: only 1–2 tier rows per day instead of 5–6.

**No PII:** Aggregate by tier — no CID or UserName.

## 2. Business Logic

### 2.1 PI Filter Application

The same commission, NOP, and fail aggregation pipeline as `Dealing_PlayerLevel_Data`, but filtered to `WHERE GuruStatusID IN (5,6)` throughout. The SP uses a FULL OUTER JOIN between PI commission data and PI fail data to preserve tiers that may have only one dimension:

```sql
-- Conceptual structure in SP (#PlayerLevel_Data_PIs)
SELECT ...
FROM #TotalData_CommissionNOP_PIs tdcn
FULL OUTER JOIN #TotalData_Fails_PIs tdf
    ON tdcn.PlayerLevelID = tdf.PlayerLevelID
WHERE GuruStatusID IN (5,6)
```

The FULL OUTER JOIN ensures that if a tier has only fails (no commissions) or only commissions (no fails), it still appears in the output.

### 2.2 Observed Tier Distribution

In recent data (2026-03-10), only Diamond and Platinum Plus tiers appear. This is consistent with the PI program design: Popular Investors must maintain high-quality track records and large follower bases, which correlates with long trading histories and high-tier membership.

### 2.3 Commission and NOP Formulas

Identical to `Dealing_PlayerLevel_Data` — see that table for the full commission attribution formula. NOP = SUM of open position values. Ratio = Count_Fails / Success_Positions.

## 3. Query Advisory

**Distribution:** ROUND_ROBIN, small table. Full scans are fast.

**Expect only Diamond/Platinum Plus rows in recent data.** Do not assume all 6 tiers will be present on any given date.

```sql
-- PI tier performance (commission + NOP) latest date
SELECT Date, PlayerLevel, TotalCommission, NOP, Count_Fails, Ratio
FROM Dealing_dbo.Dealing_PlayerLevel_Data_PIs
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_PlayerLevel_Data_PIs)
ORDER BY TotalCommission DESC

-- Compare PI vs full-population commission by tier
SELECT pd.Date, pd.PlayerLevel,
    pd.TotalCommission AS all_commission,
    ppi.TotalCommission AS pi_commission,
    CAST(ppi.TotalCommission AS FLOAT) / NULLIF(pd.TotalCommission, 0) AS pi_share
FROM Dealing_dbo.Dealing_PlayerLevel_Data pd
LEFT JOIN Dealing_dbo.Dealing_PlayerLevel_Data_PIs ppi
    ON pd.Date = ppi.Date AND pd.PlayerLevelID = ppi.PlayerLevelID
WHERE pd.Date = '2026-03-10'
ORDER BY pd.TotalCommission DESC
```

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date. Equals `@Date` SP parameter. (Tier 2 — SP_CommissionsAndFails_PerCID) |
| PlayerLevelID | int | Integer tier ID. Only Diamond(7) and Platinum Plus(6) typically observed in PI data. (Tier 2 — Dim_Customer passthrough) |
| PlayerLevel | varchar | Human-readable tier label. (Tier 2 — join-enriched from Dim_PlayerLevel) |
| TotalCommission | decimal | Sum of commissions from PI positions in this tier on this date, in USD. (Tier 2 — ETL-computed) |
| NOP | decimal | Sum of Net Open Position values in USD for PI clients in this tier on this date. (Tier 2 — ETL-computed from BI_DB_PositionPnL) |
| Count_Fails | int | Total failed position attempts by PI clients in this tier on this date. (Tier 2 — ETL-computed) |
| Success_Positions | int | Successful trade actions by PI clients in this tier on this date. (Tier 2 — ETL-computed) |
| Ratio | float | Fail-to-success ratio for PI clients in this tier. NULL when Success_Positions = 0. (Tier 2 — ETL-computed) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE()). Not a business date. (Tier 2 — SP_CommissionsAndFails_PerCID) |

## 5. Lineage

| Source | Role |
|--------|------|
| `DWH_dbo.Dim_Position` | PI commission attribution |
| `BI_DB_dbo.BI_DB_PositionPnL` | NOP per position |
| `CopyFromLake.PositionFailReal_History_PositionFail_DWH` | PI fail counts |
| `DWH_dbo.Dim_Customer` | PlayerLevelID and GuruStatusID for PI filter |
| `DWH_dbo.Dim_PlayerLevel` | PlayerLevel text label |

**ETL:** `Dealing_dbo.SP_CommissionsAndFails_PerCID` → `Dealing_dbo.Dealing_PlayerLevel_Data_PIs`

**Coverage:** December 2023 to present (active).

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_PlayerLevel_Data` | Full-population counterpart — same structure, all customers |
| `Dealing_dbo.Dealing_PlayerLevel_Fails_PIs` | PI fail reasons by tier (no commission/NOP) |
| `Dealing_dbo.Dealing_CommissionsAndFails_PIs` | Per-CID PI breakdown — more granular than this tier aggregate |

## 7. Sample Queries

```sql
-- PI tier summary (most recent date)
SELECT Date, PlayerLevel, TotalCommission, NOP, Ratio
FROM Dealing_dbo.Dealing_PlayerLevel_Data_PIs
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_PlayerLevel_Data_PIs)

-- PI commission monthly trend by tier
SELECT YEAR(Date) yr, MONTH(Date) mo, PlayerLevel,
    SUM(TotalCommission) AS monthly_pi_commission,
    SUM(NOP) AS avg_nop
FROM Dealing_dbo.Dealing_PlayerLevel_Data_PIs
WHERE Date >= '2025-01-01'
GROUP BY YEAR(Date), MONTH(Date), PlayerLevel
ORDER BY yr DESC, mo DESC
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.

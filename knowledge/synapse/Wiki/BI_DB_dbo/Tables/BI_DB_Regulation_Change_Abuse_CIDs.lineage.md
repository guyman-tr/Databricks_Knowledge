# Lineage: BI_DB_dbo.BI_DB_Regulation_Change_Abuse_CIDs

## Source Chain

| Level | Object | Type | Role |
|-------|--------|------|------|
| L0 | etoro.Fact_SnapshotCustomer (DWH-staged) | DWH Fact | Daily customer regulatory snapshot; LAG pattern detects regulation changes |
| L1 | DWH_dbo.Fact_SnapshotCustomer | DWH Fact Table | Source of regulation change history (RegulationID LAG over UpdateDate) |
| L1 | DWH_dbo.Dim_Customer | DWH Dimension | Population gate (IsValidCustomer=1, IsDepositor=1) + demographics |
| L1 | DWH_dbo.Dim_Regulation | DWH Dimension | RegulationID → regulation description (RegDesc) used in RC1-RC15 pivot |
| L1 | DWH_dbo.Dim_Country | DWH Dimension | CountryID → Country, Region |
| L1 | DWH_dbo.Dim_AccountType | DWH Dimension | AccountTypeID → AccountType |
| L1 | DWH_dbo.Dim_PlayerLevel | DWH Dimension | PlayerLevelID → PlayerLevel |
| L1 | DWH_dbo.Dim_PlayerStatus | DWH Dimension | PlayerStatusID → PlayerStatus |
| L1 | DWH_dbo.Dim_Position | DWH Fact/Dim | Position counts and most recent open position date |
| L1 | DWH_dbo.V_Liabilities | DWH View | RealizedEquity, UnRealizedEquity (ActualNWA+Liabilities), TotalPositionsAmount |
| L2 | BI_DB_dbo.BI_DB_Regulation_Change_Abuse_CIDs | **THIS TABLE** | Abuser register: individual CIDs with ≥6 regulation changes + chronological reg history |

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (daily snapshot)
  └── LAG(RegulationID) change detection
        └── #regulation02 (per-change rows: CID, RegDesc, RegChangeRowNum 1..N)
              └── MAX(RegChangeRowNum) → #maxchanges (CID → Total_RegChangeCount)
                    └── WHERE Total_RegChangeCount >= 6 → #abuserpop

DWH_dbo.Dim_Customer (IsValidCustomer=1, IsDepositor=1) → #ftdpop (demographics)
DWH_dbo.Dim_Position → #abuser02 (OpenPositionsCount, ClosedPositionsCount, MostRecentOpenPosition)
DWH_dbo.V_Liabilities (WHERE DateID=@DateID) → #abuser03 (RealizedEquity, UnRealizedEquity, TotalPositionsAmount)
#abuserpop + #regulation02 → CASE PIVOT on RegChangeRowNum 1-15 → #abuser01 (RC1..RC15)

  └── #finalcid = #abuserpop JOIN #ftdpop JOIN #abuser01 JOIN #abuser02 JOIN #abuser03

  └── SP_Regulation_Change_Abuse (@Date) — MERGE (UPDATE matched, INSERT new, DELETE ex-abusers)
        v
BI_DB_dbo.BI_DB_Regulation_Change_Abuse_CIDs (15,956 rows — 2026-04-13, HASH(CID))
  └── UC: Not Migrated
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | Dim_Customer | RealCID | Direct — eToro production customer ID. MERGE primary key. | Tier 1 |
| 2 | Total_RegChangeCount | Fact_SnapshotCustomer (computed) | RegulationID | MAX(RegChangeRowNum) per CID from LAG change detection. Minimum value = 6 (abuser threshold). | Tier 2 |
| 3 | FTDDate | Dim_Customer | FirstDepositDate | Direct — first time deposit date | Tier 1 |
| 4 | FTDMonthYear | Dim_Customer | FirstDepositDate | `FORMAT(FirstDepositDate, 'MMM-yyyy')` or equivalent — text month label | Tier 2 |
| 5 | Regulation | Dim_Regulation | Name | Direct — current regulatory jurisdiction name | Tier 1 |
| 6 | Country | Dim_Country | Country | Direct — country name | Tier 1 |
| 7 | Region | Dim_Country | Region | Direct — marketing region label | Tier 1 |
| 8 | AccountType | Dim_AccountType | Name | Direct — account type name | Tier 1 |
| 9 | PlayerLevel | Dim_PlayerLevel | Name | Direct — eToro Club tier name | Tier 1 |
| 10 | PlayerStatus | Dim_PlayerStatus | Name | Direct — customer account status | Tier 1 |
| 11 | OpenPositionsCount | Dim_Position | CloseDateID=0 | `SUM(CASE WHEN CloseDateID=0 THEN 1 ELSE 0)` — count of currently open positions (excludes partial close children) | Tier 2 |
| 12 | ClosedPositionsCount | Dim_Position | CloseDateID≠0 | `SUM(CASE WHEN CloseDateID<>0 THEN 1 ELSE 0)` — count of closed positions (excludes partial close children) | Tier 2 |
| 13 | MostRecentOpenPosition | Dim_Position | OpenOccurred | `MAX(CAST(OpenOccurred AS DATE))` — most recent position open date (includes open AND closed positions) | Tier 2 |
| 14 | RealizedEquity | V_Liabilities | RealizedEquity | `ISNULL(RealizedEquity, 0)` — total realized P&L from closed positions | Tier 2 |
| 15 | UnRealizedEquity | V_Liabilities | ActualNWA + Liabilities | `ISNULL(ActualNWA,0) + ISNULL(Liabilities,0)` — current unrealized P&L (open position value + leverage obligations) | Tier 2 |
| 16 | TotalPositionsAmount | V_Liabilities | TotalPositionsAmount | `ISNULL(TotalPositionsAmount,0)` — total amount invested across all positions | Tier 2 |
| 17–31 | RC1–RC15 | #regulation02 / Dim_Regulation | RegDesc | `MAX(CASE WHEN RegChangeRowNum=N THEN RegDesc ELSE NULL END)` — Nth regulation change in chronological order. RC1 = first change, RC15 = 15th. NULL if < N changes. | Tier 2 |
| 32 | UpdateDate | SP-computed | GETDATE() | ETL metadata: timestamp when this row was last updated by the ETL pipeline | Tier 2 |

## UC External Lineage

UC Target: Not Migrated

---
object: Dealing_SuspiciousActivityTrading_24H
lineage_type: DWH Detection → Alert Table
production_source: DWH_dbo.Dim_Position (intraday 3-minute trade pairs)
---

# Dealing_SuspiciousActivityTrading_24H — Lineage Map

## Data Flow

```
DWH_dbo.Dim_Position (OpenDateID = @DateID)
                │
                ├── Root position (pc): DATEDIFF(minute, OpenOccurred, CloseOccurred) ≤ 3
                │   AND child positions (p): TreeID = root.PositionID, OpenDateID = @DateID
                │
                ▼
          #treeTMP (CID, RootCID=pc.CID, IsCopy, NetProfit, TreeID)
                │
          DWH_dbo.Dim_Mirror (IsActive=1) → #IsImportantPI (ParentCID, NumberofCopiers)
                │
          #TreePnL (tree-level NetProfit for copy filter > $10K)
                │
          DWH_dbo.Dim_Customer (FirstDepositDate → Is3Month)
          DWH_dbo.Dim_Regulation (RegulationID → Name)
                │
          HAVING COUNT(*)≥5 AND SUM(NetProfit)>3000
          COPY filter: IsCopy='Copy' only if TreePnL > 10000
                │
          DWH_dbo.Dim_Date (LEFT JOIN to ensure row on no-activity days)
                │
                ▼
        Dealing_SuspiciousActivityTrading_24H + Dealing_SuspiciousActivityTrading_24H_Email
```

## Refresh Schedule
Daily — SP_SuspiciousActivityTrading_24H, OpsDB Priority 0, ProcessType 1 (SQL). Active.

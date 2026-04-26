# BI_DB_dbo.BI_DB_CID_BalanceDays — Column Lineage

> One row per depositor customer. Revenue/Deposit columns = cumulative from FTD through N days. Equity columns = point-in-time on Nth day after FTD. Written incrementally: row inserted on FTD day, then each metric column updated as milestones are reached (D+1, D+7, D+14, D+30, D+60, D+90, D+180, D+365).

| Column | Source Table | Source Column | Transform |
|--------|-------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | Passthrough (population: IsDepositor=1, IsValidCustomer=1) |
| Revenue1day | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissions + RollOverFee | SUM of Revenue_Total from FTD to FTD+0 days; updated only when DateDiff=0 |
| Revenue7days | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissions + RollOverFee | SUM from FTD to FTD+6 days; updated when DateDiff=6 |
| Revenue14days | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissions + RollOverFee | SUM from FTD to FTD+13 days; updated when DateDiff=13 |
| Revenue30days | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissions + RollOverFee | SUM from FTD to FTD+29 days; updated when DateDiff=29 |
| Revenue60days | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissions + RollOverFee | SUM from FTD to FTD+59 days; updated when DateDiff=59 |
| Revenue90days | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissions + RollOverFee | SUM from FTD to FTD+89 days; updated when DateDiff=89 |
| Revenue180days | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissions + RollOverFee | SUM from FTD to FTD+179 days; updated when DateDiff=179 |
| Revenue365days | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissions + RollOverFee | SUM from FTD to FTD+364 days; updated when DateDiff=364 |
| Deposit1day | DWH_dbo.Fact_CustomerAction (ActionTypeID=7) | Amount | SUM deposits from FTD to FTD+0 days; updated when DateDiff=0 |
| Deposit7days | DWH_dbo.Fact_CustomerAction (ActionTypeID=7) | Amount | SUM from FTD to FTD+6 days; updated when DateDiff=6 |
| Deposit14days | DWH_dbo.Fact_CustomerAction (ActionTypeID=7) | Amount | SUM from FTD to FTD+13 days; updated when DateDiff=13 |
| Deposit30days | DWH_dbo.Fact_CustomerAction (ActionTypeID=7) | Amount | SUM from FTD to FTD+29 days; updated when DateDiff=29 |
| Deposit60days | DWH_dbo.Fact_CustomerAction (ActionTypeID=7) | Amount | SUM from FTD to FTD+59 days; updated when DateDiff=59 |
| Deposit90days | DWH_dbo.Fact_CustomerAction (ActionTypeID=7) | Amount | SUM from FTD to FTD+89 days; updated when DateDiff=89 |
| Deposit180days | DWH_dbo.Fact_CustomerAction (ActionTypeID=7) | Amount | SUM from FTD to FTD+179 days; updated when DateDiff=179 |
| Deposit365days | DWH_dbo.Fact_CustomerAction (ActionTypeID=7) | Amount | SUM from FTD to FTD+364 days; updated when DateDiff=364 |
| Equity1day | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | Point-in-time on FTD+0 day; updated when DateDiff=0 |
| Equity7days | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | Point-in-time on FTD+6 day; updated when DateDiff=6 |
| Equity14days | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | Point-in-time on FTD+13 day; updated when DateDiff=13 |
| Equity30days | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | Point-in-time on FTD+29 day; updated when DateDiff=29 |
| Equity60days | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | Point-in-time on FTD+59 day; updated when DateDiff=59 |
| Equity90days | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | Point-in-time on FTD+89 day; updated when DateDiff=89 |
| Equity180days | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | Point-in-time on FTD+179 day; updated when DateDiff=179 |
| Equity365days | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | Point-in-time on FTD+364 day; ISNULL to 0 at 365 milestone; updated when DateDiff=364 |
| UpdateDate | SP_CID_BalanceDays | — | GETDATE() — refreshed at each UPDATE pass |

## Revenue Formula

```
Revenue_Total (per day, from BI_DB_DailyCommisionReport) =
  SUM(FullCommissions + RollOverFee)
    WHERE (IsMirror=0 AND InstrumentTypeID IN (1,2,4,5,6,10))   -- Direct trades: specific instrument types
       OR (IsMirror=1)                                            -- All CopyTrading trades regardless of instrument
```

## ETL Pipeline

```
DWH_dbo.Dim_Customer (IsDepositor=1, IsValidCustomer=1)
  → #pop: customers whose DATEDIFF(FTD, yesterday) IN (0,6,13,29,59,89,179,364)
  |
  BI_DB_dbo.BI_DB_DailyCommisionReport (revenue per day per CID)
  DWH_dbo.Fact_CustomerAction (ActionTypeID=7 = deposits)
  DWH_dbo.V_Liabilities (daily equity snapshot)
  |
  v [SP_CID_BalanceDays @yesterday — Priority 0, Daily, SB_Daily]
    1. For DateDiff=0 customers: DELETE existing row, INSERT new row (CID + UpdateDate only)
    2. For each milestone cohort:
       - Revenue{N}days: UPDATE from SUM(DailyCommisionReport) WHERE ActiveDate <= FTD+N-1
       - Deposit{N}days: UPDATE from SUM(Fact_CustomerAction) WHERE datediff <= N-1
       - Equity{N}days: UPDATE from V_Liabilities WHERE datediff = N-1
BI_DB_dbo.BI_DB_CID_BalanceDays (one row per depositor, ROUND_ROBIN, CLUSTERED CID)
```

## T1 Verbatim Copy Verification Log

No upstream wiki columns applicable. All columns Tier 2 (SP ETL logic + formula computations).

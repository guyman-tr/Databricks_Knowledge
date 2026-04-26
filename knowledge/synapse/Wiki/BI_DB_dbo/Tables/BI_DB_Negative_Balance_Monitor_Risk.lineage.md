# BI_DB_dbo.BI_DB_Negative_Balance_Monitor_Risk — Column Lineage

## Writer SP

`BI_DB_dbo.SP_Negative_Balance_Monitor_Risk` (@Date DATE)
Author: Artyom Bogomolsky, 2024-09-20.

## Load Pattern

Monthly DELETE+INSERT by FullDate. WHILE loop only fires when @Date = EOMONTH(@Date). Processes current month + prior month snapshot via self-join.

## Source Objects

| # | Source Object | Alias | Role |
|---|---------------|-------|------|
| 1 | DWH_dbo.V_Liabilities | vl | Primary — customer balance (Liabilities+ActualNWA) |
| 2 | DWH_dbo.Fact_SnapshotCustomer | fsc | Customer snapshot (IsValidCustomer=1) |
| 3 | DWH_dbo.Dim_Range | dr | Date range filter for snapshot validity |
| 4 | DWH_dbo.Dim_Date | dd | Calendar — IsLastDayOfMonth='Y' |
| 5 | DWH_dbo.Dim_PlayerLevel | dpl | Lookup — Club (player tier name) |
| 6 | DWH_dbo.Dim_PlayerStatus | dps | Lookup — PlayerStatus name |
| 7 | DWH_dbo.Dim_MifidCategorization | dmc | Lookup — MIFID category name |
| 8 | DWH_dbo.Dim_Regulation | dr1 | Lookup — Regulation name |
| 9 | DWH_dbo.Dim_Customer | dc | Customer attributes (IsDepositor, FirstDepositDate, RegisteredReal) |
| 10 | BI_DB_dbo.BI_DB_DDR_CID_Level | bddcl | Funded_New_Def (LEFT JOIN — buggy: DateID=CID) |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform |
|---|----------------|-------------|---------------|-----------|
| 1 | FullDate | Dim_Date | FullDate | End-of-month dates only (IsLastDayOfMonth='Y') |
| 2 | IsDepositor | Dim_Customer | IsDepositor | Passthrough |
| 3 | Ind_FTD_Last_30days | Dim_Customer | FirstDepositDate | CASE: DATEDIFF(day, FirstDepositDate, FullDate) <= 30 → 1, ELSE 0 |
| 4 | MIFID | Dim_MifidCategorization | Name | JOIN lookup |
| 5 | Club | Dim_PlayerLevel | Name | JOIN lookup |
| 6 | PlayerStatus | Dim_PlayerStatus | Name | JOIN lookup |
| 7 | Regulation | Dim_Regulation | Name | JOIN lookup |
| 8 | Negative_Balance_Ind | V_Liabilities | Liabilities, ActualNWA | CASE: (Liabilities+ActualNWA)<0 → 1, ELSE 0 |
| 9 | Prev_Month | Dim_Date | FullDate | EOMONTH(DATEADD(MONTH,-1,FullDate)) |
| 10 | More_than_30Days_ind | Self-join | #negative_balance_Artyom | 1 if same CID had negative balance (Balance<0) in Prev_Month |
| 11 | Funded | BI_DB_DDR_CID_Level | Funded_New_Def | LEFT JOIN (buggy: DateID=CID — rarely matches, ~97.5% NULL) |
| 12 | Balance_Group | V_Liabilities | Liabilities, ActualNWA | CASE bucket on SUM(balance): Positive, >-1, -1 to -10, -10 to -50, -50 to -100, -100 to -500, Check (bug: <-500 unreachable, falls to ELSE) |
| 13 | Registration_Last_30_Days | Dim_Customer | RegisteredReal | CASE: DATEDIFF(day, RegisteredReal, FullDate) <= 30 → 1, ELSE 0 |
| 14 | Customers | Aggregation | COUNT(RealCID) | Count of customers in each group |
| 15 | Balance | V_Liabilities | Liabilities, ActualNWA | SUM(Liabilities+ActualNWA) per group |
| 16 | UpdateDate | ETL | GETDATE() | ETL metadata |

## Production Source Chain

```
DWH_dbo.V_Liabilities (customer balance snapshots)
DWH_dbo.Fact_SnapshotCustomer (valid customer filter)
DWH_dbo.Dim_Date (end-of-month dates)
DWH_dbo.Dim_Customer + Dim_PlayerLevel + Dim_PlayerStatus + Dim_MifidCategorization + Dim_Regulation
  |-- SP_Negative_Balance_Monitor_Risk @Date ---|
  v
BI_DB_dbo.BI_DB_Negative_Balance_Monitor_Risk (78K rows)
  UC Target: _Not_Migrated
```

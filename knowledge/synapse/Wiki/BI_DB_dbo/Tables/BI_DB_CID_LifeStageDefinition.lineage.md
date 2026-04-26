# BI_DB_dbo.BI_DB_CID_LifeStageDefinition — Lineage

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (population, IsValidCustomer, IsDepositor, PlayerLevelID)
  + DWH_dbo.Dim_Range (date range filter: @dateINT BETWEEN FromDateID AND ToDateID)
  + DWH_dbo.Dim_Customer (RegisteredReal=RegistrationDate, FirstDepositDate)
  + DWH_dbo.Dim_Position (LastOpenPosition in last 90 days, partial-close excluded)
  + DWH_dbo.V_Liabilities (RealizedEquity > 0 / >= 20 — IsFunded check per date)
  + DWH_dbo.Fact_SnapshotEquity (LastFunded20Date: last date RealizedEquity >= 20 in past year, via Dim_Range+Dim_Date)
  + BI_DB_dbo.BI_DB_CIDFirstDates (FirstNewFundedDate)
  + DWH_dbo.Fact_CustomerAction (ActionTypeID=14 logins last 365 days; ActionTypeID=7 deposits last 90 days)
  + BI_DB_dbo.BI_DB_CID_LifeStageDefinition (self-reference: previous status for Winback detection)
  -> SP_CID_LifeStageDefinition(@date)
     [daily run: DELETE WHERE DateID=@date, fill from MAX(Date)+1 to yesterday in WHILE loop]
     [historical run: DELETE WHERE DateID >= @date, rebuild entire history in WHILE loop]
  -> BI_DB_dbo.BI_DB_CID_LifeStageDefinition (SCD Type 2 UPDATEs + INSERTs)
```

**Orchestration**: OpsDB ProcessName=SB_Daily, Priority=0, Frequency=Daily.

## Source → Target Column Mapping

| Target Column | Source Object | Source Column / Expression | Tier |
|--------------|---------------|----------------------------|------|
| Date | Computed | @date2 (YYYYMMDD varchar) in daily run / @date in historical run | T2 |
| DateID | Computed | CONVERT(CHAR(8), @date2, 112) as INT | T2 |
| RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID (valid customer at @date snapshot) | T2 |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate (CAST as DATE) | T2 |
| PlayerLevelID | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID (current tier at @date) | T2 |
| LSD | Computed | Priority CASE: WinBack > Lead > New > Dump > Churn > Active Open > Holder > Active LogIn > No Activity - Funded > No Activity - Not Funded | T2 |
| ToDate | Computed | '9999-12-31' at INSERT (open row); DATEADD(DAY,-1,@date2) on UPDATE when LSD changes | T2 |
| ToDateID | Computed | 99991231 at INSERT; CONVERT(CHAR(8), DATEADD(DAY,-1,@date2), 112) on UPDATE | T2 |
| UpdateDate | Computed | GETDATE() | T2 |

## LSD Classification Logic (Priority Order)

The LSD is computed via a multi-step CASE with the following priority waterfall:

| Priority | LSD Value | Rule |
|----------|----------|------|
| 1 | Win Back Deposit | Previously in Churn 14-30d / 31-60d / over 60d / Dump Churn; now deposited within last 14 days; no open position in last 14 days |
| 1 | Win Back Active Open | Previously churned; opened position in last 14 days |
| 1 | Win Back Deposit (sticky) | Was in Win Back Deposit <14 days ago; still has deposit, no open position |
| 1 | Win Back Active Open (sticky) | Was in Win Back Active Open <14 days ago; still active open |
| 2 | Lead | IsDepositor=0, logged in within last 180 days |
| 3 | New Funded | First deposit within last 14 days AND has first-funded date |
| 3 | New Depositor Only | First deposit within last 14 days, no first-funded date |
| 4 | Dump Lead | IsDepositor=0, last login > 180 days ago OR never logged in |
| 4 | Dump Churn | Previously "Churn over 60d" or "Dump Churn"; equity < $20 for over 1 year (LastFunded20Date IS NULL) |
| 5 | Churn 14-30 days | Was funded (FirstFundedDate exists), currently equity < $20, last time funded was 14-30 days ago |
| 5 | Churn 31-60 days | Same, but 31-60 days ago |
| 5 | Churn over 60 days | Same, but > 60 days ago |
| 6 | Active Open | Last opened position in last 30 days AND PlayerLevelID < 2 (Bronze) |
| 6 | Active Open Club | Last opened position in last 30 days AND PlayerLevelID >= 2 (Silver+) |
| 6 | Active Open 30-90 days | Last opened position 31-90 days ago AND PlayerLevelID < 2 |
| 6 | Active Open 30-90 days Club | Last opened position 31-90 days ago AND PlayerLevelID >= 2 |
| 7 | Holder | Has open position today (not recently active), not in New bucket, PlayerLevelID=1 (Bronze) |
| 7 | Holder Club | Same, but PlayerLevelID > 1 (Silver+) |
| 8 | Active LogIn | Not holder/active-open, logged in last 30 days |
| 9 | No Activity - Funded | None of above, currently equity >= $20 |
| 10 | No Activity - Not Funded | None of above (default) |

## SCD Type 2 Change Tracking

The table stores customer lifecycle transitions:
- **INSERT**: When a customer's LSD changes (EXCEPT logic compares new vs. current status), a new row is inserted with DateID=transition date, ToDateID=99991231 (open/current).
- **UPDATE**: Prior open row is closed: ToDate = @date - 1, ToDateID = @date - 1 as INT.
- **Self-reference**: The SP reads the table itself to get the "last status" for Winback detection and sticky-period logic.
- **Gap fill**: Daily run fills from MAX(Date)+1 to yesterday if any dates were missed (WHILE loop).

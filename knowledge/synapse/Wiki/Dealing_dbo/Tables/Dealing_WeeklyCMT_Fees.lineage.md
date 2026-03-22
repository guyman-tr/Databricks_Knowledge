# Lineage Map — Dealing_dbo.Dealing_WeeklyCMT_Fees

**Generated**: 2026-03-21
**Writer SP**: `Dealing_dbo.SP_Crypto_CMT_Fees(@Date)` — runs ONLY when @Date is Sunday
**Pattern**: DELETE WHERE EndDate=@Date + INSERT (weekly, Sundays only)

## ETL Chain

```
DWH_dbo.Dim_Position (crypto InstrumentTypeID=10, OpenDateID<=20210108, CloseDateID=0, Leverage>1, IsBuy=1)
  + DWH_dbo.Dim_Customer (IsValidCustomer=1)
  + DWH_dbo.Dim_Instrument (InstrumentTypeID=10, Tradable=1, VisibleInternallyOnly=0)
  → #Temp1 (old leveraged long crypto positions still open)

DWH_dbo.Fact_CustomerAction (ActionTypeID=35, IsFeeDividend=1 = rollover fees within week window)
  JOIN #Temp1
  → #Temp2 (positions with weekly rollover fees)

DWH_dbo.Dim_Regulation + Dim_Manager + Dim_PlayerLevel + #OnePip (Precision→pip size)
  WHERE StopRate <= pip threshold (nearly zero — effectively stopped out)
  → #Temp (aggregated by position)
        └── Dealing_dbo.Dealing_WeeklyCMT_Fees
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| EndDate | @Date parameter | — | Sunday date |
| StartDate | DATEADD(DAY,-6,@Date) | — | Monday of the week |
| CID | DWH_dbo.Dim_Position | CID | Direct |
| GCID | DWH_dbo.Dim_Customer | GCID | Direct |
| PositionID | DWH_dbo.Dim_Position | PositionID | Direct |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Direct |
| Leverage | DWH_dbo.Dim_Position | Leverage | Direct |
| IsSettled | DWH_dbo.Dim_Position | IsSettled | Direct |
| OpenOccurred | DWH_dbo.Dim_Position | OpenOccurred | Direct |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Direct |
| Regulation | DWH_dbo.Dim_Regulation | Name | Direct |
| AccountManager | DWH_dbo.Dim_Manager | FirstName+' '+LastName | Concatenation |
| RollOverFee | DWH_dbo.Fact_CustomerAction | -Amount | SUM of weekly rollover fees (ActionTypeID=35) |
| StopRate | DWH_dbo.Dim_Position | StopRate | Direct |
| UpdateDate | GETDATE() | — | ETL timestamp |

## Governance

- **Execution gate**: SP checks IF DATENAME(WEEKDAY, @Date) = 'Sunday' → only runs on Sundays
- **Position eligibility**: OpenDateID <= 20210108 (legacy crypto positions predating Jan 8, 2021)
- **StopRate filter**: Must be ≤ pip value for instrument (positions at/near zero stop — essentially stopped out)
- **ActionTypeID=35**: Rollover fee action type
- **STALE since 2023-04-09**: Program appears to have ended — no positions meet the pre-2021 open criteria anymore

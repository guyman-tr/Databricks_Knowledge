# BI_DB_dbo.BI_DB_PI_Gain — Column Lineage

## Writer SP
`BI_DB_dbo.SP_PI_Gain` — daily TRUNCATE+INSERT

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | PI/Portfolio population (GuruStatusID>=2 or AccountTypeID=9) |
| DWH_dbo.Dim_Range | DWH_dbo | Date range validity |
| DWH_dbo.Dim_Customer | DWH_dbo | UserName, ID |
| BI_DB_dbo.BI_DB_DailyGain_History | BI_DB_dbo | Daily gain percentages |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | passthrough |
| UserName | DWH_dbo.Dim_Customer | UserName | passthrough |
| CopyType | DWH_dbo.Fact_SnapshotCustomer | AccountTypeID | CASE: 9='Portfolio', else='PI' |
| Year | BI_DB_dbo.BI_DB_DailyGain_History | StartPeriod | YEAR(StartPeriod) |
| Quarter | BI_DB_dbo.BI_DB_DailyGain_History | StartPeriod | DATEPART(q, StartPeriod) |
| Month | BI_DB_dbo.BI_DB_DailyGain_History | StartPeriod | MONTH(StartPeriod) |
| TimeFarme | (computed) | — | 'M' (monthly), 'Q' (quarterly), 'Y' (yearly) |
| StartPeriod | BI_DB_dbo.BI_DB_DailyGain_History | StartPeriod | passthrough (M) / MIN (Q,Y) |
| EndPeriod | BI_DB_dbo.BI_DB_DailyGain_History | EndPeriod | passthrough (M) / MAX (Q,Y) |
| Gain | BI_DB_dbo.BI_DB_DailyGain_History | Gain | passthrough (M) / compound product via EXP(SUM(LOG(...))) (Q,Y) |
| IsLast | — | — | NOT populated by SP — always NULL |
| UpdateDate | (computed) | — | GETDATE() |

**PHASE 10B CHECKPOINT: PASS**

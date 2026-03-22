# Lineage Map — Dealing_dbo.Dealing_Commission_Assurance

## Object
- **Table**: `Dealing_dbo.Dealing_Commission_Assurance`
- **Schema**: Dealing_dbo
- **Type**: Table

## Production Source
| Attribute | Value |
|-----------|-------|
| Writer SP | `Dealing_dbo.SP_Rev_Assurance` |
| Primary Source | `DWH_dbo.Dim_Position` |
| Dimension Sources | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Customer` |
| Staging/External | None |
| Generic Pipeline | Not applicable — sourced directly from DWH dimensions |

## ETL Flow
```
DWH_dbo.Dim_Position (positions opened/closed within @FirstDayOfMonth to @DateID)
    ↓ JOIN DWH_dbo.Dim_Instrument (InstrumentType)
    ↓ JOIN DWH_dbo.Dim_Customer (PlayerLevelID <> 4 filter)
    ↓ GROUP BY InstrumentType, MirrorID>0 (Copy/Manual), Month
    ↓ AGGREGATE: Total_Units, Units_Without_Comm, Ratio, Max Rev Lost
→ Dealing_dbo.Dealing_Commission_Assurance (DELETE + INSERT for current month)
```

## Column Lineage
| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Month | SP parameter | @date | CONVERT(varchar(7), @date, 126) → YYYY-MM format |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough |
| Type | DWH_dbo.Dim_Position | MirrorID | CASE: MirrorID>0='Copy', else='Manual' |
| Total_Units | DWH_dbo.Dim_Position | AmountInUnitsDecimal | SUM of on-open + on-close units |
| Units_Without_Comm | DWH_dbo.Dim_Position | AmountInUnitsDecimal | SUM where Commission=0 or CommissionOnClose=0 |
| Ratio | Computed | — | Units_Without_Comm / Total_Units |
| Max Rev Lost | Computed | — | NoCommission_Positions_Opened × 0.005 |
| UpdateDate | ETL | GETDATE() | ETL metadata |

## Notes
- Same SP writes `Dealing_Commission_Assurance`, `Dealing_Commission_Assurance_By_Position`, and `Dealing_Rollover_Assurance`
- No Generic Pipeline involvement — data flows from DWH_dbo Dim tables directly

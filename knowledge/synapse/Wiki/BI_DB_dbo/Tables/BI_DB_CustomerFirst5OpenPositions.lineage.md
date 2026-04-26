# BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions — Column Lineage

## Writer SP

`BI_DB_dbo.SP_CustomerFirst5OpenPositions` (Priority 0, Daily, SB_Daily) — Main section

## Source Objects

| Source Object | Role |
|--------------|------|
| DWH_dbo.Dim_Customer | Population (IsDepositor=1, IsValidCustomer=1) |
| DWH_dbo.Dim_Position | Open positions for yesterday (OpenDateID=@yesterdayINT), IsBuy flag |
| DWH_dbo.Fact_CustomerAction | Action details (ActionTypeID IN (1,17), IsAirDrop IS NULL) |
| BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions | Self-reference for exclusion (users with ActionNumber=5 already) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| RealCID | DWH_dbo.Fact_CustomerAction | RealCID | Passthrough |
| Occurred | DWH_dbo.Fact_CustomerAction | Occurred | Passthrough |
| ActionTypeID | DWH_dbo.Fact_CustomerAction | ActionTypeID | Passthrough — values: 1 (Open), 17 (Copy Open) |
| MirrorID | DWH_dbo.Fact_CustomerAction | MirrorID | Passthrough — 0=direct trade, >0=copy trade |
| InstrumentID | DWH_dbo.Fact_CustomerAction | InstrumentID | Passthrough |
| Leverage | DWH_dbo.Fact_CustomerAction | Leverage | Passthrough |
| Amount | DWH_dbo.Fact_CustomerAction | Amount | Passthrough (negative = investment amount) |
| DateID | DWH_dbo.Fact_CustomerAction | DateID | Passthrough (YYYYMMDD int) |
| ActionNumber | — | — | ETL-computed: ROW_NUMBER() OVER(PARTITION BY RealCID ORDER BY Occurred). Values 1-5 only (WHERE ActionNumber<6) |
| UpdateDate | — | — | ETL metadata: GETDATE() |
| IsBuy | DWH_dbo.Dim_Position | IsBuy | Passthrough via PositionID JOIN — 1=Buy, 0=Sell |

## UC External Lineage

Not applicable — UC Target: _Not_Migrated.

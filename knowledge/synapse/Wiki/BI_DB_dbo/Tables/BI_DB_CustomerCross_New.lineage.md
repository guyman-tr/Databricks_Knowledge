# BI_DB_dbo.BI_DB_CustomerCross_New — Column Lineage

## Writer SP

`BI_DB_dbo.SP_CustomerFirst5OpenPositions` (Priority 0, Daily, SB_Daily) — Cross New section

## Source Objects

| Source Object | Role |
|--------------|------|
| DWH_dbo.Fact_CustomerAction | Source actions (ActionTypeID IN (1,17), IsAirDrop IS NULL) |
| DWH_dbo.Dim_Position | Open position identification (OpenDateID=@yesterdayINT) |
| DWH_dbo.Dim_Customer | Population (IsDepositor=1, IsValidCustomer=1) + CopyFund CID list |
| DWH_dbo.Dim_Instrument | InstrumentTypeID → asset class classification (alternative grouping) |
| DWH_dbo.Dim_Mirror | MirrorID → ParentCID for Copy/CopyFund detection |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| RealCID | DWH_dbo.Fact_CustomerAction | RealCID | Passthrough |
| ActionTypeNew | DWH_dbo.Dim_Instrument + DWH_dbo.Dim_Mirror | InstrumentTypeID, MirrorID | ETL-computed CASE: InstrumentTypeID=10→Crypto, (1,2)→FX/Commodities, (4,5,6)→Stocks/ETFs/Indices, CopyFund CIDs→Copy Fund, MirrorID NOT NULL→Copy |
| Occurred | DWH_dbo.Fact_CustomerAction | Occurred | MIN per (RealCID, ActionTypeNew) — first occurrence |
| OccurredDateID | DWH_dbo.Fact_CustomerAction | DateID | MIN per (RealCID, ActionTypeNew) — first occurrence date |
| UpdateDate | — | — | ETL metadata: GETDATE() |

## UC External Lineage

Not applicable — UC Target: _Not_Migrated.

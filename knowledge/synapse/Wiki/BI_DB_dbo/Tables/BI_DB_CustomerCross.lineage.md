# BI_DB_dbo.BI_DB_CustomerCross — Column Lineage

## Writer SP

`BI_DB_dbo.SP_CustomerFirst5OpenPositions` (Priority 0, Daily, SB_Daily) — Cross Procedure section

## Source Objects

| Source Object | Role |
|--------------|------|
| DWH_dbo.Fact_CustomerAction | Source actions (ActionTypeID IN (1,17), IsAirDrop IS NULL) |
| DWH_dbo.Dim_Position | Open position identification (OpenDateID=@yesterdayINT) |
| DWH_dbo.Dim_Customer | Population (IsDepositor=1, IsValidCustomer=1) + CopyFund CID list (AccountTypeID=9) |
| DWH_dbo.Dim_Instrument | InstrumentTypeID → asset class classification |
| DWH_dbo.Dim_Mirror | MirrorID → ParentCID for Copy/CopyFund detection |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| RealCID | DWH_dbo.Fact_CustomerAction | RealCID | Passthrough |
| ActionType_Detailed | DWH_dbo.Dim_Instrument + DWH_dbo.Dim_Mirror | InstrumentTypeID, MirrorID | ETL-computed CASE: InstrumentTypeID=10→Crypto, (1,2,4)→FX/Commodities/Indices, (5,6)+Leverage=1+IsBuy=1→Real Stocks/ETFs, (5,6)+Leverage>1 or IsBuy=0→CFD Stocks/ETFs, CopyFund CIDs→Copy Fund, MirrorID NOT NULL→Copy |
| Occurred | DWH_dbo.Fact_CustomerAction | Occurred | MIN per (RealCID, ActionType_Detailed) — first occurrence |
| OccurredDateID | DWH_dbo.Fact_CustomerAction | DateID | MIN per (RealCID, ActionType_Detailed) — first occurrence date |
| UpdateDate | — | — | ETL metadata: GETDATE() |

## UC External Lineage

Not applicable — UC Target: _Not_Migrated.

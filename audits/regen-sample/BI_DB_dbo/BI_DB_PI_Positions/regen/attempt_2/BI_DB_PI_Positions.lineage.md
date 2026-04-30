# Lineage: BI_DB_dbo.BI_DB_PI_Positions

## Source Objects

| Source Object | Type | Schema | Role |
|--------------|------|--------|------|
| DWH_dbo.Dim_Position | Table | DWH_dbo | Primary data source — all 17 data columns are direct passthroughs |
| DWH_dbo.Dim_Customer | Table | DWH_dbo | Population filter — GuruStatusID IN (2,3,4,5,6) AND IsValidCustomer=1 OR AccountTypeID=9 |
| DWH_dbo.Dim_GuruStatus | Table | DWH_dbo | Population filter — joined for PI tier filtering |
| DWH_dbo.Dim_Country | Table | DWH_dbo | Population filter — joined in #pop but no columns selected into this table |
| DWH_dbo.Dim_PlayerStatus | Table | DWH_dbo | Population filter — joined in #pop but no columns selected into this table |

## Column Lineage

| Target Column | Source Table | Source Column | Transform | Tier |
|--------------|-------------|---------------|-----------|------|
| PositionID | DWH_dbo.Dim_Position | PositionID | Passthrough | Tier 1 — Trade.PositionTbl |
| CID | DWH_dbo.Dim_Position | CID | Passthrough (filtered to PI/CopyFund population) | Tier 1 — Trade.PositionTbl |
| InstrumentID | DWH_dbo.Dim_Position | InstrumentID | Passthrough | Tier 1 — Trade.PositionTbl |
| Leverage | DWH_dbo.Dim_Position | Leverage | Passthrough | Tier 1 — Trade.PositionTbl |
| Amount | DWH_dbo.Dim_Position | Amount | Passthrough (synced via UPDATE in section 2.3) | Tier 1 — Trade.PositionTbl |
| IsBuy | DWH_dbo.Dim_Position | IsBuy | Passthrough | Tier 1 — Trade.PositionTbl |
| OpenOccurred | DWH_dbo.Dim_Position | OpenOccurred | Passthrough | Tier 1 — Trade.PositionTbl |
| CloseOccurred | DWH_dbo.Dim_Position | CloseOccurred | Passthrough (synced via UPDATE in section 2.3) | Tier 1 — Trade.PositionTbl |
| ParentPositionID | DWH_dbo.Dim_Position | ParentPositionID | Passthrough | Tier 1 — Trade.PositionTbl |
| OrigParentPositionID | DWH_dbo.Dim_Position | OrigParentPositionID | Passthrough | Tier 1 — Trade.PositionTbl |
| MirrorID | DWH_dbo.Dim_Position | MirrorID | Passthrough | Tier 1 — Trade.PositionTbl |
| OpenDateID | DWH_dbo.Dim_Position | OpenDateID | Passthrough | Tier 1 — SP_Dim_Position_DL_To_Synapse |
| CloseDateID | DWH_dbo.Dim_Position | CloseDateID | Passthrough (synced via UPDATE in section 2.3) | Tier 1 — SP_Dim_Position_DL_To_Synapse |
| Volume | DWH_dbo.Dim_Position | Volume | Passthrough | Tier 1 — SP_Dim_Position_DL_To_Synapse |
| FullCommissionOnCloseOrig | DWH_dbo.Dim_Position | FullCommissionOnCloseOrig | Passthrough (synced via UPDATE in section 2.3) | Tier 1 — SP_Dim_Position_DL_To_Synapse |
| IsSettled | DWH_dbo.Dim_Position | IsSettled | Passthrough | Tier 5 — Expert Review |
| FullCommissionByUnits | DWH_dbo.Dim_Position | FullCommissionByUnits | Passthrough (synced via UPDATE in section 2.3) | Tier 1 — Trade.Position |
| UpdateDate | — | — | ETL-computed: GETDATE() | Tier 2 — SP_PI_Dashboard_COPYDATA_RuningSideBySide |

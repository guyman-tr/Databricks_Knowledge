# BI_DB_dbo.BI_DB_US_Stocks_Transactions_Per_Time_Unit — Column Lineage

## Writer SP
`BI_DB_dbo.SP_US_Stocks_Transactions_Per_Time_Unit` — DELETE WHERE Date=@Date + INSERT

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| DWH_dbo.Dim_Position | DWH_dbo | Positions opened on @Date (RegulationID=8, InstrumentTypeID IN 5,6) |
| DWH_dbo.Dim_Position | DWH_dbo | Positions closed on @Date (RegulationID=8, ClosePositionReasonID!=10) |
| External_USABroker_Apex_ApexData | External | Apex active accounts (StatusID=12) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | (parameter) | @Date | passthrough |
| Daily | DWH_dbo.Dim_Position | PositionID | COUNT(PositionID) for entire day (open + close union) |
| Hour | DWH_dbo.Dim_Position | OpenDateTime/CloseDateTime | Hour number (0-23) of peak hour (TOP 1 by count) |
| Hourly | DWH_dbo.Dim_Position | PositionID | COUNT(PositionID) in peak hour |
| Minute | DWH_dbo.Dim_Position | OpenDateTime/CloseDateTime | Minute (0-59) of peak minute (TOP 1 by count) |
| Minutely | DWH_dbo.Dim_Position | PositionID | COUNT(PositionID) in peak minute |
| Second | DWH_dbo.Dim_Position | OpenDateTime/CloseDateTime | Second (0-59) of peak second (TOP 1 by count) |
| Secondly | DWH_dbo.Dim_Position | PositionID | COUNT(PositionID) in peak second |
| CID_Daily | DWH_dbo.Dim_Position | CID | COUNT(DISTINCT CID) for entire day |
| CID_Hourly | DWH_dbo.Dim_Position | CID | COUNT(DISTINCT CID) in peak hour |
| CID_Minutely | DWH_dbo.Dim_Position | CID | COUNT(DISTINCT CID) in peak minute |
| CID_Secondly | DWH_dbo.Dim_Position | CID | COUNT(DISTINCT CID) in peak second |
| Apex_Cnt | External_USABroker_Apex_ApexData | GCID | COUNT(DISTINCT GCID) WHERE StatusID=12 |
| UpdateDate | (computed) | — | GETDATE() |

**PHASE 10B CHECKPOINT: PASS**

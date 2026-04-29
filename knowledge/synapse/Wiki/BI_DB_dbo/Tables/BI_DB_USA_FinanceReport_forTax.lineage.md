# BI_DB_dbo.BI_DB_USA_FinanceReport_forTax — Column Lineage

## Writer SP
`BI_DB_dbo.SP_USA_FinanceReport_forTax` — DELETE WHERE DateID=@DateID + INSERT

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| DWH_dbo.Dim_Customer | DWH_dbo | RealCID, City, AffiliateID, RegulationID (6=eToroUS, 7=FinCEN) |
| DWH_dbo.Dim_State_and_Province | DWH_dbo | State name from StateID |
| DWH_dbo.Fact_CustomerAction | DWH_dbo | Compensation amounts (ActionTypeID=36) |
| DWH_dbo.Dim_Position | DWH_dbo | Closed positions, VolumeOnClose, NetProfit on @DateID |
| External_UserApiDB_Customer_ExtendedUserField | External | SSN/TIN (FieldId=6, CountryId=219) |
| History.Credit | External | Dynamic external table (created via SP_Create_External_etoro_History_Credit) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| DateID | (parameter) | @DateID | passthrough |
| Date | (parameter) | @Date | passthrough |
| RealCID | DWH_dbo.Dim_Customer | RealCID | passthrough |
| SSN | External_UserApiDB_Customer_ExtendedUserField | Value | WHERE FieldId=6 AND CountryId=219 |
| City | DWH_dbo.Dim_Customer | City | passthrough (masked in DDL with default()) |
| State | DWH_dbo.Dim_State_and_Province | Name | JOIN on StateID |
| AffiliateID | DWH_dbo.Dim_Customer | AffiliateID | passthrough |
| Compensation | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=36 |
| ClosePositions | DWH_dbo.Dim_Position | PositionID | COUNT(*) WHERE CloseDateID=@DateID |
| VolumeOnClose | DWH_dbo.Dim_Position | VolumeOnClose | SUM(VolumeOnClose) |
| Realized_PnL | DWH_dbo.Dim_Position | NetProfit | SUM(NetProfit) |
| UpdateDate | (computed) | — | GETDATE() |

**PHASE 10B CHECKPOINT: PASS**

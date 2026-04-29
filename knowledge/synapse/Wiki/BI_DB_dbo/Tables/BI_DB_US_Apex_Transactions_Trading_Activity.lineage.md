# BI_DB_dbo.BI_DB_US_Apex_Transactions_Trading_Activity — Column Lineage

## Source Objects

| Source Object | Type | Role |
|---|---|---|
| DWH_dbo.Dim_Position | Table | eToro side — opened/closed positions for US regulation |
| DWH_dbo.Dim_Instrument | Table | Instrument name and symbol |
| DWH_dbo.Fact_SnapshotCustomer | Table | Regulation verification + PlayerLevel for Club |
| DWH_dbo.Dim_Range | Table | DateRange validation |
| DWH_dbo.Dim_PlayerLevel | Table | Club level name |
| BI_DB_dbo.External_Sodreconciliation_apex_EXT872_TradeActivity | External Table | Apex side — SOD 872 trade activity |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---|---|---|---|
| ApexID | EXT872_TradeActivity | AccountNumber | Rename |
| ProccessDate | Derived | @Date | Constant date parameter |
| DateId | Derived | @DateID | INT YYYYMMDD format |
| AmountApex | EXT872_TradeActivity | NetAmount | ABS() |
| UnitsApex | EXT872_TradeActivity | Quantity | ABS() |
| PriceApex | EXT872_TradeActivity | Price | Passthrough |
| SymbolApex | EXT872_TradeActivity | Symbol | Passthrough |
| OrderIDApex | EXT872_TradeActivity | OrderId | Passthrough (contains PositionID + O/C suffix) |
| PositionID | EXT872/Dim_Position | EtoroID / PositionID | CASE: ISNULL(eToro.PositionID, parsed from OrderID) |
| PriceEtoro | Dim_Position | InitForexRate / EndForexRate | Open→InitForexRate, Close→EndForexRate |
| CIDEtoro | Dim_Position | CID | Passthrough |
| InstrumentID | Dim_Position | InstrumentID | Passthrough |
| InstrumentName | Dim_Instrument | InstrumentDisplayName | JOIN |
| SymbolEtoro | Dim_Instrument | Symbol | JOIN |
| UnitsEtoro | Dim_Position | InitialUnits / AmountInUnitsDecimal | Open→InitialUnits, Close→AmountInUnitsDecimal |
| AmountEtoro | Dim_Position | InitialAmountCents / Amount+NetProfit | Open→InitialAmountCents/100, Close→Amount+NetProfit |
| Category | Both | Type | CASE: Opened if either side is Opened, Closed if either side is Closed |
| ReconStatus | Derived | — | 'Exists in Both' / 'Missing in Apex' / 'Missing in eToro' |
| Club | Dim_PlayerLevel | Name | JOIN via Fact_SnapshotCustomer.PlayerLevelID |
| Copy_Manual | Dim_Position | MirrorID | CASE: MirrorID > 0 → 'Copy', ELSE 'Manual' |
| UpdateDate | ETL | GETDATE() | Insert timestamp |

# BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_eToroDB — Column Lineage

## Source Objects

| Source Object | Type | Role |
|---|---|---|
| DWH_dbo.Dim_Position | Table | Primary — settled stock/ETF positions for US regulation |
| DWH_dbo.Dim_Instrument | Table | Instrument name and CUSIP |
| DWH_dbo.Dim_ClosePositionReason | Table | Close reason name |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---|---|---|---|
| CID | Dim_Position | CID | Passthrough |
| InstrumentDisplayName | Dim_Instrument | InstrumentDisplayName | JOIN on DWHInstrumentID |
| CUSIP | Dim_Instrument | CUSIP | JOIN on DWHInstrumentID |
| Date | Dim_Position | CloseOccurred / OpenOccurred | CASE: ClosePositionReasonID IN (9,10) → CloseOccurred, else → OpenOccurred. Cast to DATE |
| Category | Dim_Position | ClosePositionReasonID | CASE: IN (9,10) → 'Delivered', else → 'Recieved' |
| IsAirDrop | Dim_Position | IsAirDrop | Passthrough |
| CloseReason | Dim_ClosePositionReason | Name | JOIN on ClosePositionReasonID |
| ClosePositionReasonID | Dim_Position | ClosePositionReasonID | Passthrough |
| RoundeUnits | Dim_Position | AmountInUnitsDecimal | SUM(ROUND(AmountInUnitsDecimal, 0)) |
| ExactUnits | Dim_Position | AmountInUnitsDecimal | SUM(AmountInUnitsDecimal) |
| UpdateDate | ETL | GETDATE() | Insert timestamp |

## Lineage Notes

- **US regulation filter**: WHERE RegulationIDOnOpen=8 AND IsSettled=1
- **Activity types**: ClosePositionReasonID IN (9,10) = hierarchical/system close → 'Delivered'. IsAirDrop=1 → 'Received' (crypto/stock airdrop). InstrumentTypeID IN (5,6) = stocks and ETFs only.

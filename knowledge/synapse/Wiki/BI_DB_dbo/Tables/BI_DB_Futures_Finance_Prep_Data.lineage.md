# Column Lineage: BI_DB_dbo.BI_DB_Futures_Finance_Prep_Data

## Column Mapping

| DWH Column | Source Table | Source Column | Transform | Notes |
|------------|-------------|---------------|-----------|-------|
| DateID | -- | @date parameter | ETL-computed: CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) | YYYYMMDD int from SP input date |
| PositionID | DWH_dbo.Dim_PositionChangeLog | PositionID | passthrough | Distribution key |
| CID | DWH_dbo.Dim_PositionChangeLog | CID | passthrough | |
| Occurred | DWH_dbo.Dim_PositionChangeLog | Occurred | passthrough | |
| OccurredDateID | DWH_dbo.Dim_PositionChangeLog | OccurredDateID | passthrough | |
| ChangeTypeID | DWH_dbo.Dim_PositionChangeLog | ChangeTypeID | SP-adjusted | Overridden to 99 for 'Hold' ActionType rows |
| PreviousAmount | DWH_dbo.Dim_PositionChangeLog | PreviousAmount | SP-adjusted | Set to NewAmount for 'Hold' ActionType rows |
| AmountChanged | DWH_dbo.Dim_PositionChangeLog | AmountChanged | SP-adjusted | Set to 0 for 'Hold' ActionType rows |
| NewAmount | DWH_dbo.Dim_PositionChangeLog | NewAmount | passthrough | |
| PreviousIsSettled | DWH_dbo.Dim_PositionChangeLog | PreviousIsSettled | passthrough | |
| IsSettled | DWH_dbo.Dim_PositionChangeLog + DWH_dbo.Dim_Position | IsSettled | COALESCE | COALESCE(changelog.IsSettled, Dim_Position.IsSettled) — fallback to Dim_Position |
| PreviousStopRate | DWH_dbo.Dim_PositionChangeLog | PreviousStopRate | passthrough | |
| StopRate | DWH_dbo.Dim_PositionChangeLog | StopRate | passthrough | |
| PreviousAmountInUnits | DWH_dbo.Dim_PositionChangeLog | PreviousAmountInUnits | passthrough | |
| AmountInUnits | DWH_dbo.Dim_PositionChangeLog | AmountInUnits | passthrough | |
| LotCountDecimal | DWH_dbo.Dim_PositionChangeLog | LotCountDecimal | SP-adjusted | Null-filled from ledger history (forward-fill from nearest prior non-null changelog event) |
| PreviousLotCountDecimal | DWH_dbo.Dim_PositionChangeLog | PreviousLotCountDecimal | SP-adjusted | Null-filled; set to 0 for ChangeTypeID=0 (open events), otherwise LAG-filled |
| InstrumentID | DWH_dbo.Fact_Position_Futures_Snapshot | InstrumentID | passthrough | Via #uniquesFromFuturesTable (DISTINCT from snapshot) |
| OriginalPositionID | DWH_dbo.Fact_Position_Futures_Snapshot | OriginalPositionID | passthrough | Via #uniquesFromFuturesTable |
| SettlementTime | DWH_dbo.Dim_Instrument_Snapshot | SettlementTime | passthrough | Current settlement time for the futures instrument |
| SettlementTimePrev | DWH_dbo.Dim_Instrument_Snapshot | SettlementTime | function-computed | LAG(SettlementTime, 1) OVER (PARTITION BY InstrumentID ORDER BY SettlementTime) |
| IsBuy | DWH_dbo.Fact_Position_Futures_Snapshot | IsBuy | passthrough | Via #uniquesFromFuturesTable |
| InitForexRate | DWH_dbo.Fact_Position_Futures_Snapshot | InitForexRate | passthrough | Via #uniquesFromFuturesTable |
| EndForexRate | DWH_dbo.Fact_Position_Futures_Snapshot | EndForexRate | function-computed | MAX(EndForexRate) grouped by position in #uniquesFromFuturesTable |
| RN | -- | -- | ETL-computed | ROW_NUMBER() in #ledgerPrev (PARTITION BY OriginalPositionID ORDER BY Occurred DESC); NULL for current-day entries |
| ActionType | -- | -- | ETL-computed | CASE on ChangeTypeID + OpenOccurred timing: Open, Hold, CloseOrig, PartialCloseOrig, EditSLIncreaseAmount, EditSLReduceAmount, ChildClose |
| UpdateDate | -- | -- | ETL-computed | GETDATE() |

## ETL Pipeline

```
DWH_dbo.Dim_PositionChangeLog + DWH_dbo.Fact_Position_Futures_Snapshot
+ DWH_dbo.Dim_Instrument_Snapshot + DWH_dbo.Dim_Position
    │
    └─ SP_Futures_Finance_Prep_Data(@date)
        ├─ #prevPerLotPrep (instrument settlement time + margin per lot with LAG for prev values)
        ├─ #prevPricePrep (latest settlement price per instrument from Fact_Settlement_Prices)
        ├─ #uniquesFromFuturesTable (distinct futures positions from Fact_Position_Futures_Snapshot for @date)
        ├─ #fullLedger (changelog entries for futures positions filtered by settlement window + ChangeTypeID IN (0,1,6,11,12))
        ├─ #ledgerPrev (yesterday's end-state: last changelog entry per OriginalPositionID before @dateID)
        ├─ #ledgerCurrent (today's changelog entries within settlement window)
        ├─ #final (UNION ALL of #ledgerPrev + #ledgerCurrent)
        ├─ #ledgerHistory (full changelog history for null-filling LotCountDecimal)
        ├─ UPDATE #final: null-fill LotCountDecimal/PreviousLotCountDecimal from history
        ├─ UPDATE #final: zero-out AmountChanged + override for 'Hold' rows
        ├─ DELETE WHERE DateID = @dateID
        └─ INSERT INTO BI_DB_Futures_Finance_Prep_Data (final JOIN to Dim_Position for IsSettled COALESCE)
```

## Source Tables

| Source | Role | Columns Used |
|--------|------|-------------|
| DWH_dbo.Dim_PositionChangeLog | Primary — position change ledger | PositionID, CID, Occurred, OccurredDateID, ChangeTypeID, PreviousAmount, AmountChanged, NewAmount, PreviousIsSettled, IsSettled, PreviousStopRate, StopRate, PreviousAmountInUnits, AmountInUnits, LotCountDecimal, PreviousLotCountDecimal |
| DWH_dbo.Fact_Position_Futures_Snapshot | Position filter — identifies futures positions for @date | PositionID, OriginalPositionID, InstrumentID, OpenOccurred, IsBuy, InitForexRate, EndForexRate |
| DWH_dbo.Dim_Instrument_Snapshot | Settlement window — settlement time and margin per lot | InstrumentID, SettlementTime, Multiplier, ProviderMarginPerLot, eToroMarginPerLot, IsFuture |
| DWH_dbo.Dim_Position | IsSettled fallback via final COALESCE JOIN | PositionID, IsSettled |
| DWH_dbo.Fact_Settlement_Prices | Not directly used in final output but used in #prevPricePrep | SettlementPrice, SettlementDate, InstrumentID |

## Consumer

| Consumer SP | Usage |
|-------------|-------|
| SP_Finance_Real_Futures_Custody_And_Transfers | Reads BI_DB_Futures_Finance_Prep_Data to build parent/child position ledger chains for Marex & custodian money transfer calculations |

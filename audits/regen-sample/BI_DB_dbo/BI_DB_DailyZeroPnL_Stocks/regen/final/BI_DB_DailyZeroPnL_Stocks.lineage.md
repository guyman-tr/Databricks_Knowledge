# BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks — Column Lineage

> Generated: 2026-04-29 | Writer: regen-harness attempt_1

---

## 3. Source Objects

| Source Schema | Source Object | Kind | Role |
|---|---|---|---|
| Dealing_dbo | SP_DailyZeroPnL_Stocks | Stored Procedure | Original writer (deprecated 2024-02-15; now writes to Dealing_dbo.Dealing_DailyZeroPnL_Stocks) |
| DWH_dbo | Dim_Position | Table | Provides position-level attributes and PnL fields |
| DWH_dbo | Dim_Instrument | Table | Provides instrument metadata: type, display name, industry, currency |
| DWH_dbo | Dim_Regulation | Table | Provides regulation name via CID → Fact_SnapshotCustomer |
| DWH_dbo | Fact_SnapshotCustomer | Table | Provides RegulationID and MifidCategorizationID per customer-date |
| DWH_dbo | Dim_Range | Table | Date range decode for Fact_SnapshotCustomer join |
| BI_DB_dbo | BI_DB_PositionPnL | Table | Provides NOP, DailyPnL, PositionPnL, Amount, OpenPositionValue per position-date |
| BI_DB_dbo | BI_DB_IndexesMapping_Static | Table | Provides StockIndex classification per InstrumentID |

---

## Column Lineage

| # | DWH Column | Synapse Column | Production Source | Source Column | Transform | Tier |
|---|---|---|---|---|---|---|
| 1 | Date | Date | SP_DailyZeroPnL_Stocks | @dd parameter | ETL-controlled reporting date; SET @RepDate = @dd | Tier 2 |
| 2 | HedgeServerID | HedgeServerID | Trade.PositionTbl | HedgeServerID | Passthrough via Dim_Position | Tier 1 |
| 3 | Industry | Industry | Trade.InstrumentMetaData | Industry | Passthrough via Dim_Instrument | Tier 1 |
| 4 | InstrumentType | InstrumentType | SP_Dim_Instrument | InstrumentTypeID | Inherited CASE label from Dim_Instrument.InstrumentType | Tier 2 |
| 5 | InstrumentID | InstrumentID | Trade.PositionTbl | InstrumentID | Passthrough via Dim_Position | Tier 1 |
| 6 | InstrumentDisplayName | InstrumentDisplayName | Trade.InstrumentMetaData | InstrumentDisplayName | Passthrough via Dim_Instrument | Tier 1 |
| 7 | StockIndex | StockIndex | BI_DB_IndexesMapping_Static | StockIndex | Passthrough via LEFT JOIN on InstrumentID; NULL when not mapped | Tier 3 |
| 8 | IsManual | IsManual | SP_DailyZeroPnL_Stocks | Dim_Position.MirrorID | CASE WHEN MirrorID = 0 THEN 1 ELSE 0 END | Tier 2 |
| 9 | Leverage | Leverage | Trade.PositionTbl | Leverage | Passthrough via Dim_Position | Tier 1 |
| 10 | IsCFD | IsCFD | SP_DailyZeroPnL_Stocks | Dim_Position.IsSettled | CASE WHEN IsSettled = 1 THEN 0 ELSE 1 END (inverted flag) | Tier 2 |
| 11 | Regulation | Regulation | Dictionary.Regulation | Name | Passthrough via Dim_Regulation; ISNULL(c.Name,'Unknown') | Tier 1 |
| 12 | MifID | MifID | SP_Fact_SnapshotCustomer | MifidCategorizationID | Passthrough via Fact_SnapshotCustomer; aliased MifID | Tier 2 |
| 13 | RealizedCommission | RealizedCommission | SP_DailyZeroPnL_Stocks | Dim_Position commissions | SUM(TotalCommission) across realized positions; aggregation | Tier 2 |
| 14 | RealizedZero | RealizedZero | SP_DailyZeroPnL_Stocks | Dim_Position NetProfit + commissions | SUM(CalculatedZero) WHERE Indicator='Realized' | Tier 2 |
| 15 | ChangeInUnrealizedZero | ChangeInUnrealizedZero | SP_DailyZeroPnL_Stocks | BI_DB_PositionPnL.DailyPnL + commissions | SUM(CalculatedZero) WHERE Indicator='UnRealized' | Tier 2 |
| 16 | TotalZero | TotalZero | SP_DailyZeroPnL_Stocks | Dim_Position + BI_DB_PositionPnL | SUM(CalculatedZero) all indicators; = RealizedZero + ChangeInUnrealizedZero | Tier 2 |
| 17 | NOP | NOP | SP_PositionPnL | BI_DB_PositionPnL.NOP | SUM(NOP) grouped; net open position in USD | Tier 2 |
| 18 | OpenPositions | OpenPositions | SP_DailyZeroPnL_Stocks | BI_DB_PositionPnL.NOP | SUM(NOP * direction): NOP * (IsBuy=1 THEN 1 ELSE -1) | Tier 2 |
| 19 | NOP_Units | NOP_Units | SP_DailyZeroPnL_Stocks | Dim_Position.AmountInUnitsDecimal | SUM(units) for open positions on report date | Tier 2 |
| 20 | VolumeOnOpen | VolumeOnOpen | SP_DailyZeroPnL_Stocks | Dim_Position.Volume | SUM(CASE WHEN OpenDateID=RepDate THEN Volume ELSE 0 END) | Tier 2 |
| 21 | VolumeOnClose | VolumeOnClose | SP_DailyZeroPnL_Stocks | Dim_Position.VolumeOnClose | SUM(CASE WHEN CloseDateID=RepDate THEN VolumeOnClose ELSE 0 END) | Tier 2 |
| 22 | OpenPositionValue | OpenPositionValue | SP_DailyZeroPnL_Stocks | BI_DB_PositionPnL.Amount + PositionPnL | SUM(Amount + PositionPnL) — invested value + unrealized PnL | Tier 2 |
| 23 | UpdateDate | UpdateDate | SP_DailyZeroPnL_Stocks | — | GETDATE() at ETL execution time | Tier 2 |
| 24 | InstrumentName | InstrumentName | Trade.GetInstrument | Name | Passthrough via Dim_Instrument.Name aliased as InstrumentName | Tier 1 |
| 25 | Units | Units | SP_DailyZeroPnL_Stocks | Dim_Position.AmountInUnitsDecimal | SUM(OpenUnits + CloseUnits) per instrument-regulation group | Tier 2 |
| 26 | Currency | Currency | Dictionary.Currency | Abbreviation | Passthrough via Dim_Instrument.SellCurrency; aliased Currency | Tier 1 |

---

*Tier 1: 7 columns | Tier 2: 18 columns | Tier 3: 1 column | Tier 4: 0 columns*
*Upstream wikis used: DWH_dbo/Tables/Dim_Position.md, DWH_dbo/Tables/Dim_Instrument.md, DWH_dbo/Tables/Dim_Regulation.md, DWH_dbo/Tables/Fact_SnapshotCustomer.md, BI_DB_dbo/Tables/BI_DB_PositionPnL.md*

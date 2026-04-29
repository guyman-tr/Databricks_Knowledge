# Column lineage -- BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers

## Source Objects

| Source Object | Schema | Role | Wiki |
|---|---|---|---|
| DWH_dbo.Dim_Position | DWH_dbo | Position attributes (HedgeServerID, Leverage, MirrorID, etc.) | [Dim_Position.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md) |
| BI_DB_dbo.BI_DB_PositionPnL | BI_DB_dbo | Daily open position PnL snapshot (NOP, DailyPnL, OpenPositionValue) | [BI_DB_PositionPnL.md](../../../../../knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_PositionPnL.md) |
| DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | Customer state (MifidCategorizationID, IsValidCustomer, IsCreditReportValidCB, CountryID, etc.) | [Fact_SnapshotCustomer.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md) |
| DWH_dbo.Dim_Range | DWH_dbo | DateRangeID decode for Fact_SnapshotCustomer SCD2 join | [Dim_Range.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Range.md) |
| DWH_dbo.Dim_Instrument | DWH_dbo | Instrument metadata (InstrumentTypeID, Name, InstrumentType) | [Dim_Instrument.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md) |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name lookup | [Dim_Regulation.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Regulation.md) |
| DWH_dbo.Dim_Country | DWH_dbo | Country name lookup | [Dim_Country.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Country.md) |
| DWH_dbo.Dim_PlayerLevel | DWH_dbo | Player level name lookup | [Dim_PlayerLevel.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PlayerLevel.md) |
| DWH_dbo.Dim_GuruStatus | DWH_dbo | Guru status name lookup | [Dim_GuruStatus.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_GuruStatus.md) |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|--------|---------------|---------------|-----------|------|
| 1 | Date | SP parameter | @RepDate | DECLARE @end = @start; report date | Tier 2 |
| 2 | HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | Passthrough | Tier 1 |
| 3 | Copy | DWH_dbo.Dim_Position | MirrorID, OrigParentPositionID | CASE WHEN MirrorID > 0 THEN 1 WHEN OrigParentPositionID > 0 THEN -1 ELSE 0 | Tier 2 |
| 4 | InstrumentID | DWH_dbo.Dim_Position + Dim_Instrument | InstrumentID, InstrumentTypeID | CASE WHEN InstrumentTypeID IN (5,6) THEN 1000 ELSE InstrumentID | Tier 2 |
| 5 | RiskIndex | SP literal | N/A | Empty string placeholder '' | Tier 2 |
| 6 | TreeSize_Units | DWH_dbo.Dim_Position + #TreeSize | AmountInUnitsDecimal / TreeSize_Units | CASE bucket on unit thresholds (Smaller to 2M+) | Tier 2 |
| 7 | TreeSize_USD | BI_DB_dbo.BI_DB_PositionPnL + #TreeSize | NOP / TreeSize_USD | CASE bucket on USD thresholds (Smaller to 1000K+) | Tier 2 |
| 8 | Leverage | DWH_dbo.Dim_Position | Leverage | Passthrough | Tier 1 |
| 9 | RiskGroup | SP literal | N/A | Empty string placeholder '' | Tier 2 |
| 10 | DepositGroup | SP literal | N/A | Empty string placeholder '' | Tier 2 |
| 11 | RealizedCommission | SP computed | FullCommission, FullCommissionOnClose, FullCommissionByUnits | SUM(TotalCommission) across realized + unrealized | Tier 2 |
| 12 | RealizedZero | SP computed | NetProfit, PositionPnL, FullCommissionOnClose, FullCommissionByUnits | SUM(CalculatedZero) WHERE Indicator='Realized' | Tier 2 |
| 13 | ChangeInUnrealizedZero | SP computed | DailyPnL, FullCommissionByUnits | SUM(CalculatedZero) WHERE Indicator='UnRealized' | Tier 2 |
| 14 | TotalZero | SP computed | CalculatedZero | SUM(CalculatedZero) across both indicators | Tier 2 |
| 15 | NOP | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM(NOP) -- net open position | Tier 2 |
| 16 | OpenPositions | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM(NOP * direction) -- signed open position | Tier 2 |
| 17 | Nop_Units | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | SUM(p.AmountInUnitsDecimal) | Tier 2 |
| 18 | VolumeAtOpen | DWH_dbo.Dim_Position | Volume | SUM(CASE WHEN OpenDateID=@RepDateINT THEN Volume ELSE 0) | Tier 2 |
| 19 | VolumeAtClose | DWH_dbo.Dim_Position | VolumeOnClose | SUM(CASE WHEN CloseDateID=@RepDateINT THEN VolumeOnClose ELSE 0) | Tier 2 |
| 20 | UpdateDate | SP computed | N/A | GETDATE() | Tier 3 |
| 21 | IsCFD | DWH_dbo.Dim_Position + BI_DB_PositionPnL | IsSettled (both) | CASE logic reconciling Dim_Position.IsSettled vs PositionPnL.IsSettled | Tier 2 |
| 22 | Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.RegulationID | Tier 1 |
| 23 | MifID | DWH_dbo.Fact_SnapshotCustomer | MifidCategorizationID | Rename: b.MifidCategorizationID AS MifID | Tier 1 |
| 24 | InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | CASE WHEN InstrumentTypeID IN (5,6) THEN 'Stocks/ETF' ELSE InstrumentType | Tier 2 |
| 25 | InstrumentName | DWH_dbo.Dim_Instrument | Name | CASE WHEN InstrumentTypeID IN (5,6) THEN 'Stocks/ETF' ELSE Name | Tier 2 |
| 26 | OpenPositionValue | BI_DB_dbo.BI_DB_PositionPnL | Amount, PositionPnL | SUM(p.Amount + p.PositionPnL) | Tier 2 |
| 27 | Country | DWH_dbo.Dim_Country | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.CountryID | Tier 1 |
| 28 | PlayerLevel | DWH_dbo.Dim_PlayerLevel | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.PlayerLevelID | Tier 1 |
| 29 | GuruStatus | DWH_dbo.Dim_GuruStatus | GuruStatusName | Dim-lookup passthrough via Fact_SnapshotCustomer.GuruStatusID | Tier 1 |
| 30 | Long_OP | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM(NOP * CASE WHEN IsBuy=1 THEN 1 ELSE 0) | Tier 2 |
| 31 | Short_OP | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM(NOP * CASE WHEN IsBuy=0 THEN 1 ELSE 0) | Tier 2 |
| 32 | SettlementType | DWH_dbo.Dim_Position + BI_DB_PositionPnL | IsSettled, SettlementTypeID | CASE: Real if not CFD, else CFD/TRS/CMT by SettlementTypeID | Tier 2 |
| 33 | IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | Passthrough (always 0 -- SP filters WHERE IsValidCustomer=0) | Tier 1 |
| 34 | IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough | Tier 1 |

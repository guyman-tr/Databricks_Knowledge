# Column Lineage — BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers

## Source Objects

| Source Object | Schema | Role | Wiki Path |
|--------------|--------|------|-----------|
| DWH_dbo.Dim_Position | DWH_dbo | Position attributes (HedgeServerID, Leverage, MirrorID, etc.) | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md |
| BI_DB_dbo.BI_DB_PositionPnL | BI_DB_dbo | Daily open-position PnL snapshot (NOP, DailyPnL, Amount, PositionPnL, IsSettled) | knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_PositionPnL.md |
| DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | Customer state (RegulationID, CountryID, PlayerLevelID, GuruStatusID, MifidCategorizationID, IsValidCustomer, IsCreditReportValidCB) | knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md |
| DWH_dbo.Dim_Range | DWH_dbo | SCD2 date range decode for Fact_SnapshotCustomer join | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Range.md |
| DWH_dbo.Dim_Instrument | DWH_dbo | Instrument metadata (InstrumentTypeID, Name, InstrumentType) | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name lookup | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Regulation.md |
| DWH_dbo.Dim_Country | DWH_dbo | Country name lookup | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Country.md |
| DWH_dbo.Dim_PlayerLevel | DWH_dbo | Player level name lookup | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PlayerLevel.md |
| DWH_dbo.Dim_GuruStatus | DWH_dbo | Guru status name lookup | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_GuruStatus.md |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|---------------|---------------|-----------|------|
| 1 | Date | SP parameter | @RepDate | @start parameter cast to DATE | Tier 3 |
| 2 | HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | Passthrough (GROUP BY dimension) | Tier 1 |
| 3 | Copy | DWH_dbo.Dim_Position | MirrorID, OrigParentPositionID | CASE WHEN MirrorID > 0 THEN 1 WHEN OrigParentPositionID > 0 THEN -1 ELSE 0 | Tier 2 |
| 4 | InstrumentID | DWH_dbo.Dim_Position + Dim_Instrument | InstrumentID, InstrumentTypeID | CASE WHEN InstrumentTypeID IN (5,6) THEN 1000 ELSE InstrumentID | Tier 2 |
| 5 | RiskIndex | N/A | N/A | Hardcoded empty string '' | Tier 2 |
| 6 | TreeSize_Units | Computed | AmountInUnitsDecimal / TreeSize aggregation | Bucketed label from tree-level SUM of AmountInUnitsDecimal/NOP_Units | Tier 2 |
| 7 | TreeSize_USD | Computed | OpenPosition / TreeSize aggregation | Bucketed label from tree-level SUM of OpenPosition/OP_Realized | Tier 2 |
| 8 | Leverage | DWH_dbo.Dim_Position | Leverage | Passthrough (GROUP BY dimension) | Tier 1 |
| 9 | RiskGroup | N/A | N/A | Hardcoded empty string '' | Tier 2 |
| 10 | DepositGroup | N/A | N/A | Hardcoded empty string '' | Tier 2 |
| 11 | RealizedCommission | Computed | FullCommission, FullCommissionOnClose, FullCommissionByUnits | SUM(TotalCommission) where TotalCommission = commission on close minus prorated open commission | Tier 2 |
| 12 | RealizedZero | Computed | NetProfit, PositionPnL, FullCommissionOnClose, FullCommissionByUnits | SUM of CalculatedZero for Realized (closed) positions | Tier 2 |
| 13 | ChangeInUnrealizedZero | Computed | DailyPnL, FullCommissionByUnits | SUM of CalculatedZero for UnRealized (open) positions | Tier 2 |
| 14 | TotalZero | Computed | RealizedZero + ChangeInUnrealizedZero | SUM(CalculatedZero) across realized + unrealized | Tier 2 |
| 15 | NOP | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM(NOP) × direction sign | Tier 2 |
| 16 | OpenPositions | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM(NOP × IsBuy direction) — net open position in USD | Tier 2 |
| 17 | Nop_Units | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | SUM(AmountInUnitsDecimal) from PositionPnL | Tier 2 |
| 18 | VolumeAtOpen | DWH_dbo.Dim_Position | Volume | SUM(Volume) where OpenDateID = @RepDateINT, else 0 | Tier 2 |
| 19 | VolumeAtClose | DWH_dbo.Dim_Position | VolumeOnClose | SUM(VolumeOnClose) where CloseDateID = @RepDateINT, else 0 | Tier 2 |
| 20 | UpdateDate | N/A | N/A | GETDATE() at insert time | Tier 3 |
| 21 | IsCFD | DWH_dbo.Dim_Position + BI_DB_dbo.BI_DB_PositionPnL | IsSettled (both) | CASE reconciling Dim_Position.IsSettled vs BI_DB_PositionPnL.IsSettled; 0=Real, 1=CFD | Tier 2 |
| 22 | Regulation | DWH_dbo.Dim_Regulation | Name | ISNULL(c.Name,'Unknown') via Fact_SnapshotCustomer.RegulationID → Dim_Regulation.DWHRegulationID | Tier 1 |
| 23 | MifID | DWH_dbo.Fact_SnapshotCustomer | MifidCategorizationID | Rename: b.MifidCategorizationID AS MifID | Tier 2 |
| 24 | InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType, InstrumentTypeID | CASE WHEN InstrumentTypeID IN (5,6) THEN 'Stocks/ETF' ELSE i.InstrumentType | Tier 2 |
| 25 | InstrumentName | DWH_dbo.Dim_Instrument | Name, InstrumentTypeID | CASE WHEN InstrumentTypeID IN (5,6) THEN 'Stocks/ETF' ELSE i.Name | Tier 2 |
| 26 | OpenPositionValue | BI_DB_dbo.BI_DB_PositionPnL | Amount, PositionPnL | SUM(Amount + PositionPnL) | Tier 2 |
| 27 | Country | DWH_dbo.Dim_Country | Name | dc.Name AS Country via Fact_SnapshotCustomer.CountryID | Tier 1 |
| 28 | PlayerLevel | DWH_dbo.Dim_PlayerLevel | Name | pl.Name AS PlayerLevel via Fact_SnapshotCustomer.PlayerLevelID | Tier 1 |
| 29 | GuruStatus | DWH_dbo.Dim_GuruStatus | GuruStatusName | gs.GuruStatusName AS GuruStatus via Fact_SnapshotCustomer.GuruStatusID | Tier 1 |
| 30 | Long_OP | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM(NOP × CASE WHEN IsBuy=1 THEN 1 ELSE 0) | Tier 2 |
| 31 | Short_OP | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM(NOP × CASE WHEN IsBuy=0 THEN 1 ELSE 0) | Tier 2 |
| 32 | SettlementType | DWH_dbo.Dim_Position + BI_DB_dbo.BI_DB_PositionPnL | IsSettled, SettlementTypeID | CASE: Real if not CFD, else CFD/TRS/CMT based on SettlementTypeID | Tier 2 |
| 33 | IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | Passthrough (always 0 due to WHERE filter) | Tier 2 |
| 34 | IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough | Tier 2 |

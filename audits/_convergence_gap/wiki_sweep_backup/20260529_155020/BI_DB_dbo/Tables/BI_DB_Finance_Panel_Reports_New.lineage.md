# Lineage: BI_DB_dbo.BI_DB_Finance_Panel_Reports_New

**Generated**: 2026-04-22 | **Writer SP**: `BI_DB_dbo.SP_Finance_Panel_Reports_New` | **Schema**: BI_DB_dbo

## ETL Chain

```
DWH_dbo.Dim_Position (OpenDateID = @Date)
DWH_dbo.Fact_CustomerAction (IsSettled_OnOpen, DateID = @Date)
DWH_dbo.Dim_PositionChangeLog (CFD-to-Real change events, OccurredDateID = @Date)
DWH_dbo.Fact_SnapshotCustomer + DWH_dbo.Dim_Range (IsValidCustomer=1, IsCreditReportValidCB=1)
DWH_dbo.Dim_Instrument (InstrumentTypeID=5, SellCurrencyID=666, ISINCode starts 'GB')
DWH_dbo.Dim_Regulation (RegulationName via DWHRegulationID)
DWH_dbo.Fact_CurrencyPriceWithSplit (InstrumentID IN (1,2,666) = EUR/USD, GBP/USD prices)
  |-- SP_Finance_Panel_Reports_New @Date (DELETE WHERE DateID=@DateID + INSERT) ---|
  v
BI_DB_dbo.BI_DB_Finance_Panel_Reports_New
  (UC Target: Not Migrated)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Position_Phase | Literal | — | 'Open_Position' / 'Close_Position' / 'Change_CFD_To_Real' | Tier 2 |
| 2 | DateID | DWH_dbo.Dim_Position | OpenDateID / CloseDateID | Passthrough (YYYYMMDD) | Tier 2 |
| 3 | EOW | DWH_dbo.Dim_Position | OpenOccurred / CloseOccurred | DATEADD Saturday formula | Tier 2 |
| 4 | EOM | DWH_dbo.Dim_Position | OpenOccurred / CloseOccurred | EOMONTH function | Tier 2 |
| 5 | HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | Passthrough; filter IN (121,124,125,126,128,130) | Tier 1 |
| 6 | ISINCountryCode | DWH_dbo.Dim_Instrument | ISINCode | SUBSTRING extraction (first 2-3 chars); always 'GB' | Tier 2 |
| 7 | InstrumentTypeID | DWH_dbo.Dim_Instrument | InstrumentTypeID | Passthrough; always 5 (Stocks) | Tier 2 |
| 8 | InstrumentTypeName | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough; always 'Stocks' | Tier 2 |
| 9 | InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Passthrough | Tier 1 |
| 10 | InstrumentName | DWH_dbo.Dim_Instrument | Name | Passthrough (alias) | Tier 2 |
| 11 | CID | DWH_dbo.Dim_Position | CID | Passthrough | Tier 1 |
| 12 | PositionID | DWH_dbo.Dim_Position | PositionID | Passthrough | Tier 1 |
| 13 | IsSettled_OnOpen | DWH_dbo.Fact_CustomerAction | IsSettled | Filter: ActionTypeID IN (1,2,3,39); always 1 in this table | Tier 2 |
| 14 | IsSettled_OnClose | DWH_dbo.Dim_Position | IsSettled | Passthrough; -1 for Open_Position rows | Tier 2 |
| 15 | Leverage | DWH_dbo.Dim_Position | Leverage | Passthrough; always 1 (UK real stock) | Tier 1 |
| 16 | SellCurrencyID | DWH_dbo.Dim_Instrument | SellCurrencyID | Passthrough; always 666 (GBX) | Tier 1 |
| 17 | SellCurrency | DWH_dbo.Dim_Instrument | SellCurrency | Passthrough; always 'GBX' | Tier 2 |
| 18 | Amount_OnOpen_USD | DWH_dbo.Dim_Position | InitialAmountCents | InitialAmountCents / 100; 0 for Close rows | Tier 2 |
| 19 | Amount_OnOpen_GBP | DWH_dbo.Dim_Position + DWH_dbo.Fact_CurrencyPriceWithSplit | InitialAmountCents / Ask(GBP/USD) | Currency conversion via GBP/USD rate | Tier 2 |
| 20 | Amount_OnOpen_EUR | DWH_dbo.Dim_Position + DWH_dbo.Fact_CurrencyPriceWithSplit | InitialAmountCents / Ask(EUR/USD) | Currency conversion via EUR/USD rate | Tier 2 |
| 21 | Notional_Value | DWH_dbo.Dim_Position | AmountInUnitsDecimal, InitForexRate / EndForexRate | Units × open or close forex rate | Tier 2 |
| 22 | Amount_OnClose_USD | DWH_dbo.Dim_Position | Amount | Passthrough; 0 for Open rows | Tier 2 |
| 23 | Amount_OnClose_GBP | DWH_dbo.Dim_Position + DWH_dbo.Fact_CurrencyPriceWithSplit | Amount / Ask(GBP/USD) | Currency conversion | Tier 2 |
| 24 | Amount_OnClose_EUR | DWH_dbo.Dim_Position + DWH_dbo.Fact_CurrencyPriceWithSplit | Amount / Ask(EUR/USD) | Currency conversion | Tier 2 |
| 25 | RegulationID_OnOpen | DWH_dbo.Dim_Position | RegulationIDOnOpen | Passthrough; -1 for Close rows | Tier 2 |
| 26 | RegulationName_OnOpen | DWH_dbo.Dim_Regulation | Name | JOIN on DWHRegulationID; 'N/A' for Close rows | Tier 2 |
| 27 | RegulationID_OnClose | DWH_dbo.Fact_SnapshotCustomer | RegulationID | Customer's regulation at close date; -1 for Open rows | Tier 2 |
| 28 | RegulationName_OnClose | DWH_dbo.Dim_Regulation | Name | JOIN on DWHRegulationID; 'N/A' for Open rows | Tier 2 |
| 29 | Is_Copy | DWH_dbo.Dim_Position | MirrorID | CASE WHEN MirrorID<>0 THEN 1 ELSE 0 | Tier 2 |
| 30 | Position_Quantity | Literal | — | Hardcoded 1 (always 1 position per row) | Tier 2 |
| 31 | Is_Stamp_Duty | DWH_dbo.Dim_Position + DWH_dbo.Fact_CustomerAction | IsSettled, InstrumentTypeID, SellCurrencyID | CASE logic; always 1 in this table (filter before INSERT) | Tier 2 |
| 32 | Is_MP | DWH_dbo.Dim_Position | MirrorID | CASE WHEN ISNULL(MirrorID,0)=0 THEN 1 ELSE 0 | Tier 2 |
| 33 | UpdateDate | ETL | — | GETDATE() at INSERT time | Tier 2 |
| 34 | DateOccurred | DWH_dbo.Dim_Position | OpenOccurred / CloseOccurred | CAST to date | Tier 2 |
| 35 | ISINCode | DWH_dbo.Dim_Instrument | ISINCode | Passthrough; always GB-prefix (filter) | Tier 2 |
| 36 | Units_OnOpen | DWH_dbo.Dim_Position | InitialUnits | Passthrough; 0 for Close rows | Tier 1 |
| 37 | Units_OnClose | DWH_dbo.Dim_Position | AmountInUnitsDecimal | Passthrough; 0 for Open rows | Tier 1 |
| 38 | Total_Stamp_Duty | DWH_dbo.Dim_Position | Amount_OnOpen_GBP / Amount_OnClose_GBP | CASE: HedgeServerID=126 pre-2021-01-18 → 1%, else 0.5%. Close=0 after 2021-01-18 | Tier 2 |
| 39 | PartialNULLS_Amount_OnOpen_USD | DWH_dbo.Dim_Position | InitialAmountCents, IsPartialCloseChild | CASE WHEN IsPartialCloseChild IS NULL THEN Amount; NULL for Close/Change rows | Tier 2 |
| 40 | PartialNULLS_Amount_OnOpen_GBP | DWH_dbo.Dim_Position + Prices | InitialAmountCents, IsPartialCloseChild | CASE IS NULL → converted to GBP; NULL for Close/Change rows | Tier 2 |
| 41 | PartialZero_Amount_OnOpen_USD | DWH_dbo.Dim_Position | InitialAmountCents, IsPartialCloseChild | CASE WHEN IsPartialCloseChild = 0 THEN Amount; NULL for Close/Change rows | Tier 2 |
| 42 | PartialZero_Amount_OnOpen_GBP | DWH_dbo.Dim_Position + Prices | InitialAmountCents, IsPartialCloseChild | CASE = 0 → converted to GBP; NULL for Close/Change rows | Tier 2 |
| 43 | Notional_Value_GBP | — | — | Ghost column: in DDL but NOT in SP INSERT list → always NULL | Tier 4 |

## Source Objects

| Object | Type | Role |
|--------|------|------|
| DWH_dbo.Dim_Position | Table | Primary source — positions with IsPartialCloseChild≠1 |
| DWH_dbo.Fact_CustomerAction | Table | IsSettled on open (ActionTypeID IN 1,2,3,39) |
| DWH_dbo.Dim_PositionChangeLog | Table | CFD→Real settlement change events (ChangeTypeID=13) |
| DWH_dbo.Fact_SnapshotCustomer | Table | Customer validity + RegulationID at close date |
| DWH_dbo.Dim_Range | Table | SCD date range join for Fact_SnapshotCustomer |
| DWH_dbo.Dim_Instrument | Table | Instrument metadata (type, ISIN, currency) |
| DWH_dbo.Dim_Regulation | Table | Regulation name lookup |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Table | GBP/USD and EUR/USD conversion rates |
| BI_DB_dbo.BI_DB_Finance_Panel_Reports_New | Table | Self-reference: Change_CFD_To_Real deduplication JOIN |

## Key Constraints (from SP)

- **InstrumentTypeID = 5** (Stocks only — hardcoded filter)
- **SellCurrencyID = 666** (GBX — GB pence-quoted stocks only)
- **ISINCode LIKE 'GB%'** (UK-registered instruments only)
- **HedgeServerID IN (121, 124, 125, 126, 128, 130)** (6 specific hedge execution venues)
- **IsValidCustomer = 1** (via Fact_SnapshotCustomer/Dim_Range)
- **IsCreditReportValidCB = 1** (credit bureau valid customers)
- **Is_Stamp_Duty = 1** (only rows subject to UK SDRT are inserted)
- **IsPartialCloseChild ≠ 1** for Open_Position branch (excludes partial-close child positions)

## UC Target

Not Migrated

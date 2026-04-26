# Lineage: BI_DB_dbo.BI_DB_ASIC_GAML_Invested_Amount

**Writer SP**: `SP_ASIC_GAML_Invested_Amount` (Artyom Bogomolsky, 2022-10-25)
**Pattern**: TRUNCATE + INSERT daily (single-date snapshot — always current day)
**UC Target**: `_Not_Migrated`

## ETL Chain

```
DWH_dbo.Dim_Customer (RegulationID=10, VL=3, IsDepositor=1)
  + DWH_dbo.Dim_PlayerLevel (Club name)
  + DWH_dbo.Dim_Country (Country name)
    → #pop (ASIC/GAML customer population)

BI_DB_dbo.BI_DB_PositionPnL (DateID=@date, InstrumentTypeID IN(5,6), IsSettled=1)
  JOIN #pop ON CID=RealCID
  + DWH_dbo.Dim_Instrument (InstrumentType, InstrumentTypeID filter)
    → #final (SUM Invested_Amount, Current_PNL per customer × InstrumentType × AssetType × Copy_IND)

DWH_dbo.Fact_CustomerAction (ActionTypeID IN(1,4,14), DateID>=@Date30)
  JOIN #pop
    → #activity (LogginInd, TradingInd per customer)

TRUNCATE → INSERT BI_DB_ASIC_GAML_Invested_Amount
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|---------------|-----------|------|
| 1 | RealCID | Dim_Customer | RealCID | Direct | Tier 1 — Customer.CustomerStatic |
| 2 | GCID | Dim_Customer | GCID | Direct | Tier 1 — Customer.CustomerStatic |
| 3 | PlayerLevelID | Dim_Customer | PlayerLevelID | Direct | Tier 1 — Customer.CustomerStatic |
| 4 | Club | Dim_PlayerLevel | Name | Rename (Name→Club) | Tier 1 — Dictionary.PlayerLevel |
| 5 | IsValidCustomer | Dim_Customer | IsValidCustomer | Direct | Tier 2 — SP_Dim_Customer (DWH-computed) |
| 6 | CountryID | Dim_Customer | CountryID | Direct | Tier 1 — Customer.CustomerStatic |
| 7 | Country | Dim_Country | Name | Lookup via CountryID | Tier 1 — Dictionary.Country |
| 8 | RegulationID | Dim_Customer | RegulationID | Direct | Tier 1 — BackOffice.Customer |
| 9 | Date_Relevance | SP parameter | @Date | ETL run date parameter | Tier 2 — SP_ASIC_GAML_Invested_Amount |
| 10 | Invested_Amount | BI_DB_PositionPnL | Amount | SUM() per customer × instrument type × copy mode | Tier 2 — SP_ASIC_GAML_Invested_Amount |
| 11 | Current_PNL | BI_DB_PositionPnL | PositionPnL | SUM() per customer × instrument type × copy mode | Tier 2 — SP_ASIC_GAML_Invested_Amount |
| 12 | UpdateDate | SP | GETDATE() | ETL timestamp | Propagation |
| 13 | InstrumentType | Dim_Instrument | InstrumentType | Direct (but filtered to Stocks/ETF only) | Tier 2 — SP_Dim_Instrument |
| 14 | AssetType | Dim_Instrument | InstrumentTypeID | CASE: 5=Stocks, 6=ETF | Tier 2 — SP_ASIC_GAML_Invested_Amount |
| 15 | Copy_IND | BI_DB_PositionPnL | MirrorID | CASE: MirrorID>0→'Copy', else→'Manual' | Tier 2 — SP_ASIC_GAML_Invested_Amount |
| 16 | LogginInd | Fact_CustomerAction | ActionTypeID=14 | MAX(CASE) login flag in last 30 days | Tier 2 — SP_ASIC_GAML_Invested_Amount |
| 17 | TradingInd | Fact_CustomerAction | ActionTypeID IN(1,4) | MAX(CASE) trade flag in last 30 days | Tier 2 — SP_ASIC_GAML_Invested_Amount |

## Tier Summary

- **Tier 1**: 7 (RealCID, GCID, PlayerLevelID, Club, CountryID, Country, RegulationID)
- **Tier 2**: 9 (IsValidCustomer, Date_Relevance, Invested_Amount, Current_PNL, InstrumentType, AssetType, Copy_IND, LogginInd, TradingInd)
- **Propagation**: 1 (UpdateDate)

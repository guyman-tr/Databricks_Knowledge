# Column Lineage — BI_DB_dbo.BI_DB_Reg_UK_Compliance_Professional_OptUp

**Writer SP**: `BI_DB_dbo.SP_W_Tue_Reg_UK_Compliance_Professional_OptUp`
**UC Target**: `_Not_Migrated`
**Generated**: 2026-04-21
**Author**: Nir Weber (2022-03-27) | Updated: Nir Weber (2022-04-07, added Gold to club filter) | Migrated: Slavane (2023-06-07) | DSR-1848

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Tier |
|------------|-------------|---------------|-----------|------|
| Regulation | DWH_dbo.Dim_Regulation | Name | dr.Name via Dim_Customer.DesignatedRegulationID = dr.ID | Tier 2 |
| CID | DWH_dbo.Dim_Customer | RealCID | Direct passthrough | Tier 2 |
| VerificationLevel3Date | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel3Date | CONVERT(date, fd.VerificationLevel3Date) — first date customer reached fully-verified status | Tier 2 |
| CashCredit | BI_DB_dbo.BI_DB_CIDFirstDates | Credit | Passthrough (column renamed Credit→CashCredit); yesterday's credit balance from V_Liabilities | Tier 2 |
| ApproprietnessTest | — | — | Hardcoded empty string '' — placeholder column, never populated | Tier 2 |
| FirstPosOpenDate | BI_DB_dbo.BI_DB_CIDFirstDates | FirstPosOpenDate | CONVERT(date, fd.FirstPosOpenDate) | Tier 2 |
| LastPosOpenDate | BI_DB_dbo.BI_DB_CIDFirstDates | LastPosOpenDate | CONVERT(date, fd.LastPosOpenDate) | Tier 2 |
| LastPositionOpenDateCFD | DWH_dbo.Dim_Position | OpenOccurred | MAX(CONVERT(date, OpenOccurred)) WHERE IsSettled=0 AND MirrorID=0 AND OpenDateID >= @1yearagoid | Tier 2 |
| LastPositionOpenDateRealCrypto | DWH_dbo.Dim_Position | OpenOccurred | MAX(CONVERT(date, OpenOccurred)) WHERE IsSettled=1 AND InstrumentType='Crypto Currencies' AND MirrorID=0 AND OpenDateID >= @1yearagoid | Tier 2 |
| LastPositionOpenDateRealStock | DWH_dbo.Dim_Position | OpenOccurred | MAX(CONVERT(date, OpenOccurred)) WHERE IsSettled=1 AND InstrumentType='Stocks' AND MirrorID=0 AND OpenDateID >= @1yearagoid | Tier 2 |
| Club | BI_DB_dbo.BI_DB_CIDFirstDates | Club | Passthrough from #Clients; eligibility filter requires Gold/Platinum/Platinum Plus/Diamond | Tier 2 |
| Holding | DWH_dbo.Dim_Position + Dim_Instrument | IsSettled, InstrumentType | CASE WHEN IsSettled/InstrumentType: 'Real Stocks', 'Real Crypto', 'Real ETF', 'CFD Stocks', 'CFD Crypto Currencies', 'CFD Indices', 'CFD ETF', 'CFD Commodities', 'CFD Currencies'. NULL = customer has no positions. | Tier 2 |
| OpenedPositions | DWH_dbo.Dim_Position | PositionID | COUNT(DISTINCT PositionID) WHERE OpenDateID >= @1yearagoid AND MirrorID=0 | Tier 2 |
| ClosedPositions | DWH_dbo.Dim_Position | PositionID | COUNT(DISTINCT PositionID) WHERE CloseDateID >= @1yearagoid AND MirrorID=0 | Tier 2 |
| NetProfit | DWH_dbo.Dim_Position | NetProfit | SUM(dp.NetProfit) from closed positions leg (CloseDateID >= @1yearagoid, MirrorID=0) | Tier 2 |
| AVGNotionalAmount | DWH_dbo.Dim_Position | Amount, Leverage | SUM(Amount*Leverage) / SUM(TotalPositions) across UNION ALL of opened+closed positions last 12 months | Tier 2 |
| MTMEquity | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL, Amount | ISNULL(SUM(PositionPnL + Amount), 0) WHERE DateID=@PnLDate (yesterday) AND MirrorID=0, grouped by CID×Holding | Tier 2 |
| Desk | DWH_dbo.Dim_Country | Desk | dc1.Desk from Dim_Country via Dim_Customer.CountryID | Tier 2 |
| Manager | BI_DB_dbo.BI_DB_CIDFirstDates | Manager | Passthrough from BI_DB_CIDFirstDates.Manager (account manager full name) | Tier 2 |
| MifidCategorisation | DWH_dbo.Dim_MifidCategorization | Name | mif.Name via Dim_Customer.MifidCategorizationID = mif.MifidCategorizationID | Tier 2 |
| CountryOfResidence | DWH_dbo.Dim_Country | Name | dc1.Name from Dim_Country via Dim_Customer.CountryID | Tier 2 |
| UpdateDate | ETL metadata | — | GETDATE() at insert — weekly snapshot timestamp | Tier 3 |

## Source Objects

| Source | Role |
|--------|------|
| DWH_dbo.Dim_Customer | Eligibility (DesignatedRegulationID, IsValidCustomer, IsDepositor, CountryID, MifidCategorizationID) |
| DWH_dbo.Dim_Regulation | Regulation name (CySEC, FCA) |
| DWH_dbo.Dim_MifidCategorization | MiFID II category name |
| DWH_dbo.Dim_Country | Country name (CountryOfResidence) and Desk assignment |
| BI_DB_dbo.BI_DB_CIDFirstDates | Club, Manager, VerificationLevel3Date, Credit, FirstPosOpenDate, LastPosOpenDate |
| DWH_dbo.Dim_Position | Position counts (opened/closed 12m), NetProfit, notional, last CFD/crypto/stock open dates |
| DWH_dbo.Dim_Instrument | InstrumentType for Holding derivation |
| BI_DB_dbo.BI_DB_PositionPnL | MTM equity — yesterday's open-position P&L snapshot |

## Eligibility Filter

Only customers satisfying ALL conditions are included:
- DesignatedRegulationID IN (1=CySEC, 2=FCA)
- IsValidCustomer = 1
- IsDepositor = 1
- Club IN ('Gold', 'Platinum', 'Platinum Plus', 'Diamond') from BI_DB_CIDFirstDates

## Holding Derivation

| IsSettled | InstrumentType | Holding |
|-----------|---------------|---------|
| 1 | Stocks | Real Stocks |
| 1 | Crypto Currencies | Real Crypto |
| 1 | ETF | Real ETF |
| 0 | Stocks | CFD Stocks |
| 0 | Crypto Currencies | CFD Crypto Currencies |
| 0 | Indices | CFD Indices |
| 0 | ETF | CFD ETF |
| 0 | Commodities | CFD Commodities |
| 0 | Currencies | CFD Currencies |
| (no match or no positions) | — | NULL |

## ETL Pipeline

```
DWH_dbo.Dim_Customer (CySEC + FCA regulated depositors, Gold+ club only)
  + DWH_dbo.Dim_Regulation, Dim_MifidCategorization, Dim_Country
  + BI_DB_dbo.BI_DB_CIDFirstDates (Club, Manager, dates, Credit)
    → #Clients (400,591 eligible CIDs)
DWH_dbo.Dim_Position + Dim_Instrument (non-mirror, last 12 months, opened+closed UNION ALL)
    → #Positions (OpenedPositions, ClosedPositions, NetProfit, AVGNotionalAmount per CID×Holding)
BI_DB_dbo.BI_DB_CIDFirstDates (VerificationLevel3Date, FirstPosOpenDate, LastPosOpenDate, Credit)
    → #Tests
BI_DB_dbo.BI_DB_PositionPnL (yesterday's snapshot, non-mirror)
    → #Equity (MTMEquity per CID×Holding)
DWH_dbo.Dim_Position (non-mirror, last 12 months)
    → #LastPos (LastPositionOpenDateCFD, LastPositionOpenDateRealCrypto, LastPositionOpenDateRealStock)
    |-- SP_W_Tue_Reg_UK_Compliance_Professional_OptUp (Weekly/Tuesday, Priority 21, SB_Daily) ---|
    v                                                                        [TRUNCATE + INSERT]
BI_DB_dbo.BI_DB_Reg_UK_Compliance_Professional_OptUp
  (908,698 rows | 400,591 distinct CIDs | latest snapshot 2026-04-07 | ROUND_ROBIN HEAP)
    |-- UC: _Not_Migrated
```

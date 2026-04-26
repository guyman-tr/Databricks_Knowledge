# Lineage: BI_DB_dbo.BI_DB_AffiliateFTDsAndURLS

Generated: 2026-04-21 | Writer SP: SP_AffiliateFTDsAndURLS | Batch 13 #3

## ETL Chain

```
DWH_dbo.Dim_Affiliate (AffiliateID, TradingAccount_RealCID, WebSiteURL, SubChannelID)
  |-- JOIN BI_DB_dbo.BI_DB_CIDFirstDates fd  (SerialID = AffiliateID → client events)
  |        WHERE (registered=@Date OR FirstDepositDate=@Date)
  |        AND Channel = 'Affiliate'
  |-- JOIN BI_DB_dbo.BI_DB_CIDFirstDates fd1 (fd1.CID = da.TradingAccount_RealCID) [unused join]
  |
  |  GROUP BY AffiliateID × SubChannel × WebSiteURL × FTD_date × Reg_date
  |  COUNT DISTINCT CID WHERE DesignatedRegulationID/Country/date = @Date (per regulation)
  |
  v [SP_AffiliateFTDsAndURLS @Date — Daily, SB_Daily, Priority 20]
  v [DELETE WHERE FirstDepositDate=@Date + DELETE WHERE Registered=@Date + INSERT]
  v
BI_DB_dbo.BI_DB_AffiliateFTDsAndURLS (371,656 rows)
  |
  v [UC Target: _Not_Migrated]
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | AffiliateID | DWH_dbo.Dim_Affiliate | AffiliateID | Passthrough GROUP BY key | Tier 1 |
| 2 | SubChannel | BI_DB_CIDFirstDates | SubChannel | Passthrough GROUP BY dimension | Tier 2 |
| 3 | CID | DWH_dbo.Dim_Affiliate | TradingAccount_RealCID | Passthrough GROUP BY key — affiliate's own eToro CID | Tier 1 |
| 4 | WebSiteURL | DWH_dbo.Dim_Affiliate | WebSiteURL | Passthrough GROUP BY dimension | Tier 1 |
| 5 | FTDYear | BI_DB_CIDFirstDates | FirstDepositDate | YEAR(FirstDepositDate) | Tier 2 |
| 6 | FTDMonth | BI_DB_CIDFirstDates | FirstDepositDate | MONTH(FirstDepositDate) | Tier 2 |
| 7 | FTDYearMonth | BI_DB_CIDFirstDates | FirstDepositDate | CONVERT(VARCHAR(6), FirstDepositDate, 112) | Tier 2 |
| 8 | FTDs_EU | BI_DB_CIDFirstDates | CID, DesignatedRegulationID | COUNT DISTINCT CID WHERE RegID IN (1) AND FTD date=@Date | Tier 2 |
| 9 | FTDs_ASIC | BI_DB_CIDFirstDates | CID, DesignatedRegulationID | COUNT DISTINCT CID WHERE RegID IN (4,10) AND FTD date=@Date | Tier 2 |
| 10 | FTDs_US | BI_DB_CIDFirstDates | CID, DesignatedRegulationID | COUNT DISTINCT CID WHERE RegID IN (6,7,8) AND FTD date=@Date | Tier 2 |
| 11 | FTDs_FCA | BI_DB_CIDFirstDates | CID, DesignatedRegulationID | COUNT DISTINCT CID WHERE RegID IN (2) AND FTD date=@Date | Tier 2 |
| 12 | FTDs_Total | BI_DB_CIDFirstDates | CID, FirstDepositDate | COUNT DISTINCT CID WHERE FTD date=@Date (ELSE 0 — see review notes) | Tier 2 |
| 13 | Registration_US | BI_DB_CIDFirstDates | CID, DesignatedRegulationID | COUNT DISTINCT CID WHERE RegID IN (6,7,8) AND Reg date=@Date | Tier 2 |
| 14 | Registration_ASIC | BI_DB_CIDFirstDates | CID, DesignatedRegulationID | COUNT DISTINCT CID WHERE RegID IN (4,10) AND Reg date=@Date | Tier 2 |
| 15 | Registration_EU | BI_DB_CIDFirstDates | CID, DesignatedRegulationID | COUNT DISTINCT CID WHERE RegID IN (1) AND Reg date=@Date | Tier 2 |
| 16 | Registration_FCA | BI_DB_CIDFirstDates | CID, DesignatedRegulationID | COUNT DISTINCT CID WHERE RegID IN (2) AND Reg date=@Date | Tier 2 |
| 17 | UpdateDate | ETL metadata | GETDATE() | Set at INSERT time | Tier 5 |
| 18 | FTDs_Spain | BI_DB_CIDFirstDates | CID, Country | COUNT DISTINCT CID WHERE Country='Spain' AND FTD date=@Date | Tier 2 |
| 19 | FTDs_France | BI_DB_CIDFirstDates | CID, Country | COUNT DISTINCT CID WHERE Country='France' AND FTD date=@Date | Tier 2 |
| 20 | RegisteredYear | BI_DB_CIDFirstDates | registered | YEAR(registered) | Tier 2 |
| 21 | RegisteredMonth | BI_DB_CIDFirstDates | registered | MONTH(registered) | Tier 2 |
| 22 | RegisteredYearMonth | BI_DB_CIDFirstDates | registered | CONVERT(VARCHAR(6), registered, 112) | Tier 2 |
| 23 | FTDs_FSA_Seychelles | BI_DB_CIDFirstDates | CID, DesignatedRegulationID | COUNT DISTINCT CID WHERE RegID IN (9) AND FTD date=@Date | Tier 2 |
| 24 | Registration_FSRA | BI_DB_CIDFirstDates | CID, DesignatedRegulationID | COUNT DISTINCT CID WHERE RegID IN (11) AND Reg date=@Date | Tier 2 |
| 25 | FTDs_FSRA | BI_DB_CIDFirstDates | CID, DesignatedRegulationID | COUNT DISTINCT CID WHERE RegID IN (11) AND FTD date=@Date | Tier 2 |
| 26 | Registered | BI_DB_CIDFirstDates | registered | CAST(registered AS DATE) GROUP BY dimension | Tier 2 |
| 27 | FirstDepositDate | BI_DB_CIDFirstDates | FirstDepositDate | CAST(FirstDepositDate AS DATE) GROUP BY dimension | Tier 2 |

**Note**: DDL lists 28 columns. INSERT covers all 28 columns. FTDs_FSA_Seychelles and FTDs_FSRA positions are swapped between INSERT column list (lines 128–145) and SELECT list (lines 149–178) — values may be transposed for these two columns.

## Source Objects

| Object | Schema | Role |
|--------|--------|------|
| Dim_Affiliate | DWH_dbo | AffiliateID, TradingAccount_RealCID (CID), WebSiteURL, SubChannelID |
| BI_DB_CIDFirstDates | BI_DB_dbo | Client event data: registered, FirstDepositDate, DesignatedRegulationID, Country, SubChannel, Channel |

## UC Lineage

UC Target: `_Not_Migrated` — no Unity Catalog counterpart.

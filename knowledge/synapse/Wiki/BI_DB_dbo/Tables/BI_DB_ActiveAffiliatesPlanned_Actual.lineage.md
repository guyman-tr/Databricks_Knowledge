# Lineage: BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned_Actual

Generated: 2026-04-21 | Writer SP: SP_M_Active_Affiliate_Monthly

## ETL Chain

```
BI_DB_dbo.BI_DB_CIDFirstDates (registered, SerialID, FirstDepositDate, Region, NewMarketingRegion)
  |-- JOIN DWH_dbo.Dim_Affiliate (SerialID = AffiliateID)
  |-- JOIN DWH_dbo.Dim_Channel (SubChannelID → filter Channel IN ('Affiliate','Introducing Agents'))
  |-- JOIN DWH_dbo.Dim_Country (Region → Desk / MarketingRegionManualName → Desk)
  |
  |  UNION [Branch 1 — Desk-level]
  |    LEFT JOIN BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned (Planned targets)
  |
  |  UNION [Branch 2 — NewMarketingRegion-level, added 2021-07]
  |    (Planned = NULL)
  |
  |-- [SP_M_Active_Affiliate_Monthly @date — Monthly, SB_Daily, Priority 20]
  |-- [DELETE WHERE Date = @StartDate + UNION INSERT]
  v
BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned_Actual (2,335 rows)
  |
  v [UC Target: _Not_Migrated]
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Desk | DWH_dbo.Dim_Country | Desk | Passthrough GROUP BY dimension | Tier 1 |
| 2 | Date | SP parameter | @date | DATEADD(MONTH,-1, first-day-of-next-month) = previous month | Tier 2 |
| 3 | YearMonth | SP parameter | @StartDate | CONVERT(VARCHAR(7), @StartDate, 126) | Tier 2 |
| 4 | NewAffWithRegistretActual | BI_DB_CIDFirstDates | registered | COUNT DISTINCT first-reg affiliates in month | Tier 2 |
| 5 | NewAffWithFTDActual | BI_DB_CIDFirstDates | FirstDepositDate | COUNT DISTINCT first-FTD affiliates in month | Tier 2 |
| 6 | TotalActiveAffRegistretActual | BI_DB_CIDFirstDates | registered | COUNT DISTINCT affiliates with ≥1 reg | Tier 2 |
| 7 | TotalActiveAffFTDActual | BI_DB_CIDFirstDates | FirstDepositDate | COUNT DISTINCT affiliates with ≥1 FTD | Tier 2 |
| 8 | TotalRegistretActual | BI_DB_CIDFirstDates | registered | SUM(REGs) | Tier 2 |
| 9 | TotalFTDsActual | BI_DB_CIDFirstDates | FirstDepositDate | SUM(FTDs) | Tier 2 |
| 10 | NewAffWithFTDPlaaned | BI_DB_ActiveAffiliatesPlanned | NewAffWithFTD | LEFT JOIN planned target — NULL for NMR rows | Tier 2 |
| 11 | TotalActiveAffPlaaned | BI_DB_ActiveAffiliatesPlanned | TotalActiveAff | LEFT JOIN planned target — NULL for NMR rows | Tier 2 |
| 12 | ChurnPlaaned | BI_DB_ActiveAffiliatesPlanned | Churn | LEFT JOIN planned churn rate — NULL for NMR rows | Tier 2 |
| 13 | TotalFTDsPlaaned | BI_DB_ActiveAffiliatesPlanned | TotalFTDs | LEFT JOIN planned target — NULL for NMR rows | Tier 2 |
| 14 | UpdateDate | ETL metadata | GETDATE() | Set at INSERT time | Tier 5 |
| 15 | Indicator | Hardcoded | 'Desk' / 'NewMarketingRegion' | Row type discriminator; NULL in pre-2021 rows | Tier 2 |
| 16 | NewMarketingRegion | BI_DB_CIDFirstDates | NewMarketingRegion | Passthrough for NMR rows; NULL for Desk rows | Tier 2 |

## Source Objects

| Object | Schema | Role |
|--------|--------|------|
| BI_DB_CIDFirstDates | BI_DB_dbo | Primary source — registration/FTD dates, AffiliateID, NewMarketingRegion |
| Dim_Affiliate | DWH_dbo | Dimension — AffiliatesGroupsName, SubChannelID |
| Dim_Channel | DWH_dbo | Filter — Channel IN ('Affiliate', 'Introducing Agents') |
| Dim_Country | DWH_dbo | Dimension — Desk, MarketingRegionManualName |
| BI_DB_ActiveAffiliatesPlanned | BI_DB_dbo | Planned targets — NewAffWithFTD, TotalActiveAff, Churn, TotalFTDs |

## UC Lineage

UC Target: `_Not_Migrated` — no Unity Catalog counterpart.

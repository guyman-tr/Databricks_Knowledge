# Lineage: BI_DB_dbo.BI_DB_ActiveAffActualMonthly_Region_GroupAffName

Generated: 2026-04-21 | Writer SP: SP_M_Active_Aff_Monthly_Region_GroupAff

## ETL Chain

```
BI_DB_dbo.BI_DB_CIDFirstDates (registered, SerialID, FirstDepositDate, FirstDepositAmount, Region)
  |-- JOIN DWH_dbo.Dim_Affiliate (SerialID = AffiliateID → AffiliatesGroupsName)
  |-- JOIN DWH_dbo.Dim_Channel (SubChannelID → filter Channel IN ('Affiliate','Introducing Agents'))
  |-- JOIN DWH_dbo.Dim_Country (Region → Desk)
  |
  v [SP_M_Active_Aff_Monthly_Region_GroupAff — Monthly, DELETE+INSERT per month]
  v
BI_DB_dbo.BI_DB_ActiveAffActualMonthly_Region_GroupAffName (55,724 rows)
  |
  v [UC Target: _Not_Migrated]
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Date | SP parameter | @date → DATEADD(MONTH,0,...) | First day of target month | Tier 2 |
| 2 | YearMonth | CIDFirstDates.registered / FirstDepositDate | CONVERT(VARCHAR(7), date, 126) | Year-month string via FULL OUTER JOIN ISNULL(Reg,FTD) | Tier 2 |
| 3 | Desk | DWH_dbo.Dim_Country | Desk | Passthrough GROUP BY dimension via Region join | Tier 1 |
| 4 | Region | DWH_dbo.Dim_Country / BI_DB_CIDFirstDates | Region | Passthrough GROUP BY dimension | Tier 1 |
| 5 | AffiliatesGroupsName | DWH_dbo.Dim_Affiliate | AffiliatesGroupsName | Passthrough GROUP BY dimension | Tier 1 |
| 6 | NewAffWithRegistretActual | BI_DB_CIDFirstDates | registered | COUNT(DISTINCT AffiliateID) with first reg in month filter | Tier 2 |
| 7 | NewAffWithFTDActual | BI_DB_CIDFirstDates | FirstDepositDate | COUNT(DISTINCT AffiliateID) with first FTD in month filter | Tier 2 |
| 8 | TotalActiveAffRegistretActual | BI_DB_CIDFirstDates | registered | COUNT(DISTINCT AffiliateID WHERE REGs>0) | Tier 2 |
| 9 | TotalActiveAffFTDActual | BI_DB_CIDFirstDates | FirstDepositDate | COUNT(DISTINCT AffiliateID WHERE FTD>0) | Tier 2 |
| 10 | TotalRegistretActual | BI_DB_CIDFirstDates | registered | SUM(REGs) — total registrations | Tier 2 |
| 11 | TotalFTDsActual | BI_DB_CIDFirstDates | FirstDepositDate | SUM(FTDs) — total First Time Deposits | Tier 2 |
| 12 | Amount_FTDs | BI_DB_CIDFirstDates | FirstDepositAmount | SUM(FTD_Amount) — total deposit USD | Tier 2 |
| 13 | UpdateDate | ETL metadata | GETDATE() | Set at INSERT time | Tier 5 |

## Source Objects

| Object | Schema | Role |
|--------|--------|------|
| BI_DB_CIDFirstDates | BI_DB_dbo | Primary source — registration/FTD dates, amounts, AffiliateID |
| Dim_Affiliate | DWH_dbo | Dimension — AffiliatesGroupsName, SubChannelID |
| Dim_Channel | DWH_dbo | Filter — Channel IN ('Affiliate', 'Introducing Agents') |
| Dim_Country | DWH_dbo | Dimension — Region, Desk mapping |

## UC Lineage

UC Target: `_Not_Migrated` — no Unity Catalog counterpart for this table.

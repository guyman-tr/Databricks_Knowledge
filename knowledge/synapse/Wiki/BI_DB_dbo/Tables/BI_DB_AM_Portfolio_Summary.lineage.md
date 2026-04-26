# Lineage: BI_DB_dbo.BI_DB_AM_Portfolio_Summary

**Writer SP**: `SP_AM_Portfolio_Summary` (Author: Amir Gurewitz, 2018-03-18; last updated 2024-07-01 by Ofir Chloe Gal)
**Pattern**: DELETE+INSERT days 1–7 of month; daily UPDATE throughout month
**UC Target**: `_Not_Migrated`

## ETL Chain

```
DWH_dbo.Dim_Manager (IsActive=1, SFManagerID IS NOT NULL)
  → #AM (active account managers list)

IF day 1–7 of month:
  DWH_dbo.Fact_SnapshotCustomer (IsValidCustomer=1, @ddint BETWEEN dr.FromDateID AND dr.ToDateID)
    JOIN DWH_dbo.Dim_Range ON DateRangeID
    JOIN #AM ON ManagerID = AccountManagerID
      → COUNT(DISTINCT RealCID) per manager = PortfolioSOM
      → Initial skeleton row: all financial + contact metrics set to 0
  DELETE WHERE StartOfMonth = @startofmonth + INSERT skeleton rows

#AM EXCEPT BI_DB_AM_Portfolio_Summary (this month's existing managers)
  → #newmanagers (managers added after 7th)
  DWH_dbo.Fact_SnapshotCustomer JOIN #newmanagers
  → INSERT skeleton for late-added managers (any day of month)

Every day (UPDATE):
  BI_DB_AM_Portfolio_Summary (StartOfMonth = current month)
    LEFT JOIN BI_DB_NewBonusReport ON ManagerID, DateID in [startofmonth, startNextmonth)
      → #netdeposits (TotalDeposit, TotalCO, TotalContactDeposit)

  BI_DB_AM_Portfolio_Summary
    LEFT JOIN BI_DB_UsageTracking_SF ON CreatedByManagerID, date in [startofmonth, startNextmonth)
    GROUP BY ActionName → #tempcontacts (Actions + UniqueActions per ActionName per manager)
    Filtered ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c')
      → #tempcontactSuccess (UniqueContactSuccess per manager)
    All actions → #UniqueContactAttempts (UniqueContactAttempts = any action)
    Pivot all 4 ActionName values → #contacts (Outbound_Email, Completed_Email,
      Outbound_Phonecall, Completed_Phonecall + Unique_ variants; plus UniqueContactAttempts,
      UniqueContactSuccess)

  BI_DB_AM_Portfolio_Summary
    LEFT JOIN BI_DB_UsageTracking_SF (ActionName IN ('Contacted__c','Phone_Call_Succeed__c'))
    GROUP BY manager × date → SUM(DayInWork) = ActiveDays per manager
      → #DaysCount

  BI_DB_AM_Portfolio_Summary
    LEFT JOIN DWH_dbo.Dim_Customer ON AccountManagerID, IsValidCustomer=1
    COUNT(RealCID) = CurrentPortfolio → #currentPortfolio

  UPDATE BI_DB_AM_Portfolio_Summary SET all metrics from above temp tables
  TotalMoneyInCF=0, TotalMoneyOutCF=0 (hardcoded — CopyFund section commented out)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | StartOfMonth | SP param | @dd | DATEFROMPARTS(YEAR(@dd), MONTH(@dd), 1) — first day of run month | T2 — SP param |
| 2 | Manager | DWH_dbo.Dim_Manager | FirstName, LastName | FirstName+' '+LastName concatenation | T2 — SP_AM_Portfolio_Summary |
| 3 | AccountManagerID | DWH_dbo.Dim_Manager | ManagerID | Direct (= Fact_SnapshotCustomer.AccountManagerID) | T2 — SP_AM_Portfolio_Summary |
| 4 | PortfolioSOM | DWH_dbo.Fact_SnapshotCustomer | RealCID | COUNT(DISTINCT RealCID) WHERE IsValidCustomer=1 at @startofmonth snapshot | T2 — SP_AM_Portfolio_Summary |
| 5 | TotalDeposit | BI_DB_dbo.BI_DB_NewBonusReport | TotalDepositAmount | ISNULL(SUM(TotalDepositAmount),0) MTD for manager's clients | T2 — SP_AM_Portfolio_Summary |
| 6 | TotalContactDeposit | BI_DB_dbo.BI_DB_NewBonusReport | TotalDepositAmount, IsContacted | ISNULL(SUM(CASE WHEN IsContacted=1 THEN TotalDepositAmount ELSE 0 END),0) — deposits from contacted clients only | T2 — SP_AM_Portfolio_Summary |
| 7 | TotalCO | BI_DB_dbo.BI_DB_NewBonusReport | TotalCoAmount | ISNULL(SUM(TotalCoAmount),0) MTD — total cashout for manager's clients | T2 — SP_AM_Portfolio_Summary |
| 8 | TotalMoneyInCF | SP | — | Hardcoded 0; CopyFund JOIN section commented out — dead column | Propagation — dead column |
| 9 | TotalMoneyOutCF | SP | — | Hardcoded 0; CopyFund JOIN section commented out — dead column | Propagation — dead column |
| 10 | Outbound_Email | BI_DB_dbo.BI_DB_UsageTracking_SF | ID, ActionName | COUNT(ID) WHERE ActionName='Outbound_Email__c' per manager MTD | T2 — SP_AM_Portfolio_Summary |
| 11 | Unique_Outbound_Email | BI_DB_dbo.BI_DB_UsageTracking_SF | CID, ActionName | COUNT(DISTINCT CID) WHERE ActionName='Outbound_Email__c' per manager MTD | T2 — SP_AM_Portfolio_Summary |
| 12 | Completed_Email | BI_DB_dbo.BI_DB_UsageTracking_SF | ID, ActionName | COUNT(ID) WHERE ActionName='Completed_Contact_Email__c' per manager MTD | T2 — SP_AM_Portfolio_Summary |
| 13 | Unique_Completed_Email | BI_DB_dbo.BI_DB_UsageTracking_SF | CID, ActionName | COUNT(DISTINCT CID) WHERE ActionName='Completed_Contact_Email__c' per manager MTD | T2 — SP_AM_Portfolio_Summary |
| 14 | Outbound_Phonecall | BI_DB_dbo.BI_DB_UsageTracking_SF | ID, ActionName | COUNT(ID) WHERE ActionName='Contacted__c' per manager MTD | T2 — SP_AM_Portfolio_Summary |
| 15 | Unique_Outbound_Phonecall | BI_DB_dbo.BI_DB_UsageTracking_SF | CID, ActionName | COUNT(DISTINCT CID) WHERE ActionName='Contacted__c' per manager MTD | T2 — SP_AM_Portfolio_Summary |
| 16 | Completed_Phonecall | BI_DB_dbo.BI_DB_UsageTracking_SF | ID, ActionName | COUNT(ID) WHERE ActionName='Phone_Call_Succeed__c' per manager MTD | T2 — SP_AM_Portfolio_Summary |
| 17 | Unique_Completed_Phonecall | BI_DB_dbo.BI_DB_UsageTracking_SF | CID, ActionName | COUNT(DISTINCT CID) WHERE ActionName='Phone_Call_Succeed__c' per manager MTD | T2 — SP_AM_Portfolio_Summary |
| 18 | UniqueContactAttempts | BI_DB_dbo.BI_DB_UsageTracking_SF | CID | COUNT(DISTINCT CID) with any contact action per manager MTD | T2 — SP_AM_Portfolio_Summary |
| 19 | UniqueContactSuccess | BI_DB_dbo.BI_DB_UsageTracking_SF | CID, ActionName | COUNT(DISTINCT CID WHERE ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c')) per manager MTD | T2 — SP_AM_Portfolio_Summary |
| 20 | ActiveDays | BI_DB_dbo.BI_DB_UsageTracking_SF | CreatedDate_SF, ActionName, CID | SUM of distinct calendar days WHERE ActionName IN ('Contacted__c','Phone_Call_Succeed__c') AND CID IS NOT NULL | T2 — SP_AM_Portfolio_Summary |
| 21 | CurrentPortfolio | DWH_dbo.Dim_Customer | RealCID | COUNT(RealCID) WHERE IsValidCustomer=1 AND AccountManagerID matches — daily live snapshot | T2 — SP_AM_Portfolio_Summary |
| 22 | UpdateDate | SP | GETDATE() | Timestamp of latest UPDATE execution | Propagation |

## Tier Summary

- **Tier 2**: 20 (StartOfMonth, Manager, AccountManagerID, PortfolioSOM, TotalDeposit, TotalContactDeposit, TotalCO, TotalMoneyInCF, TotalMoneyOutCF, Outbound_Email, Unique_Outbound_Email, Completed_Email, Unique_Completed_Email, Outbound_Phonecall, Unique_Outbound_Phonecall, Completed_Phonecall, Unique_Completed_Phonecall, UniqueContactAttempts, UniqueContactSuccess, ActiveDays, CurrentPortfolio)
- **Propagation**: 2 (TotalMoneyInCF, TotalMoneyOutCF as dead columns + UpdateDate — 3 total)

> Note: TotalMoneyInCF and TotalMoneyOutCF are listed under Tier 2 in the column table but classified as dead Propagation columns here; treat as Propagation for quality scoring.

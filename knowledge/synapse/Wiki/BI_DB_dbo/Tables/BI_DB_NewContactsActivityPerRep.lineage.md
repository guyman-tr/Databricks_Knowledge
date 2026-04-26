# BI_DB_dbo.BI_DB_NewContactsActivityPerRep — Column Lineage

## Writer SP

`BI_DB_dbo.SP_NewContactActivityPerRep` (@dd DATE)
Author: Amir Gurewitz, 2018-05-27. Changed: Boris (2018-09-12), Tom Boksenbojm (2023-06-25 migration).

## Load Pattern

Daily DELETE+INSERT by Date = @dd.

## Source Objects

| # | Source Object | Alias | Role |
|---|---------------|-------|------|
| 1 | DWH_dbo.Dim_Manager | dm | Manager list (excluding IDs 0,342,787,283,887) |
| 2 | BI_DB_dbo.BI_DB_UsageTracking_SF | sf | Salesforce activity actions by manager |
| 3 | BI_DB_dbo.BI_DB_CIDFirstDates | fd | FTD population (FirstDepositDate = @dd) |
| 4 | DWH_dbo.Dim_Country | dd | Desk for FTD population |
| 5 | BI_DB_dbo.BI_DB_NewBonusReport | br | Contacted depositors and deposit amounts |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform |
|---|----------------|-------------|---------------|-----------|
| 1 | Date | Parameter | @dd | Constant date |
| 2 | ManagerID | Dim_Manager | ManagerID | Passthrough |
| 3 | Manager | Dim_Manager | FirstName + ' ' + LastName | Concatenation |
| 4 | PhoneCalls | BI_DB_UsageTracking_SF | ActionName='Phone_Call_Succeed__c' | SUM(CASE) per manager |
| 5 | UnsuccessfullPhoneCalls | BI_DB_UsageTracking_SF | ActionName='Contacted__c' | SUM(CASE) per manager |
| 6 | InBoundMail | BI_DB_UsageTracking_SF | ActionName='Completed_Contact_Email__c' | SUM(CASE) per manager |
| 7 | OutBoundMail | BI_DB_UsageTracking_SF | ActionName='Outbound_Email__c' | SUM(CASE) per manager |
| 8 | CountDepositors | #deposits | COUNT(RealCID) | Count of contacted depositors |
| 9 | TotalContactedDepositAmount | BI_DB_NewBonusReport | TotalDepositAmount | SUM per contacted manager |
| 10 | TotalContactedFTDA | #ContactFTD | FirstDepositAmount | SUM of contacted FTD amounts |
| 11 | UpdateDate | ETL | GETDATE() | ETL metadata |

## Production Source Chain

```
DWH_dbo.Dim_Manager + BI_DB_dbo.BI_DB_UsageTracking_SF (Salesforce activity)
BI_DB_dbo.BI_DB_CIDFirstDates (FTD population)
BI_DB_dbo.BI_DB_NewBonusReport (deposit amounts)
  |-- SP_NewContactActivityPerRep @dd ---|
  v
BI_DB_dbo.BI_DB_NewContactsActivityPerRep (319K rows)
  UC Target: _Not_Migrated
```

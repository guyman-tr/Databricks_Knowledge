# BI_DB_dbo.BI_DB_AML_BI_Alerts_New_Master_SubAccount — Column Lineage

**Schema**: BI_DB_dbo | **Writer SP**: SP_AML_BI_Alerts_New_Master_SubAccount | **Generated**: 2026-04-22

## Pipeline Summary

```
BI_DB_dbo.External_etoro_BackOffice_Customer (master/sub account relationships)
DWH_dbo.Fact_SnapshotCustomer + Dim_Range (customer snapshot at run date)
DWH_dbo.Dim_Regulation, Dim_Country, Dim_PlayerStatus,
        Dim_PlayerLevel, Dim_AccountType, Dim_Customer, Dim_EvMatchStatus
DWH_dbo.Dim_RiskClassification (risk label — NOT External_RiskClassification)
DWH_dbo.Fact_BillingDeposit (lifetime + calendar-year deposit aggregation)
DWH_dbo.Fact_CustomerAction (deposit event detection on @Date)
BI_DB_dbo.BI_DB_KYC_Panel (Q10/Q11 income brackets; Q15 source-of-income)
BI_DB_dbo.BI_DB_AML_BI_Alerts_New_Master_SubAccount (self-reference for Total_Alerts counter)
  |-- SP_AML_BI_Alerts_New_Master_SubAccount @Date ---|
     DELETE WHERE AlertDate=@Date + INSERT (first-time only, except MA008)
  v
BI_DB_dbo.BI_DB_AML_BI_Alerts_New_Master_SubAccount (accumulating MA alert log)
  UC Target: Not Migrated
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Passthrough — RealCID of the sub-account or master account triggering the alert | T1 |
| 2 | MasterAccountCID | BI_DB_dbo.External_etoro_BackOffice_Customer | MasterAccountCID | The CID of the master account in the master/sub account relationship; equals CID when the triggering customer is the master account itself | T2 |
| 3 | AlertID | ETL (NEWID()) | — | Synthetic UUID generated at INSERT time; not a stable identifier | T2 |
| 4 | AlertCategory | SP_AML_BI_Alerts_New_Master_SubAccount | — | Always 'OnBoarding' (with trailing space in some branches) — all MA alerts are OnBoarding category | T2 |
| 5 | AlertType | SP_AML_BI_Alerts_New_Master_SubAccount | — | Hardcoded MA-series code + description string: MA001–MA009, MA011, MA013, MA014 (12 distinct codes; MA010/MA012 gaps are intentional) | T2 |
| 6 | Total_Alerts_of_TheCategory | BI_DB_AML_BI_Alerts_New_Master_SubAccount (self) | — | COUNT(existing rows WHERE MasterAccountCID=this.MasterAccountCID AND AlertType=this.AlertType) + 1; counts prior firings at master account level. SP only inserts rows where this value = 1 (first-time only), except MA008 which fires on every additional $1M milestone | T2 |
| 7 | AlertDate | ETL (@Date param) | — | = @Date parameter passed to SP; the date for which alerts were generated | T2 |
| 8 | Regulation | DWH_dbo.Dim_Regulation | Name | Customer's regulation name at SP run time via Fact_SnapshotCustomer JOIN Dim_Regulation | T2 |
| 9 | Country | DWH_dbo.Dim_Country | Name | Customer's KYC country name at SP run time via Fact_SnapshotCustomer JOIN Dim_Country | T2 |
| 10 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Customer's player status name at SP run time (excludes StatusID 2 and 4) | T2 |
| 11 | Club | DWH_dbo.Dim_PlayerLevel | Name | Customer's club level name at SP run time | T2 |
| 12 | AccountType | DWH_dbo.Dim_AccountType | Name | Customer's account type name at SP run time | T2 |
| 13 | RiskScoreName | DWH_dbo.Dim_RiskClassification | RiskClassificationName | Most recent risk classification label from Fact_SnapshotCustomer change history (NOT from External_RiskClassification unlike the base alerts table) | T2 |
| 14 | HasWallet | DWH_dbo.Dim_Customer | HasWallet | Passthrough — current snapshot at SP run time. 1 if customer has active eToro Money wallet | T1 |
| 15 | UpdateDate | ETL (GETDATE()) | — | GETDATE() at INSERT time — ETL metadata blacklist column | Blacklist |

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| T1 | 2 | CID, HasWallet |
| T2 | 12 | MasterAccountCID, AlertID, AlertCategory, AlertType, Total_Alerts_of_TheCategory, AlertDate, Regulation, Country, PlayerStatus, Club, AccountType, RiskScoreName |
| Blacklist | 1 | UpdateDate |

## UC External Lineage

UC Target: Not Migrated — no external lineage API entry.

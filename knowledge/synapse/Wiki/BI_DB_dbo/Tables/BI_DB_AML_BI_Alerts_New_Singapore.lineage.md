# BI_DB_dbo.BI_DB_AML_BI_Alerts_New_Singapore — Column Lineage

**Schema**: BI_DB_dbo | **Writer SP**: SP_AML_BI_Alerts_New_Singapore | **Generated**: 2026-04-22

## Pipeline Summary

```
DWH_dbo.Fact_SnapshotCustomer + Dim_Range (MAS-regulated customer snapshot)
  Filter: RegulationID=13 OR DesignatedRegulationID=13 (MAS) AND IsDepositor=1
DWH_dbo.Dim_Regulation, Dim_Country, Dim_PlayerStatus,
        Dim_PlayerLevel, Dim_AccountType, Dim_Customer, Dim_EvMatchStatus
DWH_dbo.Dim_RiskClassification (current risk label from snapshot)
DWH_dbo.Fact_BillingDeposit (lifetime + rolling-window deposit aggregation)
DWH_dbo.Fact_BillingWithdraw (withdrawal activity)
DWH_dbo.Fact_CustomerAction (login, deposit, cashout events; 90-day window)
DWH_dbo.Dim_Position (trading activity for dormancy check)
BI_DB_dbo.BI_DB_KYC_Panel (Q9 employment; Q15/Q18 source-of-income)
External: High-risk country tables; expiry date tables (SGNew028)
BI_DB_dbo.BI_DB_AML_BI_Alerts_New_Singapore (self-reference for dedup and counter)
  |-- SP_AML_BI_Alerts_New_Singapore @Date ---|
     DELETE WHERE AlertDate=@Date + INSERT (with dedup suppression for SGNew025/SGNew015)
  v
BI_DB_dbo.BI_DB_AML_BI_Alerts_New_Singapore (accumulating Singapore AML alert log)
  UC Target: Not Migrated
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Passthrough — RealCID of the customer triggering the AML alert | T1 |
| 2 | AlertID | ETL (NEWID()) | — | Synthetic UUID generated at INSERT time; not a stable identifier | T2 |
| 3 | AlertCategory | SP_AML_BI_Alerts_New_Singapore | — | Classification per alert rule: 'OnBoarding ', 'MIMO ', 'MIMO - Deposit', 'MIMO - Cashouts', 'MIMO - Login', 'MIMO' (with/without trailing space variants) | T2 |
| 4 | Total_Alerts_of_TheCategory | BI_DB_AML_BI_Alerts_New_Singapore (self) | — | COUNT(existing rows WHERE CID=this.CID AND AlertType=this.AlertType) + 1; cumulative counter per customer per alert type | T2 |
| 5 | AlertDate | ETL (@Date param) | — | = @Date cast as datetime; the date for which alerts were generated | T2 |
| 6 | AlertType | SP_AML_BI_Alerts_New_Singapore | — | Hardcoded SG-series alert code + description: SGNew009–SGNew032 and SG GEO005 (20+ distinct codes, SG-specific rule set) | T2 |
| 7 | Regulation | DWH_dbo.Dim_Regulation | Name | Customer's regulation name at SP run time via Fact_SnapshotCustomer JOIN Dim_Regulation | T2 |
| 8 | Country | DWH_dbo.Dim_Country | Name | Customer's KYC country name at SP run time via Fact_SnapshotCustomer JOIN Dim_Country | T2 |
| 9 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Customer's player status at SP run time (excludes StatusID 2 and 4) | T2 |
| 10 | Club | DWH_dbo.Dim_PlayerLevel | Name | Customer's club level name at SP run time | T2 |
| 11 | AccountType | DWH_dbo.Dim_AccountType | Name | Customer's account type name at SP run time | T2 |
| 12 | RiskScoreName | DWH_dbo.Dim_RiskClassification | RiskClassificationName | Current risk label from Fact_SnapshotCustomer snapshot JOIN Dim_RiskClassification (not from change history or External_RiskClassification) | T2 |
| 13 | HasWallet | DWH_dbo.Dim_Customer | HasWallet | Passthrough — current snapshot at SP run time. 1 if customer has active eToro Money wallet | T1 |
| 14 | AdditionalInfoExpiryDate | External expiry date table | LatestExpiryDate | Only populated for SGNew028 (Expiring ID alert). Stores the document expiry date that triggered the alert. NULL for all other alert types. | T2 |
| 15 | UpdateDate | ETL (GETDATE()) | — | GETDATE() at INSERT time — ETL metadata blacklist column | Blacklist |

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| T1 | 2 | CID, HasWallet |
| T2 | 12 | AlertID, AlertCategory, Total_Alerts_of_TheCategory, AlertDate, AlertType, Regulation, Country, PlayerStatus, Club, AccountType, RiskScoreName, AdditionalInfoExpiryDate |
| Blacklist | 1 | UpdateDate |

## UC External Lineage

UC Target: Not Migrated — no external lineage API entry.

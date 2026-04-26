# BI_DB_dbo.BI_DB_AML_BI_Alerts_New — Column Lineage

**Schema**: BI_DB_dbo | **Writer SP**: SP_AML_BI_Alerts_New | **Generated**: 2026-04-22

## Pipeline Summary

```
External_RiskClassification_dbo_V_RiskClassificationDataLake
DWH_dbo.Fact_BillingDeposit + Fact_BillingWithdraw (deposit/withdrawal history)
eMoney_dbo.eMoney_Fact_Transaction_Status (eTM net flows)
DWH_dbo.Fact_SnapshotCustomer + Dim_Range (customer snapshot)
DWH_dbo.Dim_Regulation, Dim_Country, Dim_PlayerStatus,
        Dim_PlayerLevel, Dim_AccountType, Dim_Customer,
        Dim_EvMatchStatus, Dim_FundingType
BI_DB_dbo.BI_DB_KYC_Panel (Q10/Q11 economic profile answers)
BI_DB_dbo.BI_DB_AML_BI_Alerts_New (self-reference for Total_Alerts counter)
  |-- SP_AML_BI_Alerts_New @Date ---|
     DELETE WHERE AlertDate=@Date + INSERT
  v
BI_DB_dbo.BI_DB_AML_BI_Alerts_New (accumulating daily AML alert log)
  UC Target: Not Migrated
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Passthrough — RealCID of the customer triggering the AML alert | T1 |
| 2 | AlertID | ETL (NEWID()) | — | Synthetic UUID generated at INSERT time; no production equivalent | T2 |
| 3 | AlertCategory | SP_AML_BI_Alerts_New | — | Hardcoded classification string per alert rule branch: 'OnBoarding', 'MIMO - Deposit', 'MIMO - Deposits', 'MIMO - Cashouts' | T2 |
| 4 | AlertType | SP_AML_BI_Alerts_New | — | Hardcoded alert code + description string per rule: e.g. 'AML1014: 12 months Deposits > 100K$', 'GEO005: Logins from HRC Rank 1' (30+ distinct codes) | T2 |
| 5 | Total_Alerts_of_TheCategory | BI_DB_AML_BI_Alerts_New (self) | — | COUNT(existing rows WHERE CID=this.CID AND AlertType=this.AlertType) + 1; cumulative fire counter per customer per alert type | T2 |
| 6 | AlertDate | ETL (@Date param) | — | = @Date parameter passed to SP; the date for which alerts were generated | T2 |
| 7 | Regulation | DWH_dbo.Dim_Regulation | Name | Customer's regulation name at SP run time via Fact_SnapshotCustomer JOIN Dim_Regulation | T2 |
| 8 | Country | DWH_dbo.Dim_Country | Name | Customer's KYC country name at SP run time via Fact_SnapshotCustomer JOIN Dim_Country | T2 |
| 9 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Customer's player status name at SP run time (excludes StatusID 2 and 4) | T2 |
| 10 | Club | DWH_dbo.Dim_PlayerLevel | Name | Customer's club level name at SP run time (Bronze/Silver/Gold/Platinum/Diamond/Platinum Plus) | T2 |
| 11 | AccountType | DWH_dbo.Dim_AccountType | Name | Customer's account type name at SP run time (Private/Corporate/etc.) | T2 |
| 12 | RiskScoreName | External_RiskClassification_dbo_V_RiskClassificationDataLake | RiskScoreName | Passthrough of risk classification label (Low/Medium/High/None) from External table | T2 |
| 13 | HasWallet | DWH_dbo.Dim_Customer | HasWallet | Passthrough — current snapshot at SP run time. 1 if customer has active eToro Money wallet | T1 |
| 14 | UpdateDate | ETL (GETDATE()) | — | GETDATE() at INSERT time — ETL metadata blacklist column | Blacklist |

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| T1 | 2 | CID, HasWallet |
| T2 | 11 | AlertID, AlertCategory, AlertType, Total_Alerts_of_TheCategory, AlertDate, Regulation, Country, PlayerStatus, Club, AccountType, RiskScoreName |
| Blacklist | 1 | UpdateDate |

## UC External Lineage

UC Target: Not Migrated — no external lineage API entry.

# BI_DB_dbo.BI_DB_AML_BI_Alerts_MultipleAccountseMoney — Column Lineage

**Schema**: BI_DB_dbo | **Writer SP**: SP_AML_BI_Alerts_MultipleAccountseMoney | **Generated**: 2026-04-22

## Pipeline Summary

```
BI_DB_dbo.BI_DB_OPS_MultipleAccounts (pre-computed multi-account groups; provides ID, AllCIDs spine)
eMoney_dbo.eMoney_Dim_Account (IBAN count per CID — filters to groups with >1 IBAN)
eMoney_dbo.eMoneyClientBalance (current eMoney balance at @Date)
eMoney_dbo.eMoney_Customer_Risk_Assessment (eMoney-specific CRA risk label)
eMoney_dbo.eMoney_Dim_Transaction (TxTypeID=7 Settled — eMoney deposit/cashout amounts)
DWH_dbo.Fact_SnapshotCustomer + Dim_Range (customer snapshot at run date)
DWH_dbo.Dim_Regulation, Dim_Country, Dim_CustomerStatus, Dim_PlayerLevel,
         Dim_AccountType, Dim_Customer, Dim_EvMatchStatus
DWH_dbo.Dim_RiskClassification (risk label from snapshot)
BI_DB_dbo.BI_DB_AML_BI_Alerts_MultipleAccountseMoney (self-reference for Total_Alerts counter)
  |-- SP_AML_BI_Alerts_MultipleAccountseMoney @Date ---|
     DELETE WHERE AlertDate=@Date + INSERT
     (IBAN MA003 first-time only; IBAN MA001/002/004/005 insert every qualifying date)
  v
BI_DB_dbo.BI_DB_AML_BI_Alerts_MultipleAccountseMoney (accumulating eMoney multi-account alert log)
  UC Target: Not Migrated
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | ID | BI_DB_dbo.BI_DB_OPS_MultipleAccounts | ID | Group identifier for the multi-account cluster — a single person's linked accounts share one ID. Used as the counter join key (not CID). | T2 |
| 2 | CID | DWH_dbo.Dim_Customer | RealCID | Passthrough — RealCID of the individual account triggering the alert within the group | T1 |
| 3 | AlertID | ETL (NEWID()) | — | Synthetic UUID generated at INSERT time; not a stable identifier | T2 |
| 4 | AlertCategory | SP_AML_BI_Alerts_MultipleAccountseMoney | — | Always 'MIMO ' (with trailing space) for all 5 IBAN alert codes | T2 |
| 5 | Total_Alerts_of_TheCategory | BI_DB_AML_BI_Alerts_MultipleAccountseMoney (self) | — | COUNT(existing rows WHERE ID=this.ID AND AlertType=this.AlertType) + 1; counter is at group ID level, not individual CID | T2 |
| 6 | AlertDate | ETL (@Date param) | — | = @Date cast as datetime; the date for which alerts were generated | T2 |
| 7 | AlertType | SP_AML_BI_Alerts_MultipleAccountseMoney | — | Hardcoded IBAN MA-series code + description. 5 distinct codes: IBAN MA001–IBAN MA005 | T2 |
| 8 | Regulation | DWH_dbo.Dim_Regulation | Name | Customer's regulation name at SP run time via Fact_SnapshotCustomer JOIN Dim_Regulation | T2 |
| 9 | Country | DWH_dbo.Dim_Country | Name | Customer's KYC country name at SP run time via Fact_SnapshotCustomer JOIN Dim_Country | T2 |
| 10 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Customer's player status name at SP run time | T2 |
| 11 | Club | DWH_dbo.Dim_PlayerLevel | Name | Customer's club level name at SP run time | T2 |
| 12 | AccountType | DWH_dbo.Dim_AccountType | Name | Customer's account type name at SP run time | T2 |
| 13 | RiskScoreName | DWH_dbo.Dim_RiskClassification | RiskClassificationName | Current platform risk classification from Fact_SnapshotCustomer snapshot JOIN Dim_RiskClassification | T2 |
| 14 | HasWallet | DWH_dbo.Dim_Customer | HasWallet | Passthrough — current snapshot at SP run time. 1 if customer has active eToro Money wallet | T1 |
| 15 | AllCIDs | ETL (STRING_AGG) | — | Comma-separated concatenation of all CIDs in the multi-account group (ID), computed via STRING_AGG(CID). Enables AML reviewers to see all linked accounts in one cell. | T2 |
| 16 | MasterAccountCID | BI_DB_dbo.BI_DB_OPS_MultipleAccounts | MasterAccountCID | Master account CID from the OpsDB multi-account grouping (pre-computed); may differ from or equal CID | T2 |
| 17 | TotalDepositsLifetime | eMoney_dbo.eMoney_Dim_Transaction | USDAmountApprox | SUM of all Settled eMoney deposits (TxTypeID=7) for this CID across the group, from eMoney_Dim_Transaction | T2 |
| 18 | TotalCashoutsLifetime | eMoney_dbo.eMoney_Dim_Transaction | USDAmountApprox | SUM of all Settled eMoney cashouts for this CID, from eMoney_Dim_Transaction | T2 |
| 19 | UpdateDate | ETL (GETDATE()) | — | GETDATE() at INSERT time — ETL metadata blacklist column | Blacklist |

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| T1 | 2 | CID, HasWallet |
| T2 | 16 | ID, AlertID, AlertCategory, Total_Alerts_of_TheCategory, AlertDate, AlertType, Regulation, Country, PlayerStatus, Club, AccountType, RiskScoreName, AllCIDs, MasterAccountCID, TotalDepositsLifetime, TotalCashoutsLifetime |
| Blacklist | 1 | UpdateDate |

## UC External Lineage

UC Target: Not Migrated — no external lineage API entry.

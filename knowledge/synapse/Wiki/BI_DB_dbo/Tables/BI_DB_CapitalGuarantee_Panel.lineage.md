# BI_DB_dbo.BI_DB_CapitalGuarantee_Panel — Column Lineage

**Generated**: 2026-04-23 | **Phase**: 10B | **Writer SP**: SP_Capital_Guarantee_Panel

## ETL Chain

```
DWH_dbo.Dim_Customer           (AccountTypeID=9 = Smart Portfolio parents)
DWH_dbo.Dim_Mirror             (dm.OpenOccurred >= '20250101' — Capital Guarantee Alpha scope)
  + DWH_dbo.Dim_Customer       (investor profile: GCID, UserName, Email, IsValidCustomer, etc.)
  + DWH_dbo.Dim_Country        (Region=MarketingRegionManualName, Country=Name)
  + DWH_dbo.Dim_PlayerLevel    (Club=Name)
  + DWH_dbo.Dim_Manager        (ManagerID, Manager=CONCAT(FirstName,' ',LastName))
  + DWH_dbo.Dim_Regulation     (Regulation=Name via dc.RegulationID=dr.DWHRegulationID)
  + DWH_dbo.V_Liabilities      (AvailableBalance=Credit for @dateID)
  + DWH_dbo.Fact_CustomerAction (MoneyIn/MoneyOut: ActionTypeID 15-18; Deposit: 7; Cashout: 8)
  + BI_DB_dbo.BI_DB_PositionPnL (CopyPnL = PositionPnL + Dim_Mirror.RealziedPnL per investor/parent)
    |-- SP_Capital_Guarantee_Panel (@date=GETDATE()-1 override, Daily SB_Daily) ---|
    |-- DELETE WHERE DateID=@dateID + INSERT (append/upsert — historical daily snapshots retained) ---|
    v
BI_DB_dbo.BI_DB_CapitalGuarantee_Panel (60.6M rows, 2025-01-01 to 2026-04-12, 467 dates)
    |-- UC: _Not_Migrated ---|
    v
  (no downstream consumers identified)
```

## Column Lineage

| DWH Column | Source | Source Column | Transform |
|---|---|---|---|
| Date | ETL (@date param) | — | SET @date = GETDATE()-1 (override) |
| DateID | ETL (@date param) | — | CONVERT(CHAR(8),@date,112) |
| ParentCID | DWH_dbo.Dim_Mirror | ParentCID | Passthrough |
| ParentUserName | DWH_dbo.Dim_Mirror | ParentUserName | Passthrough |
| InvestorCID | DWH_dbo.Dim_Mirror | CID (= Dim_Customer.RealCID) | Passthrough, rename to InvestorCID |
| InvestorGCID | DWH_dbo.Dim_Customer | GCID | Passthrough, rename to InvestorGCID |
| UserName | DWH_dbo.Dim_Customer | UserName | Passthrough |
| Email | DWH_dbo.Dim_Customer | Email | Passthrough |
| FirstTimeOpen | DWH_dbo.Dim_Mirror | OpenOccurred | MIN(OpenOccurred) — earliest copy open |
| FirstTimeOpenID | DWH_dbo.Dim_Mirror | OpenDateID | MAX(OpenDateID) — NOTE: MAX not MIN (see quirks) |
| Positions | DWH_dbo.Dim_Mirror | MirrorID | COUNT(DISTINCT MirrorID) per investor/parent |
| isOpen | DWH_dbo.Dim_Mirror | CloseDateID | CASE WHEN MIN(CloseDateID)=0 THEN 1 ELSE 0 END |
| MaxClose | DWH_dbo.Dim_Mirror | CloseOccurred | MAX(CloseOccurred) |
| MaxCloseID | DWH_dbo.Dim_Mirror | CloseDateID | MAX(CloseDateID) |
| IsValidCustomer | DWH_dbo.Dim_Customer | IsValidCustomer | Passthrough |
| Region | DWH_dbo.Dim_Country | MarketingRegionManualName | Passthrough, rename to Region |
| Country | DWH_dbo.Dim_Country | Name | Passthrough, rename to Country |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Passthrough, rename to Club |
| Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough, rename to Regulation (JOIN on RegulationID=DWHRegulationID) |
| ManagerID | DWH_dbo.Dim_Manager | ManagerID | Passthrough |
| Manager | DWH_dbo.Dim_Manager | FirstName, LastName | CONCAT(FirstName, ' ', LastName) |
| AvailableBalance | DWH_dbo.V_Liabilities | Credit | Passthrough, rename to AvailableBalance (joined on CID + DateID) |
| MoneyOut | DWH_dbo.Fact_CustomerAction | Amount | COALESCE(SUM(CASE WHEN ActionTypeID IN (16,18) THEN -Amount END), 0) for @date |
| MoneyIn | DWH_dbo.Fact_CustomerAction | Amount | COALESCE(SUM(CASE WHEN ActionTypeID IN (15,17) THEN -Amount END), 0) for @date |
| NMI | Computed | — | MoneyIn + MoneyOut |
| Deposit | DWH_dbo.Fact_CustomerAction | Amount | COALESCE(SUM(CASE WHEN ActionTypeID=7 THEN Amount END), 0) for @dateID |
| Cashout | DWH_dbo.Fact_CustomerAction | Amount | COALESCE(SUM(CASE WHEN ActionTypeID=8 THEN -Amount END), 0) for @dateID |
| CopyPnL | BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Mirror | PositionPnL + RealziedPnL | SUM(PositionPnL + RealziedPnL) per investor/parent where DateID >= @dateID |
| Acc_MoneyOut | DWH_dbo.Fact_CustomerAction | Amount | COALESCE(SUM(CASE WHEN ActionTypeID IN (16,18) THEN -Amount END), 0) cumulative to @date |
| Acc_MoneyIn | DWH_dbo.Fact_CustomerAction | Amount | COALESCE(SUM(CASE WHEN ActionTypeID IN (15,17) THEN -Amount END), 0) cumulative to @date |
| Acc_NMI | Computed | — | Acc_MoneyIn + Acc_MoneyOut |
| UpdateDate | ETL runtime | — | GETDATE() |

## Tier Pre-Assignment

| DWH Column | Upstream Wiki | Transform | Pre-Tier |
|---|---|---|---|
| Date | ETL param | Override to GETDATE()-1 | Tier 2 |
| DateID | ETL param | CONVERT(CHAR(8),@date,112) | Tier 2 |
| ParentCID | Dim_Mirror.md ✓ (ParentCID, Tier 1) | Passthrough | Tier 1 |
| ParentUserName | Dim_Mirror.md ✓ (ParentUserName, Tier 1) | Passthrough | Tier 1 |
| InvestorCID | Dim_Customer.md ✓ (RealCID, Tier 1) | Passthrough + rename | Tier 1 |
| InvestorGCID | Dim_Customer.md ✓ (GCID, Tier 1) | Passthrough + rename | Tier 1 |
| UserName | Dim_Customer.md ✓ (UserName, Tier 1) | Passthrough | Tier 1 |
| Email | Dim_Customer.md ✓ (Email, Tier 1) | Passthrough | Tier 1 |
| FirstTimeOpen | Dim_Mirror.md (OpenOccurred, Tier 2) | MIN aggregate | Tier 2 |
| FirstTimeOpenID | Dim_Mirror.md (OpenDateID, Tier 2) | MAX aggregate — mismatched with MIN(OpenOccurred) | Tier 2 |
| Positions | Dim_Mirror.md (MirrorID) | COUNT(DISTINCT) aggregate | Tier 2 |
| isOpen | Dim_Mirror.md (CloseDateID, Tier 2) | CASE aggregate | Tier 2 |
| MaxClose | Dim_Mirror.md (CloseOccurred, Tier 2) | MAX aggregate | Tier 2 |
| MaxCloseID | Dim_Mirror.md (CloseDateID, Tier 2) | MAX aggregate | Tier 2 |
| IsValidCustomer | Dim_Customer.md (IsValidCustomer, Tier 2) | Passthrough | Tier 2 |
| Region | Dim_Country.md (MarketingRegionManualName, Tier 3) | Passthrough + rename | Tier 3 |
| Country | Dim_Country.md ✓ (Name, Tier 1) | Passthrough + rename | Tier 1 |
| Club | Dim_PlayerLevel.md ✓ (Name, Tier 1) | Passthrough + rename | Tier 1 |
| Regulation | Dim_Regulation.md ✓ (Name, Tier 1) | Passthrough + rename | Tier 1 |
| ManagerID | Dim_Manager.md ✓ (ManagerID, Tier 1) | Passthrough | Tier 1 |
| Manager | Dim_Manager.md (FirstName+LastName, Tier 1) | CONCAT computed | Tier 2 |
| AvailableBalance | V_Liabilities.md (Credit, T1 passthrough from Fact_SnapshotEquity) | Passthrough + rename | Tier 2 (no full desc in V_Liabilities wiki) |
| MoneyOut | No upstream wiki for ActionTypeID 16/18 | SUM aggregate | Tier 2 |
| MoneyIn | No upstream wiki for ActionTypeID 15/17 | SUM aggregate | Tier 2 |
| NMI | Computed | MoneyIn + MoneyOut | Tier 2 |
| Deposit | No upstream wiki for ActionTypeID 7 (Fact_CustomerAction level) | SUM aggregate | Tier 2 |
| Cashout | No upstream wiki for ActionTypeID 8 | SUM aggregate | Tier 2 |
| CopyPnL | BI_DB_PositionPnL.md ✓ (PositionPnL, Tier 2) + Dim_Mirror.md (RealziedPnL, Tier 1) | SUM aggregate | Tier 2 |
| Acc_MoneyOut | No upstream wiki | SUM cumulative | Tier 2 |
| Acc_MoneyIn | No upstream wiki | SUM cumulative | Tier 2 |
| Acc_NMI | Computed | Acc_MoneyIn + Acc_MoneyOut | Tier 2 |
| UpdateDate | Propagation blacklist | GETDATE() | Propagation |

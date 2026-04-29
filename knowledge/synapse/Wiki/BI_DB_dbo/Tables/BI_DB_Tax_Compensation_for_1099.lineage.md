# Column Lineage — BI_DB_dbo.BI_DB_Tax_Compensation_for_1099

**Writer SP**: `BI_DB_dbo.SP_Tax_Compensation_for_1099` (Author: Lior Ben Dor, 2024-12-22)
**ETL Pattern**: TRUNCATE + INSERT (full reload)
**Population Filter**: Regulation IN ('eToroUS', 'FinCEN', 'FinCEN+FINRA') AND YEAR(Time) >= 2023

---

## Source Chain

```
BI_DB_dbo.BI_DB_BO_Generated_Compensations (bdbgc) ──┐
DWH_dbo.Dim_Customer (dc)  ON bdbgc.CID = dc.RealCID ┤
DWH_dbo.Dim_PlayerStatus (dps)  ON dc.PlayerStatusID  ┤──→ #pop_comp (US-regulated compensations)
DWH_dbo.Dim_State_and_Province (dsap) ON dc.RegionID  ┘
                   ↓
BI_DB_dbo.BI_DB_USA_FinanceReport_forTax (cc) ──→ #SSN (SSN lookup by RealCID)
                   ↓
              #pop_comp + #SSN ──→ #final
                   ↓
DWH_dbo.V_Liabilities (vl) ON vl.CID, DateID=yesterday ──→ #equity (Liabilities + ActualNWA)
                   ↓
              #final + #equity ──→ #final1
                   ↓
         TRUNCATE + INSERT + GETDATE() AS UpdateDate
                   ↓
     BI_DB_dbo.BI_DB_Tax_Compensation_for_1099
```

---

## Column-Level Lineage

| Target Column | Source Table (alias) | Source Column | Transform |
|--------------|---------------------|---------------|-----------|
| CID | BI_DB_BO_Generated_Compensations (bdbgc) | CID | Direct passthrough |
| Amount | BI_DB_BO_Generated_Compensations (bdbgc) | Amount | Direct passthrough |
| Type | BI_DB_BO_Generated_Compensations (bdbgc) | Type | Direct passthrough |
| Time | BI_DB_BO_Generated_Compensations (bdbgc) | Time | Direct passthrough |
| YEAR | BI_DB_BO_Generated_Compensations (bdbgc) | Time | YEAR(bdbgc.Time) — extracted calendar year |
| Description | BI_DB_BO_Generated_Compensations (bdbgc) | Description | Direct passthrough |
| Category | BI_DB_BO_Generated_Compensations (bdbgc) | Category | Direct passthrough |
| Reason | BI_DB_BO_Generated_Compensations (bdbgc) | Reason | Direct passthrough |
| Manager | BI_DB_BO_Generated_Compensations (bdbgc) | Manager | Direct passthrough |
| AffiliateID | BI_DB_BO_Generated_Compensations (bdbgc) | Affiliate | Renamed: Affiliate -> AffiliateID |
| Club | BI_DB_BO_Generated_Compensations (bdbgc) | [Player Level] | Renamed: [Player Level] -> Club |
| Regulation | BI_DB_BO_Generated_Compensations (bdbgc) | Regulation | Direct passthrough. Filter: IN ('eToroUS','FinCEN','FinCEN+FINRA') |
| PlayerStatus | Dim_PlayerStatus (dps) | Name | Resolved via Dim_Customer.PlayerStatusID -> Dim_PlayerStatus.PlayerStatusID |
| VerificationLevelID | Dim_Customer (dc) | VerificationLevelID | Direct from Dim_Customer |
| IsDepositor | Dim_Customer (dc) | IsDepositor | Direct from Dim_Customer |
| FirstName | Dim_Customer (dc) | FirstName | Direct from Dim_Customer |
| LastName | Dim_Customer (dc) | LastName | Direct from Dim_Customer |
| Email | Dim_Customer (dc) | Email | Direct from Dim_Customer |
| Country | BI_DB_BO_Generated_Compensations (bdbgc) | [Country (Reg Form)] | Renamed: [Country (Reg Form)] -> Country |
| Address | Dim_Customer (dc) | Address | Direct from Dim_Customer |
| State | Dim_State_and_Province (dsap) | Name | LEFT JOIN on dc.RegionID = dsap.RegionByIP_ID |
| City | Dim_Customer (dc) | City | Direct from Dim_Customer |
| BuildingNumber | Dim_Customer (dc) | BuildingNumber | Direct from Dim_Customer |
| Zip | Dim_Customer (dc) | Zip | Direct from Dim_Customer |
| SSN | BI_DB_USA_FinanceReport_forTax (cc) | SSN | LEFT JOIN via RealCID. NULL if no SSN on file |
| Equity | V_Liabilities (vl) | Liabilities + ActualNWA | ISNULL(vl.Liabilities,0) + ISNULL(vl.ActualNWA,0). Yesterday's date. Defaults to 0 if no match |
| UpdateDate | computed | GETDATE() | ETL execution timestamp |

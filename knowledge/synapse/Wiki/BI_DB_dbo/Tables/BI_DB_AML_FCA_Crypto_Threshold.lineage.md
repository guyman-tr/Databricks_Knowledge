# BI_DB_dbo.BI_DB_AML_FCA_Crypto_Threshold — Column Lineage

*Generated: 2026-04-21 | Phase 10B output — written BEFORE wiki*

## Source Objects

| Source | Type | Description |
|--------|------|-------------|
| BI_DB_dbo.BI_DB_PositionPnL | BI_DB Table | Daily position P&L snapshot — provides CID and DateID for crypto positions with Amount ≥ 80,000 and IsSettled=1 |
| DWH_dbo.Dim_Instrument | DWH Dimension | Instrument master — provides InstrumentTypeID=10 filter to restrict to Crypto instruments |
| DWH_dbo.Dim_Customer | DWH Dimension | Customer master — provides RealCID (dedup target), HasWallet, RegulationID, PlayerStatusID, PlayerLevelID, AccountManagerID, VerificationLevelID, IsValidCustomer, IsDepositor |
| DWH_dbo.Dim_Manager | DWH Dimension | Account manager master — provides FirstName, LastName for Account_Manager_Name computation |
| DWH_dbo.Dim_PlayerLevel | DWH Dimension | Player level master — provides Name (Club tier) via JOIN on PlayerLevelID |
| DWH_dbo.Dim_PlayerStatus | DWH Dimension | Player status master — provides Name (PlayerStatus) via JOIN on PlayerStatusID |
| DWH_dbo.Dim_Regulation | DWH Dimension | Regulation master — provides Name (Regualtion [sic]) via JOIN on DWHRegulationID=RegulationID |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|------------|---------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Passthrough: BI_DB_PositionPnL.CID resolved to Dim_Customer.RealCID via INNER JOIN ON ppnl.CID = dc.RealCID | Tier 1 — Customer.CustomerStatic |
| 2 | DateID | BI_DB_dbo.BI_DB_PositionPnL | DateID | Passthrough from BI_DB_PositionPnL.DateID (YYYYMMDD int). Always equals CONVERT(CHAR(8),@Date,112) — SP parameter | Tier 2 — SP_W_Mon_AML_FCA_Crypto_Threshold |
| 3 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN resolution: Dim_Customer.PlayerStatusID → Dim_PlayerStatus.Name. Values in table: Normal, Warning | Tier 1 — Dictionary.PlayerStatus |
| 4 | Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN resolution: Dim_Customer.PlayerLevelID → Dim_PlayerLevel.Name. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond | Tier 1 — Dictionary.PlayerLevel |
| 5 | HasWallet | DWH_dbo.Dim_Customer | HasWallet | Passthrough. Filter dc.HasWallet = 1 means all rows have HasWallet=1 | Tier 1 — BackOffice.Customer |
| 6 | Account_Manager_Name | DWH_dbo.Dim_Manager | FirstName, LastName | COMPUTED: `dm.FirstName + ' ' + dm.LastName` | Tier 1 — BackOffice.Manager |
| 7 | UpdateDate | ETL | N/A | GETDATE() at SP execution time | Tier 2 — SP_W_Mon_AML_FCA_Crypto_Threshold |
| 8 | Regualtion [sic] | DWH_dbo.Dim_Regulation | Name | JOIN resolution: Dim_Customer.RegulationID → Dim_Regulation.DWHRegulationID → Dim_Regulation.Name. Three UNION branches: RegulationID=2 (FCA), =1 (CySEC), IN (4,10) (ASIC/ASIC+GAML). Column name is a typo in DDL. | Tier 1 — Dictionary.Regulation |

## ETL Pipeline Summary

```
BI_DB_dbo.BI_DB_PositionPnL
  InstrumentTypeID = 10 (Crypto)
  Amount >= 80000 (position value threshold)
  IsSettled = 1 (Real positions only)
  DateID = @DateID (weekly Monday run)
    --> #cidpopulation: CID + DateID, deduped per CID via ROW_NUMBER()

DWH_dbo.Dim_Customer   --> RegulationID IN (1=CySEC, 2=FCA, 4=ASIC, 10=ASIC+GAML)
                            IsValidCustomer=1, IsDepositor=1
                            VerificationLevelID=3 (fully verified)
                            PlayerStatusID IN (1=Normal, 5=Warning)
                            HasWallet=1 (crypto wallet required)
DWH_dbo.Dim_Manager    --> Account_Manager_Name (FirstName + LastName)
DWH_dbo.Dim_PlayerLevel --> Club (tier name)
DWH_dbo.Dim_PlayerStatus --> PlayerStatus (Normal, Warning)
DWH_dbo.Dim_Regulation  --> Regualtion [sic] (FCA, CySEC, ASIC, ASIC & GAML)
  |-- SP_W_Mon_AML_FCA_Crypto_Threshold (@Date param, weekly Monday) ---|
  |   Load: DELETE DateID=@DateID + INSERT from #final (idempotent per-date)|
  v
BI_DB_dbo.BI_DB_AML_FCA_Crypto_Threshold
  60.9K rows | 1,186 distinct CIDs | 225 distinct monitoring dates
  Date range: 2021-11-28 to 2026-04-12 (4.5 years of weekly snapshots)
  Regulation mix: FCA 53.6%, CySEC 40.1%, ASIC+GAML 5.1%, ASIC 0.2%
  Club mix: Diamond 56.9%, Platinum Plus 42.3%
    |-- Not yet migrated to UC ---|
    v
UC Target: _Not_Migrated
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 6 | CID, PlayerStatus, Club, HasWallet, Account_Manager_Name, Regualtion |
| Tier 2 | 2 | DateID, UpdateDate |

# EXW_dbo.EXW_WalletLogins — Column Lineage

**Generated**: 2026-04-20  
**Object Type**: Table  
**Schema**: EXW_dbo  
**ETL Mechanism**: `EXW_dbo.SP_WalletLogins` — daily delete-insert by @date parameter. Reads from `DWH_dbo.Fact_CustomerAction` (ActionTypeID=14, LoggedIn) joined to `DWH_dbo.Dim_Customer` (HasWallet=1 filter). Writes 7 columns. All columns are T2 (SP code).

## ETL Pipeline Summary

```
STS_Audit_UserOperationsData (production — Session Tracking Service)
  |-- Generic Pipeline / SP_Fact_CustomerAction --|
  v
DWH_dbo.Fact_CustomerAction (ActionTypeID=14, LoggedIn rows only)
DWH_dbo.Dim_Customer (HasWallet=1 filter)
  |-- EXW_dbo.SP_WalletLogins(@date) --|
  |-- DELETE WHERE CAST(LoggedInOn AS DATE)=@date --|
  |-- INSERT SELECT with hardcoded 'retoro' ApplicationIdentifier --|
  v
EXW_dbo.EXW_WalletLogins (daily refresh, rolling history)
  |-- No Gold layer UC target --|
  v
UC Target: _Not_Migrated
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | GCID | DWH_dbo.Fact_CustomerAction | GCID | Passthrough — Group Customer ID for wallet user | Tier 2 |
| 2 | RealCID | DWH_dbo.Fact_CustomerAction | RealCID | Passthrough — real (non-virtual) customer identifier | Tier 2 |
| 3 | ApplicationIdentifier | Hardcoded in SP | — | Constant 'retoro' — eToro wallet/crypto application identifier | Tier 2 |
| 4 | SessionIdentifier | DWH_dbo.Fact_CustomerAction | SessionID | Passthrough rename — login session identifier (bigint) | Tier 2 |
| 5 | EnvironmentDetails | Hardcoded in SP | — | Constant NULL — not populated despite existing in schema | Tier 2 |
| 6 | LoggedInOn | DWH_dbo.Fact_CustomerAction | Occurred | Passthrough rename — timestamp when login event occurred (datetime) | Tier 2 |
| 7 | UpdateDate | SP — GETDATE() | — | ETL write timestamp (GETDATE() at SP execution time) | Tier 2 |

## SP Filter Logic

```sql
-- SP_WalletLogins core filter (all T2 derivations)
SELECT fca.GCID, fca.RealCID, 'retoro', fca.SessionID, NULL, fca.Occurred, GETDATE()
FROM DWH_dbo.Fact_CustomerAction fca
JOIN DWH_dbo.Dim_Customer dc ON fca.RealCID = dc.RealCID AND dc.HasWallet = 1
WHERE DateID = @dateID         -- today's partition
  AND ActionTypeID = 14        -- LoggedIn events only
```

## UC Target

`_Not_Migrated` — No Gold layer UC target in generic pipeline mapping.

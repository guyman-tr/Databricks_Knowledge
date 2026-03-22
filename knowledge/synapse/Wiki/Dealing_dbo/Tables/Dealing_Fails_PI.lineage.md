# Column Lineage: Dealing_dbo.Dealing_Fails_PI

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Fails_PI` |
| **UC Target** | `general.dealing_dbo.dealing_fails_pi` |
| **Primary Source** | `etoro.Trade.PositionFail` (via Dealing_staging.PositionFailReal_History_PositionFail_DWH) |
| **ETL SP** | `Dealing_dbo.SP_Fails_PI` |
| **Secondary Sources** | `DWH_dbo.Fact_SnapshotCustomer` (GuruStatusID for IsPI flag), `DWH_dbo.Dim_Customer` (UserName), `DWH_dbo.Dim_Instrument` (InstrumentDisplayName), `Dealing_dbo.Dealing_Fails_PI_ErrorCodes` (Generic_FailReason) |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
etoro.Trade.PositionFail (production SQL Server)
  → Generic Pipeline → Lake (Bronze/etoro/Trade/PositionFail/)
  → Dealing_staging.PositionFailReal_History_PositionFail_DWH
  → SP_Fails_PI
     #Fails (row-level fail data, full population excluding staff/test accounts)
     #Classification (HedgeFailReason extraction, ErrorType classification)
  → Dealing_dbo.Dealing_Fails_PI
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **rename** | Same value, different column name. |
| **ETL-computed** | Derived/calculated by ETL SP. |
| **join-enriched** | Joined from a secondary source table. |
| **etl_metadata** | Set by GETDATE() at SP execution. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | SP parameter | @Date | passthrough | Direct: @Date | Partition date for DELETE/INSERT cycle |
| FailOccurred | Trade.PositionFail | FailOccurred | passthrough | Direct: pf.FailOccurred | Exact datetime of failure event |
| CID | Trade.PositionFail | CID | passthrough | Direct: pf.CID | Client ID of the account that failed |
| UserName | DWH_dbo.Dim_Customer | UserName | join-enriched | LEFT JOIN Dim_Customer ON pf.CID = dc.RealCID | Display name of the client |
| InstrumentID | Trade.PositionFail | InstrumentID | passthrough | Direct: pf.InstrumentID | Instrument that failed to trade |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | join-enriched | LEFT JOIN Dim_Instrument ON pf.InstrumentID = di.InstrumentID | Human-readable instrument name |
| FailReason | Trade.PositionFail | FailReason | passthrough | Direct: pf.FailReason (raw, full text) | Raw unclassified fail reason string from platform |
| ErrorCode | Trade.PositionFail | ErrorCode | passthrough | Direct: pf.ErrorCode | Numeric error code (see Dealing_Fails_PI_ErrorCodes) |
| Generic_FailReason | Dealing_Fails_PI_ErrorCodes | FailReason | join-enriched | LEFT JOIN Dealing_Fails_PI_ErrorCodes ec ON pf.ErrorCode = ec.ErrorCode | Human-readable error code label (e.g., INSUFFICIENT_FUNDS_ERROR) |
| UpdateDate | SP runtime | GETDATE() | etl_metadata | `GETDATE()` at INSERT time | ETL insert timestamp |
| HedgeFailReason | Trade.PositionFail | FailReason | ETL-computed | `SUBSTRING(FailReason, CHARINDEX('HedgeFailReason:',FailReason)+17, ...)` when CHARINDEX > 0 ELSE FailReason | Hedge-specific failure detail extracted from composite FailReason string |
| ErrorType | Trade.PositionFail | FailReason | ETL-computed | `CASE WHEN CHARINDEX('Error closing',FailReason)>0 THEN 'Closing' WHEN CHARINDEX('Error opening',FailReason)>0 THEN 'Opening' WHEN CHARINDEX('Error hedging',FailReason)>0 THEN 'Hedging' ELSE 'Other'` | Fail category: Opening/Closing/Hedging/Other |
| HedgeServerID | Trade.PositionFail | HedgeServerID | passthrough | Direct: pf.HedgeServerID | Hedge server routing ID; NULL = platform-level rejection |
| IsCopy | Trade.PositionFail | MirrorID | ETL-computed | `CASE WHEN pf.MirrorID = 0 THEN 0 ELSE 1 END` | 1 = copy trade (position copied from another user); 0 = manual trade |
| IsPI | DWH_dbo.Fact_SnapshotCustomer | GuruStatusID | ETL-computed | `CASE WHEN sc.GuruStatusID IN (5,6) THEN 1 ELSE 0 END` | 1 = Popular Investor (Guru status 5 or 6) |
| Amount | Trade.PositionFail | Amount | passthrough | Direct: pf.Amount | Attempted position amount (USD) at time of failure |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 7 |
| **Join-enriched** | 3 |
| **ETL-computed** | 4 |
| **ETL metadata** | 1 |
| **Rename** | 0 |
| **Total** | 16 (includes 1 duplicate: HedgeFailReason + ErrorType both derived from FailReason) |

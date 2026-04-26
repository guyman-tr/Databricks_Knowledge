# BI_DB_dbo.BI_DB_Crypto_Active_Open_Churn_Winback — Column Lineage

## Writer SP

`BI_DB_dbo.SP_Crypto_Active_Open_Churn_Winback` (Priority 0, Daily, SB_Daily)

## Source Objects

| Source Object | Role |
|--------------|------|
| DWH_dbo.Fact_SnapshotCustomer | Population base — verified depositors (IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3) |
| DWH_dbo.Dim_Customer | PlayerLevelID<>4 filter (exclude Internal accounts) |
| DWH_dbo.Dim_Range | Date range resolution (DateRangeID → FromDateID/ToDateID) |
| DWH_dbo.Dim_PlayerLevel | Club name lookup (PlayerLevelID → Name) |
| DWH_dbo.Dim_Country | Country name lookup (CountryID → Name) + Region (MarketingRegionManualName) |
| DWH_dbo.Fact_CustomerAction | Crypto trading activity within current month (InstrumentTypeID=10, CategoryID=18) |
| DWH_dbo.Dim_Instrument | InstrumentTypeID=10 filter (Real Crypto) |
| DWH_dbo.Dim_ActionType | CategoryID=18 filter (crypto-relevant actions) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough — DISTINCT from population |
| Active_Month | — | — | ETL-computed: DATEFROMPARTS(YEAR(@date), MONTH(@date), 1) — first day of the execution month |
| Country | DWH_dbo.Dim_Country | Name | Passthrough via Fact_SnapshotCustomer.CountryID JOIN |
| Region | DWH_dbo.Dim_Country | MarketingRegionManualName | Passthrough via Fact_SnapshotCustomer.CountryID JOIN |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Passthrough via Fact_SnapshotCustomer.PlayerLevelID JOIN |
| Active_Crypto_Manual | DWH_dbo.Fact_CustomerAction | MirrorID | ETL-computed: MAX(CASE WHEN ISNULL(MirrorID,0)=0 THEN 1 ELSE 0 END) — direct (non-copy) crypto trade |
| Active_Crypto_Copy | DWH_dbo.Fact_CustomerAction | MirrorID | ETL-computed: MAX(CASE WHEN ISNULL(MirrorID,0)<>0 THEN 1 ELSE 0 END) — copy crypto trade |
| Active_Crypto_CFD | DWH_dbo.Fact_CustomerAction | IsSettled | ETL-computed: MAX(CASE WHEN ISNULL(IsSettled,0)=0 THEN 1 ELSE 0 END) — CFD crypto trade |
| Active_Crypto_Real | DWH_dbo.Fact_CustomerAction | IsSettled | ETL-computed: MAX(CASE WHEN ISNULL(IsSettled,0)=1 THEN 1 ELSE 0 END) — real (settled) crypto trade |
| Active_Open | — | — | ETL-computed: (Active_Crypto_Manual=1 OR Active_Crypto_Copy=1) AND (Active_Crypto_Real=1 OR Active_Crypto_CFD=1) |
| Churn | BI_DB_dbo.BI_DB_Crypto_Active_Open_Churn_Winback | Active_Open | ETL-computed: CASE WHEN Active_Open < LAG(Active_Open) OVER(PARTITION BY RealCID ORDER BY Active_Month) THEN 1 ELSE 0 END |
| Win_Back | BI_DB_dbo.BI_DB_Crypto_Active_Open_Churn_Winback | Active_Open | ETL-computed: CASE WHEN Active_Open > LAG(Active_Open) OVER(PARTITION BY RealCID ORDER BY Active_Month) THEN 1 ELSE 0 END |
| UpdateDate | — | — | ETL metadata: GETDATE() |

## UC External Lineage

Not applicable — table is not in the Generic Pipeline mapping. UC Target: _Not_Migrated.

# Lineage: eMoney_dbo.eMoney_Card_Monthly_Snapshot

**Generated**: 2026-04-21  
**Writer SP**: `eMoney_dbo.SP_eMoney_Card_Monthly_Snapshot`  
**Load Pattern**: Incremental monthly append — DELETE WHERE SnapShotDateID + INSERT per EOM date  
**Distribution**: HASH(CID), HEAP

---

## Source Objects

| Source | Type | Role |
|--------|------|------|
| DWH_dbo.Fact_SnapshotCustomer | DWH Fact | Eligible customer universe at each EOM (IsValidCustomer=1 + eMoney rollout country filter) |
| eMoney_dbo.eMoney_Dim_Country_Rollout | DWH Dim | eTM rollout country filter (34 countries) |
| DWH_dbo.Dim_Range | DWH Dim | Date range JOIN to identify valid snapshot period |
| DWH_dbo.Dim_PlayerLevel | DWH Dim | SnapshotClub and current Club name decode |
| DWH_dbo.Dim_Country | DWH Dim | SnapshotCountry and current Country name decode |
| eMoney_dbo.eMoney_Dim_Account | DWH Table | AccountSubProgram (LEFT JOIN on GCID, GCID_Unique_Count=1) |
| DWH_dbo.Dim_Customer | DWH Dim | CID → current CountryID and PlayerLevelID for Country and Club columns |
| eMoney_dbo.eMoney_Card_Instance_Summary | DWH Table | Card dates and TX counts (FMI_Date, CardCreateDate, InstanceActivationDate, TxAfterActivationCount) |
| eMoney_dbo.eMoney_Dim_Transaction | DWH Table | Tx1/Tx2 dates after first/last activation (settled card TXs) |

---

## Column Lineage

| # | Synapse Column | Source DB | Source Schema | Source Table | Source Column | Transform | Tier |
|---|---------------|-----------|---------------|--------------|---------------|-----------|------|
| 1 | SnapShotDateID | ETL | — | — | — | YYYYMMDD integer from @StartDateDailyID loop variable | 2 |
| 2 | SnapShotDate | ETL | — | — | — | EOM date from while-loop (@StartDateDaily) | 2 |
| 3 | CID | etoro | Customer | CustomerStatic | CID | Passthrough via Fact_SnapshotCustomer.RealCID | 1 |
| 4 | GCID | FiatDwhDB | dbo | FiatAccount | Gcid | Passthrough via Fact_SnapshotCustomer.GCID | 1 |
| 5 | SnapshotCountryID | DWH | — | Fact_SnapshotCustomer | CountryID | Point-in-time country as of snapshot EOM date | 2 |
| 6 | SnapshotPlayerLevelID | DWH | — | Fact_SnapshotCustomer | PlayerLevelID | Point-in-time club tier as of snapshot EOM | 2 |
| 7 | SnapshotClub | DWH | — | Dim_PlayerLevel | Name | Name decode of SnapshotPlayerLevelID at EOM | 2 |
| 8 | SnapshotCountry | DWH | — | Dim_Country | Name | Name decode of SnapshotCountryID at EOM | 2 |
| 9 | AccountSubProgram | eMoney_dbo | — | eMoney_Dim_Account | AccountSubProgram | LEFT JOIN on GCID (GCID_Unique_Count=1); NULL for non-card/non-eMoney accounts | 2 |
| 10 | FMI_Date | FiatDwhDB | dbo | FiatTransactions (eMoney) | TxStatusModificationDate | From eMoney_Card_Instance_Summary.FMI_Date (first settled IN tx) | 2 |
| 11 | CardCreateDate | FiatDwhDB | dbo | FiatCards | Created | MAX(eMoney_Card_Instance_Summary.CardCreateDate) per CID | 2 |
| 12 | LastInstanceActivationDate | FiatDwhDB | dbo | FiatCardStatuses | EventTimestamp | MAX(eMoney_Card_Instance_Summary.InstanceActivationDate) per CID | 2 |
| 13 | LastInstanceTxAfterActivationCount | ETL | — | eMoney_Card_Instance_Summary | TxAfterActivationCount | MAX(TxAfterActivationCount) per CID (last active instance's TX count) | 2 |
| 14 | FirstInstanceCreatedDate | FiatDwhDB | dbo | FiatCardStatuses | EventTimestamp | MIN(InstanceCreatedDate) by ROW_NUMBER on InstanceCreatedDate ASC from CIS | 2 |
| 15 | FirstInstanceActivationDate | FiatDwhDB | dbo | FiatCardStatuses | EventTimestamp | MIN(InstanceActivationDate) by ROW_NUMBER from CIS | 2 |
| 16 | FirstTxAfterActivationCount | ETL | — | eMoney_Card_Instance_Summary | TxAfterActivationCount | TxAfterActivationCount for first instance per CID (RowNum=1 by InstanceCreatedDate) | 2 |
| 17 | Tx1_AfterFirst | eMoney_dbo | — | eMoney_Dim_Transaction | TxStatusModificationDate | 1st settled card TX date (TxTypeID IN [1-4]) after FirstInstanceActivationDate | 2 |
| 18 | Tx2_AfterFirst | eMoney_dbo | — | eMoney_Dim_Transaction | TxStatusModificationDate | 2nd settled card TX date after FirstInstanceActivationDate | 2 |
| 19 | Tx1_AfterLast | eMoney_dbo | — | eMoney_Dim_Transaction | TxStatusModificationDate | 1st settled card TX date after LastInstanceActivationDate | 2 |
| 20 | Tx2_AfterLast | eMoney_dbo | — | eMoney_Dim_Transaction | TxStatusModificationDate | 2nd settled card TX date after LastInstanceActivationDate | 2 |
| 21 | Country | DWH | — | Dim_Country | Name | CURRENT country name via Dim_Customer → Dim_Country (may differ from SnapshotCountry) | 2 |
| 22 | Club | DWH | — | Dim_PlayerLevel | Name | CURRENT club name via Dim_Customer → Dim_PlayerLevel (may differ from SnapshotClub) | 2 |
| 23 | UpdateDate | ETL | — | — | — | GETDATE() at INSERT time | 2 |

---

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (EOM customer universe, IsValidCustomer=1)
  + eMoney_dbo.eMoney_Dim_Country_Rollout (34-country filter)
  + DWH_dbo.Dim_PlayerLevel, Dim_Country (EOM attribute decode)
  + eMoney_dbo.eMoney_Dim_Account (AccountSubProgram)
  |-- Step 1–2: #T2 (EOM eligible customer base) ---|
  v
eMoney_dbo.eMoney_Card_Instance_Summary (card timelines per CID)
  |-- Step 3–4: #T3 (last card instance), #T4 (first card instance) ---|
  v
DWH_dbo.Dim_Customer (current country/club)
  |-- Step 5: #T5 (pre-final join) ---|
  v
eMoney_dbo.eMoney_Dim_Transaction (settled card TXs after activation)
  |-- Step 6: #T6 (Tx1/Tx2 after first/last activation) ---|
  v
SP_eMoney_Card_Monthly_Snapshot: DELETE WHERE SnapShotDateID + INSERT per EOM
  v
eMoney_dbo.eMoney_Card_Monthly_Snapshot (566M rows, 27 EOM snapshots 2024-01-31→2026-03-31, HASH(CID), HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot
```

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | CID, GCID |
| Tier 2 | 21 | All others (SnapShotDateID, SnapShotDate, SnapshotCountryID, SnapshotPlayerLevelID, SnapshotClub, SnapshotCountry, AccountSubProgram, FMI_Date, CardCreateDate, LastInstanceActivationDate, LastInstanceTxAfterActivationCount, FirstInstanceCreatedDate, FirstInstanceActivationDate, FirstTxAfterActivationCount, Tx1_AfterFirst, Tx2_AfterFirst, Tx1_AfterLast, Tx2_AfterLast, Country, Club, UpdateDate) |

*Tier 1: 2 | Tier 2: 21 | Total: 23*

# BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New_Blocked — Column Lineage

**Generated**: 2026-04-23 | **Phase**: 10B | **Writer SP**: SP_Client_Balance_CID_Level_New_Blocked

## ETL Chain

```
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New  (filter: Date=GETDATE()-2 AND dc.PlayerStatusReasonID=6)
  + DWH_dbo.Dim_Customer                      (PlayerStatusID, PlayerStatusReasonID)
  + DWH_dbo.Fact_SnapshotCustomer             (BlockedTime, BlockedReasonTime — MIN date for current status/reason)
  + DWH_dbo.Dim_Range + Dim_Date              (DateKey→FullDate for block timing)
  + DWH_dbo.Dim_PlayerStatus                  (not used in output; LEFT JOIN only — PlayerStatus already in base)
  + DWH_dbo.Dim_PlayerStatusReasons           (PlayerStatusReason = Name)
  + DWH_dbo.Dim_PlayerStatusSubReasons        (PlayerStatusSubReason = PlayerStatusSubReasonName)
    |-- SP_Client_Balance_CID_Level_New_Blocked (no @date param; TRUNCATE + INSERT) ---|
    v
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New_Blocked (5 rows in current run; snapshot of GETDATE()-2)
    |-- UC: _Not_Migrated ---|
    v
  (no downstream consumers identified)
```

## Column Lineage

### Passthrough Columns (from BI_DB_Client_Balance_CID_Level_New, first 121 columns)

All 121 base table columns are selected via explicit column list from `#active`, which reads from `BI_DB_Client_Balance_CID_Level_New WHERE Date = GETDATE()-2 AND dc.PlayerStatusReasonID=6`. No transform is applied — values are direct passthroughs.

**Frozen at SP creation date (2022-01-18)**: Columns added to `BI_DB_Client_Balance_CID_Level_New` after January 2022 (TRS crypto, futures, DLT, stocks margin, etc.) are NOT present in this table. The SP uses an explicit INSERT column list that does not include post-Jan-2022 additions.

| DWH Column | Source | Transform |
|---|---|---|
| Cols 1–121 (CID through UnrealizedFullCommissionChangeCFDCrypto) | BI_DB_Client_Balance_CID_Level_New | Direct passthrough, no transform — see base table wiki for lineage |

### New Columns (added by SP_Client_Balance_CID_Level_New_Blocked)

| DWH Column | Source | Source Column | Transform |
|---|---|---|---|
| PlayerStatusID | DWH_dbo.Dim_Customer | PlayerStatusID | Passthrough (joined on RealCID=CID in #active) |
| PlayerStatusReasonID | DWH_dbo.Dim_Customer | PlayerStatusReasonID | Passthrough (filter key: = 6) |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | Passthrough + rename (LEFT JOIN on PlayerStatusReasonID) |
| PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | Passthrough + rename (LEFT JOIN on c.PlayerStatusSubReasonID) |
| TimeBucket | Computed | — | CASE WHEN DATEDIFF(hours/days/months, BlockedTime, GETDATE()) with thresholds: Under 24h / Under 48h / 5 days / 10 days / 15 days / 1 month / 2 months / Over 2 Months |
| BlockedTime | DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_Date | FullDate | MIN(FullDate) where fsc.PlayerStatusID = current PlayerStatusID — first date in current block status |
| BlockedReasonTime | DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_Date | FullDate | MIN(FullDate) where fsc.PlayerStatusReasonID = current PlayerStatusReasonID — first date with current block reason |
| BlockedReasonBucket | Computed | — | Same thresholds as TimeBucket but using BlockedReasonTime as reference |
| UpdateDate | ETL runtime | — | GETDATE() |

## Tier Pre-Assignment

| Column Group | Pre-Tier |
|---|---|
| Cols 1–121 (base passthrough) | Tier 1 — verbatim from BI_DB_Client_Balance_CID_Level_New wiki |
| PlayerStatusID | Tier 2 (ETL passthrough from Dim_Customer; no upstream wiki column dedicated to this) |
| PlayerStatusReasonID | Tier 2 (ETL passthrough; filter key; no upstream wiki) |
| PlayerStatusReason | Tier 2 (JOIN-resolved name from Dim_PlayerStatusReasons) |
| PlayerStatusSubReason | Tier 2 (JOIN-resolved name from Dim_PlayerStatusSubReasons) |
| TimeBucket | Tier 2 (computed aging CASE expression) |
| BlockedTime | Tier 2 (MIN aggregate from Fact_SnapshotCustomer) |
| BlockedReasonTime | Tier 2 (MIN aggregate from Fact_SnapshotCustomer) |
| BlockedReasonBucket | Tier 2 (computed aging CASE expression) |
| UpdateDate | Propagation |

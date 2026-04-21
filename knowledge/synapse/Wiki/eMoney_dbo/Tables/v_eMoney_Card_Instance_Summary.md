---
object: v_eMoney_Card_Instance_Summary
schema: eMoney_dbo
database: Synapse DWH
type: View
cols: 17
base_table: eMoney_dbo.eMoney_Card_Instance_Summary
tier1_count: 3
tier1_pct: 17.6
quality_score: 9.1
adversarial_score: 9.1
upstream_wiki: eMoney_dbo/Tables/eMoney_Card_Instance_Summary.md (Batch 5, same session)
writer_sp: none
etl_pattern: View — real-time SELECT; no ETL
last_updated: 2026-04-19
batch: 5
---

# v_eMoney_Card_Instance_Summary

**Schema**: eMoney_dbo | **Database**: Synapse DWH | **Type**: View | **Cols**: 17 | **Base Table**: eMoney_dbo.eMoney_Card_Instance_Summary

Thin security wrapper view over `eMoney_Card_Instance_Summary`. Exposes all 17 non-sensitive columns of the base table; `MaskedPAN` is excluded from the view definition. Recommended query surface for card instance data for analysts and downstream consumers that do not require PAN data.

---

## 1. Object Summary

| Property | Value |
|----------|-------|
| **Object** | v_eMoney_Card_Instance_Summary |
| **Schema** | eMoney_dbo |
| **Database** | Synapse DWH |
| **Type** | View |
| **Columns** | 17 (excludes MaskedPAN from base table's 18) |
| **Base Table** | eMoney_dbo.eMoney_Card_Instance_Summary |
| **Writer SP** | None — SELECT-only view |
| **ETL Pattern** | Real-time SELECT; rows reflect base table as of last daily TRUNCATE + INSERT |
| **Excluded Column** | MaskedPAN (commented out in view DDL — PAN data protection) |
| **Tier 1 Coverage** | 3 / 17 (17.6%) — inherited from base table |
| **Quality Score** | 9.1 |

---

## 2. Source & Lineage

This view is a direct `SELECT` of 17 columns from `eMoney_dbo.eMoney_Card_Instance_Summary`. There are no joins, filters, aliases, or computed columns — the view adds no transformation logic beyond the exclusion of `MaskedPAN`.

**Base table documentation**: See `eMoney_Card_Instance_Summary.md` (Batch 5) for full ETL chain, column lineage, and business logic.

**MaskedPAN exclusion**: The base table stores `MaskedPAN` (masked card number, last digits only, from FiatDwhDB.dbo.FiatCardInstances). The view comments this column out as a data access control measure. Callers requiring MaskedPAN must query the base table directly, subject to appropriate permissions.

---

## 3. Sample Data

> MCP unavailable — live sampling skipped per prior-batch practice. View is a passthrough from eMoney_Card_Instance_Summary — see base table documentation for sample values.

---

## 4. Elements

All columns are direct passthroughs from `eMoney_Card_Instance_Summary`. Descriptions and tier assignments are inherited verbatim from the base table wiki.

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | bigint | YES | eToro trading platform customer ID (RealCID from Dim_Customer). Used as the Synapse HASH distribution key on the base table. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 2 | ProviderHolderID | bigint | YES | Provider-side holder identifier for this account (Tribe's holder ID). Passthrough from eMoney_Dim_Account.ProviderHolderID. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 3 | FMI_Date | date | YES | First Money In date. Date of the customer's first settled incoming transaction (TxStatusID=2) of type TransferReceived (TxTypeID=5) or PaymentReceived (TxTypeID=7) with non-zero HolderAmount. NULL if no qualifying incoming transaction. (Tier 2 — eMoney_Dim_Transaction) |
| 4 | DWH_CardID | bigint | YES | Auto-incrementing surrogate PK of the logical card in FiatCards. The most recent card associated with this account. Renamed from eMoney_Dim_Account.CardID (FiatDwhDB.dbo.FiatCards.Id). (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 5 | ProviderCardID | bigint | YES | Provider-side card identifier (Tribe's internal card ID). Passthrough from eMoney_Dim_Account.ProviderCardID. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 6 | CardCreateDate | date | YES | Date portion of CardCreateTime. ETL-derived CAST. Passthrough from eMoney_Dim_Account.CardCreateDate. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 7 | IsValidETM | int | YES | 1 if the customer qualifies as a valid eToro Money customer (IsValidCustomer=1 AND IsTestAccount=0 AND IsCancelledAccount=0), else 0. Primary filter for production analytics. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 8 | GCID_Unique_Count | int | YES | Row number within the customer partition (GCID) ordered by AccountCreateTime descending. 1 = the customer's most recently created currency balance. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 9 | DWH_CardInstanceId | bigint | YES | Auto-incrementing surrogate PK. Referenced by FiatCardStatuses.CardInstanceId. Renamed from FiatCardInstances.Id. (Tier 1 — FiatDwhDB.dbo.FiatCardInstances) |
| 10 | InstanceStatus | nvarchar(50) | YES | Current status of this card instance. ETL-computed as the most recent CardStatus label (TOP 1 ordered by EventTimestamp DESC) from FiatCardStatuses, resolved via eMoney_Dictionary_CardStatus. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 11 | InstanceCreatedDate | date | YES | Date the card instance was created (first status event, CardStatusId=0). ETL-computed as MIN(EventTimestamp WHERE CardStatusId=0) CAST to DATE. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 12 | InstanceActivationDate | date | YES | Date the card instance was activated (first activation event, CardStatusId=1). ETL-computed as MIN(EventTimestamp WHERE CardStatusId=1) CAST to DATE. NULL if not yet activated. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 13 | InstanceExpirationDate | date | YES | Expiration date of this card instance. NULL for instances where expiration is not yet set. Renamed from FiatCardInstances.CardExpirationDate; CAST to DATE. (Tier 1 — FiatDwhDB.dbo.FiatCardInstances) |
| 14 | StatusByHighestRNDasc | nvarchar(50) | YES | Status label of the most recently issued card instance for the parent CardID (highest activation-order rank = RNDasc). Enables card-level current status reporting across all historical instances. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 15 | NextActivationDateTime | datetime | YES | Activation datetime of the next card instance for the same DWH_CardID. NULL for the most recently issued instance. Used as the upper bound for TxAfterActivationCount. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 16 | TxAfterActivationCount | int | YES | Count of settled qualifying card transactions (TxTypeID IN 1,2,3,4) within this instance's active window. NULL when NextActivationDateTime IS NULL (current active instance). (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 17 | UpdateDate | datetime | NO | ETL load timestamp from the base table's last TRUNCATE + INSERT run. (Tier 2 — SP_eMoney_Card_Instance_Summary) |

---

## 5. Business Logic

This view adds no business logic. All derivations, filters, and transformations occur in `SP_eMoney_Card_Instance_Summary` before data reaches `eMoney_Card_Instance_Summary`. See the base table wiki for:
- Card instance lifecycle and RNDasc activation-order rank
- TxAfterActivationCount window logic (InstanceActivationDate → NextActivationDateTime)
- GCID_Unique_Count=1 filter behavior
- InstanceStatus computation from FiatCardStatuses

The sole function of this view is to exclude `MaskedPAN` from the visible column set.

---

## 6. Known Issues & Review Items

| # | Severity | Item |
|---|----------|------|
| 1 | Info | MaskedPAN exclusion is implemented by commenting out the column in the DDL (`-- [MaskedPAN]`), not by a WHERE clause or column masking policy. The base table `eMoney_Card_Instance_Summary` retains the full MaskedPAN value. Ensure base table access is restricted to authorized roles only. |
| 2 | Info | All known issues from the base table (`eMoney_Card_Instance_Summary`) apply to rows exposed through this view — see base table Known Issues section. |

---

## 7. Downstream Usage

| Object | Type | How Used |
|--------|------|----------|
| eMoney_Card_Instance_Summary | Table | Base table — this view is a direct SELECT from it |
| SP_eMoney_Card_Monthly_Snapshot | SP | Likely references the view (recommended surface) for card instance data; confirm whether SP references the view or the base table directly |

---

## 8. Change Log

| Date | Batch | Author | Notes |
|------|-------|--------|-------|
| 2026-04-19 | Batch 5 | DWH Wiki Pipeline | Initial documentation — view DDL read (23 lines); base table documented in same batch |

# Lineage: eMoney_dbo.eMoney_Card_Instance_Summary

**Generated**: 2026-04-21  
**Writer SP**: `eMoney_dbo.SP_eMoney_Card_Instance_Summary`  
**Load Pattern**: TRUNCATE + INSERT (full daily refresh)  
**Distribution**: HASH(CID), HEAP

---

## Source Objects

| Source | Type | Role |
|--------|------|------|
| CopyFromLake.FiatDwhDB_dbo_FiatCardInstances | External/CopyFromLake | Card instance records (MaskedPAN, expiration, IsVirtual) |
| eMoney_dbo.eMoney_Dim_Account | DWH Table | Customer identity (CID, ProviderHolderID, CardID, IsValidETM, GCID) — filter: GCID_Unique_Count=1 |
| eMoney_dbo.eMoney_Panel_FirstDates | DWH Table | FMI_Date milestone |
| eMoney_dbo.FiatCardStatuses | FiatDwhDB Mirror | Card status events (EventTimestamp per instance, CardStatusId) |
| eMoney_dbo.eMoney_Dictionary_CardStatus | DWH Dictionary | CardStatusId → CardStatus text decode |
| eMoney_dbo.eMoney_Dim_Transaction | DWH Table | Count of settled card TXs per instance lifespan |

---

## Column Lineage

| # | Synapse Column | Source DB | Source Schema | Source Table | Source Column | Transform | Tier |
|---|---------------|-----------|---------------|--------------|---------------|-----------|------|
| 1 | CID | etoro | Customer | CustomerStatic | CID | Passthrough via Dim_Customer → eMoney_Dim_Account | 1 |
| 2 | ProviderHolderID | FiatDwhDB | dbo | AccountsProviderHoldersMapping | ProviderHolderId | Rename; passthrough via eMoney_Dim_Account | 1 |
| 3 | FMI_Date | FiatDwhDB | dbo | FiatTransactions (eMoney_Dim_Transaction) | TxStatusModificationDate | MIN settled IN tx by ROW_NUMBER ASC (computed in eMoney_Panel_FirstDates) | 2 |
| 4 | DWH_CardID | FiatDwhDB | dbo | FiatCards | Id | Renamed (CardID → DWH_CardID); passthrough via eMoney_Dim_Account | 1 |
| 5 | ProviderCardID | FiatDwhDB | dbo | CardsProvidersMapping | ProviderCardId | Passthrough via eMoney_Dim_Account | 2 |
| 6 | CardCreateDate | FiatDwhDB | dbo | FiatCards | Created | CAST to DATE; via eMoney_Dim_Account.CardCreateDate | 2 |
| 7 | IsValidETM | ETL | — | eMoney_Dim_Account | IsValidETM | Composite flag passthrough (IsValidCustomer AND IsTestAccount=0 AND IsCancelledAccount=0) | 2 |
| 8 | GCID_Unique_Count | ETL | — | eMoney_Dim_Account | GCID_Unique_Count | Passthrough; SP JOIN filter ensures value is always 1 in this table | 2 |
| 9 | DWH_CardInstanceId | FiatDwhDB | dbo | FiatCardInstances | Id | Renamed (Id → DWH_CardInstanceId) | 1 |
| 10 | MaskedPAN | FiatDwhDB | dbo | FiatCardInstances | MaskedPAN | Passthrough; PII — last 4 digits visible | 1 |
| 11 | InstanceStatus | FiatDwhDB | dbo | FiatCardStatuses + Dictionary.CardStatuses | CardStatusId | JOIN decode via eMoney_Dictionary_CardStatus; newest status by EventTimestamp DESC (TOP 1) | 2 |
| 12 | InstanceCreatedDate | FiatDwhDB | dbo | FiatCardStatuses | EventTimestamp | CAST(MIN(EventTimestamp WHERE CardStatusId=0) AS DATE) — first NotActivated event = card issuance | 2 |
| 13 | InstanceActivationDate | FiatDwhDB | dbo | FiatCardStatuses | EventTimestamp | CAST(MIN(EventTimestamp WHERE CardStatusId=1) AS DATE) — first Activated event | 2 |
| 14 | InstanceExpirationDate | FiatDwhDB | dbo | FiatCardInstances | CardExpirationDate | CAST from datetime2 to DATE | 1 |
| 15 | StatusByHighestRNDasc | ETL | — | #Step4 (derived) | InstanceStatus | InstanceStatus of the most recent card instance per CardID (highest RNDasc) | 2 |
| 16 | NextActivationDateTime | ETL | — | #Step3 (derived) | InstanceActivationDateTime | MIN(InstanceActivationDateTime) of a later instance for same CID; NULL if this is the latest activated instance | 2 |
| 17 | TxAfterActivationCount | ETL | — | eMoney_Dim_Transaction | — | COUNT(*) of settled card TXs (IsValidETM=1, IsTxSettled=1, TxTypeID IN [1,2,3,4]) between this instance's ActivationDateTime and NextActivationDateTime | 2 |
| 18 | UpdateDate | ETL | — | — | — | GETDATE() at INSERT time | 2 |

---

## ETL Pipeline

```
FiatDwhDB.dbo.FiatCardInstances (card instances — PAN, expiration)
FiatDwhDB.dbo.FiatCardStatuses  (status events — activation timestamps)
  |-- CopyFromLake external tables ---|
  v
eMoney_dbo.FiatCardStatuses / CopyFromLake.FiatDwhDB_dbo_FiatCardInstances
  |-- SP_eMoney_Card_Instance_Summary (5-step temp table pipeline) ---|
  + eMoney_dbo.eMoney_Dim_Account (CID, ProviderHolderID, CardID, IsValidETM)
  + eMoney_dbo.eMoney_Panel_FirstDates (FMI_Date)
  + eMoney_dbo.eMoney_Dictionary_CardStatus (status decode)
  + eMoney_dbo.eMoney_Dim_Transaction (TxAfterActivationCount)
  v
eMoney_dbo.eMoney_Card_Instance_Summary (130,301 rows, HASH(CID), HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary
```

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 6 | CID, ProviderHolderID, DWH_CardID, DWH_CardInstanceId, MaskedPAN, InstanceExpirationDate |
| Tier 2 | 12 | FMI_Date, ProviderCardID, CardCreateDate, IsValidETM, GCID_Unique_Count, InstanceStatus, InstanceCreatedDate, InstanceActivationDate, StatusByHighestRNDasc, NextActivationDateTime, TxAfterActivationCount, UpdateDate |

*Tier 1 count: 6 columns | Tier 2: 12 columns | Total: 18*

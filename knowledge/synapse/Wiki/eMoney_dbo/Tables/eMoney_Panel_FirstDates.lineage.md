# Column Lineage — eMoney_dbo.eMoney_Panel_FirstDates

**Generated**: 2026-04-21
**Writer SP**: `SP_eMoney_Panel_FirstDates` (Steps 1–8)
**Primary Sources**: `eMoney_Dim_Account` (identity grain), `eMoney_Dim_Transaction` (all date/type/amount data)
**ETL Pattern**: DELETE + INSERT (full refresh daily)
**Filter**: `WHERE mda.GCID_Unique_Count = 1` — excludes multi-account GCIDs (added 2026-01-12 by Shachar Rubin)

---

## Column Lineage Summary

| Group | Column Range | Source | Transform | Tier |
|-------|-------------|--------|-----------|------|
| Identity | AccountID, GCID, CID | eMoney_Dim_Account | Passthrough (grain = one row per account) | Tier 1 |
| FMI | FMI_Date, FMI_Time, FMI_Source | eMoney_Dim_Transaction | ROW_NUMBER ASC on settled IN tx (TxTypeID IN [5,7], TxStatusID=2, HolderAmount≠0), row 1 only | Tier 2 |
| FMI seniority | Seniority_FMI | SP | DATEDIFF(MONTH, FMI_Date, @Date) | Tier 2 |
| FMO | FMO_Date, FMO_Time, FMO_Target, FMO_MOP | eMoney_Dim_Transaction | ROW_NUMBER ASC on settled OUT tx (TxTypeID IN [1-4,6,8,13], TxStatusID=2, HolderAmount≠0), row 1 | Tier 2 |
| FMO seniority | Seniority_FMO | SP | DATEDIFF(MONTH, FMO_Date, @Date) | Tier 2 |
| TX date aggregates | LastSettledTXDate, FirstIBANSettledTXDate, LastIBANSettledTXDate, FirstCardSettledTXDate, LastCardSettledTXDate | eMoney_Dim_Transaction | MIN/MAX(TxStatusModificationDate) by type group (IBAN=TxTypeID 5-8, Card=TxTypeID 1-4) | Tier 2 |
| TX seniority | Seniority_LastTXDate | SP | DATEDIFF(MONTH, LastSettledTXDate, @Date) | Tier 2 |
| Card activation | CardActivationTime | eMoney_Dim_Account | CASE WHEN CardStatusID=1 THEN CardStatusTime ELSE NULL END | Tier 2 |
| General actions 1-5 | [1st-5th]ActionDate/Type/USDApproxAmount | eMoney_Dim_Transaction | ROW_NUMBER ASC on all settled tx (TxStatusID=2, HolderAmount≠0); MAX(CASE WHEN RowNum=N THEN col) per account | Tier 2 |
| IBAN actions 1-5 | IBAN[1st-5th]ActionDate/Type/USDApproxAmount | eMoney_Dim_Transaction | ROW_NUMBER ASC on settled IBAN tx (TxTypeID IN [5,6,7,8]) | Tier 2 |
| Card actions 1-5 | Card[1st-5th]ActionDate/Type/USDApproxAmount | eMoney_Dim_Transaction | ROW_NUMBER ASC on settled Card tx (TxTypeID IN [1,2,3,4]) | Tier 2 |
| Metadata | UpdateDate | SP | GETDATE() | Tier 2 |

---

## Detailed Column Lineage (65 columns)

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | AccountID | eMoney_Dim_Account | AccountID | Passthrough (grain key) | Tier 1 |
| 2 | GCID | eMoney_Dim_Account | GCID | Passthrough | Tier 1 |
| 3 | CID | eMoney_Dim_Account | CID | Passthrough | Tier 1 |
| 4 | FMI_Date | eMoney_Dim_Transaction | TxStatusModificationDate | First settled IN tx (TxTypeID IN [5,7]) by ROW_NUMBER ASC | Tier 2 |
| 5 | Seniority_FMI | SP | — | DATEDIFF(MONTH, FMI_Date, @Date) | Tier 2 |
| 6 | FMI_Time | eMoney_Dim_Transaction | TxStatusModificationTime | First settled IN tx | Tier 2 |
| 7 | FMI_Source | SP | TxTypeID | CASE: 7=External (PaymentReceived), 5=TP (TransferReceived) | Tier 2 |
| 8 | FMO_Date | eMoney_Dim_Transaction | TxStatusModificationDate | First settled OUT tx (TxTypeID IN [1-4,6,8,13]) by ROW_NUMBER ASC | Tier 2 |
| 9 | Seniority_FMO | SP | — | DATEDIFF(MONTH, FMO_Date, @Date) | Tier 2 |
| 10 | FMO_Time | eMoney_Dim_Transaction | TxStatusModificationTime | First settled OUT tx | Tier 2 |
| 11 | FMO_Target | SP | TxTypeID | CASE: 6=TP (TransferReceived), others=External | Tier 2 |
| 12 | FMO_MOP | SP | TxTypeID | CASE: 1-4=Card, 6/8=IBAN, 13=DirectDebit | Tier 2 |
| 13 | LastSettledTXDate | eMoney_Dim_Transaction | TxStatusModificationDate | MAX(date) for all settled tx (TxStatusID=2, HolderAmount≠0) | Tier 2 |
| 14 | Seniority_LastTXDate | SP | — | DATEDIFF(MONTH, LastSettledTXDate, @Date) | Tier 2 |
| 15 | FirstIBANSettledTXDate | eMoney_Dim_Transaction | TxStatusModificationDate | MIN(date) WHERE TxTypeID IN (5,6,7,8) | Tier 2 |
| 16 | LastIBANSettledTXDate | eMoney_Dim_Transaction | TxStatusModificationDate | MAX(date) WHERE TxTypeID IN (5,6,7,8) | Tier 2 |
| 17 | CardActivationTime | eMoney_Dim_Account | CardStatusTime | CASE WHEN CardStatusID=1 THEN CardStatusTime ELSE NULL END | Tier 2 |
| 18 | FirstCardSettledTXDate | eMoney_Dim_Transaction | TxStatusModificationDate | MIN(date) WHERE TxTypeID IN (1,2,3,4) | Tier 2 |
| 19 | LastCardSettledTXDate | eMoney_Dim_Transaction | TxStatusModificationDate | MAX(date) WHERE TxTypeID IN (1,2,3,4) | Tier 2 |
| 20 | [1stActionDate] | eMoney_Dim_Transaction | TxStatusModificationDate | MAX(CASE WHEN RowNumASC=1) across all settled tx | Tier 2 |
| 21 | [1stActionType] | eMoney_Dim_Transaction | TxType | MAX(CASE WHEN RowNumASC=1) | Tier 2 |
| 22 | [1stActionUSDApproxAmount] | eMoney_Dim_Transaction | USDAmountApprox | MAX(CASE WHEN RowNumASC=1) — money type | Tier 2 |
| 23-37 | [2nd-5th]Action* | eMoney_Dim_Transaction | TxStatusModificationDate, TxType, USDAmountApprox | MAX(CASE WHEN RowNumASC=2-5) — same pattern | Tier 2 |
| 38-52 | IBAN[1st-5th]Action* | eMoney_Dim_Transaction | TxStatusModificationDate, TxType, USDAmountApprox | MAX(CASE WHEN RowNumASC=1-5) filtered to TxTypeID IN (5,6,7,8) | Tier 2 |
| 53-67 | Card[1st-5th]Action* | eMoney_Dim_Transaction | TxStatusModificationDate, TxType, USDAmountApprox | MAX(CASE WHEN RowNumASC=1-5) filtered to TxTypeID IN (1,2,3,4) | Tier 2 |
| 65 | UpdateDate | SP_eMoney_Panel_FirstDates | — | GETDATE() at insert | Tier 2 |

---

## ETL Pipeline

```
eMoney_Dim_Account (WHERE GCID_Unique_Count=1 — grain definition)
  + eMoney_Dim_Transaction (WHERE TxStatusID=2, HolderAmount≠0)
    → Step 1: #fmi — first settled IN tx (TxTypeID IN [5,7]) ROW_NUMBER ASC
    → Step 2: #fmo — first settled OUT tx (TxTypeID IN [1-4,6,8,13]) ROW_NUMBER ASC
    → Step 3: #transactions — MIN/MAX dates by IBAN/Card type groups
    → Step 4: #firstactions_general — top-5 settled tx (all types)
    → Step 5: #firstactions_iban — top-5 IBAN tx (TxTypeID IN [5,6,7,8])
    → Step 6: #firstactions_card — top-5 Card tx (TxTypeID IN [1,2,3,4])
    → Step 7: #final — JOIN all temp tables to eMoney_Dim_Account
    |-- SP_eMoney_Panel_FirstDates Step 8 (DELETE + INSERT, daily) ---|
    v
eMoney_dbo.eMoney_Panel_FirstDates (2,031,884 rows, HASH(CID) HEAP)
    |-- Generic Pipeline (Override, parquet, daily) ---|
    v
bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates
```

---

## Source Objects

| Object | Schema | Role |
|--------|--------|------|
| eMoney_Dim_Account | eMoney_dbo | Grain source — one row per eMoney account (GCID_Unique_Count=1) |
| eMoney_Dim_Transaction | eMoney_dbo | Transaction data — dates, types, amounts for all FMI/FMO/action derivations |
| SP_eMoney_Panel_FirstDates | eMoney_dbo | Writer SP |

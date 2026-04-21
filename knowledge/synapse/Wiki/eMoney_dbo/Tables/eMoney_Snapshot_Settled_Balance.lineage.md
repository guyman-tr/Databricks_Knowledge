# Lineage: eMoney_dbo.eMoney_Snapshot_Settled_Balance

**Generated**: 2026-04-21  
**Writer SP**: `eMoney_dbo.SP_eMoney_Snapshot_Settled_Balance`  
**Load Pattern**: TRUNCATE + INSERT (full daily refresh — yesterday's date only)  
**Distribution**: HASH(CID), HEAP

---

## Source Objects

| Source | Type | Role |
|--------|------|------|
| eMoney_dbo.eMoney_Dim_Account | DWH Table | Account identity (AccountID, GCID, CID, CurrencyBalanceISOCode) — grain driver |
| eMoney_dbo.eMoney_Dim_Transaction | DWH Table | Settled transactions (TxStatusID=2) — HolderAmount SUM/COUNT grouped by TxType category |
| eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static | DWH Table | Currency ISO code → text label (HolderBalanceCurrency) |
| DWH_dbo.Fact_CurrencyPriceWithSplit | DWH Fact | FX rate for USD approximation (USDApprox* columns) |

---

## Column Lineage

| # | Synapse Column | Source DB | Source Schema | Source Table | Source Column | Transform | Tier |
|---|---------------|-----------|---------------|--------------|---------------|-----------|------|
| 1 | DateID | ETL | — | — | — | YYYYMMDD integer from GETDATE()-1 at SP run time | 2 |
| 2 | AccountID | FiatDwhDB | dbo | FiatAccount | Id | Renamed; passthrough via eMoney_Dim_Account | 1 |
| 3 | GCID | FiatDwhDB | dbo | FiatAccount | Gcid | Passthrough via eMoney_Dim_Account | 1 |
| 4 | CID | etoro | Customer | CustomerStatic | CID | Passthrough via eMoney_Dim_Account | 1 |
| 5 | CurrencyBalanceISOCode | ETL | — | eMoney_Dim_Account | CurrencyBalanceISOCode | GROUP BY key — ISO 4217 numeric code per account | 2 |
| 6 | HolderBalanceCurrency | ETL | — | eMoney_Currency_Instrument_Mapping_Static | — | Text currency label lookup by ISO code; NULL for DKK (208) | 2 |
| 7 | HolderBalance | ETL | — | eMoney_Dim_Transaction | HolderAmount | SUM(HolderAmount WHERE TxStatusID=2) — cumulative settled balance | 2 |
| 8 | CountTxsHolderBalance | ETL | — | eMoney_Dim_Transaction | — | COUNT(*) of all settled transactions (TxStatusID=2) | 2 |
| 9 | TotalMI | ETL | — | eMoney_Dim_Transaction | HolderAmount | SUM(HolderAmount) WHERE HolderAmount > 0 (money-in) | 2 |
| 10 | CountTxsMI | ETL | — | eMoney_Dim_Transaction | — | COUNT(*) of money-in transactions | 2 |
| 11 | TotalMO | ETL | — | eMoney_Dim_Transaction | HolderAmount | SUM(HolderAmount) WHERE HolderAmount < 0 (money-out) | 2 |
| 12 | CountTxsMO | ETL | — | eMoney_Dim_Transaction | — | COUNT(*) of money-out transactions | 2 |
| 13 | CardTxMI | ETL | — | eMoney_Dim_Transaction | HolderAmount | SUM MI for card transaction TxTypeIDs; NULL if no card MI | 2 |
| 14 | CardTxMO | ETL | — | eMoney_Dim_Transaction | HolderAmount | SUM MO for card transaction TxTypeIDs; NULL if no card MO | 2 |
| 15 | IBANInMI | ETL | — | eMoney_Dim_Transaction | HolderAmount | SUM MI for IBAN incoming (bank→eTM) TxTypeIDs | 2 |
| 16 | IBANInMO | ETL | — | eMoney_Dim_Transaction | HolderAmount | SUM MO for IBAN incoming reversals; NULL if none | 2 |
| 17 | IBANOutMI | ETL | — | eMoney_Dim_Transaction | HolderAmount | SUM MI for IBAN outgoing reversals (returned to account); NULL if none | 2 |
| 18 | IBANOutMO | ETL | — | eMoney_Dim_Transaction | HolderAmount | SUM MO for IBAN outgoing (eTM→bank) TxTypeIDs | 2 |
| 19 | DirectDebitMI | ETL | — | eMoney_Dim_Transaction | HolderAmount | SUM MI for direct debit refunds/reversals; NULL if none | 2 |
| 20 | DirectDebitMO | ETL | — | eMoney_Dim_Transaction | HolderAmount | SUM MO for direct debit deductions; NULL if none (593 rows non-NULL) | 2 |
| 21 | OtherMI | ETL | — | eMoney_Dim_Transaction | HolderAmount | SUM MI for uncategorised TxTypeIDs; NULL if none (11,580 rows non-NULL) | 2 |
| 22 | OtherMO | ETL | — | eMoney_Dim_Transaction | HolderAmount | SUM MO for uncategorised TxTypeIDs; NULL if none | 2 |
| 23 | USDApproxDate | ETL | — | — | — | GETDATE()-1 (same as DateID) | 2 |
| 24 | USDApproxBalance | ETL | — | Fact_CurrencyPriceWithSplit | — | HolderBalance × USD FX rate for USDApproxDate; NULL for DKK | 2 |
| 25 | USDApproxTotalMI | ETL | — | Fact_CurrencyPriceWithSplit | — | TotalMI × USD FX rate; NULL for DKK | 2 |
| 26 | USDApproxTotalMO | ETL | — | Fact_CurrencyPriceWithSplit | — | TotalMO × USD FX rate; NULL for DKK | 2 |
| 27 | UpdateDate | ETL | — | — | — | GETDATE() at INSERT time | 2 |

---

## ETL Pipeline

```
eMoney_dbo.eMoney_Dim_Account (AccountID, GCID, CID, CurrencyBalanceISOCode — grain)
  + eMoney_dbo.eMoney_Dim_Transaction (settled TXs, TxStatusID=2 — HolderAmount SUM/COUNT by category)
  |-- SP Step 1: #accountbalance (account-level balance + MI/MO breakdown by TxType) ---|
  v
eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static (ISO code → currency text)
  + DWH_dbo.Fact_CurrencyPriceWithSplit (USD FX rate for GETDATE()-1)
  |-- SP Step 2: #final (adds CurrencyBalanceISOCode, HolderBalanceCurrency, USD approx columns) ---|
  v
SP_eMoney_Snapshot_Settled_Balance: TRUNCATE + INSERT (Date=GETDATE()-1)
  v
eMoney_dbo.eMoney_Snapshot_Settled_Balance (1,287,999 rows, 4 currencies, DateID=20260411, HASH(CID), HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance
```

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 3 | AccountID, GCID, CID |
| Tier 2 | 24 | All others (DateID, CurrencyBalanceISOCode, HolderBalanceCurrency, HolderBalance, CountTxsHolderBalance, TotalMI, CountTxsMI, TotalMO, CountTxsMO, CardTxMI, CardTxMO, IBANInMI, IBANInMO, IBANOutMI, IBANOutMO, DirectDebitMI, DirectDebitMO, OtherMI, OtherMO, USDApproxDate, USDApproxBalance, USDApproxTotalMI, USDApproxTotalMO, UpdateDate) |

*Tier 1: 3 | Tier 2: 24 | Total: 27*

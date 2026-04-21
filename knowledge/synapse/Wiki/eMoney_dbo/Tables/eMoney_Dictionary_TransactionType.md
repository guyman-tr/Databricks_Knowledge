# eMoney_dbo.eMoney_Dictionary_TransactionType

> 15-row lookup table mapping fiat transaction type identifiers to names for the eToro Money platform; sourced from FiatDwhDB.Dictionary.TransactionTypes via Generic Pipeline Bronze export. Covers all 15 types including CryptoToFiat (ID=14).

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dictionary) |
| **Production Source** | FiatDwhDB.Dictionary.TransactionTypes (Generic Pipeline Bronze export) |
| **Refresh** | Generic Pipeline (scheduled; matches FiatDwhDB update cadence) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **Row Count** | 15 (0=Unknown through 14=CryptoToFiat) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dictionary_TransactionType` is a lookup/reference table that defines the 15 valid transaction type values for the eToro Money fiat platform. Each row maps a `TransactionTypeID` integer to a human-readable type name. These types categorize every financial transaction flowing through eToro Money: card payments, IBAN transfers, fees, balance adjustments, direct debits, and the crypto-to-fiat bridge.

This dictionary is the foundational classification used by analysts and ETL SPs throughout the eMoney layer. The `eMoney_Calculated_Balance` SP groups these types into business-level buckets (CardActivity, Loads, Unloads, BankingPaymentsIN, BankingPaymentsOut, Fee, BalanceAdjustments, DirectDebit, Unknown, TBD). The full type map with 15 rows matches the FiatDwhDB source — no lag.

---

## 2. Business Logic

### 2.1 Transaction Type Enumeration

**What**: 15 distinct transaction types covering all eToro Money financial operations.

**Columns Involved**: `TransactionTypeID`, `TransactionType`

**Rules**:
- `0=Unknown` — unclassified transactions
- `1=CardPayment` — chip & signature card payment
- `2=Contactless` — tap-to-pay card transaction
- `3=OnlinePayment` — e-commerce/CNP card payment
- `4=CashWithdrawal` — ATM withdrawal
- `5=TransferReceived` — inbound IBAN transfer (= Money In / FMI)
- `6=Transfer` — outbound IBAN transfer (= Money Out / FMO)
- `7=PaymentReceived` — inbound banking payment (= Money In / FMI)
- `8=Payment` — outbound banking payment (= Money Out / FMO)
- `9=Refund` — card payment refund
- `10=Fee` — platform fee transaction
- `11=CreditBA` — credit bank account balance adjustment
- `12=DebitBA` — debit bank account balance adjustment
- `13=DirectDebit` — direct debit pull payment
- `14=CryptoToFiat` — crypto-to-fiat conversion credit (C2F bridge)

### 2.2 Analytical Groupings (from eMoney_Calculated_Balance)

**What**: SP_eMoney_Calculated_Balance maps these 15 types to 10 analytical categories.

**Rules**:
- `CardActivity`: [1, 2, 3, 4, 9] — all card-related transactions including refunds
- `Loads`: [5] — inbound TP transfers (FMI)
- `Unloads`: [6] — outbound TP transfers (FMO)
- `BankingPaymentsIN`: [7] — inbound banking payments (FMI)
- `BankingPaymentsOut`: [8] — outbound banking payments (FMO)
- `Fee`: [10] — platform fees
- `BalanceAdjustments`: [11, 12] — credit and debit BA adjustments
- `DirectDebit`: [13]
- `Unknown`: [0]
- `TBD`: [14, other] — CryptoToFiat and any unmapped types are TBD; not yet categorized in balance logic

### 2.3 FMI / FMO Definitions

**What**: The two key eMoney MIMO event categories.

**Rules**:
- **FMI (First Money In)**: `TxTypeID IN (5, 7) AND TxStatusID=2 AND HolderAmount<>0`
- **FMO (First Money Out)**: `TxTypeID IN (1, 2, 3, 4, 6, 8, 13) AND TxStatusID=2 AND HolderAmount<>0`
- Used in `SP_eMoney_Panel_FirstDates` and `SP_eMoney_Panel_Retention` for MIMO computation

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE — 15-row table broadcast to all distributions. Joins are data-local.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode transaction type | `JOIN eMoney_Dictionary_TransactionType t ON f.TransactionTypeID = t.TransactionTypeID` |
| Filter card transactions | `WHERE f.TransactionTypeID IN (1, 2, 3, 4, 9)` |
| Filter IBAN money-in | `WHERE f.TransactionTypeID IN (5, 7) AND f.TransactionStatusID = 2` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Fact_Transaction_Status | TransactionTypeID = TransactionTypeID | Decode all transaction type events |
| eMoney_Dim_Transaction | TransactionTypeID = TransactionTypeID | Decode latest transaction type |
| eMoney_Snapshot_Settled_Balance | (by type group) | Balance reconciliation by category |

### 3.4 Gotchas

- `14=CryptoToFiat` is classified as `TBD` in `eMoney_Calculated_Balance` — C2F transactions are not included in CardActivity, Loads, or Unloads yet. This creates a gap in the balance-by-category view
- `0=Unknown` should be rare in production; a spike in Unknown counts may indicate a new transaction type not yet classified
- `5=TransferReceived` and `7=PaymentReceived` are both FMI but on different rails (TP vs banking); combine them for total FMI
- `TxTypeID IN (1,2,3,4,9)` for CardActivity includes Refunds (9) — if you want net card spend, subtract refunds or filter `TxTypeID IN (1,2,3,4)`

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (FiatDwhDB) |
| Tier 2 | Derived from ETL SP code or DWH logic |
| Tier 3 | Inferred from column name and context |
| Tier 4 | Best available — limited confidence |
| Tier 5 | Glossary-sourced |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | TransactionTypeID | int | YES | Lookup identifier. Primary key. 0=Unknown, 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat. (Tier 1 — Dictionary.TransactionTypes) |
| 2 | TransactionType | varchar(50) | YES | Human-readable name for this value. 0=Unknown, 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat. (Tier 1 — Dictionary.TransactionTypes) |
| 3 | UpdateDate | datetime | YES | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| TransactionTypeID | FiatDwhDB.Dictionary.TransactionTypes | Id | Rename; tinyint→int widen |
| TransactionType | FiatDwhDB.Dictionary.TransactionTypes | Name | Rename; nvarchar→varchar(50) narrow |
| UpdateDate | ETL metadata | — | Populated by Generic Pipeline |

### 5.2 ETL Pipeline

```
FiatDwhDB.Dictionary.TransactionTypes (source — 15 rows: 0=Unknown through 14=CryptoToFiat)
  |-- Generic Pipeline (Bronze export) ---|
  v
Bronze parquet (ADLS Gen2 Data Lake)
  |-- External Table: External_FiatDwhDB_Dictionary_TransactionTypes ---|
  v
eMoney_dbo.eMoney_Dictionary_TransactionType (15 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype
```

---

## 6. Relationships

### 6.1 References To

This object has no outgoing foreign key references.

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| eMoney_Fact_Transaction_Status | TransactionTypeID | All transaction events carry type |
| eMoney_Dim_Transaction | TransactionTypeID | Latest-status transaction type |
| eMoney_Calculated_Balance | (grouped into buckets) | Pre-aggregated by type group |
| eMoney_Snapshot_Settled_Balance | (TxType category columns) | Balance by type category |
| eMoney_Panel_FirstDates | (FMI/FMO definitions) | FMI/FMO uses TypeID IN (5,7) / IN (1,2,3,4,6,8,13) |

---

## 7. Sample Queries

### 7.1 View all transaction type values
```sql
SELECT TransactionTypeID, TransactionType
FROM [eMoney_dbo].[eMoney_Dictionary_TransactionType]
ORDER BY TransactionTypeID;
```

### 7.2 Daily settled transaction volume by type (last 7 days)
```sql
SELECT t.TransactionType,
       COUNT(*) AS TxCount,
       SUM(f.HolderAmount) AS TotalHolderAmount
FROM [eMoney_dbo].[eMoney_Fact_Transaction_Status] f
JOIN [eMoney_dbo].[eMoney_Dictionary_TransactionType] t
    ON f.TransactionTypeID = t.TransactionTypeID
WHERE f.TransactionStatusID = 2  -- Settled
  AND f.OccurredDateID >= CONVERT(int, CONVERT(varchar, DATEADD(day,-7,GETDATE()), 112))
GROUP BY t.TransactionType
ORDER BY TxCount DESC;
```

### 7.3 FMI / FMO first-event check per customer
```sql
-- Customers with their first FMI and FMO dates
SELECT CID,
       MIN(CASE WHEN TransactionTypeID IN (5,7) THEN OccurredDate END) AS FirstFMI_Date,
       MIN(CASE WHEN TransactionTypeID IN (1,2,3,4,6,8,13) THEN OccurredDate END) AS FirstFMO_Date
FROM [eMoney_dbo].[eMoney_Fact_Transaction_Status]
WHERE TransactionStatusID = 2 AND HolderAmount <> 0
GROUP BY CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Transaction type definitions are documented in the FiatDwhDB upstream wiki.

---

T1 COPY VERIFICATION:
  TransactionTypeID: upstream "Lookup identifier. Primary key." → wiki "Lookup identifier. Primary key. 0=Unknown, 1=CardPayment, ... 14=CryptoToFiat." — IDENTICAL core (values from live data added)
  TransactionType: upstream "Human-readable name for this value." → wiki "Human-readable name for this value. 0=Unknown, ... 14=CryptoToFiat." — IDENTICAL core (values from live data added)

*Generated: 2026-04-20 | Quality: 9.3/10 | Phases: 7/14 (SIMPLE-DICT fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 10/10, Sources: 8/10*
*Object: eMoney_dbo.eMoney_Dictionary_TransactionType | Type: Table (Dictionary) | Production Source: FiatDwhDB.Dictionary.TransactionTypes*

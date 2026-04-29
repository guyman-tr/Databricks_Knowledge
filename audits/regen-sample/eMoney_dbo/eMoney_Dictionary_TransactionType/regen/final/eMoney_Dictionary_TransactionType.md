# eMoney_dbo.eMoney_Dictionary_TransactionType

> 15-row replicated lookup table mapping fiat transaction type identifiers (0=Unknown through 14=CryptoToFiat) to human-readable names for the eToro Money platform. Sourced from FiatDwhDB.Dictionary.TransactionTypes via Generic Pipeline Bronze export (Override, daily). All UpdateDate values static at 2023-06-12.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dictionary) |
| **Production Source** | FiatDwhDB.Dictionary.TransactionTypes (Generic Pipeline ID 524, server: prod-banking-fiat) |
| **Refresh** | Generic Pipeline Override, every 1440 min (~daily) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **Row Count** | 15 (0=Unknown through 14=CryptoToFiat) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dictionary_TransactionType` is a lookup/reference table that defines the 15 valid transaction type values for the eToro Money fiat platform. Each row maps a `TransactionTypeID` integer to a human-readable `TransactionType` name. These types categorize every financial transaction flowing through eToro Money: card payments (chip, contactless, online), ATM withdrawals, IBAN transfers, banking payments, fees, balance adjustments, direct debits, refunds, and the crypto-to-fiat bridge.

The dictionary is sourced 1:1 from `FiatDwhDB.Dictionary.TransactionTypes` via Generic Pipeline Bronze export. The 15 values (0 through 14) match the production source exactly. Nine eMoney SPs reference `TxTypeID` — most notably `SP_eMoney_Calculated_Balance`, which groups these 15 types into 10 analytical categories (CardActivity, Loads, Unloads, BankingPaymentsIN, BankingPaymentsOut, Fee, BalanceAdjustments, DirectDebit, Unknown, TBD). `SP_eMoney_Panel_FirstDates` uses type subsets to define FMI (First Money In) and FMO (First Money Out) events.

---

## 2. Business Logic

### 2.1 Transaction Type Enumeration

**What**: 15 distinct transaction types covering all eToro Money financial operations.

**Columns Involved**: `TransactionTypeID`, `TransactionType`

**Rules**:
- `0=Unknown` — unclassified transactions
- `1=CardPayment` — chip & signature card payment
- `2=Contactless` — tap-to-pay card transaction
- `3=OnlinePayment` — e-commerce / card-not-present payment
- `4=CashWithdrawal` — ATM withdrawal
- `5=TransferReceived` — inbound IBAN transfer
- `6=Transfer` — outbound IBAN transfer
- `7=PaymentReceived` — inbound banking payment
- `8=Payment` — outbound banking payment
- `9=Refund` — card payment refund
- `10=Fee` — platform fee transaction
- `11=CreditBA` — credit balance adjustment
- `12=DebitBA` — debit balance adjustment
- `13=DirectDebit` — direct debit pull payment
- `14=CryptoToFiat` — crypto-to-fiat conversion credit

### 2.2 Analytical Groupings (SP_eMoney_Calculated_Balance)

**What**: SP_eMoney_Calculated_Balance maps these 15 types to 10 analytical categories via CASE on `TxTypeID`.

**Rules** (verified from SP source code):
- `CardActivity`: TxTypeID IN (1, 2, 3, 4, 9) — all card-related transactions including refunds
- `Loads`: TxTypeID = 5 — inbound TP transfers
- `Unloads`: TxTypeID = 6 — outbound TP transfers
- `BankingPaymentsIN`: TxTypeID = 7 — inbound banking payments
- `BankingPaymentsOut`: TxTypeID = 8 — outbound banking payments
- `Fee`: TxTypeID = 10 — platform fees
- `BalanceAdjustments`: TxTypeID IN (11, 12) — credit and debit BA adjustments
- `DirectDebit`: TxTypeID = 13
- `Unknown`: TxTypeID = 0
- `TBD`: TxClientBalanceCategory = 'TBD' — CryptoToFiat (14) and any unmapped types fall here

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distribution — 15-row table broadcast to all compute nodes. All JOINs are data-local with zero data movement. HEAP storage (no clustered index needed for 15 rows).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode transaction type ID to name | `JOIN eMoney_dbo.eMoney_Dictionary_TransactionType t ON f.TransactionTypeID = t.TransactionTypeID` |
| Filter card transactions | `WHERE TransactionTypeID IN (1, 2, 3, 4, 9)` |
| Filter FMI (First Money In) | `WHERE TransactionTypeID IN (5, 7) AND TransactionStatusID = 2 AND HolderAmount <> 0` |
| Filter FMO (First Money Out) | `WHERE TransactionTypeID IN (1, 2, 3, 4, 6, 8, 13) AND TransactionStatusID = 2 AND HolderAmount <> 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Fact_Transaction_Status | TransactionTypeID = TransactionTypeID | Decode transaction type on all events |
| eMoney_Dim_Transaction | TransactionTypeID = TransactionTypeID | Decode latest transaction type |
| eMoney_Calculated_Balance | (grouped via TxTypeID CASE) | Pre-aggregated balance by type category |
| eMoney_Snapshot_Settled_Balance | (type category columns) | Settled balance by type category |

### 3.4 Gotchas

- `14=CryptoToFiat` is classified as `TBD` in SP_eMoney_Calculated_Balance — C2F transactions are not included in CardActivity, Loads, or Unloads. This creates a gap in the balance-by-category view
- `0=Unknown` should be rare in production; a spike in Unknown counts may indicate a new transaction type not yet classified
- `5=TransferReceived` and `7=PaymentReceived` are both FMI but on different rails (TP vs banking); combine them for total FMI
- `CardActivity` includes Refunds (TxTypeID=9) — for net card spend, filter `TxTypeID IN (1, 2, 3, 4)` excluding 9
- The dictionary uses `TxTypeID` in SPs but `TransactionTypeID` in this table — match on the correct column name when joining

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (FiatDwhDB.Dictionary.TransactionTypes) |
| Tier 2 | Derived from ETL SP code or DWH logic |
| Tier 3 | Inferred from column name and context |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | TransactionTypeID | int | YES | Lookup identifier. Primary key. 0=Unknown, 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat. (Tier 1 — Dictionary.TransactionTypes) |
| 2 | TransactionType | varchar(50) | YES | Human-readable name for this value. 0=Unknown, 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat. (Tier 1 — Dictionary.TransactionTypes) |
| 3 | UpdateDate | datetime | YES | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Currently static at 2023-06-12 across all 15 rows. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| TransactionTypeID | FiatDwhDB.Dictionary.TransactionTypes | Id | Rename Id→TransactionTypeID; type widen tinyint→int |
| TransactionType | FiatDwhDB.Dictionary.TransactionTypes | Name | Rename Name→TransactionType; type narrow nvarchar(32-50)→varchar(50) |
| UpdateDate | Generic Pipeline ETL | — | ETL metadata timestamp; populated by Generic Pipeline load process |

### 5.2 ETL Pipeline

```
FiatDwhDB.Dictionary.TransactionTypes (prod-banking-fiat, 15 rows: 0=Unknown through 14=CryptoToFiat)
  |-- Generic Pipeline (Bronze export, Override, parquet, every 1440 min) ---|
  v
Bronze parquet (ADLS Gen2: internal-sources@/Bronze/FiatDwhDB/Dictionary/TransactionTypes)
  |-- eMoney_Migration.eMoney_Dictionary_TransactionType (staging external table) ---|
  v
eMoney_dbo.eMoney_Dictionary_TransactionType (15 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype
```

---

## 6. Relationships

### 6.1 References To (this object points to)

This object has no outgoing foreign key references (leaf lookup table).

### 6.2 Referenced By (other objects point to this)

| Object | Column | Description |
|--------|--------|-------------|
| eMoney_Fact_Transaction_Status | TxTypeID | All transaction events carry the type identifier |
| eMoney_Dim_Transaction | TxTypeID | Latest-status transaction dimension |
| eMoney_Calculated_Balance | TxTypeID (CASE grouping) | Pre-aggregated balance by type category |
| eMoney_Snapshot_Settled_Balance | TxTypeID (category columns) | Settled balance by type category |
| eMoney_Panel_FirstDates | TxTypeID (FMI/FMO filter) | FMI: IN (5,7); FMO: IN (1,2,3,4,6,8,13) |
| eMoney_Customer_Risk_Assessment | TxTypeID | Risk assessment transaction type filter |
| eMoney_UserData_Marketing | TxTypeID | Marketing user data by transaction type |
| eMoney_Card_Monthly_Snapshot | TxTypeID | Card monthly snapshot by transaction type |
| eMoney_Card_Instance_Summary | TxTypeID | Card instance summary by transaction type |
| eMoney_Risk_Portfolio | TxTypeID | Risk portfolio transaction type filter |

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
WHERE f.TransactionStatusID = 2
  AND f.OccurredDateID >= CONVERT(int, CONVERT(varchar, DATEADD(day, -7, GETDATE()), 112))
GROUP BY t.TransactionType
ORDER BY TxCount DESC;
```

### 7.3 FMI / FMO first-event check per customer
```sql
SELECT CID,
       MIN(CASE WHEN TxTypeID IN (5, 7) THEN OccurredDate END) AS FirstFMI_Date,
       MIN(CASE WHEN TxTypeID IN (1, 2, 3, 4, 6, 8, 13) THEN OccurredDate END) AS FirstFMO_Date
FROM [eMoney_dbo].[eMoney_Fact_Transaction_Status]
WHERE TransactionStatusID = 2 AND HolderAmount <> 0
GROUP BY CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Transaction type definitions are documented in the FiatDwhDB upstream wiki (Dictionary.TransactionTypes).

---

T1 COPY VERIFICATION:
  TransactionTypeID: upstream "Lookup identifier. Primary key." → wiki "Lookup identifier. Primary key. 0=Unknown, ... 14=CryptoToFiat." — IDENTICAL core (inline values added per <=15 dictionary rule)
  TransactionType: upstream "Human-readable name for this value." → wiki "Human-readable name for this value. 0=Unknown, ... 14=CryptoToFiat." — IDENTICAL core (inline values added per <=15 dictionary rule)

*Generated: 2026-04-27 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 10/10, Sources: 8/10*
*Object: eMoney_dbo.eMoney_Dictionary_TransactionType | Type: Table (Dictionary) | Production Source: FiatDwhDB.Dictionary.TransactionTypes*

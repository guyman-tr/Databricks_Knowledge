# Billing.DepotToCurrency

> Depot-to-currency activity registry. Each row records that a specific payment depot supports a specific currency, tracking cumulative processed amount and last transaction date. 346 pairs; 241 active, 105 inactive.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (DepotID, CurrencyID) - NONCLUSTERED PK; CLUSTERED on CurrencyID |
| **Row Count** | 346 rows |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 CLUSTERED on CurrencyID; 1 NONCLUSTERED composite PK |

---

## 1. Business Meaning

`Billing.DepotToCurrency` records which currencies each payment depot can process, and tracks usage statistics. A depot may process multiple currencies (e.g., USD, EUR, GBP), and this table records the cumulative `ProcessedAmount` and `LastTransactionDate` for each (depot, currency) pair as a performance/activity tracker.

The `IsActive` flag marks whether this depot-currency pairing is currently enabled for new transactions (241 active, 105 inactive).

**Used in**: `Billing.DepositAdd` and `Billing.DepositProcess` reference this table to validate depot-currency routing, and to update `ProcessedAmount` and `LastTransactionDate` on deposit approval.

---

## 2. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **DepotID** | int | NOT NULL | - | Billing.Depot(DepotID) | [CODE-BACKED] Payment gateway ID; part of composite PK. |
| **CurrencyID** | int | NOT NULL | - | Dictionary.Currency(CurrencyID) | [CODE-BACKED] Currency for this depot pairing; part of composite PK. Also the CLUSTERED index key. |
| **ProcessedAmount** | money | NOT NULL | - | - | [CODE-BACKED] Cumulative amount processed through this depot-currency pair (in the currency's unit). Incremented on each approved deposit. |
| **LastTransactionDate** | datetime | NOT NULL | - | - | [CODE-BACKED] UTC timestamp of the last transaction through this depot-currency pair. Updated on each approved deposit. |
| **IsActive** | bit | NULL | - | - | [CODE-BACKED] Whether this depot-currency pair is active for new transactions. 241 true (69.7%), 105 false (30.3%). |

---

## 3. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_BD2C | NONCLUSTERED | (DepotID ASC, CurrencyID ASC) | FILLFACTOR=90. Logical PK. |
| BD2C_CURRENCY | CLUSTERED | CurrencyID ASC | Physical row ordering by currency - optimizes currency-first lookups. |

---

## 4. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.Depot | Many-to-one | DepotToCurrency.DepotID = Depot.DepotID | Explicit FK. |
| Dictionary.Currency | Many-to-one | DepotToCurrency.CurrencyID = Currency.CurrencyID | Explicit FK. |

---

*Quality: 8.9/10 | 5 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,3,5,11*

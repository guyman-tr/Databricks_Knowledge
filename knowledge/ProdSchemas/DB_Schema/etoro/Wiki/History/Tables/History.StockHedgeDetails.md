# History.StockHedgeDetails

> Audit log capturing each individual monetary transaction detail recorded during a stocks hedge operation, linking the hedge operation to the account and broker transaction ID.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | HedgeDetailsID (INT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

History.StockHedgeDetails is the per-transaction audit record for stock hedging operations executed by eToro's real-stocks (fractional equity) infrastructure. Each row represents one monetary leg of a hedge - an interaction with the broker or liquidity provider to buy/sell stock units on behalf of customers holding real stock positions.

This table exists to provide traceability and auditability for every hedge transaction amount. When the Stocks hedging engine executes a hedge operation (recorded in Stocks.Hedge / History.StocksHedge), the individual account-level monetary details are logged here so reconciliation, dispute resolution, and reporting can identify exactly what was transacted, on which account, and with which external transaction reference.

Data flows here exclusively through Stocks.SetHedgeDetails: the Stocks hedging engine calls this procedure after completing a hedge step, which simultaneously inserts into this table and updates the Stocks.HedgeAggregate running totals. This table is append-only - rows are never updated or deleted once written.

---

## 2. Business Logic

### 2.1 Hedge Operation Detail Recording

**What**: Each row records one monetary detail for a hedge operation - the amount transacted, the account used, and the broker's transaction reference.

**Columns/Parameters Involved**: `HedgeOperationID`, `HedgeAccountID`, `Amount`, `TransactionID`, `Notes`

**Rules**:
- One HedgeOperationID can have multiple detail rows (e.g., if a hedge is executed in tranches or across multiple accounts)
- Amount can be negative, representing a reversal or sell-back of previously hedged stock units
- HedgeAccountID in production is typically 1 (the single institutional hedge account)
- TransactionID is the external broker's reference for reconciliation - short codes like "10000" or "100003"
- Notes is an optional free-text field, populated only in exceptional circumstances (99.8% NULL in practice)

**Diagram**:
```
Stocks.Hedge (HedgeOperationID) <-- FK [implicit]
        |
        v
History.StockHedgeDetails (HedgeDetailsID)
  HedgeOperationID = parent operation
  HedgeAccountID   = institutional hedge account
  Amount           = monetary amount of this detail leg
  TransactionID    = broker transaction reference
  Notes            = optional remarks
        |
        v
Stocks.HedgeAggregate (running total updated atomically via SetHedgeDetails)
```

### 2.2 Atomic Insert + Aggregate Update

**What**: Stocks.SetHedgeDetails writes to this table and updates the running Stocks.HedgeAggregate total in a single transaction.

**Columns/Parameters Involved**: `HedgeOperationID`, `HedgeAccountID`, `Amount`, `TransactionID`

**Rules**:
- The INSERT and HedgeAggregate UPDATE are always wrapped in a transaction (begun if no outer transaction exists)
- This ensures that no hedge detail row exists without a corresponding aggregate update, and vice versa
- The aggregate is keyed by InstrumentID (passed by the caller), not by HedgeOperationID - so one instrument's total hedge is the running sum of all detail amounts

---

## 3. Data Overview

| HedgeDetailsID | HedgeOperationID | HedgeAccountID | Amount | TransactionID | Meaning |
|---|---|---|---|---|---|
| 2709 | 20920 | 1 | 0 | 100003 | Zero-amount detail - likely a rounding or no-fill step for the hedge operation; the TransactionID references broker leg "100003" |
| 2708 | 20813 | 1 | 1 | 100003 | Standard small-amount hedge detail; single unit transacted for operation 20813 |
| 2707 | 20708 | 1 | 1 | 10000 | Hedge detail for operation 20708 using broker transaction "10000" (alternate broker/routing) |
| 2705 | 20389 | 1 | 1 | 100003 | Standard hedge step - 1 unit for operation 20389 |
| 1 | (earliest) | 1 | (varies) | (varies) | First ever hedge detail - establishes that this table has been active since the launch of the real stocks hedging system |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeDetailsID | INT IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-incrementing surrogate primary key. IDENTITY NOT FOR REPLICATION ensures key generation does not conflict when the table is used as a replication target. Uniquely identifies each hedge transaction detail record. |
| 2 | HedgeOperationID | INT | NO | - | CODE-BACKED | References the parent hedge operation in Stocks.Hedge (HedgeOperationID). Groups detail rows under the broader hedge batch. Written by Stocks.SetHedgeDetails from @HedgeOperationID parameter. Most operations produce 1-2 detail rows; occasional batching produces more. |
| 3 | HedgeAccountID | INT | NO | - | CODE-BACKED | Identifies the institutional hedge account used for this transaction. In practice always = 1 (single institutional account), but the column is generic enough to support multiple hedge accounts. Passed by the Stocks engine via @HedgeAccountID. |
| 4 | Amount | MONEY | NO | - | CODE-BACKED | Monetary value of this hedge transaction leg, in the instrument's trading currency. Positive = buy/add hedge; negative = sell/reversal of previously hedged position. Ranges from -1,187 to 100,000 in current data. The Stocks.HedgeAggregate.TotalHedge is incremented by this value atomically. |
| 5 | TransactionID | VARCHAR(50) | NO | - | CODE-BACKED | External broker/exchange transaction reference code assigned by the liquidity provider for this hedge leg. Used for reconciliation between eToro's internal records and the broker's trade confirmations. Short numeric codes (e.g., "10000", "100003") in current data; length 50 accommodates longer future formats. |
| 6 | Notes | VARCHAR(MAX) | YES | NULL | CODE-BACKED | Optional free-text remarks about this hedge detail. Populated only in exceptional circumstances (99.8% NULL). Used for manual annotations such as error explanations or override justifications. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeOperationID | Stocks.Hedge | Implicit FK | Each detail row belongs to a hedge operation. Stocks.Hedge is the authoritative record for the hedge batch; this table stores per-leg details. |
| HedgeOperationID | History.StocksHedge | Implicit FK | History mirror of the hedge operation. The History schema pair (StocksHedge + StockHedgeDetails) preserves the full hedge audit trail. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Stocks.SetHedgeDetails | HedgeOperationID | Writer (INSERT) | Sole writer. Inserts one row per hedge detail and atomically updates Stocks.HedgeAggregate. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.StockHedgeDetails (table)
  (leaf - no code-level dependencies in CREATE TABLE DDL)
```

### 6.1 Objects This Depends On

No dependencies. The CREATE TABLE DDL has no explicit FK constraints, no UDTs, no computed columns, and no sequences.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Stocks.SetHedgeDetails | Stored Procedure | WRITER - sole inserter of rows into this table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_StockHedgeDetails | CLUSTERED PK | HedgeDetailsID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_StockHedgeDetails | PRIMARY KEY CLUSTERED | Enforces uniqueness on HedgeDetailsID; clustered for sequential insert performance (IDENTITY column) |

---

## 8. Sample Queries

### 8.1 Retrieve all detail records for a specific hedge operation
```sql
SELECT
    hd.HedgeDetailsID,
    hd.HedgeOperationID,
    hd.HedgeAccountID,
    hd.Amount,
    hd.TransactionID,
    hd.Notes
FROM History.StockHedgeDetails hd WITH (NOLOCK)
WHERE hd.HedgeOperationID = 20920
ORDER BY hd.HedgeDetailsID;
```

### 8.2 Summarize total hedged amount per operation
```sql
SELECT
    hd.HedgeOperationID,
    COUNT(*) AS DetailCount,
    SUM(hd.Amount) AS TotalAmount,
    MIN(hd.TransactionID) AS FirstTxID,
    MAX(hd.TransactionID) AS LastTxID
FROM History.StockHedgeDetails hd WITH (NOLOCK)
GROUP BY hd.HedgeOperationID
ORDER BY hd.HedgeOperationID DESC;
```

### 8.3 Join to parent hedge operation for full context
```sql
SELECT
    h.HedgeOperationID,
    h.InstrumentID,
    h.StartHedge,
    h.EndHedge,
    h.IsComplete,
    hd.HedgeDetailsID,
    hd.HedgeAccountID,
    hd.Amount,
    hd.TransactionID,
    hd.Notes
FROM History.StocksHedge h WITH (NOLOCK)
INNER JOIN History.StockHedgeDetails hd WITH (NOLOCK)
    ON h.HedgeOperationID = hd.HedgeOperationID
WHERE h.HedgeOperationID = 20920
ORDER BY hd.HedgeDetailsID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Stocks.SetHedgeDetails) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.StockHedgeDetails | Type: Table | Source: etoro/etoro/History/Tables/History.StockHedgeDetails.sql*

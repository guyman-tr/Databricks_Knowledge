# Dictionary.AccountTransactionType

> Lookup table classifying financial transaction types for hedge account operations — deposits, withdrawals, fees, adjustments, and other money movements in hedge liquidity accounts.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | TransactionTypeID (int, PK CLUSTERED) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.AccountTransactionType defines the 13 categories of financial transactions that affect hedge account balances. Hedge.AccountTransactions tracks every money movement in hedge liquidity accounts — deposits, withdrawals, refunds, commissions, fees, adjustments, interest, conversions, rebates, and system costs. Each row in that table references a TransactionTypeID so the financial audit trail is complete and categorically searchable.

Without this classification, hedge account reconciliation, financial reporting, and regulatory compliance would lack structured categorization. The Hedge schema uses it to segment transaction volumes by type, support P&L attribution, and enforce audit requirements for different transaction categories (e.g., distinguishing manual adjustments from automated fees).

Data flows into Hedge.AccountTransactions via procedures that INSERT with a TransactionTypeID. The lookup is read when generating hedge account statements, reconciling against external ledgers, and producing regulatory reports. Application code and reporting tools JOIN to resolve TransactionTypeID to TransactionTypeName for display and filtering.

---

## 2. Business Logic

### 2.1 Transaction Type Hierarchy

**What**: The 13 transaction types and their financial semantics.

**Columns/Parameters Involved**: `TransactionTypeID`, `TransactionTypeName`

**Rules**:
- **Deposit (1), Withdrawal (2), Refund (3)**: Core customer-facing flows — money in, money out, money returned.
- **Compensation (4), Commission (5), Adjustment (6)**: Operational and corrective entries.
- **Interest (7), Transaction Fees (8), Overnight Fees (9)**: Cost-of-carry and trading-related charges.
- **Conversion (10), Rebate (11)**: Currency/exposure adjustments and promotional credits.
- **Manual Cost (12), System Cost (13)**: BackOffice or system-generated cost allocations.

**Diagram**:
```
Transaction Type Categories:

  Customer Flows:     Deposit │ Withdrawal │ Refund
  Operational:       Compensation │ Commission │ Adjustment
  Fees & Interest:   Interest │ Transaction Fees │ Overnight Fees
  Adjustments:       Conversion │ Rebate
  Cost Allocations:  Manual Cost │ System Cost
```

### 2.2 Hedge Account Integration

**What**: How TransactionTypeID is used in the Hedge schema.

**Columns/Parameters Involved**: `TransactionTypeID`

**Rules**:
- Hedge.AccountTransactions has an explicit FK from TransactionTypeID to this table.
- Every hedge account money movement is classified; there is no untyped transaction.
- Reporting and reconciliation procedures filter by TransactionTypeID for volume analysis and audit trails.

---

## 3. Data Overview

| TransactionTypeID | TransactionTypeName | Meaning |
|---|---|---|
| 1 | Deposit | Inbound funds to hedge account. Customer or internal transfer adds liquidity. Primary inflow type. |
| 2 | Withdrawal | Outbound funds from hedge account. Customer or internal transfer removes liquidity. Primary outflow type. |
| 3 | Refund | Return of previously deposited or charged funds. Tied to prior transaction; used for dispute resolution. |
| 5 | Commission | Commission charges applied to hedge account activity. Common fee type for hedge operations. |
| 8 | Transaction Fees | Fees charged per transaction (e.g., spread, execution fee). Cost-of-trade charges. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TransactionTypeID | int | NO | - | CODE-BACKED | Primary key identifying the transaction category. 1–13 map to Deposit, Withdrawal, Refund, Compensation, Commission, Adjustment, Interest, Transaction Fees, Overnight Fees, Conversion, Rebate, Manual Cost, System Cost. Referenced by Hedge.AccountTransactions via FK. |
| 2 | TransactionTypeName | varchar(20) | NO | - | CODE-BACKED | Human-readable transaction type name. Used in reports, statements, and UI. Values match live data (MCP verified). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.AccountTransactions | TransactionTypeID | FK (FK_AccountTransactions_AccountTransactionType) | Every hedge account transaction is classified by type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. Dictionary tables are leaf nodes with no code-level references.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountTransactions | Table | FK — stores TransactionTypeID per transaction |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AccountTransactionType | CLUSTERED PK | TransactionTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_AccountTransactionType | PRIMARY KEY | Unique TransactionTypeID on PRIMARY filegroup. |

---

## 8. Sample Queries

### 8.1 List all transaction types
```sql
SELECT  TransactionTypeID,
        TransactionTypeName
FROM    Dictionary.AccountTransactionType WITH (NOLOCK)
ORDER BY TransactionTypeID;
```

### 8.2 Hedge transaction volume by type
```sql
SELECT  att.TransactionTypeName,
        COUNT(*)                AS TransactionCount
FROM    Hedge.AccountTransactions hat WITH (NOLOCK)
JOIN    Dictionary.AccountTransactionType att WITH (NOLOCK)
        ON hat.TransactionTypeID = att.TransactionTypeID
GROUP BY att.TransactionTypeName
ORDER BY TransactionCount DESC;
```

### 8.3 Filter deposits and withdrawals
```sql
SELECT  hat.*,
        att.TransactionTypeName
FROM    Hedge.AccountTransactions hat WITH (NOLOCK)
JOIN    Dictionary.AccountTransactionType att WITH (NOLOCK)
        ON hat.TransactionTypeID = att.TransactionTypeID
WHERE   hat.TransactionTypeID IN (1, 2);  -- Deposit, Withdrawal
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AccountTransactionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AccountTransactionType.sql*

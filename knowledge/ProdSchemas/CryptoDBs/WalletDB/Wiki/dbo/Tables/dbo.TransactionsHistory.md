# dbo.TransactionsHistory

> SCD Type 2 history table tracking every state change of blockchain transactions - from pending through confirmation, verification, error, or timeout.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, no PK constraint) |
| **Partition** | No |
| **Indexes** | 1 active (ix_TransactionsHistory CLUSTERED on EndDate, BeginDate) |

---

## 1. Business Meaning

This table is the temporal history of blockchain transaction status changes within the wallet system. Each blockchain transaction (identified by its on-chain hash) goes through multiple status states as it progresses from submission to confirmation on the blockchain. Every state change creates a new SCD Type 2 version, preserving the complete audit trail with precise timestamps.

Without this table, the system would lose visibility into how long transactions spent in each state and which transactions encountered errors or timeouts. The main Wallet schema tables hold only the current state; this history table enables debugging of delayed or stuck transactions and compliance reporting.

The table has 2,428 rows - relatively small compared to RedemptionsHistory (4.3M), suggesting it captures only a subset of transactions (possibly from early system operations or a specific transaction type). It follows the same SCD Type 2 temporal pattern as other dbo history tables.

---

## 2. Business Logic

### 2.1 Transaction Status Lifecycle

**What**: Each blockchain transaction progresses through a defined status lifecycle tracked as temporal versions.

**Columns/Parameters Involved**: `Id`, `Status`, `BeginDate`, `EndDate`

**Rules**:
- Status values from Dictionary.TransactionStatus: 0=Pending, 1=Confirmed, 2=Verified, 3=Error, 4=Timeout, 5=PermanentError, 6=WavedError
- Normal flow: 0 (Pending) -> 1 (Confirmed) -> 2 (Verified)
- Error flow: 0 (Pending) -> 3 (Error) or 4 (Timeout)
- Error recovery: 3 (Error) -> 0 (Pending) retry observed in sample data

**Diagram**:
```
Status lifecycle:
  0 (Pending) --> 1 (Confirmed) --> 2 (Verified)  [happy path]
  0 (Pending) --> 3 (Error)                         [blockchain error]
  0 (Pending) --> 4 (Timeout)                       [no confirmation in time]
  3 (Error)   --> 0 (Pending)                       [retry after error]

Distribution: 0=1091, 1=419, 2=771, 3=96, 4=51
```

---

## 3. Data Overview

| Id | RequestGuid | BlockchainTransactionId | WalletId | Status | BeginDate | EndDate | Meaning |
|---|---|---|---|---|---|---|---|
| 1 | C8C3D1CD-... | 0e20632a... | D3CB0CA4-... | 0 | 2018-04-23 12:05 | 2018-04-23 12:33 | Transaction pending blockchain confirmation for ~28 minutes |
| 1 | C8C3D1CD-... | 0e20632a... | D3CB0CA4-... | 3 | 2018-04-23 12:33 | 2018-04-23 12:45 | Transaction hit an error after 28 minutes - blockchain returned error |
| 1 | C8C3D1CD-... | 0e20632a... | D3CB0CA4-... | 0 | 2018-04-23 12:45 | 2018-04-23 12:54 | Retried - back to Pending after error recovery |
| 1 | C8C3D1CD-... | 0e20632a... | D3CB0CA4-... | 4 | 2018-04-23 12:54 | 2018-04-23 12:58 | Timed out on retry - transaction ultimately failed |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Transaction record identifier. Groups all temporal versions of the same transaction. Multiple rows share the same Id with different Status values and BeginDate/EndDate ranges. |
| 2 | RequestGuid | uniqueidentifier | NO | - | CODE-BACKED | Unique GUID for the transaction request. Used for end-to-end correlation across the wallet system and external blockchain provider APIs. |
| 3 | BlockchainTransactionId | nvarchar(100) | NO | - | CODE-BACKED | On-chain transaction hash. The blockchain-native identifier (e.g., Bitcoin txid, Ethereum tx hash) that uniquely identifies this transaction on the public ledger. |
| 4 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | Internal wallet identifier. References the customer wallet involved in this transaction. Links to the Wallet schema's wallet records. |
| 5 | Status | tinyint | NO | - | VERIFIED | Transaction processing status: 0=Pending (awaiting blockchain confirmation), 1=Confirmed (blockchain confirmed), 2=Verified (internally verified after confirmation), 3=Error (blockchain or provider error), 4=Timeout (no confirmation within time limit), 5=PermanentError, 6=WavedError. (Dictionary.TransactionStatus) |
| 6 | BeginDate | datetime2(7) | NO | - | CODE-BACKED | SCD Type 2 version start timestamp. When this status version became effective. |
| 7 | EndDate | datetime2(7) | NO | - | CODE-BACKED | SCD Type 2 version end timestamp. When the next status transition occurred. |
| 8 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Optional correlation ID linking this transaction to a higher-level business operation (e.g., a redemption or conversion). NULL for standalone transactions or older records. |
| 9 | TransactionTypeId | tinyint | YES | - | CODE-BACKED | Transaction type classifier. Maps to Dictionary.TransactionTypes: 0=Redeem, 1=CustomerMoneyOut, 4=Funding, etc. NULL for older records predating this column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Status | Dictionary.TransactionStatus | Lookup | Transaction status: 0=Pending through 6=WavedError |
| TransactionTypeId | Dictionary.TransactionTypes | Implicit | Transaction type (0=Redeem, 1=CustomerMoneyOut, etc.) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in dbo schema code scan.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_TransactionsHistory | CLUSTERED | EndDate, BeginDate | - | - | Active |

Data compression: PAGE.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Full status history for a transaction
```sql
SELECT Id, RequestGuid, Status, BeginDate, EndDate,
       DATEDIFF(SECOND, BeginDate, EndDate) AS DurationSec
FROM dbo.TransactionsHistory WITH (NOLOCK)
WHERE Id = 1
ORDER BY BeginDate
```

### 8.2 Find timed-out transactions
```sql
SELECT Id, RequestGuid, BlockchainTransactionId, WalletId, BeginDate
FROM dbo.TransactionsHistory WITH (NOLOCK)
WHERE Status = 4
ORDER BY BeginDate DESC
```

### 8.3 Transaction status distribution with readable names
```sql
SELECT ts.Name AS Status, COUNT(*) AS Cnt
FROM dbo.TransactionsHistory th WITH (NOLOCK)
JOIN Dictionary.TransactionStatus ts WITH (NOLOCK) ON ts.Id = th.Status
GROUP BY ts.Name
ORDER BY Cnt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 7.4/10 (Elements: 8.9/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.TransactionsHistory | Type: Table | Source: WalletDB/dbo/Tables/dbo.TransactionsHistory.sql*

# Wallet.GetReceivedTransactionList

> Multi-statement table-valued function returning a customer's received (inbound) transaction history with Travel Rule compliance status, filtered by crypto, date range, and optional staking-only mode.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Multi-Statement Table-Valued Function |
| **Key Identifier** | Returns table (Id, CorrelationId, BeginDate, Amount, Status, BlockchainTransactionId, Address, TransactionType, TravelRuleRequired, TravelRuleStatus) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetReceivedTransactionList is one of the core transaction list functions used by the wallet API to return a customer's inbound (received) cryptocurrency transaction history. It queries `Wallet.ReceivedTransactions` for a specific customer and crypto, enriching each result with a simplified status code, travel rule compliance information, and transaction type classification.

This function exists because the raw received transaction data requires substantial business logic to present correctly to end users: status codes must be simplified, internal transfers (conversions, payments) must be excluded, XRP account activation transactions must be hidden, and Travel Rule regulatory metadata must be attached. Centralizing this logic in a TVF ensures consistent results across all consumers.

Called by `Wallet.GetTransactionList`, `Wallet.GetTransactionListV2`, `Wallet.GetTransactionList_temp`, and `Staking.GetStakingRecordsList`. These stored procedures aggregate multiple transaction types (sent, received, conversion, payment, staking) into a unified transaction history for the wallet UI.

---

## 2. Business Logic

### 2.1 Status Simplification

**What**: Maps internal received transaction statuses to a simplified 4-value scheme for the API.

**Columns/Parameters Involved**: `Status` (output), `ReceivedTransactionStatuses.StatusId`

**Rules**:
- StatusId 0 (Pending) or 3 (Error) -> Simplified 0 (Pending/In Progress)
- StatusId 1 (Confirmed) -> 1 (Confirmed on blockchain)
- StatusId 2 (Verified) -> 2 (Fully verified and credited)
- All other StatusId values -> 3 (Other/Unknown)

**Diagram**:
```
ReceivedTransactionStatuses.StatusId:
  0 (Pending) -----> 0 (Pending)
  1 (Confirmed) ---> 1 (Confirmed)
  2 (Verified) ----> 2 (Verified)
  3 (Error) -------> 0 (Pending)  -- errors shown as pending, not exposed to user
  Other -----------> 3 (Other)
```

### 2.2 XRP First Transaction Exclusion

**What**: Hides the account activation transaction for XRP wallets (CryptoId=4).

**Columns/Parameters Involved**: `@CryptoId`, `ReceivedTransactions.Id`, `ReceivedTransactions.WalletId`

**Rules**:
- When `@CryptoId = 4` (XRP), the earliest received transaction per wallet+address combination is excluded
- This is the XRP account activation deposit (minimum reserve of 10 XRP) which is a protocol requirement, not a user-initiated deposit
- For all other cryptocurrencies, no transactions are excluded by this rule

### 2.3 Internal Transfer Exclusion

**What**: Filters out received transactions that are the result of internal wallet operations (conversions and payments).

**Columns/Parameters Involved**: `ReceivedTransactions.BlockchainTransactionId`, `SentTransactions.BlockchainTransactionId`

**Rules**:
- Excludes any received transaction whose `BlockchainTransactionId` matches a `SentTransactions` record that is linked to a `Wallet.Conversions` entry (internal crypto-to-crypto swap)
- Excludes any received transaction whose `BlockchainTransactionId` matches a `SentTransactions` record that is linked to a `Wallet.Payments` entry (internal fiat payment flow)
- These are NOT external user deposits - they are internal platform transfers that appear on the blockchain but should not be shown as "received" in the user's transaction list

### 2.4 Staking Filter

**What**: Optional mode to return only staking distribution transactions.

**Columns/Parameters Involved**: `@IsStakingOnly`, `ReceivedTransactionTypeId`

**Rules**:
- When `@IsStakingOnly = 1`: only transactions with `ReceivedTransactionTypeId = 8` (staking distribution) are returned, and only if their status is 2 (Verified)
- When `@IsStakingOnly = 0`: all transaction types are returned (normal + staking)
- Staking distributions that are not yet verified (status != 2) are hidden even in staking-only mode

### 2.5 Travel Rule Compliance

**What**: Attaches regulatory Travel Rule information to transactions that require it.

**Columns/Parameters Involved**: `TravelRuleRequired`, `TravelRuleStatus`

**Rules**:
- LEFT JOINs `TransactionTravelRuleInformation` on `ReceiveRequestCorrelationId = RequestCorrelationId`
- If a Travel Rule record exists: `TravelRuleRequired = 1`, `TravelRuleStatus` = latest status name from `TransactionTravelRuleStatuses` via `Dictionary.TravelRuleStatuses`
- If no Travel Rule record: `TravelRuleRequired = 0`, `TravelRuleStatus = ''`

---

## 3. Data Overview

N/A for table-valued function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID. Filters to wallets owned by this customer via JOIN to `Wallet.CustomerWalletsView`. |
| 2 | @CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency ID (FK to Wallet.CryptoTypes). Filters received transactions to a specific crypto. Also triggers XRP-specific logic when value is 4. |
| 3 | @BeginDateAfter | datetime2(7) | YES | - | CODE-BACKED | Start of date range filter on `BlockchainTransactionDate`. NULL means no lower bound (defaults to '2000-01-01'). |
| 4 | @BeginDateBefore | datetime2(7) | YES | - | CODE-BACKED | End of date range filter on `BlockchainTransactionDate`. NULL means no upper bound (defaults to '2100-01-01'). |
| 5 | @RecordsLimit | int | YES | 10000 | CODE-BACKED | Maximum number of transactions to return. Applied as TOP(@RecordsLimit) on the inner query, ordered by date DESC (most recent first). |
| 6 | @IsStakingOnly | bit | YES | 0 | CODE-BACKED | When 1, returns only staking distribution transactions (ReceivedTransactionTypeId=8) that are verified (status=2). When 0, returns all types. |
| 7 | Id | bigint | NO | - | CODE-BACKED | ReceivedTransactions.Id - unique identifier for the received transaction record. |
| 8 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Request correlation ID from ReceivedTransactions. Links the received transaction to the originating request for end-to-end tracing. |
| 9 | BeginDate | datetime2(7) | YES | - | CODE-BACKED | Mapped from `ReceivedTransactions.BlockchainTransactionDate`. The timestamp when the transaction was recorded on the blockchain. |
| 10 | Amount | decimal(36,18) | YES | - | CODE-BACKED | The amount of cryptocurrency received in this transaction. Precision to 18 decimals supports all crypto denominations. |
| 11 | Status | int | YES | - | CODE-BACKED | Simplified status: 0=Pending/Error (in progress), 1=Confirmed (on blockchain), 2=Verified (fully credited), 3=Other. See Section 2.1. |
| 12 | BlockchainTransactionId | nvarchar(100) | YES | - | CODE-BACKED | The on-chain transaction hash/ID. Used for blockchain explorer lookups and for internal transfer exclusion logic. |
| 13 | Address | nvarchar(1024) | YES | - | CODE-BACKED | Mapped from `ReceivedTransactions.SenderAddress`. The blockchain address that sent the funds to the customer's wallet. |
| 14 | TransactionType | int | YES | - | CODE-BACKED | Transaction type: 1=normal receive, 8=staking distribution. Derived from `ReceivedTransactionTypeId` - type 8 is mapped to 8, all others map to 1. |
| 15 | TravelRuleRequired | bit | YES | - | CODE-BACKED | 1 if a Travel Rule information record exists for this transaction's receive request correlation, 0 otherwise. Indicates regulatory compliance tracking is active. |
| 16 | TravelRuleStatus | varchar(64) | YES | - | CODE-BACKED | Current Travel Rule status name from `Dictionary.TravelRuleStatuses` (e.g., 'Pending', 'Completed', 'Failed'). Empty string if no Travel Rule record exists. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.ReceivedTransactions | FROM | Primary data source - received transaction records |
| @Gcid, @CryptoId | Wallet.CustomerWalletsView | JOIN | Filters to wallets owned by the specified customer and crypto |
| - | Wallet.WalletAddresses | JOIN | Matches on NormalizedAddress to link received transactions to wallet addresses |
| - | Wallet.ReceivedTransactionStatuses | JOIN | Gets the latest status for each received transaction |
| - | Wallet.SentTransactions | NOT EXISTS | Exclusion - identifies internal transfers to filter out |
| - | Wallet.Conversions | NOT EXISTS | Exclusion - identifies conversion-related internal transfers |
| - | Wallet.Payments | NOT EXISTS | Exclusion - identifies payment-related internal transfers |
| - | Wallet.TransactionTravelRuleInformation | LEFT JOIN | Travel Rule regulatory data for compliance tracking |
| - | Wallet.TransactionTravelRuleStatuses | CTE subquery | Gets the latest Travel Rule status per information record |
| - | Dictionary.TravelRuleStatuses | JOIN | Resolves numeric Travel Rule status ID to human-readable name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetTransactionList | - | CROSS APPLY | Calls to get received transactions as part of unified transaction history |
| Wallet.GetTransactionListV2 | - | CROSS APPLY | V2 variant of unified transaction list |
| Wallet.GetTransactionList_temp | - | CROSS APPLY | Temp/development variant |
| Staking.GetStakingRecordsList | - | CROSS APPLY | Uses this function for staking-related received transactions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetReceivedTransactionList (function)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.ReceivedTransactionStatuses (table)
+-- Wallet.CustomerWalletsView (view)
|     +-- Wallet.Wallets (table)
|     +-- Wallet.WalletAddresses (table)
+-- Wallet.WalletAddresses (table)
+-- Wallet.SentTransactions (table)
+-- Wallet.Conversions (table)
+-- Wallet.Payments (table)
+-- Wallet.TransactionTravelRuleInformation (table)
+-- Wallet.TransactionTravelRuleStatuses (table)
+-- Dictionary.TravelRuleStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactions | Table | FROM - primary data source for received transactions |
| Wallet.ReceivedTransactionStatuses | Table | JOIN - latest status lookup |
| Wallet.CustomerWalletsView | View | JOIN - customer wallet ownership filter |
| Wallet.WalletAddresses | Table | JOIN - address matching via NormalizedAddress |
| Wallet.SentTransactions | Table | NOT EXISTS - internal transfer detection |
| Wallet.Conversions | Table | NOT EXISTS - conversion transfer exclusion |
| Wallet.Payments | Table | NOT EXISTS - payment transfer exclusion |
| Wallet.TransactionTravelRuleInformation | Table | LEFT JOIN - Travel Rule compliance data |
| Wallet.TransactionTravelRuleStatuses | Table | CTE - latest Travel Rule status |
| Dictionary.TravelRuleStatuses | Table | JOIN - Travel Rule status name resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetTransactionList | Stored Procedure | Calls to include received transactions in unified history |
| Wallet.GetTransactionListV2 | Stored Procedure | V2 variant |
| Wallet.GetTransactionList_temp | Stored Procedure | Temp variant |
| Staking.GetStakingRecordsList | Stored Procedure | Staking received transactions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for table-valued function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all BTC received transactions for a customer
```sql
SELECT * FROM Wallet.GetReceivedTransactionList(30351701, 1, NULL, NULL, 100, 0)
ORDER BY BeginDate DESC
```

### 8.2 Get staking distributions only for ADA
```sql
SELECT * FROM Wallet.GetReceivedTransactionList(30351701, 18, NULL, NULL, 100, 1)
```

### 8.3 Date-filtered received transactions with Travel Rule info
```sql
SELECT
    Id, CorrelationId, BeginDate, Amount, Status,
    BlockchainTransactionId, Address, TransactionType,
    TravelRuleRequired, TravelRuleStatus
FROM Wallet.GetReceivedTransactionList(30351701, 1, '2026-01-01', '2026-04-01', 50, 0)
WHERE TravelRuleRequired = 1
ORDER BY BeginDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetReceivedTransactionList | Type: Table-Valued Function | Source: WalletDB/Wallet/Functions/Wallet.GetReceivedTransactionList.sql*

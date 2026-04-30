# Wallet.GetStakingTransactionListV2

> Returns a paginated list of crypto staking transactions for a customer wallet (V2 API variant), with identical logic to V1 including provider staking address, fee breakdown, and crypto name lookup.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Multi-Statement TVF |
| **Key Identifier** | Returns one row per staking request (CorrelationId / RecordId) |

---

## 1. Business Meaning

`GetStakingTransactionListV2` is the versioned successor to `GetStakingTransactionList`, serving the V2 wallet API's staking transaction history endpoint. It presents customers with a complete history of their crypto staking operations — the locking of cryptocurrency with a staking provider to earn yield — including the current status, blockchain fee, and external provider address.

As with other V2 function variants in this codebase, the function was forked from V1 to create an isolated code path for the V2 API, allowing the two versions to diverge independently as product requirements evolve. At the time of creation the SQL body is functionally identical to V1: the same three CTEs (Requests, Stakings, Transactions), the same `COALESCE(r.Status, s.Status, 3)` status priority, the same hardcoded zeros for fee fields, and the same `Wallet.CryptoTypes` JOIN for crypto name. The `@FromBackOffice` parameter is accepted but unused in both versions.

---

## 2. Business Logic

Identical to `GetStakingTransactionList`:

- **`Requests`** — Top `@RecordsLimit` rows from `Wallet.Requests` for `RequestTypeId = 6`, ordered by `Timestamp DESC`. `CryptoId` and `Amount` parsed via `JSON_VALUE`. Status: `3` (Error) or NULL. Error JSON validated via `ISJSON`.
- **`Stakings`** — `Staking.Staking` LEFT JOINed to `Staking.StakingTransactions` and resolved latest status via `OUTER APPLY TOP 1`. Status: Completed→2, Failed→3, Pending/other→0. Fee fields: 0.
- **`Transactions`** — `Wallet.SentTransactions` aggregated for TX ID and fee.

**Final SELECT**: LEFT JOIN Requests→Stakings→Transactions, INNER JOIN `Wallet.CryptoTypes`. `COALESCE(r.Status, s.Status, 3)` for status. `TransactionType = 5`.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

### Parameters (IN)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `@Gcid` | BIGINT | required | Customer global customer ID |
| `@CryptoId` | INT | required | Filter by crypto (NULL = all) |
| `@BeginDateAfter` | DATETIME2(7) | required | Inclusive lower bound on request timestamp (NULL = 2000-01-01) |
| `@BeginDateBefore` | DATETIME2(7) | required | Exclusive upper bound on request timestamp (NULL = 2100-01-01) |
| `@RecordsLimit` | INT | 10000 | Maximum rows returned |
| `@FromBackOffice` | BIT | 0 | Accepted for API symmetry; currently unused in query logic |

### Return Columns (OUT)

| Column | Type | Description |
|--------|------|-------------|
| `CorrelationId` | UNIQUEIDENTIFIER | Cross-system correlation key |
| `RecordId` | INT | Request ID from Wallet.Requests |
| `BeginDate` | DATETIME2(7) | Timestamp the staking request was initiated |
| `Amount` | DECIMAL(36,18) | Crypto amount staked |
| `Status` | INT | 0=Pending, 2=Completed, 3=Failed/Error |
| `BlockChainTransactionId` | NVARCHAR(100) | On-chain transaction ID |
| `Address` | NVARCHAR(1024) | External staking provider address |
| `TransactionType` | INT | Hardcoded to 5 (staking) |
| `BlockchainFees` | DECIMAL(36,18) | Actual or estimated blockchain fee |
| `CryptoId` | INT | Crypto asset ID |
| `CryptoName` | VARCHAR(20) | Crypto asset name (from CryptoTypes) |
| `EtoroFeePercentage` | DECIMAL(36,18) | Hardcoded to 0 |
| `EtoroFeeCalculated` | DECIMAL(36,18) | Hardcoded to 0 |
| `ProviderFeePercentage` | DECIMAL(36,18) | Hardcoded to 0 |
| `ProviderFeeCalculated` | DECIMAL(36,18) | Hardcoded to 0 |
| `InitiationTime` | DATETIME2(7) | Timestamp of latest staking status update |
| `TransactionError` | VARCHAR(MAX) | Error JSON from RequestStatuses (Error status only) |

---

## 5. Relationships

### 5.1 References To

| Object | Schema | Type | Purpose |
|--------|--------|------|---------|
| `Requests` | Wallet | Table | Staking request source (RequestTypeId = 6) |
| `RequestStatuses` | Wallet | Table | Latest status and error resolution |
| `RequestStatuses` | Dictionary | Table | Status name lookup |
| `Staking` | Staking | Table | Staking provider records |
| `StakingTransactions` | Staking | Table | External staking address and estimated fee |
| `StakingStatuses` | Staking | Table | Staking status history |
| `StakingStatuses` | Dictionary | Table | Status name lookup |
| `SentTransactions` | Wallet | Table | On-chain TX ID and actual blockchain fee |
| `CryptoTypes` | Wallet | Table | Crypto asset name lookup |

### 5.2 Referenced By

| Object | Type | Notes |
|--------|------|-------|
| Wallet V2 staking transaction list API procedures | Stored Procedure | V2 customer-facing staking history endpoint |
| Back-office staking reports (V2) | Ad-hoc | Staking reconciliation queries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetStakingTransactionListV2
├── Wallet.Requests
├── Wallet.RequestStatuses → Dictionary.RequestStatuses
├── Staking.Staking
│   ├── Staking.StakingTransactions
│   └── Staking.StakingStatuses → Dictionary.StakingStatuses
├── Wallet.SentTransactions
└── Wallet.CryptoTypes
```

### 6.1 Objects This Depends On

- `Wallet.Requests`
- `Wallet.RequestStatuses`
- `Dictionary.RequestStatuses`
- `Staking.Staking`
- `Staking.StakingTransactions`
- `Staking.StakingStatuses`
- `Dictionary.StakingStatuses`
- `Wallet.SentTransactions`
- `Wallet.CryptoTypes`

### 6.2 Objects That Depend On This

- Wallet API V2 staking transaction list stored procedures
- Back-office staking operations reporting (V2)

---

## 7. Technical Details

N/A for function.

---

## 8. Sample Queries

**1. All staking transactions for a customer via V2 path:**
```sql
SELECT *
FROM Wallet.GetStakingTransactionListV2(
    123456, NULL,
    DATEADD(DAY, -180, GETUTCDATE()),
    GETUTCDATE(),
    500,
    0
)
ORDER BY BeginDate DESC;
```

**2. Confirm V1 and V2 produce identical results:**
```sql
SELECT CorrelationId, RecordId, Status, Amount, CryptoName
FROM Wallet.GetStakingTransactionList(123456, NULL, '2025-01-01', NULL, 200, 0)
EXCEPT
SELECT CorrelationId, RecordId, Status, Amount, CryptoName
FROM Wallet.GetStakingTransactionListV2(123456, NULL, '2025-01-01', NULL, 200, 0);
```

**3. Pending staking transactions for monitoring:**
```sql
SELECT CorrelationId, BeginDate, Amount, CryptoName, Address
FROM Wallet.GetStakingTransactionListV2(
    123456, NULL,
    DATEADD(DAY, -7, GETUTCDATE()),
    GETUTCDATE(),
    1000, 0
)
WHERE Status = 0;  -- Pending
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetStakingTransactionListV2 | Type: Table-Valued Function | Source: WalletDB/Wallet/Functions/Wallet.GetStakingTransactionListV2.sql*

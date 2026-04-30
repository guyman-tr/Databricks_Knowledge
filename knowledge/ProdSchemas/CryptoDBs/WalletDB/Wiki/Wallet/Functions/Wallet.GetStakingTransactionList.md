# Wallet.GetStakingTransactionList

> Returns a paginated list of crypto staking transactions for a customer wallet, merging request records with staking provider data including fee breakdown, crypto name, and provider staking address.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Multi-Statement TVF |
| **Key Identifier** | Returns one row per staking request (CorrelationId / RecordId) |

---

## 1. Business Meaning

When an eToro wallet customer initiates a staking operation — locking up cryptocurrency to earn yield from a staking provider — the platform creates a staking request with `RequestTypeId = 6`. This function assembles the full staking transaction record for the wallet UI and back-office tools by combining the request record (which captures the customer's initiated action and any errors) with the staking provider record (which contains the actual staking amount, external staking address, estimated fees, and settlement status).

The function is structured around the concept of a dual-source merge: requests provide the date, correlation ID, and error information, while the `Staking.Staking` and `Staking.StakingTransactions` tables provide the provider-facing staking details. Status resolution uses `COALESCE(r.Status, s.Status, 3)`, meaning a request-level error takes precedence, but if the request has no error status, the staking record's status is used, defaulting to failed (3) if neither has a definitive value. The `@FromBackOffice` parameter is accepted but currently unused in the WHERE clause — it is present for future use or symmetry with other list functions.

---

## 2. Business Logic

**Three CTEs:**

- **`Requests`** — Top `@RecordsLimit` rows from `Wallet.Requests` for `RequestTypeId = 6` (staking), filtered by `@Gcid`, optional `@CryptoId`, and date range, ordered by `Timestamp DESC`. `CryptoId` and `Amount` parsed from `DetailsJson` using `JSON_VALUE`. Latest status via `OUTER APPLY TOP 1`. Error JSON via second `OUTER APPLY` (validated with `ISJSON`). Status: `3` (Error) or NULL (defer to staking record).
- **`Stakings`** — Reads `Staking.Staking` LEFT JOINed to `Staking.StakingTransactions` for the external staking address and estimated blockchain fee. Latest staking status resolved via `OUTER APPLY TOP 1` from `Staking.StakingStatuses`. Status: Completed→2, Failed→3, Pending→0, else→0. Fee fields hardcoded to 0 (no eToro or provider fee on staking). `InitiationTime` from the latest status record timestamp.
- **`Transactions`** — Aggregates `Wallet.SentTransactions` by `CorrelationId + BlockChainTransactionId` for on-chain TX ID and summed blockchain fee.

**Final SELECT**: LEFT JOINs Requests→Stakings→Transactions, then INNER JOINs `Wallet.CryptoTypes` for crypto name. `BlockchainFees`: actual from `SentTransactions` or estimated from staking record. `CryptoId` falls back to request's `CryptoId` if staking record is missing. `TransactionType` hardcoded to `5` (staking).

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
| `Amount` | DECIMAL(36,18) | Crypto amount staked (from request DetailsJson) |
| `Status` | INT | 0=Pending, 2=Completed, 3=Failed/Error (COALESCE: request → staking → default 3) |
| `BlockChainTransactionId` | NVARCHAR(100) | On-chain transaction ID |
| `Address` | NVARCHAR(1024) | External staking provider address |
| `TransactionType` | INT | Hardcoded to 5 (staking) |
| `BlockchainFees` | DECIMAL(36,18) | Actual fee from SentTransactions or estimated from staking record |
| `CryptoId` | INT | Crypto asset ID |
| `CryptoName` | VARCHAR(20) | Crypto asset name (from CryptoTypes) |
| `EtoroFeePercentage` | DECIMAL(36,18) | Hardcoded to 0 (no eToro fee on staking) |
| `EtoroFeeCalculated` | DECIMAL(36,18) | Hardcoded to 0 |
| `ProviderFeePercentage` | DECIMAL(36,18) | Hardcoded to 0 |
| `ProviderFeeCalculated` | DECIMAL(36,18) | Hardcoded to 0 |
| `InitiationTime` | DATETIME2(7) | Timestamp of the latest staking status update |
| `TransactionError` | VARCHAR(MAX) | Error JSON from RequestStatuses (Status = Error only) |

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
| Wallet staking transaction list API procedures | Stored Procedure | Customer-facing staking history endpoint |
| Back-office staking operations reports | Ad-hoc | Staking reconciliation and status monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetStakingTransactionList
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

- Wallet API staking transaction list stored procedures
- Back-office staking operations and reconciliation reports

---

## 7. Technical Details

N/A for function.

---

## 8. Sample Queries

**1. All staking transactions for a customer across all cryptos:**
```sql
SELECT *
FROM Wallet.GetStakingTransactionList(
    123456, NULL,
    DATEADD(DAY, -180, GETUTCDATE()),
    GETUTCDATE(),
    500,
    0
)
ORDER BY BeginDate DESC;
```

**2. Staking transactions for a specific crypto (e.g., ADA = CryptoId 5):**
```sql
SELECT CorrelationId, BeginDate, Amount, Status,
       Address, BlockChainTransactionId, BlockchainFees
FROM Wallet.GetStakingTransactionList(
    123456, 5,
    '2025-01-01', '2026-01-01',
    1000, 0
)
WHERE Status = 2;  -- Completed only
```

**3. Identify failed staking transactions with error detail:**
```sql
SELECT CorrelationId, BeginDate, Amount, CryptoName, TransactionError
FROM Wallet.GetStakingTransactionList(
    123456, NULL,
    '2024-01-01', NULL,
    10000, 0
)
WHERE Status = 3
  AND TransactionError IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetStakingTransactionList | Type: Table-Valued Function | Source: WalletDB/Wallet/Functions/Wallet.GetStakingTransactionList.sql*

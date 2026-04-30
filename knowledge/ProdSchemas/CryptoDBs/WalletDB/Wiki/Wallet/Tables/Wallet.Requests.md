# Wallet.Requests

> Central request tracking table recording every wallet operation initiated by users or the system - the primary unit of work orchestrating wallet creation, transactions, conversions, payments, and redemptions.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 5 active NC (1 unique) + 1 clustered PK |

---

## 1. Business Meaning

This table is the central orchestration record for every operation in the crypto wallet system. Each row represents a single request - whether creating a wallet, sending a transaction, redeeming crypto from a trading position, converting between assets, initiating a payment, or any other wallet operation. With ~4.9M rows, it is one of the highest-volume tables in the schema.

The request is the fundamental unit of work. Every wallet operation begins by inserting a row here, which generates a unique `Id` and `CorrelationId`. These identifiers propagate through the entire processing pipeline: status tracking (`Wallet.RequestStatuses`), blockchain transactions (`Wallet.SentTransactions`), conversions (`Wallet.Conversions`), payments (`Wallet.Payments`), and redemptions (`Wallet.Redemptions`). Without this table, the system would have no way to track, correlate, or audit wallet operations.

Rows are created by `Wallet.InsertRequest` when an operation is initiated (either by user action or system process). The `CorrelationId` (GUID) serves as the idempotency key and cross-service correlation identifier. `RequestTypeId` determines which processing pipeline handles the request. `DetailsJson` stores type-specific parameters (e.g., destination address and amount for send transactions). The request's lifecycle is tracked via `Wallet.RequestStatuses`.

---

## 2. Business Logic

### 2.1 Request Type Routing

**What**: Each request type triggers a different processing pipeline with distinct workflows and status progressions.

**Columns/Parameters Involved**: `RequestTypeId`, `DetailsJson`

**Rules**:
- 0=CreateWallet (50% of requests) - creates a new blockchain wallet for a customer on a specific crypto
- 1=SendTransaction (26%) - sends crypto from an eToro wallet to an external address
- 3=Redeem (15%) - converts a trading position into actual crypto in the user's wallet
- 4=Conversion (3%) - swaps one crypto for another
- 2=InitiatePayment (2%) - initiates a fiat payment linked to crypto
- 8=ReceiveTransaction (2%) - records an incoming blockchain transaction
- 5=Funding (0.4%) - pre-funds pool wallets from omnibus
- 7=ConversionToFiat (0.4%) - converts crypto holdings to fiat
- 9=ConversionToPosition (0.08%) - converts crypto into a trading position
- 6=Staking (0.06%) - stakes crypto for rewards
- See [Request Type](../../_glossary.md#request-type) for full definitions. FK to Dictionary.RequestTypes.

### 2.2 Correlation and Idempotency

**What**: Each request has a unique CorrelationId GUID that prevents duplicate processing and enables cross-service tracking.

**Columns/Parameters Involved**: `CorrelationId`, `Id`

**Rules**:
- CorrelationId is unique (enforced by index) and assigned by the calling service
- Used as idempotency key: if the same CorrelationId is submitted twice, the duplicate is detected
- Propagates to downstream tables (SentTransactions.CorrelationId, ReceivedTransactions.CorrelationId, etc.)
- Used by monitoring/support to trace a request across all system components

---

## 3. Data Overview

| Id | CorrelationId | Gcid | CryptoId | RequestTypeId | Meaning |
|---|---|---|---|---|---|
| 4990706 | 8F4F3FAA-... | 30351701 | 1 | 1 | A send transaction request: user 30351701 sending BTC (crypto 1) to an external address. DetailsJson contains the destination address and amount. |
| 4990707 | 8B8BDC3C-... | 18134253 | 19 | 8 | A receive transaction request: incoming DOGE (crypto 19) detected for user 18134253. DetailsJson contains the batch correlation ID and receiver details. |
| 4990708 | 3339A1DD-... | 36405891 | 107 | 0 | A create wallet request: user 36405891 requesting a new wallet for crypto 107 (likely an ERC-20 token). |
| 4990709 | 89668B37-... | 18106433 | 4 | 0 | A create wallet request: user 18106433 requesting a new XRP wallet (crypto 4). |
| 4990710 | 2BB3BB04-... | 40133357 | 19 | 0 | A create wallet request: user 40133357 requesting a new DOGE wallet (crypto 19). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key and the primary identifier for a request across the entire wallet system. Referenced by Wallet.RequestStatuses.RequestId as FK. Also used as lookup key by numerous stored procedures. |
| 2 | CorrelationId | uniqueidentifier | YES | - | VERIFIED | GUID serving as idempotency key and cross-service correlation identifier. Unique index enforced. Generated by the calling service before insertion. Propagates to SentTransactions, ReceivedTransactions, Conversions, and Payments for end-to-end traceability. NULL only for legacy records. |
| 3 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID identifying the user who initiated the request. Used for filtering requests by customer and for authorization checks. High-cardinality column indexed for efficient per-user lookups. |
| 4 | CryptoId | int | NO | - | VERIFIED | Identifier of the cryptocurrency this request operates on. Implicit reference to Wallet.CryptoTypes.CryptoID. For conversions, this is the source crypto. Combined with Gcid for per-user per-crypto request lookups. |
| 5 | RequestTypeId | tinyint | NO | - | VERIFIED | Type of wallet operation: 0=CreateWallet, 1=SendTransaction, 2=InitiatePayment, 3=Redeem, 4=Conversion, 5=Funding, 6=Staking, 7=ConversionToFiat, 8=ReceiveTransaction, 9=ConversionToPosition. See [Request Type](../../_glossary.md#request-type). FK to Dictionary.RequestTypes. |
| 6 | Timestamp | datetime2(7) | NO | - | CODE-BACKED | When the request was created. No default - explicitly set by the calling code. Used for chronological ordering, SLA monitoring, and date-range queries. Indexed descending for recent-request lookups. |
| 7 | DetailsJson | varchar(max) | YES | - | CODE-BACKED | JSON payload containing type-specific request parameters. For SendTransaction: destination address, amount, original address. For ReceiveTransaction: batch correlation ID, receiver list. For CreateWallet: typically NULL (no extra params needed). Schema varies by RequestTypeId. |
| 8 | DeviceId | varchar(50) | YES | - | NAME-INFERRED | Identifier of the device or client that initiated the request. Used for fraud detection and audit purposes. NULL for system-initiated requests (Funding, ReceiveTransaction). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RequestTypeId | Dictionary.RequestTypes | FK | Classifies the type of wallet operation |
| CryptoId | Wallet.CryptoTypes | Implicit | Identifies which cryptocurrency the request operates on |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.RequestStatuses | RequestId | FK | Tracks the lifecycle status progression of this request |
| Wallet.CorrelatedRequests | RequestId (implicit) | Implicit | Links causally-related requests (e.g., bounceback from receive) |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (FK targets are Dictionary tables).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.RequestTypes | Table | FK target for RequestTypeId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.RequestStatuses | Table | FK on RequestId |
| Wallet.InsertRequest | Stored Procedure | Inserts new requests |
| Wallet.DoesRequestExist | Stored Procedure | Checks request existence by CorrelationId |
| Wallet.GetRequestStatus | Stored Procedure | Reads request with latest status |
| Wallet.GetRequestStatuses | Stored Procedure | Reads all statuses for a request |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Requests | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_Requests_CorrelationId | NC UNIQUE | CorrelationId ASC | - | - | Active |
| IX_Wallet_Requests__RequestTypeId_Gcid_Timestamp_CryptoId | NC | RequestTypeId, Gcid, Timestamp DESC, CryptoId | - | - | Active |
| IX_Wallet_Requests_Gcid_CryptoId_Timestamp | NC | Gcid, CryptoId, Timestamp | - | - | Active |
| IX_Wallet_Requests_RequestTypeId_Inc | NC | RequestTypeId | CorrelationId, Gcid | - | Active |
| IX_Wallet_Requests_Timestamp | NC | Timestamp DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_Wallet_Requestss_RequestTypeId__Dictionary_RequestTypes_Id | FK | RequestTypeId -> Dictionary.RequestTypes.Id |

---

## 8. Sample Queries

### 8.1 Get recent requests for a customer
```sql
SELECT r.Id, r.CorrelationId, r.CryptoId, rt.Name AS RequestType, r.Timestamp
FROM Wallet.Requests r WITH (NOLOCK)
JOIN Dictionary.RequestTypes rt WITH (NOLOCK) ON r.RequestTypeId = rt.Id
WHERE r.Gcid = 30351701
ORDER BY r.Timestamp DESC
```

### 8.2 Find a request by correlation ID
```sql
SELECT r.Id, r.Gcid, r.CryptoId, r.RequestTypeId, r.Timestamp, r.DetailsJson
FROM Wallet.Requests r WITH (NOLOCK)
WHERE r.CorrelationId = '8F4F3FAA-027C-499D-9FF6-BF265D37F942'
```

### 8.3 Request volume by type
```sql
SELECT rt.Name AS RequestType, COUNT(*) AS RequestCount
FROM Wallet.Requests r WITH (NOLOCK)
JOIN Dictionary.RequestTypes rt WITH (NOLOCK) ON r.RequestTypeId = rt.Id
GROUP BY rt.Name
ORDER BY RequestCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 9.4/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.Requests | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.Requests.sql*

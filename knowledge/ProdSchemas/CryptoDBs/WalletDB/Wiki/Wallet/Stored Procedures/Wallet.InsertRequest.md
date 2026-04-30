# Wallet.InsertRequest

> Creates a new wallet operation request with its initial status atomically, returning the generated RequestId - the central entry point for all wallet operations used by 10 service consumers.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.Requests + RequestStatuses (transactional), returns RequestId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the most widely consumed writer procedure in the wallet system, called by 10 service accounts: AML, back-office API, conversion, executer, monitor, redeem persistor, redeem scheduler, scheduled jobs, staking, and wallet middleware. Every wallet operation - creating a wallet, sending crypto, redeeming a position, converting between cryptos, initiating a payment - begins with InsertRequest.

The procedure atomically creates a request record in Wallet.Requests and its initial status in Wallet.RequestStatuses within a transaction. It returns the generated RequestId (SCOPE_IDENTITY) which the caller uses for all subsequent operations on this request. The CorrelationId (GUID) serves as the cross-service idempotency and tracing key. The @RequestTypeId determines which processing pipeline handles the request (0=CreateWallet, 1=SendTransaction, 3=Redeem, etc.).

---

## 2. Business Logic

### 2.1 Atomic Request + Status Creation

**What**: Creates the request and its initial status in a single transaction.

**Columns/Parameters Involved**: `Requests`, `RequestStatuses`, `@RequestStatusId`

**Rules**:
- BEGIN TRANSACTION ensures both inserts succeed or both roll back
- SCOPE_IDENTITY() captures the generated RequestId
- Initial RequestStatusId is passed by caller (typically 0=Pending or an initial state)
- Timestamp is set to GETDATE() for both records
- Returns @RequestId as a scalar result set

### 2.2 Request Type Routing

**What**: The @RequestTypeId determines which processing pipeline handles this request.

**Columns/Parameters Involved**: `@RequestTypeId`

**Rules**:
- 0=CreateWallet, 1=SendTransaction, 2=InitiatePayment, 3=Redeem, 4=Conversion, 5=Funding, 6=Staking, 7=ConversionToFiat, 8=ReceiveTransaction, 9=ConversionToPosition
- See [Request Type](../../_glossary.md#request-type) for full definitions
- The type determines which downstream procedures and services process this request

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Cross-service idempotency and tracing key. Unique. |
| 2 | @Gcid | bigint | NO | - | VERIFIED | Customer initiating the request. 0 for system/omnibus operations. |
| 3 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency this request operates on. FK to Wallet.CryptoTypes. |
| 4 | @RequestTypeId | tinyint | NO | - | VERIFIED | Operation type: 0=CreateWallet, 1=SendTransaction, 3=Redeem, 4=Conversion, etc. See [Request Type](../../_glossary.md#request-type). |
| 5 | @DetailsJson | varchar(max) | YES | - | CODE-BACKED | Type-specific JSON parameters (e.g., destination address, amount for sends). |
| 6 | @RequestStatusId | tinyint | NO | - | VERIFIED | Initial request status. FK to Dictionary.RequestStatuses. |
| 7 | @DeviceId | varchar(50) | YES | - | CODE-BACKED | Device identifier for the requesting client. Not stored in current implementation (reserved parameter). |
| 8 | @TimeOutSeconds | int | YES | - | CODE-BACKED | Request timeout in seconds. Not stored in current implementation (reserved parameter). |
| 9 | (output) | bigint | NO | - | CODE-BACKED | Returns the generated RequestId. 0 on error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.Requests | INSERT | Creates the request record |
| - | Wallet.RequestStatuses | INSERT | Creates the initial status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser | - | EXECUTE | AML-initiated requests |
| BackApiUser | - | EXECUTE | Back-office operations |
| ConversionUser | - | EXECUTE | Conversion requests |
| ExecuterUser | - | EXECUTE | Execution pipeline requests |
| MonitorUser | - | EXECUTE | Monitor-initiated requests |
| RedeemPersistorUser | - | EXECUTE | Redemption requests |
| RedeemSchedulerUser | - | EXECUTE | Scheduled redemptions |
| ScheduledJobsUser | - | EXECUTE | Scheduled operations |
| StakingUser | - | EXECUTE | Staking requests |
| WalletMiddlewareUser | - | EXECUTE | Middleware operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertRequest (procedure)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | INSERT target |
| Wallet.RequestStatuses | Table | Initial status INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AmlUser, BackApiUser, ConversionUser, ExecuterUser, MonitorUser, RedeemPersistorUser, RedeemSchedulerUser, ScheduledJobsUser, StakingUser, WalletMiddlewareUser | Service Accounts | EXECUTE grants (10 consumers) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses BEGIN/COMMIT TRANSACTION.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Create a send transaction request
```sql
EXEC Wallet.InsertRequest
    @CorrelationId = 'NEW-GUID', @Gcid = 30351701, @CryptoId = 1,
    @RequestTypeId = 1, @DetailsJson = '{"address":"1ABC...","amount":0.5}',
    @RequestStatusId = 0, @DeviceId = NULL, @TimeOutSeconds = 300;
```

### 8.2 Create a wallet creation request
```sql
EXEC Wallet.InsertRequest
    @CorrelationId = 'NEW-GUID', @Gcid = 30351701, @CryptoId = 19,
    @RequestTypeId = 0, @DetailsJson = NULL,
    @RequestStatusId = 0, @DeviceId = NULL, @TimeOutSeconds = 60;
```

### 8.3 Track the request
```sql
SELECT r.Id, r.CorrelationId, r.RequestTypeId, rs.RequestStatusId, rs.Timestamp
FROM Wallet.Requests r WITH (NOLOCK) JOIN Wallet.RequestStatuses rs WITH (NOLOCK) ON rs.RequestId = r.Id
WHERE r.CorrelationId = 'YOUR-GUID' ORDER BY rs.Id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertRequest | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertRequest.sql*

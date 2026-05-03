# EXW_Wallet.Requests

> 5.0M-row crypto wallet request log tracking every wallet operation request (create wallet, send, receive, redeem, convert, fund, stake) from 2018-07-11 to present. Mirrors production WalletDB.Wallet.Requests via Generic Pipeline (Append, daily). Read by SP_EXW_C2F_E2E (crypto-to-fiat/crypto-to-position reconciliation) and SP_EXW_FactRedeemTransactions (redeem transaction reconciliation).

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.Requests (Generic Pipeline, Append) |
| **Refresh** | Daily (1440 min), Append strategy, parquet |
| **Synapse Distribution** | HASH(Gcid) |
| **Synapse Index** | HEAP |
| **UC Target** | `wallet.bronze_walletdb_wallet_requests` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

EXW_Wallet.Requests is a raw staging mirror of the production WalletDB.Wallet.Requests table, containing 5.0M rows spanning from July 2018 to present. Each row represents a single wallet operation request initiated by a customer (identified by Gcid) for a specific cryptocurrency (CryptoId).

The table captures 10 distinct request types: CreateWallet (0, ~2.5M rows), SendTransaction (1, ~1.3M), Redeem (3, ~751K), Conversion (4, ~158K), ReceiveTransaction (8, ~137K), InitiatePayment (2, ~117K), Funding (5, ~21K), ConversionToFiat (7, ~19K), ConversionToPosition (9, ~4K), and Staking (6, ~3K).

The table is loaded via the Generic Pipeline (Append strategy, daily at 1440-minute intervals) from the WalletDB production database. There is no writer SP in Synapse; data arrives as-is from production. Two downstream SPs read from this table:
- **SP_EXW_C2F_E2E** filters for RequestTypeId=7 (ConversionToFiat) and RequestTypeId=9 (ConversionToPosition), joining with RequestStatuses and EXW_DimUser to build the end-to-end C2F/C2P reconciliation pipeline.
- **SP_EXW_FactRedeemTransactions** joins Requests with RequestStatuses to determine the final status of redemption-related requests.

The CorrelationId serves as the cross-system linking key, connecting wallet requests to sent transactions, conversion records, and eMoney transactions in the downstream E2E pipeline. The etr_y/etr_ym/etr_ymd columns are deprecated partition columns that are 100% NULL. DeviceId is also 100% NULL across all rows.

---

## 2. Business Logic

### 2.1 Request Type Classification

**What**: Each request is classified by type, determining the wallet operation being performed.
**Columns Involved**: RequestTypeId
**Rules**:
- 0 = CreateWallet (most common, ~50% of all requests)
- 1 = SendTransaction (crypto send to external address)
- 2 = InitiatePayment
- 3 = Redeem (position redemption to crypto)
- 4 = Conversion (crypto-to-crypto)
- 5 = Funding
- 6 = Staking
- 7 = ConversionToFiat (C2F)
- 8 = ReceiveTransaction
- 9 = ConversionToPosition (C2P)

### 2.2 Correlation Linking

**What**: CorrelationId links requests across multiple wallet subsystems for end-to-end tracking.
**Columns Involved**: CorrelationId, Id
**Rules**:
- CorrelationId is a GUID that connects Requests to SentTransactions, RequestStatuses, and WalletConversionDB records
- SP_EXW_C2F_E2E uses CorrelationId to build the full C2F/C2P lifecycle from request through conversion to eMoney/deposit settlement
- SP_EXW_FactRedeemTransactions links via CorrelationId (as SendRequestCorrelationId in Redemptions) to track redeem completion

### 2.3 JSON Details Payload

**What**: DetailsJson contains variable-structure JSON with request-specific parameters.
**Columns Involved**: DetailsJson
**Rules**:
- NULL for CreateWallet requests (RequestTypeId=0) and many older records (~50% NULL overall)
- For SendTransaction (1): contains Amount, ToAddress, OriginalAddress
- For Conversion (4): contains CryptoIdFrom, CryptoIdTo, AmountFrom, AmountTo, rate and fee fields
- Structure varies by RequestTypeId; no fixed schema

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The table is HASH-distributed on Gcid and uses a HEAP (no clustered index). Queries filtering by Gcid benefit from distribution-aligned access. For large scans, filter by partition_date to limit data movement.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| All requests for a customer | `WHERE Gcid = @gcid` (distribution-aligned) |
| Requests by type in a date range | `WHERE RequestTypeId = @type AND partition_date BETWEEN @start AND @end` |
| Parse JSON details for send requests | `WHERE RequestTypeId = 1 AND DetailsJson IS NOT NULL`, use JSON_VALUE on DetailsJson |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.RequestStatuses | Requests.Id = RequestStatuses.RequestId | Get request status history/last status |
| CopyFromLake.WalletDB_Dictionary_RequestStatuses | Dictionary.Id = RequestStatuses.RequestStatusId | Resolve status name |
| CopyFromLake.WalletDB_Dictionary_RequestTypes | Dictionary.Id = Requests.RequestTypeId | Resolve request type name |
| EXW_dbo.EXW_DimUser | DimUser.GCID = Requests.Gcid | Enrich with customer details (RealCID, Club, Country) |
| EXW_Wallet.CustomerWalletsView | CWV.Gcid = Requests.Gcid AND CWV.CryptoId = Requests.CryptoId | Get wallet address |
| EXW_Wallet.SentTransactions | SentTransactions.CorrelationId = Requests.CorrelationId | Link to sent blockchain transactions |

### 3.4 Gotchas

- **DeviceId is 100% NULL** — the column exists in DDL but is never populated. Do not rely on it.
- **etr_y, etr_ym, etr_ymd are 100% NULL** — deprecated ETL partition columns, never populated.
- **DetailsJson structure varies by RequestTypeId** — there is no single JSON schema. Always check RequestTypeId before parsing.
- **CorrelationId is NOT the primary key** — Id is the unique request identifier. CorrelationId links across subsystems and may appear in multiple tables.
- **Append-only ingestion** — rows are never deleted or updated from production. SynapseUpdateDate reflects the Synapse load batch, not a row modification time.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL transform logic |
| Tier 3 | Grounded in DDL, sample data, and downstream SP usage — no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Primary key of the wallet request. Unique identifier assigned by the WalletDB production system. Used as join key to EXW_Wallet.RequestStatuses (RequestStatuses.RequestId = Requests.Id). (Tier 3 — WalletDB.Wallet.Requests, no upstream wiki) |
| 2 | CorrelationId | uniqueidentifier | YES | Cross-system correlation identifier (GUID). Links this request to SentTransactions, WalletConversionDB records, Redemptions, and eMoney transactions in downstream E2E reconciliation pipelines. Used as the primary linking key in SP_EXW_C2F_E2E and SP_EXW_FactRedeemTransactions. (Tier 3 — WalletDB.Wallet.Requests, no upstream wiki) |
| 3 | Gcid | int | YES | Global Customer ID. Identifies the customer who initiated the wallet request. Distribution key for the table. Joins to EXW_dbo.EXW_DimUser.GCID for customer enrichment (RealCID, Club, Country, Regulation). (Tier 3 — WalletDB.Wallet.Requests, no upstream wiki) |
| 4 | CryptoId | int | YES | Cryptocurrency identifier. FK to EXW_Wallet.CryptoTypes.CryptoID. Identifies which cryptocurrency the request pertains to (e.g., 1=Bitcoin, 2=Ethereum, 6=Litecoin, 18=Cardano based on sample data). (Tier 3 — WalletDB.Wallet.Requests, no upstream wiki) |
| 5 | RequestTypeId | int | YES | Type of wallet operation requested. FK to WalletDB.Dictionary.RequestTypes. 0=CreateWallet, 1=SendTransaction, 2=InitiatePayment, 3=Redeem, 4=Conversion, 5=Funding, 6=Staking, 7=ConversionToFiat, 8=ReceiveTransaction, 9=ConversionToPosition. (Tier 3 — WalletDB.Wallet.Requests, no upstream wiki) |
| 6 | Timestamp | datetime2(7) | YES | Timestamp when the request was created in the production WalletDB system. Used by downstream SPs as RequestTime. SP_EXW_C2F_E2E casts this to DATE for RequestDate and uses it for ROW_NUMBER ordering. (Tier 3 — WalletDB.Wallet.Requests, no upstream wiki) |
| 7 | DetailsJson | varchar(max) | YES | JSON payload containing request-specific parameters. Structure varies by RequestTypeId. For SendTransaction: {Amount, ToAddress, OriginalAddress}. For Conversion: {CryptoIdFrom, CryptoIdTo, AmountFrom, AmountTo, rate/fee fields}. NULL for ~50% of rows (primarily CreateWallet requests). (Tier 3 — WalletDB.Wallet.Requests, no upstream wiki) |
| 8 | DeviceId | varchar(max) | YES | Device identifier of the requesting client. Currently 100% NULL across all 5M rows — column exists in production DDL but is not populated. Referenced as RequestDeviceID in SP_EXW_C2F_E2E but carries no data. (Tier 3 — WalletDB.Wallet.Requests, no upstream wiki) |
| 9 | etr_y | varchar(max) | YES | ETL year partition column. Deprecated — 100% NULL across all rows. Not used by any downstream SP. (Tier 3 — ETL infrastructure column, unused) |
| 10 | etr_ym | varchar(max) | YES | ETL year-month partition column. Deprecated — 100% NULL across all rows. Not used by any downstream SP. (Tier 3 — ETL infrastructure column, unused) |
| 11 | etr_ymd | varchar(max) | YES | ETL year-month-day partition column. Deprecated — 100% NULL across all rows. Not used by any downstream SP. (Tier 3 — ETL infrastructure column, unused) |
| 12 | SynapseUpdateDate | datetime | YES | Timestamp of the Synapse data load batch. Reflects when the row was ingested into Synapse via the Generic Pipeline, not when the request was created in production. (Tier 3 — Synapse ETL infrastructure) |
| 13 | partition_date | date | YES | Date-level partition derived from the request Timestamp. Used for efficient date-range filtering. Aligns with the Append ingestion strategy partition boundary. (Tier 3 — Synapse ETL infrastructure) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | WalletDB.Wallet.Requests | Id | Passthrough |
| CorrelationId | WalletDB.Wallet.Requests | CorrelationId | Passthrough |
| Gcid | WalletDB.Wallet.Requests | Gcid | Passthrough |
| CryptoId | WalletDB.Wallet.Requests | CryptoId | Passthrough |
| RequestTypeId | WalletDB.Wallet.Requests | RequestTypeId | Passthrough |
| Timestamp | WalletDB.Wallet.Requests | Timestamp | Passthrough |
| DetailsJson | WalletDB.Wallet.Requests | DetailsJson | Passthrough |
| DeviceId | WalletDB.Wallet.Requests | DeviceId | Passthrough |
| etr_y | — | — | ETL partition (unused) |
| etr_ym | — | — | ETL partition (unused) |
| etr_ymd | — | — | ETL partition (unused) |
| SynapseUpdateDate | — | — | Synapse load timestamp |
| partition_date | WalletDB.Wallet.Requests | Timestamp | CAST to DATE |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.Requests (production, WalletDB server)
  |-- Generic Pipeline (Bronze export, Append, daily, parquet) ---|
  v
Bronze/WalletDB/Wallet/Requests/ (Data Lake)
  |-- CopyFromLake / Direct Load ---|
  v
EXW_Wallet.Requests (Synapse, 5.0M rows, HASH(Gcid), HEAP)
  |-- Generic Pipeline (Bronze export, delta) ---|
  v
wallet.bronze_walletdb_wallet_requests (Unity Catalog)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| Gcid | EXW_dbo.EXW_DimUser | Customer dimension lookup (GCID) |
| CryptoId | EXW_Wallet.CryptoTypes | Cryptocurrency type lookup (CryptoID) |
| RequestTypeId | CopyFromLake.WalletDB_Dictionary_RequestTypes | Request type name resolution |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| Id | EXW_Wallet.RequestStatuses | Status history for each request (RequestStatuses.RequestId = Requests.Id) |
| CorrelationId | EXW_dbo.EXW_C2F_E2E | C2F end-to-end reconciliation (via SP_EXW_C2F_E2E) |
| CorrelationId | EXW_dbo.EXW_C2P_E2E | C2P end-to-end reconciliation (via SP_EXW_C2F_E2E) |
| CorrelationId | EXW_dbo.EXW_FactRedeemTransactions | Redemption reconciliation (via SP_EXW_FactRedeemTransactions) |

---

## 7. Sample Queries

### 7.1 Request Volume by Type and Month

```sql
SELECT
    rt.Name AS RequestType,
    FORMAT(r.partition_date, 'yyyy-MM') AS Month,
    COUNT(*) AS RequestCount
FROM EXW_Wallet.Requests r
JOIN CopyFromLake.WalletDB_Dictionary_RequestTypes rt
    ON rt.Id = r.RequestTypeId
WHERE r.partition_date >= '2026-01-01'
GROUP BY rt.Name, FORMAT(r.partition_date, 'yyyy-MM')
ORDER BY Month DESC, RequestCount DESC;
```

### 7.2 Request with Last Status for a Customer

```sql
SELECT
    r.Id,
    r.CorrelationId,
    rt.Name AS RequestType,
    r.[Timestamp] AS RequestTime,
    rs.RequestStatusId,
    drs.Name AS StatusName,
    rs.[Timestamp] AS StatusTime
FROM EXW_Wallet.Requests r
JOIN EXW_Wallet.RequestStatuses rs ON r.Id = rs.RequestId
JOIN CopyFromLake.WalletDB_Dictionary_RequestStatuses drs ON drs.Id = rs.RequestStatusId
JOIN CopyFromLake.WalletDB_Dictionary_RequestTypes rt ON rt.Id = r.RequestTypeId
WHERE r.Gcid = @gcid
    AND rs.[Timestamp] = (
        SELECT MAX(rs2.[Timestamp])
        FROM EXW_Wallet.RequestStatuses rs2
        WHERE rs2.RequestId = r.Id
    )
ORDER BY r.[Timestamp] DESC;
```

### 7.3 Parse Send Transaction Details

```sql
SELECT
    r.Id,
    r.Gcid,
    r.[Timestamp],
    JSON_VALUE(r.DetailsJson, '$.Amount') AS Amount,
    JSON_VALUE(r.DetailsJson, '$.ToAddress') AS ToAddress
FROM EXW_Wallet.Requests r
WHERE r.RequestTypeId = 1
    AND r.DetailsJson IS NOT NULL
    AND r.partition_date >= '2026-04-01';
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — Jira/Confluence phase skipped).

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 13 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 7/10, Lineage: Complete*
*Object: EXW_Wallet.Requests | Type: Table | Production Source: WalletDB.Wallet.Requests (Generic Pipeline)*

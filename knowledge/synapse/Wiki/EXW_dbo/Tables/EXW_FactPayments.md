# EXW_dbo.EXW_FactPayments

> 553,884-row accumulating snapshot of Simplex fiat-to-crypto payment events for eToro Wallet users, covering 2020-01-29 to 2022-09-20 — one row per payment × status transition, so ~99,410 distinct payment requests each appear approximately 5–6 times as they progress through the 11-stage payment lifecycle. Sourced from WalletDB.Wallet.Payments, PaymentTransactions, and PaymentStatuses. Table is frozen as Simplex was decommissioned in September 2022.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.Payments + Wallet.PaymentTransactions + Wallet.PaymentStatuses |
| **Refresh** | Frozen — last data 2022-09-20 (Simplex decommissioned); UpdateDate max 2022-09-21 |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_FactPayments records the lifecycle of every Simplex fiat-to-crypto payment request on the eToro Wallet platform. Simplex was a third-party payment provider enabling users to purchase cryptocurrency using credit/debit cards in EUR or GBP. Each payment passed through up to 11 status stages, and EXW_FactPayments stores one row per payment per status transition — making it an event-log/accumulating snapshot rather than a simple payment fact table.

The table contains 553,884 rows representing 99,410 distinct payment requests spanning 2020-01-29 to 2022-09-20. The payment success rate is approximately 22% (21,747 "Completed" events out of 99,410 payments). Most payments either fail at the provider initiation stage or are stuck in DocumentCompleted/InitiateCompleted intermediate states.

**Architectural note**: Each PaymentID appears approximately 5–6 times — once for each status it passes through. To get current payment status, filter to the latest row per PaymentID (by ModificationDate or RequestDateID). Columns like ExchangeRate, ToAddress, AmountInCrypto, and fees are populated only for rows where crypto execution occurred (PendingTransaction/TransferCompleted/Completed stages).

Fiat currencies: EUR (68%), GBP (32%). Crypto: BTC (72%), ETH (14%), LTC (5%), XLM (4%), XRP (3%), BCH (2%).

---

## 2. Business Logic

### 2.1 Payment Status Lifecycle

**What**: Each payment progresses through up to 11 statuses. EXW_FactPayments has one row per status event.  
**Columns Involved**: PaymentStatus, ModificationDate, RequestDate  
**Rules**:
- Status progression (typical happy path): InitiateStarted → PendingProvider → InitiateCompleted → ProviderSubmitted → PendingTransaction → TransferCompleted → Completed
- Terminal failure states: Failed, InternalError, InitiateFailed
- DocumentCompleted is an intermediate state for KYC/document verification
- Filter to `PaymentStatus = 'Completed'` for successful payments only
- To get the latest status: `MAX(ModificationDate)` or rank by ModificationDate DESC per PaymentID

### 2.2 Crypto Execution Fields — Conditional Population

**What**: Crypto execution columns are only populated at the execution phase of the payment.  
**Columns Involved**: ExchangeRate, ToAddress, AmountInCrypto, EtoroFeePercentage, EtoroFeeCalculated, ProviderFeeCalculated, EstimatedBlockChainFee, BlockChainFee, SentTransactionID, BlockchainTransactionId  
**Rules**:
- These columns are NULL for early-stage statuses (InitiateStarted, PendingProvider, DocumentCompleted, Failed)
- Populated when crypto was actually executed: ProviderSubmitted, PendingTransaction, TransferCompleted, Completed
- `BlockChainFee` = actual fee paid; `EstimatedBlockChainFee` = pre-execution estimate

### 2.3 Fee Structure

**What**: Three fee types apply to each Simplex payment.  
**Columns Involved**: EtoroFeePercentage, EtoroFeeCalculated, ProviderFeeCalculated, EstimatedBlockChainFee, BlockChainFee  
**Rules**:
- `EtoroFeePercentage`: eToro's service fee percentage applied to the fiat amount
- `EtoroFeeCalculated`: eToro fee in crypto units (`EtoroFeePercentage × AmountInCrypto`)
- `ProviderFeeCalculated`: Simplex provider fee in crypto units
- `EstimatedBlockChainFee`: Network fee estimate at order time; `BlockChainFee` = actual at settlement

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) distribution with HEAP. Queries by GCID (customer ID) will benefit from data locality. JOINs to other HASH(GCID) tables (e.g., EXW_DimUser_Enriched, EXW_FactBalance) avoid data movement. HEAP allows fast bulk loads but full table scans for non-GCID filters.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Successful payments only | `WHERE PaymentStatus = 'Completed'` |
| Latest status per payment | `QUALIFY ROW_NUMBER() OVER (PARTITION BY PaymentID ORDER BY ModificationDate DESC) = 1` |
| Total fiat spent by customer | `WHERE PaymentStatus = 'Completed' GROUP BY GCID, SUM(AmountInFiat)` |
| Payment success rate | `COUNT(CASE WHEN PaymentStatus='Completed' THEN 1 END) / COUNT(DISTINCT PaymentID)` |
| Join to Simplex mapping | `JOIN EXW_SimplexMapping ON EXW_SimplexMapping.long_id = EXW_FactPayments.ProviderPaymentID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_SimplexMapping | `EXW_SimplexMapping.long_id = ProviderPaymentID` | Link internal payment to Simplex API record |
| EXW_dbo.EXW_ECPBank | `EXW_ECPBank.uti ~ ProviderPaymentID` | Cross-reference with ECP Bank settlement |
| EXW_dbo.EXW_PaymentReconciliation | `EXW_PaymentReconciliation.PaymentID = PaymentID` | Full payment reconciliation view |
| EXW_dbo.EXW_DimUser_Enriched | `EXW_DimUser_Enriched.GCID = GCID` | Add customer demographics |

### 3.4 Gotchas

- **Multiple rows per PaymentID** — NOT a fact table with one row per payment; must deduplicate by status or filter to desired status before aggregating
- **Crypto execution columns are NULL for failed/early-stage rows** — filter to Completed/TransferCompleted for non-null financial data
- **ProviderPaymentID is nvarchar(max)** — direct JOIN to EXW_SimplexMapping.long_id may need explicit CAST; both are GUIDs
- **WalletID is nvarchar(max)** — stored as string; join to wallet-keyed tables requires CAST to uniqueidentifier
- **Date column = date portion of RequestDate** — RequestDateID = YYYYMMDD int key from RequestDate (not ModificationDate)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki (WalletDB) |
| Tier 2 | Derived from ETL logic or join enrichment analysis |
| Tier 3 | Inferred from column name, type, and data samples |
| Tier 4 | Best-available inference — no upstream wiki match |
| Tier 5 | Placeholder — domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PaymentID | bigint | YES | Auto-incrementing primary key. FK target for Wallet.PaymentStatuses, Wallet.PaymentTransactions, and Wallet.Chargebacks. Passthrough from Wallet.Payments.Id. (Tier 1 — Wallet.Payments) |
| 2 | ProviderPaymentID | nvarchar(max) | YES | Payment identifier assigned by the external payment provider. Used for reconciliation and provider API calls. Links to EXW_SimplexMapping.long_id and EXW_ECPBank.uti. (Tier 1 — Wallet.Payments) |
| 3 | WalletID | nvarchar(max) | YES | The customer's wallet receiving the purchased crypto. FK to Wallet.Wallets.WalletId. (Tier 1 — Wallet.Payments) |
| 4 | AmountInFiat | numeric(38,8) | YES | Fiat amount of the payment. Denominated in the currency specified by FiatId (e.g., 125 EUR). Passthrough from Wallet.Payments.Amount. (Tier 1 — Wallet.Payments) |
| 5 | FiatID | int | YES | The fiat currency used for payment: 1=USD, 2=EUR, 3=GBP, 5=AUD. FK to Wallet.FiatTypes.Id. (Tier 1 — Wallet.Payments) |
| 6 | CorrelationID | nvarchar(max) | YES | Links to the parent request in Wallet.Requests.CorrelationId. (Tier 1 — Wallet.Payments) |
| 7 | RequestDate | datetime | YES | Timestamp when the payment was initiated. Passthrough from Wallet.Payments.Occurred. Primary date for payment filtering; see also RequestDateID and Date. (Tier 1 — Wallet.Payments) |
| 8 | ModificationDate | datetime | YES | Timestamp of this status transition. Passthrough from Wallet.PaymentStatuses.Occurred. Each row represents a status event; this is when the payment entered the current PaymentStatus. (Tier 1 — Wallet.PaymentStatuses) |
| 9 | ExchangeRate | numeric(38,8) | YES | Fiat-to-crypto exchange rate at execution time. Used to convert the fiat Amount to crypto. NULL for non-execution status rows. (Tier 1 — Wallet.PaymentTransactions) |
| 10 | ToAddress | nvarchar(512) | YES | Blockchain destination address for the purchased crypto. NULL for non-execution status rows. (Tier 1 — Wallet.PaymentTransactions) |
| 11 | AmountInCrypto | numeric(38,8) | YES | Amount of crypto being purchased/transferred. Passthrough from Wallet.PaymentTransactions.Amount. NULL for non-execution status rows. (Tier 1 — Wallet.PaymentTransactions) |
| 12 | EtoroFeePercentage | numeric(38,8) | YES | eToro service fee as a percentage. NULL for non-execution status rows. (Tier 1 — Wallet.PaymentTransactions) |
| 13 | EtoroFeeCalculated | numeric(38,8) | YES | Calculated eToro fee in crypto units. NULL for non-execution status rows. (Tier 1 — Wallet.PaymentTransactions) |
| 14 | ProviderFeeCalculated | numeric(38,8) | YES | Calculated provider fee in crypto units. NULL for non-execution status rows. (Tier 1 — Wallet.PaymentTransactions) |
| 15 | EstimatedBlockChainFee | numeric(38,8) | YES | Estimated blockchain network fee. Estimated at order time; compare with BlockChainFee for actual. NULL for non-execution rows. (Tier 1 — Wallet.PaymentTransactions) |
| 16 | FiatName | nvarchar(50) | YES | Fiat currency name, denormalized from Wallet.FiatTypes via FiatID. Values: EUR, GBP. (Tier 2 — ETL join enrichment) |
| 17 | CryptoId | int | YES | The cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID. (Tier 3 — Wallet.Payments) |
| 18 | CryptoName | nvarchar(500) | YES | Cryptocurrency name, denormalized from Wallet.CryptoTypes via CryptoId. Values: BTC, ETH, LTC, XLM, XRP, BCH. (Tier 2 — ETL join enrichment) |
| 19 | SentTransactionID | bigint | YES | Internal identifier for the sent blockchain transaction. Links to WalletDB transaction tables. NULL for non-execution rows. (Tier 2 — WalletDB transaction tables) |
| 20 | ReceivedTransactionID | bigint | YES | Internal identifier for the received blockchain transaction. NULL for non-execution rows. (Tier 2 — WalletDB transaction tables) |
| 21 | BlockchainTransactionId | nvarchar(max) | YES | Blockchain transaction hash (hex string) for the executed crypto transfer. NULL for non-execution rows. (Tier 2 — WalletDB transaction tables) |
| 22 | PaymentStatus | varchar(500) | YES | Payment lifecycle status name. Values: InitiateStarted, PendingProvider, InitiateCompleted, ProviderSubmitted, PendingTransaction, TransferCompleted, Completed, Failed, InternalError, DocumentCompleted, InitiateFailed. Each row represents this payment at this specific status. (Tier 2 — Dictionary.PaymentStatuses via ETL join) |
| 23 | GCID | int | YES | Global Customer ID of the wallet owner. Distribution key. Derived via Wallet.Wallets → customer mapping. Links to EXW_DimUser_Enriched.GCID. (Tier 2 — WalletDB wallet-customer mapping) |
| 24 | BlockChainFee | numeric(38,8) | YES | Actual blockchain network fee paid at execution, as opposed to EstimatedBlockChainFee. NULL for non-execution rows. (Tier 2 — WalletDB transaction tables) |
| 25 | UpdateDate | datetime | YES | ETL-managed load timestamp. Not a business date. Max = 2022-09-21. (Tier 2 — ETL) |
| 26 | BlockchainCryptoID | int | YES | Blockchain-specific crypto type identifier. May differ from CryptoId in encoding scheme. (Tier 2 — ETL denorm) |
| 27 | RequestDateID | int | YES | Date integer key (YYYYMMDD) derived from RequestDate. For date dimension joins. (Tier 2 — ETL) |
| 28 | Date | date | YES | Date portion of RequestDate. Redundant with RequestDate for date-only filters. (Tier 2 — ETL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| PaymentID | Wallet.Payments | Id | Renamed |
| ProviderPaymentID, WalletID, AmountInFiat, FiatID, CorrelationID, RequestDate, CryptoId | Wallet.Payments | ProviderPaymentId, WalletId, Amount, FiatId, CorrelationId, Occurred, CryptoId | Passthrough (rename) |
| ModificationDate | Wallet.PaymentStatuses | Occurred | Renamed |
| ExchangeRate, ToAddress, AmountInCrypto, EtoroFeePercentage, EtoroFeeCalculated, ProviderFeeCalculated, EstimatedBlockChainFee | Wallet.PaymentTransactions | same names (Amount→AmountInCrypto) | Passthrough |
| FiatName | Wallet.FiatTypes | FiatName | Denormalized join via FiatID |
| CryptoName | Wallet.CryptoTypes | Name | Denormalized join via CryptoId |
| PaymentStatus | Dictionary.PaymentStatuses | Name | Denormalized join via PaymentStatusId |
| GCID, SentTransactionID, ReceivedTransactionID, BlockchainTransactionId, BlockChainFee, BlockchainCryptoID | WalletDB various tables | — | ETL-derived |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.Payments (~99K payments)
  + WalletDB.Wallet.PaymentStatuses (~554K status events)
  + WalletDB.Wallet.PaymentTransactions (execution details)
  + WalletDB.Wallet.FiatTypes (fiat name lookup)
  + WalletDB.Wallet.CryptoTypes (crypto name lookup)
  + WalletDB.Wallet.Wallets → customer mapping (GCID)
  |-- External pipeline (no SSDT SP found) ---|
  v
EXW_dbo.EXW_FactPayments (553K rows, HASH(GCID), HEAP)
  |-- Data frozen 2022-09-20 — Simplex decommissioned ---|
  v
No UC Generic Pipeline mapping (_Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| ProviderPaymentID | EXW_dbo.EXW_SimplexMapping.long_id | Links to Simplex API payment record |
| ProviderPaymentID | EXW_dbo.EXW_ECPBank.uti | Links to ECP Bank settlement |
| GCID | EXW_dbo.EXW_DimUser_Enriched.GCID | Customer profile |

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| EXW_dbo.EXW_PaymentReconciliation | PaymentID, GCID | Full payment reconciliation joins this table |

---

## 7. Sample Queries

### Successful Payments by Crypto Asset (Latest Status)

```sql
SELECT
    CryptoName,
    COUNT(DISTINCT PaymentID) AS completed_payments,
    SUM(AmountInFiat) AS total_fiat_amount
FROM [EXW_dbo].[EXW_FactPayments]
WHERE PaymentStatus = 'Completed'
GROUP BY CryptoName
ORDER BY completed_payments DESC;
```

### Latest Status per Payment (De-duplicated View)

```sql
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY PaymentID
            ORDER BY ModificationDate DESC
        ) AS rn
    FROM [EXW_dbo].[EXW_FactPayments]
) t
WHERE rn = 1;
```

### Payment Lifecycle for a Specific Customer

```sql
SELECT
    PaymentID,
    CryptoName,
    AmountInFiat,
    FiatName,
    PaymentStatus,
    RequestDate,
    ModificationDate
FROM [EXW_dbo].[EXW_FactPayments]
WHERE GCID = 842615
ORDER BY PaymentID, ModificationDate;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian (Confluence/Jira) sources found for EXW_FactPayments. Source documentation exists in WalletDB upstream wiki (CryptoDBs/WalletDB/Wiki).

---

*Generated: 2026-04-20 | Quality: 9.0/10 | Phases: 13/14*  
*Tiers: 16 T1, 12 T2, 0 T3, 0 T4, 0 T5 | Elements: 28/28, Logic: 3/10, Data Evidence: P2+P3 PASS*  
*Object: EXW_dbo.EXW_FactPayments | Type: Table | Production Source: WalletDB.Wallet.Payments + PaymentTransactions + PaymentStatuses*

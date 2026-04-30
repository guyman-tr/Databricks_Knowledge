# dbo.GetTransactionRequests

> Memory-optimized, session-scoped temporary result table used by Wallet.GetTransactionList_temp to assemble a unified view of all crypto transaction types for a customer.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | None (no PK - session-scoped via SPID filter) |
| **Partition** | No |
| **Indexes** | 1 active (ix_SpidFiler on SpidFilter) |

---

## 1. Business Meaning

This table is a memory-optimized, schema-only (non-durable) staging table that acts as a per-session scratchpad for assembling a unified transaction list across all crypto transaction types. When a customer requests their transaction history, the system cannot return results from a single table because transactions are spread across multiple domains (sent, received, conversions, payments, staking, crypto-to-fiat). This table collects rows from all six sources into one result set.

Without this table, the application would need to make six separate queries and merge results client-side, or use a complex UNION ALL query that might not perform well. The memory-optimized design with session-scoped durability (SCHEMA_ONLY) means rows exist only for the duration of the calling session and disappear automatically - no cleanup needed.

Data flows through this table in a single stored procedure call: `Wallet.GetTransactionList_temp` first DELETEs any prior rows for the session (filtered by @@SPID), then INSERTs rows from six table-valued functions (GetSentTransactionList, GetCryptoToFiatTransactionList, GetReceivedTransactionList, GetConversionTransactionList, GetPaymentTransactionList, GetStakingTransactionList), and finally SELECTs the combined results ordered by BeginDate DESC.

---

## 2. Business Logic

### 2.1 Session Isolation via SPID Filter

**What**: Each database session can only see its own rows, enforced by a CHECK constraint on @@SPID.

**Columns/Parameters Involved**: `SpidFilter`

**Rules**:
- The `SpidFilter` column defaults to `@@spid` (the current session's process ID)
- A CHECK constraint `CHK_GetTransactionRequests_SpidFilter` enforces `SpidFilter = @@spid`
- This guarantees complete session isolation without explicit transaction management - each caller sees only their own assembled results

### 2.2 Multi-Source Transaction Assembly

**What**: Six different transaction types are assembled into a single unified schema.

**Columns/Parameters Involved**: `TransactionType`, `CorrelationId`, `Status`, `Amount`, plus domain-specific columns

**Rules**:
- Sent transactions: Basic crypto sends (Amount, Address, BlockchainFees)
- Received transactions: Incoming crypto (Amount, Address)
- Conversion transactions: Crypto-to-crypto swaps (FromCryptoId, ToCryptoId, FromAmount, ToAmount, ExchangeRate)
- Payment transactions: Fiat-related payments (FiatId, FiatAmount, ProviderPaymentId, Chargeback fields)
- Crypto-to-fiat transactions: C2F operations (FiatAmount, ExchangeRate)
- Staking transactions: Staking rewards/operations (BlockchainFees, EtoroFeePercentage)

**Diagram**:
```
Wallet.GetTransactionList_temp
  |
  +--> DELETE FROM dbo.GetTransactionRequests (session cleanup)
  |
  +--> INSERT FROM Wallet.GetSentTransactionList()
  +--> INSERT FROM Wallet.GetCryptoToFiatTransactionList()
  +--> INSERT FROM Wallet.GetReceivedTransactionList()
  +--> INSERT FROM Wallet.GetConversionTransactionList()
  +--> INSERT FROM Wallet.GetPaymentTransactionList()
  +--> INSERT FROM Wallet.GetStakingTransactionList()
  |
  +--> SELECT TOP(@RecordsLimit) * ORDER BY BeginDate DESC
```

---

## 3. Data Overview

N/A - Table is SCHEMA_ONLY (non-durable) and session-scoped. Rows exist only during active procedure execution and are not persistently stored. Row count is always 0 outside of an active session.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Request correlation identifier linking this transaction to the originating wallet operation across all Wallet schema tables. Used to trace end-to-end flow. |
| 2 | BeginDate | datetime2(7) | YES | - | CODE-BACKED | Transaction initiation timestamp. The primary sort column for the final result set (ORDER BY BeginDate DESC). |
| 3 | Amount | decimal(36,18) | YES | - | CODE-BACKED | Transaction amount in native cryptocurrency units. Populated for sent, received, payment, and staking transactions. NULL for pure conversion records. |
| 4 | Status | int | YES | - | CODE-BACKED | Transaction status code. Meaning varies by transaction type but generally follows: 0=Pending, 1=Confirmed, 2=Verified, 3=Error, 4=Timeout, 5=PermanentError, 6=WavedError (Dictionary.TransactionStatus). |
| 5 | BlockChainTransactionId | nvarchar(100) | YES | - | CODE-BACKED | Primary blockchain transaction hash. The on-chain identifier for the transaction. For conversions, this is the first leg's transaction hash. |
| 6 | Address | nvarchar(max) | YES | - | CODE-BACKED | Source or destination blockchain address for the transaction. For sent transactions, this is the recipient; for received, this is the deposit address. |
| 7 | TransactionType | int | YES | - | CODE-BACKED | Transaction type classifier: 0=Redeem, 1=CustomerMoneyOut, 2=AmlMoneyBack, 4=Funding, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking, 10=BlockChainActivation, 11=OmnibusMoneyOut, 12=ConversionToFiat, 13=ManualUserMoneyOut, 14=StakeAndRewardsRefund, 15=CustomerMoneyBack (Dictionary.TransactionTypes). |
| 8 | EtoroFee | decimal(36,18) | YES | - | CODE-BACKED | eToro platform fee charged for this transaction, in native crypto units. Populated for sent, conversion, and payment transactions. |
| 9 | BlockchainFees | decimal(36,18) | YES | - | CODE-BACKED | On-chain network/gas fee for the blockchain transaction. Populated when an actual on-chain transfer occurs. |
| 10 | FromCryptoId | int | YES | - | CODE-BACKED | Source cryptocurrency ID for conversion transactions. Maps to Wallet.CryptoTypes (1=BTC, 2=ETH, etc.). NULL for non-conversion types. |
| 11 | ToCryptoId | int | YES | - | CODE-BACKED | Target cryptocurrency ID for conversion transactions. Maps to Wallet.CryptoTypes. NULL for non-conversion types. |
| 12 | FromAmount | decimal(36,18) | YES | - | CODE-BACKED | Amount of source cryptocurrency in a conversion. The amount debited from the source wallet. |
| 13 | ToAmount | decimal(36,18) | YES | - | CODE-BACKED | Amount of target cryptocurrency received in a conversion. The amount credited to the destination wallet. |
| 14 | ToAddress | nvarchar(max) | YES | - | CODE-BACKED | Destination address for conversions or multi-address transactions. Separate from Address when source and destination differ. |
| 15 | ExchangeRate | decimal(36,18) | YES | - | CODE-BACKED | Conversion exchange rate applied between the two cryptocurrencies or between crypto and fiat. Populated for conversion and C2F transactions. |
| 16 | BlockchainFees2 | decimal(36,18) | YES | - | CODE-BACKED | Second blockchain fee for conversion transactions involving two on-chain transfers (e.g., swap requires sending crypto A and receiving crypto B on different chains). |
| 17 | BlockChainTransactionId2 | nvarchar(100) | YES | - | CODE-BACKED | Second blockchain transaction hash for conversion transactions with two on-chain legs. |
| 18 | ProviderPaymentId | varchar(100) | YES | - | CODE-BACKED | External payment provider's reference ID for fiat payment transactions. Links to the third-party payment processor's record. |
| 19 | FiatId | int | YES | - | CODE-BACKED | Fiat currency identifier for payment and C2F transactions. References the platform's currency lookup. |
| 20 | FiatName | varchar(20) | YES | - | CODE-BACKED | Fiat currency display name (e.g., "USD", "EUR"). Denormalized from the currency lookup for direct display. |
| 21 | FiatAmount | decimal(36,18) | YES | - | CODE-BACKED | Fiat currency amount involved in the transaction. For payments, this is the fiat value; for C2F, the fiat proceeds. |
| 22 | EtoroFeePercentage | decimal(36,18) | YES | - | CODE-BACKED | eToro fee as a percentage of the transaction amount. Populated for payment and staking transactions. |
| 23 | EtoroFeeCalculated | decimal(36,18) | YES | - | CODE-BACKED | Calculated eToro fee amount based on the percentage. The actual fee deducted, in the transaction's denomination. |
| 24 | ProviderFeePercentage | decimal(36,18) | YES | - | CODE-BACKED | Third-party payment provider's fee as a percentage. Populated for payment transactions involving external providers. |
| 25 | ProviderFeeCalculated | decimal(36,18) | YES | - | CODE-BACKED | Calculated provider fee amount based on the percentage. The actual provider fee deducted from the payment. |
| 26 | InitiationTime | datetime2(7) | YES | - | CODE-BACKED | Timestamp when the transaction was initiated in the payment provider's system. May differ from BeginDate which tracks the wallet system's awareness. |
| 27 | ModificationTime | datetime2(7) | YES | - | CODE-BACKED | Last modification timestamp from the payment provider. Tracks when the provider last updated the transaction status. |
| 28 | ChargebackDate | datetime2(7) | YES | - | CODE-BACKED | Date when a chargeback was filed against this payment transaction. NULL if no chargeback occurred. |
| 29 | ChargebackAmount | decimal(36,18) | YES | - | CODE-BACKED | Amount of the chargeback in the payment's denomination. The value being disputed/reversed. |
| 30 | ChargebackDescription | varchar(256) | YES | - | CODE-BACKED | Chargeback reason description from the payment provider. Explains why the chargeback was initiated. |
| 31 | ChargebackVerificationCode | varchar(20) | YES | - | CODE-BACKED | Verification code associated with the chargeback for dispute resolution tracking. |
| 32 | TransactionError | varchar(max) | YES | - | CODE-BACKED | Error message or error details when the transaction failed. Contains the failure reason for debugging and customer support. |
| 33 | SpidFilter | smallint | NO | @@spid | CODE-BACKED | Session process ID filter. Defaults to @@spid and is constrained to equal @@spid, ensuring each session can only see its own rows. Enables the memory-optimized table to serve as a per-session scratchpad. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransactionType | Dictionary.TransactionTypes | Lookup | Classifies transaction type: 0=Redeem through 15=CustomerMoneyBack |
| Status | Dictionary.TransactionStatus | Lookup | Transaction processing status: 0=Pending through 6=WavedError |
| FromCryptoId / ToCryptoId | Wallet.CryptoTypes | Lookup | Cryptocurrency identifier for conversion transactions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetTransactionList_temp | - | WRITER + READER | Primary (and only) consumer - populates and reads back the assembled transaction list |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetTransactionList_temp | Stored Procedure | DELETE + INSERT (6 sources) + SELECT - assembles unified transaction list |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_SpidFiler | NONCLUSTERED | SpidFilter | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (default) | DEFAULT | SpidFilter = @@spid - automatically tags rows with the calling session's process ID |
| CHK_GetTransactionRequests_SpidFilter | CHECK | SpidFilter = @@spid - prevents any session from reading/writing another session's rows |

**Special**: `MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY` - table structure persists across restarts but data does not. Rows exist only during the session that created them.

---

## 8. Sample Queries

### 8.1 Retrieve transaction list for a customer (via procedure)
```sql
EXEC Wallet.GetTransactionList_temp
    @Gcid = 9694133,
    @CryptoId = 1,
    @BeginDateAfter = '2024-01-01',
    @BeginDateBefore = '2024-12-31'
```

### 8.2 Check if any session data exists (diagnostic)
```sql
SELECT SpidFilter, COUNT(*) AS Rows
FROM dbo.GetTransactionRequests WITH (NOLOCK)
GROUP BY SpidFilter
```

### 8.3 Examine transaction type distribution (during active session only)
```sql
SELECT TransactionType, COUNT(*) AS Cnt
FROM dbo.GetTransactionRequests WITH (NOLOCK)
GROUP BY TransactionType
ORDER BY Cnt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 33 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GetTransactionRequests | Type: Table | Source: WalletDB/dbo/Tables/dbo.GetTransactionRequests.sql*

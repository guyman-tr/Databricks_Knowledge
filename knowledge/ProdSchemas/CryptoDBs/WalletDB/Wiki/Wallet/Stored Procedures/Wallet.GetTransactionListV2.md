# Wallet.GetTransactionListV2

> V2 of the unified transaction history endpoint, aggregating a customer's sends, receives, conversions, crypto-to-fiat, payments, and staking transactions from six V2 table-valued functions into a single chronological result set.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns unified transaction list for Gcid + CryptoId + date range |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the V2 replacement for `Wallet.GetTransactionList`, providing the same unified transaction history for a customer but calling V2 versions of five of the six underlying table-valued functions (send, C2F, conversion, payment, staking). The receive TVF remains unchanged (`GetReceivedTransactionList`). The V2 functions contain updated logic and column mappings reflecting newer transaction processing patterns.

Like its predecessor, this procedure merges all transaction types into a single temp table with a superset schema, sorts by date descending, and returns up to @RecordsLimit rows. The @FromBackOffice flag enables extended visibility for the C2F, payment, and staking TVFs. No service accounts have direct EXECUTE permissions - this is likely called through the back-office API layer.

---

## 2. Business Logic

### 2.1 Six-Function V2 Aggregation

**What**: Each transaction type has a dedicated V2 TVF returning its subset of history into a common schema.

**Columns/Parameters Involved**: `@Gcid`, `@CryptoId`, `@BeginDateAfter`, `@BeginDateBefore`, `@RecordsLimit`, `@FromBackOffice`

**Rules**:
- GetSentTransactionListV2: Customer sends - populates address, fees, travel rule fields
- GetCryptoToFiatTransactionListV2: Crypto-to-fiat sales - populates fiat details, exchange rate
- GetReceivedTransactionList: Incoming receives (non-V2) - populates amount, address, travel rule
- GetConversionTransactionListV2: Crypto swaps - populates from/to crypto, dual blockchain fields
- GetPaymentTransactionListV2: Fiat payments - populates all fee/chargeback fields
- GetStakingTransactionListV2: Staking operations - populates fee percentages, initiation time
- Final: TOP(@RecordsLimit) ORDER BY BeginDate DESC with OPTION (RECOMPILE)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Global Customer ID whose transaction history to retrieve. |
| 2 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency filter. FK to Wallet.CryptoTypes. |
| 3 | @BeginDateAfter | datetime2(7) | NO | - | CODE-BACKED | Start of date range (inclusive). |
| 4 | @BeginDateBefore | datetime2(7) | NO | - | CODE-BACKED | End of date range (inclusive). |
| 5 | @RecordsLimit | int | YES | 10000 | CODE-BACKED | Maximum rows to return from the merged result. |
| 6 | @FromBackOffice | bit | YES | 0 | CODE-BACKED | When 1, enables extended columns in C2F, payment, and staking TVFs. |
| 7 | CorrelationId (output) | uniqueidentifier | YES | - | CODE-BACKED | Business request correlation ID for cross-system tracing. |
| 8 | BeginDate (output) | datetime2(7) | YES | - | CODE-BACKED | Transaction timestamp for chronological ordering. |
| 9 | Amount (output) | decimal(36,18) | YES | - | CODE-BACKED | Primary crypto amount. Interpretation varies by TransactionType. |
| 10 | Status (output) | int | YES | - | CODE-BACKED | Transaction status code. Meaning varies by type. |
| 11 | BlockChainTransactionId (output) | nvarchar(100) | YES | - | CODE-BACKED | On-chain transaction hash. |
| 12 | Address (output) | nvarchar(max) | YES | - | CODE-BACKED | Blockchain address (destination for sends, source for receives). |
| 13 | TransactionType (output) | int | YES | - | CODE-BACKED | Category discriminator identifying which TVF produced this row. |
| 14 | EtoroFee (output) | decimal(36,18) | YES | - | CODE-BACKED | eToro service fee. |
| 15 | BlockchainFees (output) | decimal(36,18) | YES | - | CODE-BACKED | Primary blockchain network fee. |
| 16 | FromCryptoId (output) | int | YES | - | CODE-BACKED | Source crypto for conversions. |
| 17 | ToCryptoId (output) | int | YES | - | CODE-BACKED | Destination crypto for conversions. |
| 18 | FromAmount (output) | decimal(36,18) | YES | - | CODE-BACKED | Source amount in conversions. |
| 19 | ToAmount (output) | decimal(36,18) | YES | - | CODE-BACKED | Destination amount in conversions. |
| 20 | ToAddress (output) | nvarchar(max) | YES | - | CODE-BACKED | Destination address for conversions. |
| 21 | ExchangeRate (output) | decimal(36,18) | YES | - | CODE-BACKED | Exchange rate for conversions/payments. |
| 22 | BlockchainFees2 (output) | decimal(36,18) | YES | - | CODE-BACKED | Secondary chain fee for conversions. |
| 23 | BlockChainTransactionId2 (output) | nvarchar(100) | YES | - | CODE-BACKED | Secondary chain hash for conversions. |
| 24 | ProviderPaymentId (output) | varchar(100) | YES | - | CODE-BACKED | Payment provider reference ID. |
| 25 | FiatId (output) | int | YES | - | CODE-BACKED | Fiat currency ID for C2F/payments. |
| 26 | FiatName (output) | varchar(20) | YES | - | CODE-BACKED | Fiat currency name. |
| 27 | FiatAmount (output) | decimal(36,18) | YES | - | CODE-BACKED | Fiat amount for C2F/payments. |
| 28 | EtoroFeePercentage (output) | decimal(36,18) | YES | - | CODE-BACKED | eToro fee as percentage. |
| 29 | EtoroFeeCalculated (output) | decimal(36,18) | YES | - | CODE-BACKED | Calculated eToro fee amount. |
| 30 | ProviderFeePercentage (output) | decimal(36,18) | YES | - | CODE-BACKED | Provider fee percentage. |
| 31 | ProviderFeeCalculated (output) | decimal(36,18) | YES | - | CODE-BACKED | Calculated provider fee. |
| 32 | InitiationTime (output) | datetime2(7) | YES | - | CODE-BACKED | Transaction initiation time. |
| 33 | ModificationTime (output) | datetime2(7) | YES | - | CODE-BACKED | Last modification time. |
| 34 | ChargebackDate (output) | datetime2(7) | YES | - | CODE-BACKED | Chargeback date if applicable. |
| 35 | ChargebackAmount (output) | decimal(36,18) | YES | - | CODE-BACKED | Chargeback amount. |
| 36 | ChargebackDescription (output) | varchar(256) | YES | - | CODE-BACKED | Chargeback reason. |
| 37 | ChargebackVerificationCode (output) | varchar(20) | YES | - | CODE-BACKED | Chargeback verification reference. |
| 38 | AdditionalDetails (output) | varchar(1000) | YES | - | CODE-BACKED | Extra context for C2F transactions. |
| 39 | TransactionError (output) | varchar(max) | YES | - | CODE-BACKED | Error description if failed. |
| 40 | TravelRuleRequired (output) | bit | YES | - | CODE-BACKED | Whether travel rule compliance was required. |
| 41 | TravelRuleStatus (output) | varchar(64) | YES | - | CODE-BACKED | Travel rule compliance status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.GetSentTransactionListV2 | TVF call | Send transaction history (V2) |
| - | Wallet.GetCryptoToFiatTransactionListV2 | TVF call | C2F transaction history (V2) |
| - | Wallet.GetReceivedTransactionList | TVF call | Receive transaction history |
| - | Wallet.GetConversionTransactionListV2 | TVF call | Conversion history (V2) |
| - | Wallet.GetPaymentTransactionListV2 | TVF call | Payment history (V2) |
| - | Wallet.GetStakingTransactionListV2 | TVF call | Staking history (V2) |

### 5.2 Referenced By (other objects point to this)

No direct EXECUTE grants found. Likely accessed through the application layer or via dynamic SQL from the back-office API.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetTransactionListV2 (procedure)
+-- Wallet.GetSentTransactionListV2 (function)
+-- Wallet.GetCryptoToFiatTransactionListV2 (function)
+-- Wallet.GetReceivedTransactionList (function)
+-- Wallet.GetConversionTransactionListV2 (function)
+-- Wallet.GetPaymentTransactionListV2 (function)
+-- Wallet.GetStakingTransactionListV2 (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetSentTransactionListV2 | TVF | SELECT FROM - send transactions |
| Wallet.GetCryptoToFiatTransactionListV2 | TVF | SELECT FROM - C2F transactions |
| Wallet.GetReceivedTransactionList | TVF | SELECT FROM - receive transactions |
| Wallet.GetConversionTransactionListV2 | TVF | SELECT FROM - conversion transactions |
| Wallet.GetPaymentTransactionListV2 | TVF | SELECT FROM - payment transactions |
| Wallet.GetStakingTransactionListV2 | TVF | SELECT FROM - staking transactions |

### 6.2 Objects That Depend On This

No dependents found via EXECUTE grants.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. OPTION (RECOMPILE) on final SELECT optimizes for variable temp table sizes.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get all transactions for a customer in the last month
```sql
EXEC Wallet.GetTransactionListV2
    @Gcid = 30351701,
    @CryptoId = 1,
    @BeginDateAfter = '2026-03-15',
    @BeginDateBefore = '2026-04-15';
```

### 8.2 Get transactions with back-office extended detail
```sql
EXEC Wallet.GetTransactionListV2
    @Gcid = 30351701,
    @CryptoId = 1,
    @BeginDateAfter = '2026-01-01',
    @BeginDateBefore = '2026-04-15',
    @RecordsLimit = 500,
    @FromBackOffice = 1;
```

### 8.3 Compare V1 and V2 outputs
```sql
-- V1 (original):
EXEC Wallet.GetTransactionList @Gcid=30351701, @CryptoId=1, @BeginDateAfter='2026-03-15', @BeginDateBefore='2026-04-15';
-- V2 (this SP - uses V2 TVFs):
EXEC Wallet.GetTransactionListV2 @Gcid=30351701, @CryptoId=1, @BeginDateAfter='2026-03-15', @BeginDateBefore='2026-04-15';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 40 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetTransactionListV2 | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetTransactionListV2.sql*

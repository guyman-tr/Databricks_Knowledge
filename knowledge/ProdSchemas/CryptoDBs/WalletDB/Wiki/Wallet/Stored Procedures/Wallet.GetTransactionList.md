# Wallet.GetTransactionList

> Aggregates a customer's complete transaction history across all transaction types (sends, receives, conversions, payments, staking, crypto-to-fiat) into a unified result set by calling six specialized table-valued functions and merging their outputs.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns unified transaction list for a customer + crypto + date range |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the master transaction history endpoint for a customer. It provides a unified, chronologically sorted list of all wallet transactions for a given customer (Gcid), cryptocurrency (CryptoId), and date range. Rather than querying each transaction type separately, it delegates to six specialized table-valued functions - one per transaction category - and merges their results into a single temp table with a common schema.

The sole consumer is the back-office API (BackApiUser), which uses this to power the transaction history view in the customer management interface. A single API call retrieves all transaction types, enabling operations staff to see a customer's complete wallet activity in one timeline.

The temp table schema is a superset of all transaction types' fields. Each TVF populates the columns relevant to its type, leaving others NULL. For example, conversion transactions populate FromCryptoId/ToCryptoId/ExchangeRate while send transactions populate Address/EtoroFee/BlockchainFees. The final SELECT returns the merged results ordered by BeginDate DESC, limited to @RecordsLimit rows.

---

## 2. Business Logic

### 2.1 Six-Function Aggregation Pattern

**What**: Each transaction type has a dedicated TVF that returns its subset of transaction history, all merged into one common schema.

**Columns/Parameters Involved**: All six TVFs receive the same core parameters: `@Gcid`, `@CryptoId`, `@BeginDateAfter`, `@BeginDateBefore`, `@RecordsLimit`

**Rules**:
- GetSentTransactionList: Customer sends (withdrawals) - populates BlockChainTransactionId, Address, EtoroFee, BlockchainFees, TravelRule fields
- GetCryptoToFiatTransactionList: Crypto-to-fiat sales - populates FiatAmount, FiatId, ExchangeRate, AdditionalDetails
- GetReceivedTransactionList: Incoming receives - populates Amount, Address, TravelRule fields
- GetConversionTransactionList: Crypto-to-crypto swaps - populates From/To CryptoId, From/To Amount, ExchangeRate, dual blockchain fields
- GetPaymentTransactionList: Fiat payment transactions - populates all fee fields, chargeback fields, provider payment details
- GetStakingTransactionList: Staking operations - populates Amount, fee percentages, initiation time

**Diagram**:
```
@Gcid + @CryptoId + Date Range
        |
  +-----+-----+-----+-----+-----+-----+
  |     |     |     |     |     |     |
  v     v     v     v     v     v     v
 Sent  C2F  Recv  Conv  Pay  Stake
  |     |     |     |     |     |
  v     v     v     v     v     v
  +---> #GetTransactionRequests (merged) <---+
                    |
                    v
          TOP(@RecordsLimit)
          ORDER BY BeginDate DESC
```

### 2.2 Back-Office Extended Parameters

**What**: The @FromBackOffice flag enables additional data visibility for operations staff.

**Columns/Parameters Involved**: `@FromBackOffice`

**Rules**:
- Default 0 (standard view)
- When 1, passed to GetCryptoToFiatTransactionList, GetPaymentTransactionList, and GetStakingTransactionList
- These functions return additional detail columns when called from back-office context
- Send, Receive, and Conversion functions do not use this flag

### 2.3 OPTION (RECOMPILE) for Query Optimization

**What**: Forces plan recompilation on the final SELECT to handle variable-size temp tables.

**Columns/Parameters Involved**: Final SELECT statement

**Rules**:
- The temp table size varies dramatically based on customer activity and date range
- RECOMPILE ensures the optimizer sees actual row counts rather than estimated statistics
- Prevents cached plan inefficiencies when alternating between high-activity and low-activity customers

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Global Customer ID. Identifies the customer whose transaction history to retrieve. Passed to all six TVFs. |
| 2 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency filter. Limits results to transactions involving this crypto. FK to Wallet.CryptoTypes. |
| 3 | @BeginDateAfter | datetime2(7) | NO | - | CODE-BACKED | Start of the date range (inclusive). Only transactions on or after this date are included. |
| 4 | @BeginDateBefore | datetime2(7) | NO | - | CODE-BACKED | End of the date range (inclusive). Only transactions on or before this date are included. |
| 5 | @RecordsLimit | int | YES | 10000 | CODE-BACKED | Maximum number of records to return. Applied to the final merged result set, not to individual TVFs. Default 10000. |
| 6 | @FromBackOffice | bit | YES | 0 | CODE-BACKED | When 1, enables extended data visibility in C2F, Payment, and Staking TVFs. Default 0 (standard). |
| 7 | CorrelationId (output) | uniqueidentifier | YES | - | CODE-BACKED | Business request correlation ID. Links each transaction to its parent request. |
| 8 | BeginDate (output) | datetime2(7) | YES | - | CODE-BACKED | Transaction timestamp. Used for chronological ordering. |
| 9 | Amount (output) | decimal(36,18) | YES | - | CODE-BACKED | Primary crypto amount for the transaction. Interpretation varies by TransactionType. |
| 10 | Status (output) | int | YES | - | CODE-BACKED | Transaction status code. Meaning varies by TransactionType (sent status vs receive status vs conversion status). |
| 11 | BlockChainTransactionId (output) | nvarchar(100) | YES | - | CODE-BACKED | On-chain hash. Present for send, receive, conversion, and staking transactions. |
| 12 | Address (output) | nvarchar(max) | YES | - | CODE-BACKED | Blockchain address. For sends: destination. For receives: source. For conversions: source address. |
| 13 | TransactionType (output) | int | YES | - | VERIFIED | Transaction category discriminator. Determines which columns in the row are populated. Values correspond to the six TVF types. |
| 14 | EtoroFee (output) | decimal(36,18) | YES | - | CODE-BACKED | eToro service fee for the transaction. |
| 15 | BlockchainFees (output) | decimal(36,18) | YES | - | CODE-BACKED | Network fee for the primary blockchain transaction. |
| 16 | FromCryptoId (output) | int | YES | - | CODE-BACKED | Source crypto for conversions. NULL for non-conversion transactions. |
| 17 | ToCryptoId (output) | int | YES | - | CODE-BACKED | Destination crypto for conversions. NULL for non-conversion transactions. |
| 18 | FromAmount (output) | decimal(36,18) | YES | - | CODE-BACKED | Amount of source crypto in conversions. |
| 19 | ToAmount (output) | decimal(36,18) | YES | - | CODE-BACKED | Amount of destination crypto in conversions. |
| 20 | ToAddress (output) | nvarchar(max) | YES | - | CODE-BACKED | Destination address for conversions. |
| 21 | ExchangeRate (output) | decimal(36,18) | YES | - | CODE-BACKED | Exchange rate applied. For conversions: crypto-to-crypto. For payments: crypto-to-fiat. |
| 22 | BlockchainFees2 (output) | decimal(36,18) | YES | - | CODE-BACKED | Network fee for the second leg of a conversion (destination chain). |
| 23 | BlockChainTransactionId2 (output) | nvarchar(100) | YES | - | CODE-BACKED | On-chain hash for the second leg of a conversion. |
| 24 | ProviderPaymentId (output) | varchar(100) | YES | - | CODE-BACKED | Payment provider's reference ID. For payment transactions only. |
| 25 | FiatId (output) | int | YES | - | CODE-BACKED | Fiat currency ID for C2F and payment transactions. |
| 26 | FiatName (output) | varchar(20) | YES | - | CODE-BACKED | Fiat currency name (e.g., 'USD', 'EUR'). For payment transactions only. |
| 27 | FiatAmount (output) | decimal(36,18) | YES | - | CODE-BACKED | Fiat amount for C2F and payment transactions. |
| 28 | EtoroFeePercentage (output) | decimal(36,18) | YES | - | CODE-BACKED | eToro fee as a percentage. For payments and staking. |
| 29 | EtoroFeeCalculated (output) | decimal(36,18) | YES | - | CODE-BACKED | Calculated eToro fee amount. For payments and staking. |
| 30 | ProviderFeePercentage (output) | decimal(36,18) | YES | - | CODE-BACKED | Provider fee percentage. For payment transactions. |
| 31 | ProviderFeeCalculated (output) | decimal(36,18) | YES | - | CODE-BACKED | Calculated provider fee amount. For payment transactions. |
| 32 | InitiationTime (output) | datetime2(7) | YES | - | CODE-BACKED | When the transaction was initiated (vs BeginDate which may be the execution time). For payments and staking. |
| 33 | ModificationTime (output) | datetime2(7) | YES | - | CODE-BACKED | Last modification timestamp. For payment transactions. |
| 34 | ChargebackDate (output) | datetime(7) | YES | - | CODE-BACKED | Date of chargeback if one occurred. For payment transactions. |
| 35 | ChargebackAmount (output) | decimal(36,18) | YES | - | CODE-BACKED | Chargeback amount. For payment transactions. |
| 36 | ChargebackDescription (output) | varchar(256) | YES | - | CODE-BACKED | Chargeback reason. For payment transactions. |
| 37 | ChargebackVerificationCode (output) | varchar(20) | YES | - | CODE-BACKED | Chargeback verification reference. For payment transactions. |
| 38 | AdditionalDetails (output) | varchar(1000) | YES | - | CODE-BACKED | Additional context for C2F transactions (e.g., exchange details). |
| 39 | TransactionError (output) | varchar(max) | YES | - | CODE-BACKED | Error description if the transaction failed. Present across all types except receive. |
| 40 | TravelRuleRequired (output) | bit | YES | - | CODE-BACKED | Whether travel rule compliance was required. For send and receive transactions. |
| 41 | TravelRuleStatus (output) | varchar(64) | YES | - | CODE-BACKED | Travel rule compliance status. For send and receive transactions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.GetSentTransactionList | TVF call | Send transaction history |
| - | Wallet.GetCryptoToFiatTransactionList | TVF call | Crypto-to-fiat transaction history |
| - | Wallet.GetReceivedTransactionList | TVF call | Receive transaction history |
| - | Wallet.GetConversionTransactionList | TVF call | Conversion transaction history |
| - | Wallet.GetPaymentTransactionList | TVF call | Payment transaction history |
| - | Wallet.GetStakingTransactionList | TVF call | Staking transaction history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Back-office API for unified customer transaction history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetTransactionList (procedure)
+-- Wallet.GetSentTransactionList (function)
+-- Wallet.GetCryptoToFiatTransactionList (function)
+-- Wallet.GetReceivedTransactionList (function)
+-- Wallet.GetConversionTransactionList (function)
+-- Wallet.GetPaymentTransactionList (function)
+-- Wallet.GetStakingTransactionList (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetSentTransactionList | Table-Valued Function | SELECT FROM - send transactions |
| Wallet.GetCryptoToFiatTransactionList | Table-Valued Function | SELECT FROM - C2F transactions |
| Wallet.GetReceivedTransactionList | Table-Valued Function | SELECT FROM - receive transactions |
| Wallet.GetConversionTransactionList | Table-Valued Function | SELECT FROM - conversion transactions |
| Wallet.GetPaymentTransactionList | Table-Valued Function | SELECT FROM - payment transactions |
| Wallet.GetStakingTransactionList | Table-Valued Function | SELECT FROM - staking transactions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Temp table #GetTransactionRequests is created without indexes; the final SELECT uses OPTION (RECOMPILE) to optimize the sort on BeginDate DESC.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get all transactions for a customer in the last month
```sql
EXEC Wallet.GetTransactionList
    @Gcid = 30351701,
    @CryptoId = 1,
    @BeginDateAfter = '2026-03-15',
    @BeginDateBefore = '2026-04-15';
```

### 8.2 Get transactions with back-office extended detail
```sql
EXEC Wallet.GetTransactionList
    @Gcid = 30351701,
    @CryptoId = 1,
    @BeginDateAfter = '2026-01-01',
    @BeginDateBefore = '2026-04-15',
    @RecordsLimit = 500,
    @FromBackOffice = 1;
```

### 8.3 Analyze transaction type distribution for a customer
```sql
-- After calling the SP, group by TransactionType
-- TransactionType values identify the source TVF
SELECT TransactionType, COUNT(*) AS TxCount,
       SUM(ISNULL(Amount, 0)) AS TotalAmount
FROM #GetTransactionRequests
GROUP BY TransactionType;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 40 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetTransactionList | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetTransactionList.sql*

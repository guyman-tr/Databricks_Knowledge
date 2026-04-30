# Wallet.GetWalletsBalance

> Computes comprehensive wallet balances for a set of customer-crypto pairs, calculating total, confirmed, and spendable balances from transaction history while detecting discrepancies against cached provider balances, with special handling for XRP reserve requirements and recent conversion cooldowns.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns computed balances per wallet from GcidAndCryptoIds TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the core balance computation procedure for the wallet platform, used by five consumer groups: balance service, back-office API, wallet team, customer support, and Tier 2 support. It computes three balance types for each wallet: TotalBalance (all non-failed transactions), ConfirmedBalance (only verified/confirmed transactions), and SpendableBalance (total minus reserved amounts). It also detects discrepancies between the computed balance and the cached provider balance.

The procedure takes a TVP of (Gcid, CryptoId) pairs and processes them in bulk using seven temp tables: wallets (base data), sent (outbound totals), received (inbound totals), balances (cached provider balance), conversions (last conversion time), payments (last payment time), and xrpAttributes (XRP-specific reserve amounts). The final SELECT joins all temp tables to produce a comprehensive balance view with discrepancy detection.

Data flows through a multi-stage pipeline: first resolving wallets from CustomerWalletsView, then aggregating sent/received amounts with status-based inclusion/exclusion logic, then comparing against cached WalletBalances, and finally computing the HasBalanceDiscrepancy flag and TooRecentConversion cooldown indicator.

---

## 2. Business Logic

### 2.1 Three-Tier Balance Computation

**What**: Computes three distinct balance levels from transaction history.

**Columns/Parameters Involved**: `TotalBalance`, `ConfirmedBalance`, `SpendableBalance`

**Rules**:
- TotalBalance = Received.TotalAmount - Sent.TotalAmount - XRP_reserve (if CryptoId=4)
- ConfirmedBalance = Received.ConfirmedAmount - Sent.ConfirmedAmount - XRP_reserve
- SpendableBalance = TotalBalance - XRP_ReservedAmount (from WalletPoolAttributes, default 25 XRP)
- XRP (CryptoId=4) has a fixed 0.0225 XRP deduction from total/confirmed (network minimum balance)
- ConfirmedAmount only includes transactions with 'Verified' or 'Confirmed' status

### 2.2 Status-Based Transaction Inclusion

**What**: Different transaction statuses are included/excluded differently for total vs confirmed amounts.

**Columns/Parameters Involved**: `SentTransactionStatuses`, `ReceivedTransactionStatuses`, `Dictionary.TransactionStatus`

**Rules**:
- Sent: Excludes Timeout, PermanentError, WavedError (these failed, funds didn't move)
- Sent: Special rule for XRP/XLM (CryptoId 4, 21): PermanentError and WavedError transactions still count their blockchain fee but not their amount
- Received: Excludes Timeout, PermanentError, WavedError
- Self-sends excluded: Outputs TO the wallet's own addresses are filtered out (not counted as spent)
- Self-receives excluded: Receives FROM the wallet's own addresses are filtered out

### 2.3 Balance Discrepancy Detection

**What**: Compares computed balance against cached provider balance to detect inconsistencies.

**Columns/Parameters Involved**: `HasBalanceDiscrepancy`, `Balance`, `BalanceThreshold`

**Rules**:
- Balance = latest WalletBalances.Balance (most recent active balance record where DateTo = '3000-01-01')
- HasBalanceDiscrepancy = 1 when ABS(TotalBalance - Balance) > BalanceThreshold (from CryptoTypes)
- Balance defaults to -1000 for base-chain wallets without a cached balance (forces discrepancy)
- Balance defaults to 0 for token sub-wallets without a cached balance

### 2.4 Recent Conversion/Payment Cooldown

**What**: Flags wallets that had a recent conversion or payment, as balance may not yet be settled.

**Columns/Parameters Involved**: `TooRecentConversion`, `@DBBalanceIntervalFromLastConversionMinutes`

**Rules**:
- TooRecentConversion = 1 when either last conversion OR last payment occurred within @DBBalanceIntervalFromLastConversionMinutes minutes
- Default threshold is 0 (disabled) - caller must pass a positive value to enable
- Used to suppress false balance discrepancy alerts during settlement windows

### 2.5 eToro Fee Handling by Crypto Type

**What**: Blockchain fees are conditionally included based on the crypto's fee handling model.

**Columns/Parameters Involved**: `CryptoTypes.IsEtoroHandlingFee`, `SentTransactions.BlockchainFee`

**Rules**:
- When IsEtoroHandlingFee = 0: blockchain fee is deducted from wallet balance (customer pays)
- When IsEtoroHandlingFee = 1: blockchain fee is NOT deducted (eToro absorbs the fee)
- This controls whether BlockchainFee is included in the sent amount calculation

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GcidAndCryptoIds | Wallet.GcidAndCryptoIds | NO | - | VERIFIED | TVP containing (Gcid, CryptoId) pairs to compute balances for. |
| 2 | @DBBalanceIntervalFromLastConversionMinutes | int | YES | 0 | VERIFIED | Minutes after a conversion/payment during which TooRecentConversion is flagged. 0 = disabled. |
| 3 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Wallet ID. |
| 4 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID. |
| 5 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency. |
| 6 | TotalBalance (output) | decimal | NO | - | VERIFIED | Computed balance from all non-failed transactions (received - sent - XRP reserve). |
| 7 | ConfirmedBalance (output) | decimal | NO | - | VERIFIED | Computed balance from only Verified/Confirmed transactions. |
| 8 | SpendableBalance (output) | decimal | NO | - | VERIFIED | TotalBalance minus XRP reserved amount (for XRP wallets). Equals TotalBalance for non-XRP. |
| 9 | HasBalanceDiscrepancy (output) | bit | NO | - | VERIFIED | 1 = computed TotalBalance differs from cached provider Balance by more than BalanceThreshold. |
| 10 | TooRecentConversion (output) | bit | NO | - | CODE-BACKED | 1 = wallet had a conversion or payment within the cooldown window. Balance may not yet be settled. |
| 11 | BlockchainProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider's reference for this wallet. |
| 12 | Balance (output) | decimal | YES | - | CODE-BACKED | Cached provider balance from WalletBalances. -1000 if no cached balance for base-chain wallets. |
| 13 | BalanceThreshold (output) | decimal | YES | - | CODE-BACKED | Acceptable discrepancy threshold from CryptoTypes. Varies by cryptocurrency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GcidAndCryptoIds | Wallet.CustomerWalletsView | JOIN | Resolves wallets from Gcid+CryptoId pairs |
| - | Wallet.SentTransactions + SentTransactionOutputs | Aggregation | Outbound amount calculation |
| - | Wallet.SentTransactionStatuses + Dictionary.TransactionStatus | Status resolution | Transaction status for inclusion logic |
| - | Wallet.ReceivedTransactions + ReceivedTransactionStatuses | Aggregation | Inbound amount calculation |
| - | Wallet.WalletBalances | Latest balance | Cached provider balance for discrepancy check |
| - | Wallet.ConversionTransactions | Latest conversion | Conversion cooldown detection |
| - | Wallet.Payments | Latest payment | Payment cooldown detection |
| - | Wallet.WalletPool + WalletPoolAttributes | XRP attributes | XRP reserve amount |
| - | Wallet.CryptoTypes | Config | Fee handling flag, balance threshold |
| - | Wallet.WalletAddresses | Self-send filter | Excludes outputs to own addresses |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Back-office balance display |
| BalanceUser | - | EXECUTE | Core balance computation |
| WalletTeam | - | EXECUTE | Team-level balance monitoring |
| CS | - | EXECUTE | Customer support balance inquiries |
| Tier2 | - | EXECUTE | Tier 2 support balance inquiries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletsBalance (procedure)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionOutputs (table)
+-- Wallet.SentTransactionStatuses (table)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.ReceivedTransactionStatuses (table)
+-- Wallet.WalletBalances (table)
+-- Wallet.ConversionTransactions (table)
+-- Wallet.Payments (table)
+-- Wallet.WalletPool (table)
+-- Wallet.WalletPoolAttributes (table)
+-- Wallet.WalletAddresses (table)
+-- Wallet.CryptoTypes (table)
+-- Dictionary.TransactionStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Base wallet resolution |
| Wallet.SentTransactions | Table | Outbound transaction data |
| Wallet.SentTransactionOutputs | Table | Output amounts (excluding self-sends) |
| Wallet.SentTransactionStatuses | Table | Latest sent status |
| Wallet.ReceivedTransactions | Table | Inbound transaction data |
| Wallet.ReceivedTransactionStatuses | Table | Latest received status |
| Wallet.WalletBalances | Table | Cached provider balance |
| Wallet.ConversionTransactions | Table | Last conversion timestamp |
| Wallet.Payments | Table | Last payment timestamp |
| Wallet.WalletPool + WalletPoolAttributes | Tables | XRP reserve amount |
| Wallet.WalletAddresses | Table | Self-send address filter |
| Wallet.CryptoTypes | Table | Fee handling, balance threshold |
| Dictionary.TransactionStatus | Table | Status name resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser, BalanceUser, WalletTeam, CS, Tier2 | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses 7 temp tables and OPTION (RECOMPILE) on final SELECT.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Compute balance for specific wallets
```sql
DECLARE @ids Wallet.GcidAndCryptoIds;
INSERT INTO @ids VALUES (30351701, 1); -- BTC
INSERT INTO @ids VALUES (30351701, 19); -- DOGE
EXEC Wallet.GetWalletsBalance @GcidAndCryptoIds = @ids;
```

### 8.2 With conversion cooldown detection
```sql
DECLARE @ids Wallet.GcidAndCryptoIds;
INSERT INTO @ids VALUES (30351701, 1);
EXEC Wallet.GetWalletsBalance @GcidAndCryptoIds = @ids, @DBBalanceIntervalFromLastConversionMinutes = 30;
```

### 8.3 Find wallets with discrepancies
```sql
-- After running the SP, filter results where HasBalanceDiscrepancy = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletsBalance | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletsBalance.sql*

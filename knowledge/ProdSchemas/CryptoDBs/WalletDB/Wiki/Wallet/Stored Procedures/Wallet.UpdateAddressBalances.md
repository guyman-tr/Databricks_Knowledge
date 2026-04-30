# Wallet.UpdateAddressBalances

> Bulk-updates wallet balance snapshots using temporal versioning (DateFrom/DateTo), skipping unchanged balances and only writing when values actually differ, used by the back-office API and balance service for provider-reported balance ingestion.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE + INSERT into WalletBalances with change detection (temporal) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure ingests bulk balance updates from the blockchain provider. It uses a temporal pattern: each balance snapshot has a DateFrom and DateTo. The active balance has DateTo='3000-01-01'. When a balance changes, the current active record's DateTo is set to now, and a new record is inserted with the new balance and DateTo='3000-01-01'. Unchanged balances are detected and skipped to minimize writes.

The back-office API and balance service call this with a TVP of (BalanceAccountID, CryptoId, Balance) tuples. The procedure resolves BalanceAccountIDs to WalletAddressIds, identifies which balances actually changed, and performs the temporal update transactionally.

---

## 2. Business Logic

### 2.1 Temporal Balance Versioning with Change Detection

**What**: Only writes when the balance has actually changed.

**Columns/Parameters Involved**: `WalletBalances.DateFrom`, `DateTo`, `Balance`

**Rules**:
- Resolves BalanceAccountID to WalletAddresses.Id
- Identifies unchanged balances: WHERE DateTo='3000-01-01' AND Balance = new balance -> skip
- For changed balances: UPDATE DateTo = NOW on current active record
- INSERT new record with DateFrom=NOW, DateTo='3000-01-01', new Balance
- Transaction ensures atomic UPDATE + INSERT

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AddressBalances | Wallet.CurrentBalanceType | NO | - | VERIFIED | TVP of (BalanceAccountID, CryptoId, Balance) tuples from the provider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BalanceAccountID | Wallet.WalletAddresses | JOIN | Resolves to WalletAddressId |
| - | Wallet.WalletBalances | UPDATE + INSERT | Temporal balance versioning |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser, BalanceUser | - | EXECUTE | Balance ingestion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.UpdateAddressBalances (procedure)
+-- Wallet.WalletAddresses (table)
+-- Wallet.WalletBalances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletAddresses | Table | BalanceAccountID resolution |
| Wallet.WalletBalances | Table | Temporal UPDATE + INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser, BalanceUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Creates clustered index on temp table for performance.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Update balances
```sql
DECLARE @balances Wallet.CurrentBalanceType;
INSERT INTO @balances VALUES ('BA-12345', 1, 0.5), ('BA-67890', 19, 100.0);
EXEC Wallet.UpdateAddressBalances @AddressBalances = @balances;
```

### 8.2 Check current balances
```sql
SELECT * FROM Wallet.WalletBalances WITH (NOLOCK) WHERE DateTo = '3000-01-01' ORDER BY WalletAddressesId;
```

### 8.3 Check balance history
```sql
SELECT * FROM Wallet.WalletBalances WITH (NOLOCK) WHERE WalletAddressesId = 12345 ORDER BY DateFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.UpdateAddressBalances | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.UpdateAddressBalances.sql*

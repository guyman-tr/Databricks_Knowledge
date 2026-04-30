# Wallet.V_WalletBalances

> View enriching wallet balance snapshots with customer Gcid, WalletId, CryptoId, and InstrumentId by joining WalletBalances through WalletAddresses and CustomerWalletsView to CryptoTypes. **NOTE: Currently has binding errors in production - not queryable.**

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | View |
| **Key Identifier** | WalletAddressesId (bigint) + CryptoId (int) + DateTo (datetime2) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view enriches wallet balance snapshots with customer and instrument context. It joins WalletBalances -> WalletAddresses -> CustomerWalletsView -> CryptoTypes to produce rows that include the customer Gcid, the WalletId, the CryptoId, the InstrumentId (from CryptoTypes), and the balance date range. This enables balance queries that include customer identity and trading instrument mapping in a single view.

**Current status**: This view has binding errors in the live database (`Could not use view or function 'Wallet.V_WalletBalances' because of binding errors`). This typically means a column referenced by the view has been renamed, removed, or its type changed in one of the base objects. The DDL in SSDT defines the view, but it cannot be queried in the current database state.

The view's only consumer is `Wallet.ForDelete_GetWalletBalances` (a ForDelete procedure), suggesting this view may be deprecated or scheduled for removal. It joins through `WalletBalances.WalletAddressesId` which requires WalletBalances to have that column - the binding error may indicate this column was removed or renamed.

---

## 2. Business Logic

### 2.1 Balance-to-Customer Resolution

**What**: The view chains multiple JOINs to resolve a balance record back to its customer and instrument.

**Columns/Parameters Involved**: `WalletAddressesId`, `WalletId`, `Gcid`, `InstrumentId`

**Rules**:
- `WalletBalances.WalletAddressesId -> WalletAddresses.Id`: Maps balance to address record
- `WalletAddresses.WalletId -> CustomerWalletsView.Id`: Maps address to active customer wallet
- `CustomerWalletsView.CryptoId -> CryptoTypes.CryptoId`: Maps crypto to trading instrument
- All JOINs are INNER, meaning only balances for active customer wallets with valid addresses appear

---

## 3. Data Overview

N/A - view cannot be queried due to binding errors in the live database.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletAddressesId | bigint | NO | - | CODE-BACKED | The WalletAddresses record linked to this balance. From WalletBalances.WalletAddressesId. Note: this column may not exist in the current WalletBalances schema (binding error). |
| 2 | Gcid | bigint | NO | - | VERIFIED | Global Customer ID. Resolved via CustomerWalletsView. Enables customer-level balance reporting. |
| 3 | WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet this balance belongs to. From WalletAddresses.WalletId -> CustomerWalletsView.Id. |
| 4 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency. From CustomerWalletsView.CryptoId. Matches on WalletBalances.CryptoId. FK to Wallet.CryptoTypes.CryptoID. |
| 5 | InstrumentId | int | YES | - | CODE-BACKED | Trading platform instrument ID mapped from the crypto asset. From Wallet.CryptoTypes.InstrumentId. Bridges crypto wallet system to the trading platform's instrument namespace. |
| 6 | DateFrom | datetime2(7) | NO | - | CODE-BACKED | Start of balance snapshot validity window. From WalletBalances.DateFrom. |
| 7 | DateTo | datetime2(7) | NO | - | CODE-BACKED | End of balance snapshot validity window. 3000-01-01 = current balance. From WalletBalances.DateTo. |
| 8 | Balance | decimal(36,18) | YES | - | VERIFIED | Confirmed crypto balance in native units. From WalletBalances.Balance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletAddressesId | Wallet.WalletBalances | JOIN (source) | Balance snapshots |
| WalletAddressesId | Wallet.WalletAddresses | JOIN | Resolves WalletId from address record |
| WalletId, CryptoId | Wallet.CustomerWalletsView | JOIN | Resolves customer Gcid |
| CryptoId | Wallet.CryptoTypes | JOIN | Resolves InstrumentId |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.ForDelete_GetWalletBalances | Procedure (ForDelete) | READER | Reads balances for deletion purposes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.V_WalletBalances (view, BINDING ERRORS)
+-- Wallet.WalletBalances (table)
+-- Wallet.WalletAddresses (table)
+-- Wallet.CustomerWalletsView (view)
|   +-- Wallet.Wallets (table)
|   +-- Wallet.WalletPool (table)
|   +-- Wallet.WalletAssets (table)
+-- Wallet.CryptoTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletBalances | Table | Source of balance snapshots (WalletAddressesId JOIN) |
| Wallet.WalletAddresses | Table | Maps WalletAddressesId to WalletId |
| Wallet.CustomerWalletsView | View | Resolves customer Gcid and CryptoId match |
| Wallet.CryptoTypes | Table | Resolves InstrumentId from CryptoId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ForDelete_GetWalletBalances | Procedure (ForDelete) | Reads balance data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BINDING ERROR | Runtime Error | View references `WalletBalances.WalletAddressesId` which may not exist in the current database schema. The view DDL exists in SSDT but cannot be materialized. |

---

## 8. Sample Queries

### 8.1 Query the view (when binding is fixed)
```sql
SELECT Gcid, WalletId, CryptoId, InstrumentId, Balance, DateFrom, DateTo
FROM Wallet.V_WalletBalances WITH (NOLOCK)
WHERE Gcid = 9248755
  AND DateTo = '3000-01-01'
```

### 8.2 Workaround using base tables directly
```sql
SELECT cw.Gcid, wa.WalletId, cw.CryptoId, ct.InstrumentId, wb.Balance, wb.DateFrom, wb.DateTo
FROM Wallet.WalletBalances wb WITH (NOLOCK)
INNER JOIN Wallet.WalletAddresses wa WITH (NOLOCK) ON wb.WalletAddressesId = wa.Id
INNER JOIN Wallet.CustomerWalletsView cw WITH (NOLOCK) ON wa.WalletId = cw.Id AND cw.CryptoId = wb.CryptoId
INNER JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoId = cw.CryptoId
WHERE cw.Gcid = 9248755
```

### 8.3 Check if binding error still exists
```sql
SELECT TOP 1 * FROM Wallet.V_WalletBalances WITH (NOLOCK)
-- If this returns data, the binding is fixed. If error, the column mismatch persists.
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 7.5/10 (Elements: 10/10, Logic: 6/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/7 (Phase 2 blocked by binding error)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.V_WalletBalances | Type: View | Source: WalletDB/Wallet/Views/Wallet.V_WalletBalances.sql*

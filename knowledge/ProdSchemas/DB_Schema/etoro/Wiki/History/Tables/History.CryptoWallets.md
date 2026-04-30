# History.CryptoWallets

> Temporal HISTORY_TABLE for CryptoLiquidity.CryptoWallets - currently empty (no version history yet); will store versioned snapshots of crypto wallet configurations as they change.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table (clustered on SysEndTime, SysStartTime) |
| **Partition** | No |
| **Temporal** | Yes - HISTORY_TABLE for CryptoLiquidity.CryptoWallets |
| **Indexes** | 1 (clustered on SysEndTime ASC, SysStartTime ASC) |
| **Compression** | DATA_COMPRESSION=PAGE |

---

## 1. Business Meaning

History.CryptoWallets is the SQL Server temporal HISTORY_TABLE for CryptoLiquidity.CryptoWallets. It stores versioned row snapshots when crypto wallet configurations are modified.

CryptoLiquidity.CryptoWallets defines the crypto wallets used by eToro's crypto liquidity system - including wallet name, type (WalletType), the liquidity provider (ProviderId), the balance source (BalanceSource), and optional comments. These wallets handle cryptocurrency deposits, withdrawals, and position management.

0 rows - CryptoLiquidity.CryptoWallets has never had a row updated or deleted since temporal versioning was enabled. All wallet configurations are still at their original values.

---

## 2. Business Logic

### 2.1 Auto-Managed by SQL Server Temporal Versioning

**What**: Every modification to a row in CryptoLiquidity.CryptoWallets writes the prior version here.

**Rules**:
- Never written to directly
- 0 rows = wallet configurations have been stable since temporal versioning was configured

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 0 |
| **Status** | Empty - no wallet configuration changes recorded |

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Pid | int | NO | Wallet process/provider ID. Primary identifier for the wallet in CryptoLiquidity.CryptoWallets. |
| 2 | Name | varchar(64) | NO | Wallet name (e.g., "ETH-Main", "BTC-Liquidity"). |
| 3 | WalletType | int | NO | Type of wallet. Implicit FK to a wallet type lookup. |
| 4 | ProviderId | int | YES | Liquidity provider ID associated with this wallet. Implicit FK to provider table. |
| 5 | BalanceSource | int | NO | Source for balance queries (e.g., on-chain, custodian API). |
| 6 | Comments | varchar(256) | YES | Optional notes about the wallet configuration. |
| 7 | DbLoginName | nvarchar(128) | YES | SQL Server login at time of change. Audit column. |
| 8 | AppLoginName | varchar(500) | YES | Application login from context_info(). Audit column. |
| 9 | SysStartTime | datetime2(7) | NO | When this version became current. |
| 10 | SysEndTime | datetime2(7) | NO | When this version was superseded. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | CryptoLiquidity.CryptoWallets | HISTORY_TABLE (temporal) | Auto-managed history for CryptoLiquidity.CryptoWallets. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Compression |
|-----------|------|-------------|-------------|
| ix_CryptoWallets | CLUSTERED | SysEndTime ASC, SysStartTime ASC | PAGE |

---

*Generated: 2026-03-19 | Quality: 8.0/10 (Elements: 8.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Object: History.CryptoWallets | Type: Table | Source: etoro/etoro/History/Tables/History.CryptoWallets.sql*

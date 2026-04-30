# Wallet.SagaSendTx_History

> System-managed temporal history table for Wallet.SagaSendTx, automatically storing previous versions of saga send transaction rows when they are updated.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | No PK (heap with clustered index on temporal columns) |
| **Partition** | No |
| **Indexes** | 1 clustered index on (EndDate, BeginDate) |

---

## 1. Business Meaning

This is the system-managed temporal history table for `Wallet.SagaSendTx`. SQL Server automatically moves previous row versions here when the parent table's rows are updated. It provides a complete audit trail of how saga send transaction state changed over time. The table mirrors the parent's column structure with explicit BeginDate/EndDate temporal columns.

Currently empty (parent table SagaSendTx is also empty - legacy/deprecated feature).

---

## 2. Business Logic

N/A - system-managed temporal history table. Data is automatically managed by SQL Server's SYSTEM_VERSIONING feature.

---

## 3. Data Overview

Table is empty (parent SagaSendTx is also empty).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SagaID | int | NO | - | CODE-BACKED | Saga execution identifier (mirrors parent PK). |
| 2 | WalletID | int | NO | - | CODE-BACKED | Wallet identifier (legacy integer format). |
| 3 | GCID | int | NO | - | CODE-BACKED | Global Customer ID (legacy integer format). |
| 4 | CryptoID | int | NO | - | CODE-BACKED | Cryptocurrency identifier. |
| 5 | DestAddress | nvarchar(256) | NO | - | CODE-BACKED | Destination blockchain address. |
| 6 | Amount | int | NO | - | CODE-BACKED | Send amount in smallest units. |
| 7 | TxHash | nvarchar(256) | YES | - | CODE-BACKED | Blockchain transaction hash. |
| 8 | TxTimestamp | datetime | YES | - | CODE-BACKED | Transaction timestamp. |
| 9 | TxHex | varbinary(1) | YES | - | CODE-BACKED | Unsigned transaction hex (stub). |
| 10 | TxHexPartSigned | varbinary(1) | YES | - | CODE-BACKED | Partially signed transaction hex (stub). |
| 11 | TxHexSigned | varbinary(1) | YES | - | CODE-BACKED | Fully signed transaction hex (stub). |
| 12 | Confirmations | int | YES | - | CODE-BACKED | Blockchain confirmations. |
| 13 | CurrentStepIndex | int | NO | - | CODE-BACKED | Current saga step. |
| 14 | BeginDate | datetime2(7) | NO | - | CODE-BACKED | Temporal period start - when this version became active. |
| 15 | EndDate | datetime2(7) | NO | - | CODE-BACKED | Temporal period end - when this version was superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.SagaSendTx | Temporal | History table for the parent temporal table |

### 5.2 Referenced By (other objects point to this)

Not directly referenced. Accessed via FOR SYSTEM_TIME queries on parent.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies (system-managed).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaSendTx | Table | Parent temporal table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_SagaSendTx_History | CLUSTERED | EndDate ASC, BeginDate ASC | - | - | Active |

### 7.2 Constraints

None. System-managed table.

---

## 8. Sample Queries

### 8.1 View all history
```sql
SELECT * FROM Wallet.SagaSendTx_History WITH (NOLOCK) ORDER BY EndDate DESC
```

### 8.2 Query via parent temporal syntax
```sql
SELECT * FROM Wallet.SagaSendTx FOR SYSTEM_TIME ALL ORDER BY SagaID, BeginDate
```

### 8.3 Row count
```sql
SELECT COUNT(*) FROM Wallet.SagaSendTx_History WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.SagaSendTx_History | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.SagaSendTx_History.sql*

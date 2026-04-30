# Wallet.SagaSendTx

> Legacy saga-based send transaction state table, tracking the execution state of blockchain send operations using a step-based saga pattern with temporal versioning for state change history.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | SagaID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |
| **Temporal** | Yes - SYSTEM_VERSIONING with history table Wallet.SagaSendTx_History |

---

## 1. Business Meaning

This table stores the state of saga-based send transaction workflows in the legacy saga execution engine. Each row tracks a single send operation through its multi-step execution: wallet selection, transaction signing, blockchain broadcast, and confirmation. The temporal versioning provides a full audit trail of state changes. Currently empty (0 rows), suggesting this legacy saga mechanism has been superseded by the newer `Wallet.SagaRuns`/`Wallet.SagaSteps` framework.

---

## 2. Business Logic

No complex logic. Legacy table with temporal state tracking for saga-based transaction execution.

---

## 3. Data Overview

Table is empty (0 rows). This is a legacy/deprecated saga execution table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SagaID | int | NO | - | CODE-BACKED | Saga execution identifier. Manually assigned PK. |
| 2 | WalletID | int | NO | - | CODE-BACKED | Wallet identifier (legacy integer format, not the GUID used in current tables). |
| 3 | GCID | int | NO | - | CODE-BACKED | Global Customer ID (legacy integer format). |
| 4 | CryptoID | int | NO | - | CODE-BACKED | Cryptocurrency identifier. |
| 5 | DestAddress | nvarchar(256) | NO | - | CODE-BACKED | Destination blockchain address for the send. |
| 6 | Amount | int | NO | - | CODE-BACKED | Amount to send (legacy integer format - likely in smallest units). |
| 7 | TxHash | nvarchar(256) | YES | - | CODE-BACKED | Blockchain transaction hash after broadcast. NULL until transaction is submitted. |
| 8 | TxTimestamp | datetime | YES | - | CODE-BACKED | Timestamp of the blockchain transaction. |
| 9 | TxHex | varbinary(1) | YES | - | CODE-BACKED | Raw unsigned transaction hex (legacy, 1-byte stub). |
| 10 | TxHexPartSigned | varbinary(1) | YES | - | CODE-BACKED | Partially signed transaction hex (legacy, 1-byte stub). |
| 11 | TxHexSigned | varbinary(1) | YES | - | CODE-BACKED | Fully signed transaction hex (legacy, 1-byte stub). |
| 12 | Confirmations | int | YES | - | CODE-BACKED | Number of blockchain confirmations received. |
| 13 | CurrentStepIndex | int | NO | - | CODE-BACKED | Current step in the saga execution sequence. |
| 14 | BeginDate | datetime2(7) | NO | sysutcdatetime() | CODE-BACKED | Temporal ROW START. |
| 15 | EndDate | datetime2(7) | NO | 9999-12-31... | CODE-BACKED | Temporal ROW END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references.

### 5.2 Referenced By (other objects point to this)

Not directly referenced. Legacy table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaSendTx_History | Table | Temporal history table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK__SagaSendTx_SagaID | CLUSTERED PK | SagaID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_SagaSendTx_BeginDate | DEFAULT | sysutcdatetime() |
| DF_SagaSendTx_EndDate | DEFAULT | 9999-12-31 23:59:59.9999999 |

---

## 8. Sample Queries

### 8.1 Check if table has any data
```sql
SELECT COUNT(*) AS RowCount FROM Wallet.SagaSendTx WITH (NOLOCK)
```

### 8.2 View temporal history
```sql
SELECT * FROM Wallet.SagaSendTx FOR SYSTEM_TIME ALL ORDER BY SagaID, BeginDate
```

### 8.3 Find active sagas
```sql
SELECT SagaID, CryptoID, DestAddress, Amount, CurrentStepIndex FROM Wallet.SagaSendTx WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.SagaSendTx | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.SagaSendTx.sql*

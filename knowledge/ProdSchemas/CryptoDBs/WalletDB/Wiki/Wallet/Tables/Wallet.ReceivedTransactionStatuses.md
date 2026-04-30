# Wallet.ReceivedTransactionStatuses

> Event-sourced status history for received blockchain transactions, tracking each processing step from detection through AML screening to final acknowledgment.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 5 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table tracks the processing lifecycle of received (inbound) blockchain transactions. Unlike `Wallet.SentTransactionStatuses` which tracks blockchain confirmation states, this table tracks the internal processing pipeline: detection, AML screening, crediting, and notification. The `DetailsJson` column captures rich context for each processing step.

Rows are created by `Wallet.InsertReceivedTransactionStatus` as the receive processing pipeline progresses.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Status progression mirrors the request status flow for receive transactions. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for high-volume event table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing event identifier. |
| 2 | ReceivedTransactionId | bigint | NO | - | VERIFIED | The received transaction this status belongs to. FK to Wallet.ReceivedTransactions.Id. |
| 3 | StatusId | tinyint | NO | - | CODE-BACKED | Processing status. Uses the same Dictionary.TransactionStatus values as sent transactions but in the context of receive processing (0=Pending processing, 1=Confirmed/credited, etc.). |
| 4 | Occurred | datetime2(7) | YES | getutcdate() | CODE-BACKED | Timestamp of this processing step. |
| 5 | DetailsJson | varchar(max) | YES | - | CODE-BACKED | JSON payload with step-specific context (AML results, error details, processing metadata). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReceivedTransactionId | Wallet.ReceivedTransactions | FK | Parent received transaction |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertReceivedTransactionStatus | - | Writer | Appends status events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.ReceivedTransactionStatuses (table)
└── Wallet.ReceivedTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactions | Table | FK target for ReceivedTransactionId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertReceivedTransactionStatus | Stored Procedure | Inserts status events |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ReceivedTransactionStatuses | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Occurred_inc_ReceivedTransactionId_StatusId | NC | Occurred | ReceivedTransactionId, StatusId | - | Active |
| IX_ReceivedTransactionStatuses_StatusId | NC | StatusId | ReceivedTransactionId | - | Active |
| IX_...ReceivedTransactionId_Id | NC | ReceivedTransactionId, Id DESC | - | - | Active |
| IX_...ReceivedTransactionId_Occurred | NC | ReceivedTransactionId, Occurred DESC | - | - | Active |
| IX_...ReceivedTransactionId_Occurred_Inc | NC | ReceivedTransactionId, Occurred DESC | StatusId | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_...Occurred | DEFAULT | getutcdate() |
| FK_...ReceivedTransactionId | FK | -> Wallet.ReceivedTransactions.Id |

---

## 8. Sample Queries

### 8.1 Get status history for a received transaction
```sql
SELECT rts.Id, rts.StatusId, rts.Occurred, rts.DetailsJson
FROM Wallet.ReceivedTransactionStatuses rts WITH (NOLOCK)
WHERE rts.ReceivedTransactionId = 2525976
ORDER BY rts.Id
```

### 8.2 Latest status per received transaction
```sql
SELECT rts.ReceivedTransactionId, rts.StatusId, rts.Occurred
FROM Wallet.ReceivedTransactionStatuses rts WITH (NOLOCK)
WHERE rts.Id = (SELECT MAX(rts2.Id) FROM Wallet.ReceivedTransactionStatuses rts2 WITH (NOLOCK) WHERE rts2.ReceivedTransactionId = rts.ReceivedTransactionId)
  AND rts.ReceivedTransactionId > 2525900
```

### 8.3 Find receives with errors
```sql
SELECT rts.ReceivedTransactionId, rts.StatusId, rts.Occurred, rts.DetailsJson
FROM Wallet.ReceivedTransactionStatuses rts WITH (NOLOCK)
WHERE rts.StatusId = 3
ORDER BY rts.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ReceivedTransactionStatuses | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.ReceivedTransactionStatuses.sql*

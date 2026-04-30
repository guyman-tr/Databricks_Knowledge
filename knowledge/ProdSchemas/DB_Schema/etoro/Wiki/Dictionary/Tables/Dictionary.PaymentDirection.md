# Dictionary.PaymentDirection

> Lookup table defining the 2 payment communication directions — From Googess (internal) and From PSP (external) — identifying who initiated the payment message.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PaymentDirectionID (INT, PK NONCLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Row Count** | 2 (MCP verified) |
| **Indexes** | 2 active (PK nonclustered + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.PaymentDirection classifies the origin of a payment communication message logged in History.PaymentLog. Every payment interaction between eToro and its PSPs (Payment Service Providers) generates log entries, and each entry is tagged with a direction indicating who initiated the message.

"Googess" is eToro's internal payment orchestration system/gateway — when eToro sends a request to a PSP (e.g., initiate a deposit charge, request a cashout), the direction is "From Googess" (1). When the PSP sends a response or callback notification back to eToro (e.g., transaction result, webhook), the direction is "From PSP" (2).

This bidirectional logging is essential for payment reconciliation, debugging failed transactions, and audit trails. The PaymentDirectionID is written by Billing.PaymentLogAdd for every payment communication and read by Billing.LoadPaymentDirections for caching.

---

## 2. Business Logic

### 2.1 Payment Communication Directions

**What**: The two directions of payment message flow.

**Columns/Parameters Involved**: `PaymentDirectionID`, `Name`

**Rules**:
- **From Googess (1)**: eToro's payment system (Googess) initiates communication to the PSP. This covers outbound requests: deposit charges, cashout instructions, refund requests, status inquiries. Googess is the internal name for eToro's payment gateway/orchestrator.
- **From PSP (2)**: The Payment Service Provider sends communication back to eToro. This covers inbound responses: transaction results, webhook callbacks (postbacks), settlement confirmations, error notifications.

**Diagram**:
```
Payment Communication Flow:

  eToro (Googess)                    PSP (Visa/PayPal/etc.)
       │                                    │
       ├── Request (Direction=1) ──────────►│
       │                                    │
       │◄────────── Response (Direction=2) ──┤
       │                                    │
       │◄────────── Callback (Direction=2) ──┤
       │                                    │
  [History.PaymentLog records both directions]
```

---

## 3. Data Overview

| PaymentDirectionID | Name | Meaning |
|---|---|---|
| 1 | From Googess | Outbound message initiated by eToro's internal payment orchestration system (Googess). Covers all requests sent to PSPs: charge requests, cashout instructions, refund commands, and status queries. |
| 2 | From PSP | Inbound message received from the Payment Service Provider. Covers all PSP responses: transaction results, webhook/postback callbacks, settlement confirmations, and error notifications. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentDirectionID | int | NO | - | VERIFIED | Primary key identifying the communication direction. 1=From Googess (outbound, eToro→PSP), 2=From PSP (inbound, PSP→eToro). Referenced by History.PaymentLog via explicit FK. Written by Billing.PaymentLogAdd for every payment communication event. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable direction label. Unique constraint prevents duplicates. Values: 'From Googess', 'From PSP'. "Googess" is eToro's internal payment gateway name. Used in payment logs, reconciliation reports, and debugging UIs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.PaymentLog | PaymentDirectionID | Explicit FK (FK_DPMD_HPML) | Every payment log entry records the communication direction |
| Billing.PaymentLogAdd | @PaymentDirectionID | Parameter | Inserts payment log entries with direction |
| Billing.LoadPaymentDirections | - | SELECT * | Loads all directions for application-layer caching |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.PaymentDirection (table)
  └── referenced by History.PaymentLog (FK_DPMD_HPML)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.PaymentLog | Table | FK constraint on PaymentDirectionID |
| Billing.PaymentLogAdd | Stored Procedure | Writes direction per payment log entry |
| Billing.LoadPaymentDirections | Stored Procedure | Loads all directions for caching |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPMD | NONCLUSTERED PK | PaymentDirectionID ASC | - | - | Active |
| DPMD_NAME | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPMD | PRIMARY KEY | Unique direction identifier, FILLFACTOR 90, DICTIONARY filegroup |
| DPMD_NAME | UNIQUE INDEX | Ensures no duplicate direction names, FILLFACTOR 90 |

---

## 8. Sample Queries

### 8.1 List all payment directions
```sql
SELECT  PaymentDirectionID,
        Name
FROM    Dictionary.PaymentDirection WITH (NOLOCK)
ORDER BY PaymentDirectionID;
```

### 8.2 Count payment log entries by direction
```sql
SELECT  dpd.Name            AS Direction,
        COUNT(*)            AS LogEntries
FROM    History.PaymentLog hpl WITH (NOLOCK)
JOIN    Dictionary.PaymentDirection dpd WITH (NOLOCK)
        ON hpl.PaymentDirectionID = dpd.PaymentDirectionID
GROUP BY dpd.Name
ORDER BY LogEntries DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data and codebase analysis of Billing.PaymentLogAdd and History.PaymentLog FK references.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PaymentDirection | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PaymentDirection.sql*

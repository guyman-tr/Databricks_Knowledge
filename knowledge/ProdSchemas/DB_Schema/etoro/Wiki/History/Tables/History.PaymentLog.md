# History.PaymentLog

> Legacy payment gateway raw message log, storing the full text response/notification received from external payment processors (Google Checkout and PSP), associated with History.PaymentAction billing transactions.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PaymentLogID (INT IDENTITY, NONCLUSTERED PK) |
| **Partition** | No (PAGE compression, on HISTORY filegroup) |
| **Indexes** | 3 (NONCLUSTERED PK, NC on PaymentActionID, NC on PaymentDirectionID) |

---

## 1. Business Meaning

History.PaymentLog is the legacy payment gateway message log from the early eToro billing era (circa 2007-2011). When the legacy billing system received a notification or response from an external payment processor, it stored the full raw message text here along with the associated payment action and direction of the communication.

This table is the companion to History.PaymentAction (the billing transaction archive, 459,664 rows from 2007-2011). PaymentLog stores the raw gateway communication text (XML, HTTP body, or other format) that accompanied each PaymentAction, enabling debugging and reconciliation of payment processing events.

PaymentDirectionID indicates the direction of the message: 1="From Googess" (Google Checkout - the legacy Google payment product, discontinued; "Googess" is a typo in the dictionary data) or 2="From PSP" (Payment Service Provider - the generic card processor path).

The table currently has 0 rows in the live database, consistent with the legacy era of its companion History.PaymentAction. Written exclusively by Billing.PaymentLogAdd and read by Billing.LoadPaymentLogs.

---

## 2. Business Logic

### 2.1 Payment Gateway Communication Logging

**What**: Each row captures one raw message from a payment gateway, associated with a specific billing transaction action.

**Columns/Parameters Involved**: `PaymentDirectionID`, `PaymentActionID`, `PaymentLogDate`, `PaymentMessage`

**Rules**:
- Written by Billing.PaymentLogAdd, called when a payment gateway sends a notification or response.
- PaymentActionID: FK to History.PaymentAction - ties the log entry to a specific billing transaction (pre-authorization, purchase, cashout, refund, settle, etc.).
- PaymentDirectionID: FK to Dictionary.PaymentDirection:
  - 1="From Googess" (Google Checkout notifications; "Googess" is a data typo for "Google")
  - 2="From PSP" (generic Payment Service Provider responses)
- PaymentMessage: full raw gateway message text (XML, POST body, or other format). Stored as TEXT type (legacy SQL Server data type; no max length). On HISTORY filegroup via TEXTIMAGE_ON.
- PaymentLogDate: the datetime when the message was received (passed by the caller, not GETDATE() - allows accurate timestamping from when the gateway sent the message).
- SCOPE_IDENTITY() is returned by the procedure, allowing callers to reference the new PaymentLogID.

### 2.2 Legacy Gateway Context

**What**: The two payment directions correspond to the two external payment processors integrated in the early platform.

**Rules**:
- Google Checkout ("Googess"): Google's payment product that allowed customers to pay using their Google account. Google discontinued Checkout in 2013.
- PSP (Payment Service Provider): generic credit/debit card processor path.
- Both directions delivered messages "FROM" the gateway (inbound notifications), suggesting this table captures gateway-initiated callbacks (instant payment notifications, IPNs, postbacks).
- The PaymentAction.PaymentActionType (1=PreAuth, 2=Purchase, 3=Cashout, 4=Refund, 5=Settle, 6=PostBack, 7=Cancel) aligns with typical IPN lifecycle events.

---

## 3. Data Overview

Table is currently empty (0 rows) - legacy billing era table, no longer written. Data from the active 2007-2011 period was either not migrated to this environment or was purged.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentLogID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate PK. NOT FOR REPLICATION prevents identity gaps during SQL replication. |
| 2 | PaymentDirectionID | int | NO | - | CODE-BACKED | Source of the payment message. FK to Dictionary.PaymentDirection (FK_DPMD_HPML). Values: 1="From Googess" (Google Checkout; typo for "Google"), 2="From PSP" (Payment Service Provider). NC index for direction-based queries. |
| 3 | PaymentActionID | int | NO | - | CODE-BACKED | The billing transaction action this message is associated with. FK to History.PaymentAction (FK_HPMA_HPML). Links raw gateway message to a specific PaymentAction record (preauth, purchase, etc.). NC index for action-based lookups. |
| 4 | PaymentLogDate | datetime | NO | - | CODE-BACKED | Datetime when this gateway message was received/processed. Passed by the caller - not server GETDATE(). Allows accurate event timeline reconstruction. |
| 5 | PaymentMessage | text | NO | - | CODE-BACKED | Full raw message text from the payment gateway (XML, HTTP body, or other format). TEXT type (legacy; varchar(max) equivalent). Stored on HISTORY filegroup via TEXTIMAGE_ON. Contains the complete gateway notification payload. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentDirectionID | Dictionary.PaymentDirection | FK (FK_DPMD_HPML) | Payment message source direction lookup. |
| PaymentActionID | History.PaymentAction | FK (FK_HPMA_HPML) | The billing transaction action this log entry accompanies. |

### 5.2 Referenced By (other objects point to this)

No other objects reference History.PaymentLog.

---

## 6. Dependencies

### 6.0 Dependency Chain

`Dictionary.PaymentDirection` <- PaymentDirectionID FK
`History.PaymentAction` <- PaymentActionID FK

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PaymentDirection | Table | FK - validates payment direction (Google/PSP) |
| History.PaymentAction | Table | FK - the associated billing transaction action |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PaymentLogAdd | Stored Procedure | WRITER - inserts new payment log entries |
| Billing.LoadPaymentLogs | Stored Procedure | READER - returns all payment log rows (SELECT *) |
| Billing.CustomerRemove | Stored Procedure | READER/WRITER - may interact with payment log during customer removal |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HPLG | NONCLUSTERED PK | PaymentLogID ASC | - | - | Active |
| HPLG_PAYMENTACTION | NONCLUSTERED | PaymentActionID ASC | - | - | Active |
| HPLG_PAYMENTDIRECTION | NONCLUSTERED | PaymentDirectionID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HPLG | PRIMARY KEY | Unique per log entry |
| FK_DPMD_HPML | FOREIGN KEY | PaymentDirectionID -> Dictionary.PaymentDirection |
| FK_HPMA_HPML | FOREIGN KEY | PaymentActionID -> History.PaymentAction |

### 7.3 Storage

| Property | Value |
|----------|-------|
| Filegroup | HISTORY |
| TEXTIMAGE filegroup | HISTORY (for PaymentMessage text column) |
| Data Compression | PAGE |
| NOT FOR REPLICATION | Applied to IDENTITY |

---

## 8. Sample Queries

### 8.1 Get all payment log entries for a specific payment action

```sql
SELECT pl.PaymentLogID, pd.Name AS Direction, pl.PaymentLogDate,
       LEFT(CAST(pl.PaymentMessage AS varchar(500)), 200) AS MessagePreview
FROM History.PaymentLog pl WITH (NOLOCK)
JOIN Dictionary.PaymentDirection pd WITH (NOLOCK) ON pd.PaymentDirectionID = pl.PaymentDirectionID
WHERE pl.PaymentActionID = 12345
ORDER BY pl.PaymentLogDate;
```

### 8.2 Count log entries by payment direction

```sql
SELECT pd.Name AS Direction, COUNT(*) AS LogCount
FROM History.PaymentLog pl WITH (NOLOCK)
JOIN Dictionary.PaymentDirection pd WITH (NOLOCK) ON pd.PaymentDirectionID = pl.PaymentDirectionID
GROUP BY pd.Name;
```

### 8.3 Join payment logs with payment actions for full audit trail

```sql
SELECT pa.PaymentActionID, pa.PaymentID, pa.PaymentActionTypeID,
       pa.Amount / 100.0 AS AmountUSD,
       pl.PaymentLogDate, pd.Name AS LogDirection,
       LEFT(CAST(pl.PaymentMessage AS varchar(500)), 100) AS MessagePreview
FROM History.PaymentAction pa WITH (NOLOCK)
LEFT JOIN History.PaymentLog pl WITH (NOLOCK) ON pl.PaymentActionID = pa.PaymentActionID
LEFT JOIN Dictionary.PaymentDirection pd WITH (NOLOCK) ON pd.PaymentDirectionID = pl.PaymentDirectionID
WHERE pa.PaymentID = 99999
ORDER BY pa.PaymentActionID, pl.PaymentLogDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PaymentLog | Type: Table | Source: etoro/etoro/History/Tables/History.PaymentLog.sql*

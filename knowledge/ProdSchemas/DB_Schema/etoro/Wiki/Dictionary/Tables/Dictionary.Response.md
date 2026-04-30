# Dictionary.Response

> Configuration table with ~3,970 payment gateway response code mappings — translating PSP-specific response codes to eToro payment statuses, with support for protocol-specific, gateway-specific, and terminal-specific routing.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ResponseID (INT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 4 (PK nonclustered + 3 NCI on PaymentActionTypeID, PaymentStatusID, ProtocolID) |

---

## 1. Business Meaning

Dictionary.Response maps every possible response code from every payment gateway to an internal eToro payment status and action type. When a PSP returns a response (e.g., "00" for approved, "51" for insufficient funds), this table translates it into the eToro billing system's status model.

This table is the key to payment result processing. It determines whether a transaction succeeded, failed, needs retry, or should be terminated. The ShouldTerminate flag indicates whether the billing engine should stop retrying after receiving this response.

Consumed by Billing.GetResponse (response lookup during transaction processing), Billing.LoadResponses (cache loader), and Billing.GetDepositsForExecutions/GetDepositsCustomerCardPCIVersion for deposit processing.

---

## 2. Business Logic

### 2.1 Response Code Translation

**What**: Each row maps a PSP response code to an internal payment status under a specific protocol/action type.

**Columns/Parameters Involved**: `ProtocolID`, `PaymentActionTypeID`, `PaymentStatusID`, `ResponseCode`, `ResponseName`, `Meaning`, `ShouldTerminate`

**Rules**:
- The same ResponseCode can mean different things for different protocols (e.g., "00" means "Approved" for Xor but may not exist for PayPal).
- PaymentActionTypeID (FK → Dictionary.PaymentActionType) specifies whether this is a PreAuth, Purchase, Refund, etc.
- PaymentStatusID (FK → Dictionary.PaymentStatus) is the resulting eToro status after receiving this response.
- ShouldTerminate=true means the billing engine should NOT retry — the response is final (e.g., card stolen, account closed).
- TerminalID and GatewayID allow response overrides per specific terminal or gateway.

---

## 3. Data Overview

Response table contains ~3,970 rows covering all PSP-specific response code mappings. Representative rows shown from available data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ResponseID | int | NO | - | VERIFIED | Primary key. Sequential identifier for each response mapping. |
| 2 | ProtocolID | int | NO | - | VERIFIED | FK → Dictionary.Protocol. Identifies which payment protocol this response belongs to. Indexed. |
| 3 | PaymentActionTypeID | int | NO | - | VERIFIED | FK → Dictionary.PaymentActionType. The action type context (PreAuth=1, Purchase=2, Refund=3, etc.). Indexed. |
| 4 | PaymentStatusID | int | NO | - | VERIFIED | FK → Dictionary.PaymentStatus. The resulting eToro payment status (Approved=1, Declined=2, etc.). Indexed. |
| 5 | ResponseCode | varchar(50) | NO | - | VERIFIED | PSP-specific response code (e.g., "00", "51", "APPROVED", "DECLINED"). Format varies by protocol. |
| 6 | ResponseName | varchar(255) | NO | - | VERIFIED | Human-readable PSP response description (e.g., "Transaction Approved", "Insufficient Funds"). |
| 7 | Meaning | varchar(1000) | YES | - | VERIFIED | Extended explanation of the response code's meaning and recommended action. May be NULL for self-explanatory codes. |
| 8 | TerminalID | int | YES | - | VERIFIED | Optional terminal-specific override. When set, this response mapping only applies to transactions on this terminal. NULL = all terminals. |
| 9 | GatewayID | int | YES | - | VERIFIED | FK → Dictionary.Gateway. Optional gateway-specific override. When set, this mapping only applies to this gateway. NULL = all gateways. |
| 10 | ShouldTerminate | bit | YES | - | VERIFIED | When true, the billing engine should stop retrying — the response is final and won't change (e.g., card stolen, fraud, account closed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Element | FK Constraint | Description |
|-------------------|---------|---------------|-------------|
| Dictionary.Protocol | ProtocolID | FK_DPRT_DRES | Payment protocol this response belongs to |
| Dictionary.PaymentActionType | PaymentActionTypeID | FK_DPAT_DRES | Action type context (PreAuth/Purchase/Refund) |
| Dictionary.PaymentStatus | PaymentStatusID | FK_DPMS_DRES | Resulting eToro payment status |
| Dictionary.Gateway | GatewayID | FK_Dictionary_Response_GatewayID | Optional gateway-specific override |

### 5.2 Referenced By (other objects point to this)

No direct FK consumers — read as configuration by billing procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.Response
├── Dictionary.Protocol (FK)
├── Dictionary.PaymentActionType (FK)
├── Dictionary.PaymentStatus (FK)
└── Dictionary.Gateway (FK)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Protocol | Table | FK — payment protocol |
| Dictionary.PaymentActionType | Table | FK — action type context |
| Dictionary.PaymentStatus | Table | FK — resulting payment status |
| Dictionary.Gateway | Table | FK — optional gateway override |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetResponse | Stored Procedure | Reader — response lookup during transaction processing |
| Billing.LoadResponses | Stored Procedure | Reader — caches all response mappings |
| Billing.GetDepositsForExecutions | Stored Procedure | Reader — deposit processing |
| Billing.GetDepositsCustomerCardPCIVersion | Stored Procedure | Reader — PCI deposit processing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DRSP | NONCLUSTERED PK | ResponseID ASC | - | - | Active (FF=90) |
| DRSP_PAYMENTACTIONTYPE | NONCLUSTERED | PaymentActionTypeID ASC | - | - | Active (FF=90) |
| DRSP_PAYMENTSTATUS | NONCLUSTERED | PaymentStatusID ASC | - | - | Active (FF=90) |
| DRSP_PROTOCOL | NONCLUSTERED | ProtocolID ASC | - | - | Active (FF=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DRSP | PRIMARY KEY | Unique response mapping identifier |
| FK_DPRT_DRES | FOREIGN KEY | ProtocolID → Dictionary.Protocol |
| FK_DPAT_DRES | FOREIGN KEY | PaymentActionTypeID → Dictionary.PaymentActionType |
| FK_DPMS_DRES | FOREIGN KEY | PaymentStatusID → Dictionary.PaymentStatus |
| FK_Dictionary_Response_GatewayID | FOREIGN KEY | GatewayID → Dictionary.Gateway |

---

## 8. Sample Queries

### 8.1 Find response mapping for a protocol and code
```sql
SELECT  r.ResponseID,
        r.ResponseCode,
        r.ResponseName,
        ps.Name AS PaymentStatus,
        r.ShouldTerminate
FROM    [Dictionary].[Response] r WITH (NOLOCK)
JOIN    [Dictionary].[PaymentStatus] ps WITH (NOLOCK) ON r.PaymentStatusID = ps.PaymentStatusID
WHERE   r.ProtocolID = 31
        AND r.ResponseCode = '00';
```

### 8.2 Count response codes per protocol
```sql
SELECT  p.Name AS ProtocolName,
        COUNT(*) AS ResponseCount
FROM    [Dictionary].[Response] r WITH (NOLOCK)
JOIN    [Dictionary].[Protocol] p WITH (NOLOCK) ON r.ProtocolID = p.ProtocolID
GROUP BY p.Name
ORDER BY ResponseCount DESC;
```

### 8.3 Find terminal responses
```sql
SELECT  r.ResponseCode,
        r.ResponseName,
        r.ShouldTerminate
FROM    [Dictionary].[Response] r WITH (NOLOCK)
WHERE   r.ShouldTerminate = 1
        AND r.ProtocolID = 1
ORDER BY r.ResponseCode;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Response | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Response.sql*

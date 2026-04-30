# Billing.GetResponse

> Single-row payment gateway response code lookup: given a PSP response code and protocol ID, returns the full response mapping from Dictionary.Response including the resulting eToro payment status, action type, ShouldTerminate flag, and contextual meaning.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ResponseCode + @ProtocolID (protocol-scoped response code lookup); returns 0 or 1 rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetResponse` is the real-time payment gateway response translator used by the billing engine during deposit and withdrawal processing. When a PSP returns a response code (e.g., "00" for approved, "51" for insufficient funds, "DECLINED"), the billing system calls this procedure to translate it into eToro's internal payment model.

The procedure is a thin, direct wrapper over `Dictionary.Response` - it adds no logic beyond the WHERE clause. Its value is in being the standard API through which the application resolves PSP response codes, keeping the dictionary table abstracted behind a procedure call. The companion procedure `Billing.LoadResponses` bulk-loads the entire response dictionary into application cache at startup; this procedure is used for runtime single-code lookups.

The returned row tells the caller: what is the eToro payment status (PaymentStatusID), what action type does this apply to (PaymentActionTypeID), what does this response mean in plain English (Meaning), and - critically - should the billing engine stop retrying (ShouldTerminate). A ShouldTerminate=1 result causes the billing engine to mark the payment as permanently failed, preventing wasteful retry loops for terminal responses like "card stolen" or "account closed".

---

## 2. Business Logic

### 2.1 Protocol-Scoped Response Code Resolution

**What**: Response codes are not globally unique - the same code can have different meanings across payment protocols. The ProtocolID scope ensures the correct mapping is returned.

**Columns/Parameters Involved**: `@ResponseCode`, `@ProtocolID`, `Dictionary.Response.ResponseCode`, `Dictionary.Response.ProtocolID`

**Rules**:
- `WHERE ProtocolID = @ProtocolID AND ResponseCode = @ResponseCode` - both conditions required; without ProtocolID, "00" could match Visa, PayPal, Xor, and others simultaneously with different PaymentStatusID meanings
- Returns 0 rows if the response code is unknown for this protocol (unmapped response)
- Returns 1 row for the standard mapping; may return multiple rows if TerminalID or GatewayID overrides exist for the same code (caller must select the appropriate override)
- No NOLOCK hint - this is a dictionary table with infrequent updates; read consistency is acceptable

### 2.2 ShouldTerminate Routing Decision

**What**: The ShouldTerminate bit determines whether the billing engine should retry the payment or treat it as final.

**Columns/Parameters Involved**: `ShouldTerminate`

**Rules**:
- `ShouldTerminate = 1`: The response is terminal - do not retry. Examples: card stolen, fraud flag, account permanently closed, invalid card number.
- `ShouldTerminate = 0` or NULL: The response may be transient - retry may be appropriate. Examples: network timeout, temporary processing failure.
- The billing engine reads this flag from the returned row and branches its retry/terminate logic accordingly.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ResponseCode | VARCHAR(10) | NO | - | CODE-BACKED | PSP-specific response code returned by the payment gateway (e.g., "00", "51", "APPROVED", "DECLINED"). Must match the `ResponseCode` column in `Dictionary.Response` for the given protocol. Format varies by PSP. |
| 2 | @ProtocolID | INT | NO | - | CODE-BACKED | Payment protocol identifier (FK to `Dictionary.Protocol`). Scopes the response code lookup to the specific PSP protocol in use for this transaction. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | ResponseID | INT | NO | - | CODE-BACKED | PK of the response mapping in `Dictionary.Response`. For logging and audit purposes. |
| 4 | ProtocolID | INT | NO | - | CODE-BACKED | Payment protocol ID (echoes @ProtocolID). FK to `Dictionary.Protocol`. |
| 5 | PaymentActionTypeID | INT | NO | - | CODE-BACKED | Action type this response applies to (FK to `Dictionary.PaymentActionType`). Values: 1=PreAuth, 2=Purchase, 3=Refund, etc. Determines which payment flow this response mapping is valid for. |
| 6 | PaymentStatusID | INT | NO | - | CODE-BACKED | The eToro payment status resulting from this response code (FK to `Dictionary.PaymentStatus`). Values: 1=Approved, 2=Declined, etc. This is the core translation output - the billing engine uses this to update `Billing.Deposit.PaymentStatusID` or `Billing.Withdraw.CashoutStatusID`. |
| 7 | ResponseCode | VARCHAR(50) | NO | - | CODE-BACKED | The matched PSP response code (echoes @ResponseCode). |
| 8 | ResponseName | VARCHAR(255) | NO | - | CODE-BACKED | Human-readable PSP response description (e.g., "Transaction Approved", "Insufficient Funds", "Do not honour"). |
| 9 | Meaning | VARCHAR(1000) | YES | - | CODE-BACKED | Extended explanation of the response code's business meaning and recommended action. NULL for self-explanatory codes. Useful for operations team troubleshooting. |
| 10 | TerminalID | INT | YES | - | CODE-BACKED | Optional terminal-specific override scope. NULL = applies to all terminals under this protocol. When set, this mapping only applies to the specified terminal. |
| 11 | GatewayID | INT | YES | - | CODE-BACKED | Optional gateway-specific override scope (FK to `Dictionary.Gateway`). NULL = applies to all gateways. When set, this mapping is only valid for the named gateway. |
| 12 | ShouldTerminate | BIT | YES | - | CODE-BACKED | When 1, the billing engine should stop retrying - this response is final and will not change (e.g., stolen card, fraud, closed account). When 0 or NULL, retry may be appropriate. Critical routing flag for the billing retry scheduler. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProtocolID + @ResponseCode | Dictionary.Response | SELECT (single-row lookup) | Response code to payment status translation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application billing engine (deposit processing) | @ResponseCode, @ProtocolID | EXEC | Called at runtime when a PSP returns a response code during deposit authorization |
| Application billing engine (withdrawal processing) | @ResponseCode, @ProtocolID | EXEC | Called during withdrawal processing to translate PSP response codes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetResponse (procedure)
+-- Dictionary.Response (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Response | Table | SELECT source for response code mapping lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application billing engine | External | Runtime PSP response code translation during payment processing |
| Billing.LoadResponses | Stored Procedure | Bulk response dictionary loader (uses Dictionary.Response directly; this procedure handles single lookups) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No NOLOCK | Consistency | Dictionary.Response is read without NOLOCK (configuration data, infrequent updates; consistency acceptable) |
| No SET NOCOUNT ON | Minor | Missing SET NOCOUNT ON means a row-count message is returned alongside the result set; standard for thin wrapper procedures |
| Zero rows = unmapped code | Design | If the PSP returns an unknown response code for a protocol, 0 rows are returned; caller must handle this case (typically as an error or manual review trigger) |
| Multiple rows possible | Design | If TerminalID/GatewayID overrides exist for the same protocol+ResponseCode, multiple rows may be returned; caller should prefer terminal/gateway-specific rows over generic ones |

---

## 8. Sample Queries

### 8.1 Look up an approved response code for a specific protocol
```sql
EXEC Billing.GetResponse @ResponseCode = '00', @ProtocolID = 1;
-- Returns PaymentStatusID = 1 (Approved), ShouldTerminate = 0 for standard "00" = approved
```

### 8.2 Look up a terminal decline to check if retry is appropriate
```sql
EXEC Billing.GetResponse @ResponseCode = '51', @ProtocolID = 1;
-- Returns PaymentStatusID = 2 (Declined), ShouldTerminate = 0 or 1 depending on protocol config
-- ShouldTerminate = 0 means "insufficient funds" may succeed on retry; 1 means permanent failure
```

### 8.3 View all terminal (ShouldTerminate=1) responses for a protocol
```sql
SELECT ResponseCode, ResponseName, Meaning
FROM Dictionary.Response WITH (NOLOCK)
WHERE ProtocolID = 1
  AND ShouldTerminate = 1
ORDER BY ResponseCode;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetResponse | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetResponse.sql*

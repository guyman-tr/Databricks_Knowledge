# Billing.GetPWMBAddAccountRequest

> Retrieves a PWMB (likely PayWith My Bank or similar Open Banking provider) add-account request record by its external transaction ID, used to look up the status and details of a bank account linking attempt.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Billing.PWMBAddAccountRequest rows WHERE ExternalTransactionID=@ExternalTransactionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetPWMBAddAccountRequest` retrieves a bank account addition request record from the PWMB payment provider integration. PWMB appears to be an Open Banking or bank account linking provider (the acronym likely stands for "PayWith My Bank" or similar). When a customer adds their bank account via this provider, a request record is stored in `Billing.PWMBAddAccountRequest` with an external transaction ID assigned by the PWMB provider.

The procedure exists to allow services to look up a PWMB add-account request by its external transaction ID - typically to check the status of an account linking attempt (was it successful? what account details were returned?). This is a callback/webhook pattern: eToro stores the request, sends it to PWMB, and later looks it up by the external transaction ID when PWMB returns a result.

Data flows: created RD-7470 (2019-06-23). No explicit GRANT EXECUTE found in SSDT permission files - callers likely use an application role or the procedure is called internally. The ExternalTransactionID VARCHAR(15) suggests PWMB assigns short transaction reference codes.

---

## 2. Business Logic

### 2.1 External Transaction ID Lookup

**What**: Direct lookup by PWMB's external transaction reference.

**Columns/Parameters Involved**: `@ExternalTransactionID`, `PWMBAddAccountRequest.ExternalTransactionID`

**Rules**:
- `SELECT [6 columns] FROM Billing.PWMBAddAccountRequest WHERE ExternalTransactionID = @ExternalTransactionID`
- No IsActive or status filter - returns whatever record exists for this external ID
- The ExternalTransactionID is a provider-assigned reference (VARCHAR(15)) - not an internal eToro ID
- May return 0 rows if the external transaction ID is not found (no record for this PWMB transaction)
- May return 1 row if the ID is unique (typical for external transaction references)

### 2.2 PWMB Integration Pattern

**What**: The PWMB add-account flow is a two-phase async pattern.

**Flow**:
```
Customer initiates bank account addition via PWMB
        |
        v
eToro creates PWMBAddAccountRequest record (stores ExternalTransactionID)
        |
        v
Customer completes flow at PWMB provider
        |
        v
PWMB notifies eToro (callback/webhook with ExternalTransactionID)
        |
        v
EXEC Billing.GetPWMBAddAccountRequest @ExternalTransactionID = 'PWMB-REF-001'
        |
        v
Check request status, retrieve account details, link to customer's funding instruments
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExternalTransactionID | VARCHAR(15) | NO | - | CODE-BACKED | The external transaction reference ID assigned by the PWMB provider. Used to correlate eToro's request record with the PWMB provider's transaction reference. Max length 15 chars reflects PWMB's reference format. |

**Return columns (6 columns from Billing.PWMBAddAccountRequest):**

| # | Column | Confidence | Description |
|---|--------|------------|-------------|
| 2 | (PK column) | NAME-INFERRED | Internal record ID (likely PWMBAddAccountRequestID or similar) - primary key of the request record. |
| 3 | ExternalTransactionID | CODE-BACKED | Echoed from filter - PWMB's reference ID for this add-account transaction. |
| 4 | CID | NAME-INFERRED | Customer ID - which customer initiated this bank account addition request. FK to Customer.Customer. |
| 5 | (Status column) | NAME-INFERRED | Request status (pending/completed/failed) - outcome of the account addition attempt. |
| 6 | (Account details column) | NAME-INFERRED | Bank account information returned by PWMB (account number, sort code, or similar). May be encrypted or tokenized. |
| 7 | (Timestamp column) | NAME-INFERRED | Creation or modification timestamp for the request record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ExternalTransactionID | Billing.PWMBAddAccountRequest.ExternalTransactionID | Lookup | Retrieves the add-account request record by provider reference |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No permission grants found in SSDT) | - | - | Likely called via application-level role or from a callback handler service |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPWMBAddAccountRequest (procedure)
└── Billing.PWMBAddAccountRequest (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.PWMBAddAccountRequest | Table | SELECT by ExternalTransactionID; returns all columns for the matching request record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No callers found in SSDT permission files) | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**PWMB Integration**: Created RD-7470 (2019-06-23). PWMB is an older integration (2019) - likely an Open Banking or direct debit provider that eToro used in an earlier era of payment method expansion. The VARCHAR(15) ExternalTransactionID is characteristic of payment provider reference codes. **Callers**: No GRANT EXECUTE found in SSDT permission files - this may be called from a dedicated PWMB service process or via an application role not tracked in the SSDT repo.

---

## 8. Sample Queries

### 8.1 Get a PWMB add-account request by external ID
```sql
EXEC [Billing].[GetPWMBAddAccountRequest] @ExternalTransactionID = 'PWMB12345678901'
```

### 8.2 Check recent PWMB add-account requests
```sql
SELECT TOP 20 *
FROM Billing.PWMBAddAccountRequest WITH (NOLOCK)
ORDER BY (SELECT NULL)  -- or by creation timestamp if available
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| RD-7470 (referenced in DDL comment) | Jira | Initial creation of PWMB add-account request integration (2019-06-23) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 7/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 5 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (RD-7470 in DDL comment) | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPWMBAddAccountRequest | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetPWMBAddAccountRequest.sql*

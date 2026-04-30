# Billing.PayPalBillingAgreementDelete

> Soft-deletes (via temporal versioning) a PayPal Billing Agreement record either by agreement ID or by customer ID, returning the deleted row - used when a customer revokes their PayPal billing agreement or when an agent cancels all agreements for a customer.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BillingAgreementId (agreement-level) OR @CID (customer-level) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayPalBillingAgreementDelete` removes one or more records from `Billing.PayPalBillingAgreement`, which is a system-versioned temporal table. Because the underlying table is temporal, the DELETE is not a permanent data loss - the deleted row moves to the history table automatically, preserving the full lifecycle for audit purposes.

Two exclusive delete modes exist:
- **By Agreement ID** (`@BillingAgreementId IS NOT NULL`): Deletes the specific PayPal bilateral agreement token. Used when a particular agreement is revoked.
- **By Customer** (`@CID IS NOT NULL`): Deletes all billing agreements for a customer. Used when a customer closes their account or disables PayPal as a payment method entirely.

The OUTPUT clause captures the deleted rows before they are removed, allowing the caller to confirm what was deleted or to update downstream state. Created as part of PAYUSOLA-4629 (PayPal Billing Agreement feature).

---

## 2. Business Logic

### 2.1 Delete by Agreement ID

**What**: Removes a specific PayPal billing agreement token.

**Columns Involved**: `Billing.PayPalBillingAgreement.BillingAgreementID`, `Billing.PayPalBillingAgreement.PayPalBillingAgreementID`

**Rules**:
- WHERE BillingAgreementID = @BillingAgreementId (if @BillingAgreementId IS NOT NULL).
- Removes the specific agreement by the provider's token string.
- Typically affects 1 row (BillingAgreementID is expected to be unique per customer).

### 2.2 Delete by Customer

**What**: Removes all billing agreements associated with a customer.

**Columns Involved**: `Billing.PayPalBillingAgreement.CID`

**Rules**:
- WHERE CID = @CID (if @CID IS NOT NULL).
- Removes ALL agreements for this customer.
- Used for bulk cleanup (account closure, disabling PayPal).
- May affect 0, 1, or multiple rows.

### 2.3 OUTPUT Clause

**What**: Returns all deleted rows to the caller.

**Rules**:
- DELETE ... OUTPUT DELETED.* returns all columns of the deleted row(s).
- Allows the caller to confirm what was removed and to cascade updates if needed.
- Since `Billing.PayPalBillingAgreement` is system-versioned temporal, the DELETE also inserts the deleted row into the history table automatically.

**Diagram**:
```
@BillingAgreementId IS NOT NULL?       @CID IS NOT NULL?
    YES                                    YES
    |                                      |
DELETE FROM PayPalBillingAgreement    DELETE FROM PayPalBillingAgreement
  OUTPUT DELETED.*                      OUTPUT DELETED.*
  WHERE BillingAgreementID=@Id          WHERE CID=@CID
    |                                      |
  Deletes specific agreement          Deletes ALL agreements for customer
  (1 row typically)                   (0..N rows)
    |                                      |
    Returns deleted rows via OUTPUT result set
    (row moves to temporal history table automatically)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BillingAgreementId | nvarchar(255) | YES | NULL | CODE-BACKED | The PayPal billing agreement token/ID to delete. When provided, the DELETE targets `WHERE BillingAgreementID = @BillingAgreementId`. Mutually exclusive with @CID delete path. |
| 2 | @CID | int | YES | NULL | CODE-BACKED | Customer ID. When provided, the DELETE targets `WHERE CID = @CID`, removing ALL billing agreements for this customer. Mutually exclusive with @BillingAgreementId delete path. |

**Result Set**: All columns from the deleted row(s) via `OUTPUT DELETED.*`. See `Billing.PayPalBillingAgreement` for column definitions.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BillingAgreementId / @CID | [Billing.PayPalBillingAgreement](../Tables/Billing.PayPalBillingAgreement.md) | Write (DELETE + OUTPUT) | Deletes one or more billing agreement rows; temporal versioning preserves history. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PayPal / payment application | - | EXEC | Called on agreement revocation or customer PayPal disable. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayPalBillingAgreementDelete (procedure)
└── Billing.PayPalBillingAgreement (system-versioned temporal table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.PayPalBillingAgreement](../Tables/Billing.PayPalBillingAgreement.md) | Table | DELETE with OUTPUT - removes agreement records (temporal table preserves history). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PayPal application | Application | Called to revoke a specific agreement or cancel all agreements for a customer. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

- By @BillingAgreementId: uses an index on BillingAgreementID column.
- By @CID: uses an index on CID column.
- Both target `Billing.PayPalBillingAgreement` which as a temporal table has system period columns (SysStartTime, SysEndTime). The DELETE automatically creates a history row.

### 7.2 Constraints

N/A for stored procedure.

**Temporal table behavior**: Since `Billing.PayPalBillingAgreement` is SYSTEM_VERSIONING=ON, the DELETE does not truly destroy data - it moves the row to `Billing.PayPalBillingAgreementHistory` with SysEndTime set to the deletion timestamp. Full agreement lifecycle is recoverable via the history table.

---

## 8. Sample Queries

### 8.1 Delete a specific billing agreement

```sql
EXEC Billing.PayPalBillingAgreementDelete
    @BillingAgreementId = 'B-1AB23456CD789012E',
    @CID = NULL;
-- Returns DELETED.* for the removed agreement
```

### 8.2 Delete all billing agreements for a customer

```sql
EXEC Billing.PayPalBillingAgreementDelete
    @BillingAgreementId = NULL,
    @CID = 12345;
-- Returns all deleted rows for this customer
```

### 8.3 View deleted agreements in history (post-delete audit)

```sql
SELECT *
FROM Billing.PayPalBillingAgreementHistory WITH (NOLOCK)
WHERE CID = 12345
ORDER BY SysEndTime DESC;
-- Shows the deleted rows with their deletion timestamp
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUSOLA-4629 | Jira (referenced in code comment) | PayPal Billing Agreement feature - this procedure is part of the agreement lifecycle management |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 1 Jira (code comment) | Procedures: 0 SQL callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PayPalBillingAgreementDelete | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayPalBillingAgreementDelete.sql*

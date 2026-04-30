# Billing.LoadPaymentStatuses

> Data loader intended to return all payment status definitions from Dictionary.PaymentStatuse - currently broken due to a typo in the table name (references non-existent Dictionary.PaymentStatuse instead of Dictionary.PaymentStatus).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - intended to return full payment status reference table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadPaymentStatuses is a bulk data loader intended to return all rows from Dictionary.PaymentStatus, providing the billing engine with the complete list of payment status definitions. Dictionary.PaymentStatus contains 39 rows defining the full lifecycle of deposit transactions (New, Approved, Decline, Technical, InProcess, Canceled, Confirmed, and many decline sub-types).

**CRITICAL DEFECT**: The procedure body references `Dictionary.PaymentStatuse` (with a trailing 'e') which does not exist in the database or SSDT repository. The correct table name is `Dictionary.PaymentStatus`. This means the procedure will fail with error "Invalid object name 'Dictionary.PaymentStatuse'" when executed. The likely intended source table `Dictionary.PaymentStatus` has 39 statuses covering all payment lifecycle states and decline reasons.

This procedure was part of the standard billing engine initialization pattern. Its broken state suggests the billing engine now either uses `Dictionary.PaymentStatus` directly, calls a replacement procedure, or does not rely on this loader.

---

## 2. Business Logic

### 2.1 Broken Reference - Typo in Table Name

**What**: The procedure body contains a typo that causes it to fail on every execution.

**Columns/Parameters Involved**: (none - no parameters)

**Rules**:
- Code: `SELECT * FROM Dictionary.PaymentStatuse WITH (NOLOCK)` - table `Dictionary.PaymentStatuse` does not exist.
- Intended table: `Dictionary.PaymentStatus` - exists with 39 rows defining payment statuses.
- Executing this procedure raises: "Invalid object name 'Dictionary.PaymentStatuse'".
- The intended behavior was to return all payment status definitions for billing engine cache loading.
- Dictionary.PaymentStatus values (for reference): 1=New, 2=Approved, 3=Decline, 4=Technical, 5=InProcess, 6=Canceled, 7=Confirmed, 8=DeclineBlockCard, 9=DeclineBadBins, 10=DeclineMemberLimits, 11=Chargeback, 12=Refund, 13=Pending, 14-28=Various blocked/declined states, 29-39=Additional decline reasons.

**Diagram**:
```
Billing.LoadPaymentStatuses
        |
        v [FAILS - object not found]
Dictionary.PaymentStatuse (does NOT exist)

Intended target:
Dictionary.PaymentStatus (EXISTS - 39 rows)
  1=New, 2=Approved, 3=Decline, 4=Technical,
  5=InProcess, 6=Canceled, 7=Confirmed, ...
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no input parameters) | - | - | - | - | - | This procedure takes no parameters. |
| RETURN | int | NO | - | CODE-BACKED | Intended to return 0 on success - currently fails before reaching RETURN. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT *) | Dictionary.PaymentStatuse | READ (BROKEN) | References a non-existent table due to typo. Intended target is Dictionary.PaymentStatus. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing Engine (BILLING_MANAGER role) | - | EXEC | Permission exists but procedure fails on execution. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadPaymentStatuses (procedure)
└── Dictionary.PaymentStatuse (DOES NOT EXIST - typo, intended: Dictionary.PaymentStatus)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PaymentStatuse | Table | SELECT * (BROKEN - table does not exist). Intended: Dictionary.PaymentStatus. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing Engine (BILLING_MANAGER) | Application | EXEC - permission granted but procedure fails on execution. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Query the intended source table directly (workaround for broken procedure)
```sql
SELECT PaymentStatusID, Name
FROM Dictionary.PaymentStatus WITH (NOLOCK)
ORDER BY PaymentStatusID;
```

### 8.2 View all decline-type statuses (subset of Dictionary.PaymentStatus)
```sql
SELECT PaymentStatusID, Name
FROM Dictionary.PaymentStatus WITH (NOLOCK)
WHERE Name LIKE 'Decline%'
ORDER BY PaymentStatusID;
```

### 8.3 Payments per status (uses correct Dictionary.PaymentStatus)
```sql
SELECT ps.Name AS StatusName, COUNT(*) AS PaymentCount
FROM Billing.Payment p WITH (NOLOCK)
INNER JOIN Dictionary.PaymentStatus ps WITH (NOLOCK)
    ON p.PaymentStatusID = ps.PaymentStatusID
GROUP BY ps.Name
ORDER BY PaymentCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadPaymentStatuses | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadPaymentStatuses.sql*

# Billing.LoadPayPals

> Data loader that returns all rows from Billing.PayPal, providing the billing engine with the full list of customer-registered PayPal email accounts used for deposits and withdrawals.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full Billing.PayPal table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadPayPals is a bulk data loader that returns every row from Billing.PayPal. The Billing.PayPal table stores the PayPal email account addresses registered by customers as their PayPal payment instrument for deposits and withdrawals. Each row represents one customer's registered PayPal account.

This procedure is part of the billing engine's standard initialization pattern. At startup, the engine calls this loader to cache all registered PayPal accounts, enabling the routing and validation logic to identify customers' PayPal instruments without repeated round-trips.

The table is a companion to Billing.PayPalToPayment (which links PayPal accounts to specific payment transactions). Together they form the PayPal instrument registry within the billing system.

---

## 2. Business Logic

### 2.1 Bulk PayPal Account Load

**What**: Returns the complete PayPal account registry for cache population.

**Columns/Parameters Involved**: (none - no parameters)

**Rules**:
- Returns all columns and all rows from Billing.PayPal via SELECT * WITH (NOLOCK).
- No filtering - entire table returned for cache loading.
- RETURN 0 on success.
- Called alongside other Load* procedures during billing engine initialization.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no input parameters) | - | - | - | - | - | This procedure takes no parameters. |
| RETURN | int | NO | - | CODE-BACKED | Returns 0 on successful execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT *) | Billing.PayPal | READ | Reads all registered PayPal account records. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing Engine (BILLING_MANAGER role) | - | EXEC | Called during initialization to cache PayPal account data. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadPayPals (procedure)
└── Billing.PayPal (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.PayPal | Table | SELECT * - reads all registered PayPal accounts. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing Engine (BILLING_MANAGER) | Application | EXEC - loads PayPal account cache at startup. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the loader
```sql
EXEC Billing.LoadPayPals;
```

### 8.2 Query the underlying table directly
```sql
SELECT PayPalID, PayPalEmailAccount
FROM Billing.PayPal WITH (NOLOCK)
ORDER BY PayPalID;
```

### 8.3 Find PayPal accounts linked to specific payments
```sql
SELECT pp.PayPalID, pp.PayPalEmailAccount,
       ptp.PaymentID, ptp.Amount
FROM Billing.PayPal pp WITH (NOLOCK)
INNER JOIN Billing.PayPalToPayment ptp WITH (NOLOCK)
    ON pp.PayPalID = ptp.PayPalID
ORDER BY ptp.PaymentID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadPayPals | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadPayPals.sql*

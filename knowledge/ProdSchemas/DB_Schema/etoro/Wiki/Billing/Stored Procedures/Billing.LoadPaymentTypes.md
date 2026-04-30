# Billing.LoadPaymentTypes

> Data loader that returns all rows from Dictionary.PaymentType, providing the billing engine with the three fundamental payment direction categories: Deposit, Cashout, and Refund.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full Dictionary.PaymentType table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadPaymentTypes is a bulk data loader that returns all rows from Dictionary.PaymentType. This dictionary table contains the three fundamental categories of payment transactions in the eToro billing system: 1=Deposit (money coming in from customer), 2=Cashout (money going out to customer), and 3=Refund (money returned to customer after a reversal).

This procedure is part of the standard billing engine initialization pattern. It is called at startup to cache the payment type definitions, enabling the engine to display and filter payment records by type without repeated database lookups. Payment type is a key discriminator in Billing.Payment and related tables, distinguishing inbound from outbound money flows.

The table is small and stable - only 3 rows exist and the definitions have not changed. The three types cover the complete bilateral payment flow: customer funds arriving (Deposit), customer funds leaving (Cashout), and error correction flows (Refund).

---

## 2. Business Logic

### 2.1 Payment Flow Direction Classification

**What**: The three payment types classify the direction and nature of every money movement in the billing system.

**Columns/Parameters Involved**: (none - no parameters)

**Rules**:
- Returns all columns and all rows from Dictionary.PaymentType via SELECT * WITH (NOLOCK).
- Values: 1=Deposit (customer sends money to eToro), 2=Cashout (eToro returns money to customer), 3=Refund (eToro reverses a deposit back to customer).
- PaymentTypeID is referenced throughout Billing.Payment, Billing.CheckMemberLimit, and other core billing procedures to distinguish transaction types.
- Billing.CheckMemberLimit uses PaymentTypeID=1 (Deposit) to count only inbound transactions when checking deposit velocity limits.

**Diagram**:
```
Customer -> eToro     : PaymentTypeID=1 (Deposit)
eToro   -> Customer   : PaymentTypeID=2 (Cashout)
eToro   -> Customer   : PaymentTypeID=3 (Refund - deposit reversal)
```

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
| (SELECT *) | Dictionary.PaymentType | READ | Reads all payment type definitions (Deposit, Cashout, Refund). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing Engine (BILLING_MANAGER role) | - | EXEC | Called during initialization to cache payment type definitions. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadPaymentTypes (procedure)
└── Dictionary.PaymentType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PaymentType | Table | SELECT * - reads all payment type definitions. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing Engine (BILLING_MANAGER) | Application | EXEC - loads payment type definitions at startup. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the loader to retrieve all payment types
```sql
EXEC Billing.LoadPaymentTypes;
```

### 8.2 Query the underlying table directly
```sql
SELECT PaymentTypeID, Name
FROM Dictionary.PaymentType WITH (NOLOCK)
ORDER BY PaymentTypeID;
```

### 8.3 Payment counts broken down by type
```sql
SELECT pt.Name AS PaymentType, COUNT(*) AS TotalPayments
FROM Billing.Payment p WITH (NOLOCK)
INNER JOIN Dictionary.PaymentType pt WITH (NOLOCK)
    ON p.PaymentTypeID = pt.PaymentTypeID
GROUP BY pt.Name
ORDER BY TotalPayments DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.2/10 (Elements: 10/10, Logic: 6/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadPaymentTypes | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadPaymentTypes.sql*

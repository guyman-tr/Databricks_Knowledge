# Billing.GetPendingCashouts

> Returns all pending cashout records (CashoutStatusID=1) for a given customer, used by billing managers to check a customer's open cashout requests.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all Billing.Cashout rows for @CID where CashoutStatusID=1 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetPendingCashouts` retrieves all open (pending, not yet processed) cashout records for a specific customer from `Billing.Cashout`. A "pending" cashout (CashoutStatusID=1) is one that has been requested by the customer but not yet dispatched to a payment provider or finalized.

The procedure exists as a quick customer-level pending cashout check used by billing managers to see what active cashout requests a customer has before taking actions like approvals, investigations, or risk assessments.

Data flows: billing managers call this when investigating a customer account. The cashout flow records high-level cashout requests in `Billing.Cashout`; this procedure reads only those in pending status (1) for the given customer.

---

## 2. Business Logic

### 2.1 Pending Status Filter (CashoutStatusID=1)

**What**: Only returns cashouts in status 1 (Pending/Open).

**Rules**:
- `WHERE CID = @CID AND CashoutStatusID = 1`
- CashoutStatusID=1 = pending/open - not yet dispatched to provider
- Completed, declined, or processing cashouts are excluded
- Uses WITH (NOLOCK) - dirty reads acceptable for this informational query

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer identifier. Filters `Billing.Cashout.CID` to return only this customer's pending cashouts. |

**Return columns: all from Billing.Cashout (SELECT *). See Billing.Cashout documentation for full column descriptions.**

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Cashout.CID | Filter | Returns pending cashout records for this customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BILLING_MANAGER | GRANT EXECUTE | Permission | Billing management role - customer cashout status review |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI admin role |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPendingCashouts (procedure)
└── Billing.Cashout (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Cashout | Table | Filtered SELECT by CID and CashoutStatusID=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BILLING_MANAGER | DB Security Principal | EXECUTE permission |
| PROD_BIadmins | DB Security Principal | EXECUTE permission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get pending cashouts for a customer
```sql
EXEC [Billing].[GetPendingCashouts] @CID = 12345678
```

### 8.2 Equivalent direct query
```sql
SELECT * FROM Billing.Cashout WITH (NOLOCK)
WHERE CID = 12345678 AND CashoutStatusID = 1
```

### 8.3 Check how many customers currently have pending cashouts
```sql
SELECT COUNT(DISTINCT CID) AS CustomersWithPendingCashouts,
       COUNT(*) AS TotalPendingCashouts
FROM Billing.Cashout WITH (NOLOCK)
WHERE CashoutStatusID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 7/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPendingCashouts | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetPendingCashouts.sql*

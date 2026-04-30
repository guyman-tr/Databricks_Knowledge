# Billing.LoadPaymentServiceStatuses

> Data loader that returns all rows from Dictionary.PaymentServiceStatus, providing the billing engine with the full list of payment service operational state definitions.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full Dictionary.PaymentServiceStatus table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadPaymentServiceStatuses is a bulk data loader that returns every row from Dictionary.PaymentServiceStatus in a single call. Payment service statuses define the operational states that can be assigned to individual payment services (e.g., active, inactive, under maintenance). The billing engine calls this procedure to load all available status definitions into memory, enabling it to interpret and display payment service state without repeated individual lookups.

This procedure exists as part of the standard billing engine initialization pattern: a family of "Load*" stored procedures each populate one reference table into the engine's cache at startup. Without this loader, the billing engine would need to query Dictionary.PaymentServiceStatus on every payment service status lookup, or would lack the status definitions needed for routing and display logic.

The procedure is called by the billing engine's data loading layer (referenced in BILLING_MANAGER and PROD_BIadmins permission grants). It returns all rows unconditionally - there are no filters, pagination, or parameters. Currently Dictionary.PaymentServiceStatus contains only test/placeholder data (3 rows: Test, test2, test3), suggesting the payment service status feature is in an early or staging deployment stage.

---

## 2. Business Logic

### 2.1 Bulk Reference Data Load

**What**: Returns the complete payment service status dictionary in a single result set for cache population.

**Columns/Parameters Involved**: (none - no parameters)

**Rules**:
- Returns all columns and all rows from Dictionary.PaymentServiceStatus via SELECT * WITH (NOLOCK).
- No filtering, sorting, or pagination - the entire reference table is returned.
- NOLOCK hint is used because this is read-only reference data; dirty reads are acceptable for cache loading.
- Returns error code 0 on success (RETURN 0).
- Called alongside other Load* procedures during billing engine initialization to populate all reference caches simultaneously.

**Diagram**:
```
Billing Engine Startup
        |
        v
Billing.LoadPaymentServiceStatuses
        |
        v
Dictionary.PaymentServiceStatus
  [PaymentServiceStatusID, Name]
        |
        v
Billing Engine In-Memory Cache
(payment service status lookup map)
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
| (SELECT *) | Dictionary.PaymentServiceStatus | READ | Reads all payment service status definitions for cache loading. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing Engine (BILLING_MANAGER role) | - | EXEC | Called by billing engine startup/initialization layer to populate payment service status cache. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadPaymentServiceStatuses (procedure)
└── Dictionary.PaymentServiceStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PaymentServiceStatus | Table | SELECT * - reads all rows for cache population. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing Engine (BILLING_MANAGER, PROD_BIadmins) | Application | EXEC - calls this procedure during initialization to load payment service status definitions. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the loader to retrieve all payment service statuses
```sql
EXEC Billing.LoadPaymentServiceStatuses;
```

### 8.2 Query the underlying table directly
```sql
SELECT PaymentServiceStatusID, Name
FROM Dictionary.PaymentServiceStatus WITH (NOLOCK)
ORDER BY PaymentServiceStatusID;
```

### 8.3 View payment services and their current status names
```sql
SELECT ps.PaymentServiceID, ps.Name AS ServiceName,
       pss.Name AS StatusName
FROM Billing.PaymentService ps WITH (NOLOCK)
INNER JOIN Dictionary.PaymentServiceStatus pss WITH (NOLOCK)
    ON ps.PaymentServiceStatusID = pss.PaymentServiceStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadPaymentServiceStatuses | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadPaymentServiceStatuses.sql*

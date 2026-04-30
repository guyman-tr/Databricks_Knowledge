# Dictionary.PaymentServiceStatus

> Lookup table defining payment service operational statuses — currently contains test/placeholder data indicating the table is in development or staging use.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PaymentServiceStatusID (INT, NC PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (PK nonclustered + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.PaymentServiceStatus defines the operational states of payment services within the billing infrastructure. Payment services (stored in Billing.PaymentService) represent the various payment providers and methods available for deposits and withdrawals. Each service can be in different operational states — active, under maintenance, disabled, etc.

This table exists to control the availability of payment services. When a payment service is marked with a particular status, the billing system routes or blocks transactions accordingly. The Billing.PaymentServiceEdit procedure modifies service statuses, and Billing.LoadPaymentServiceStatuses reads all statuses for the billing engine.

Currently the table contains only test/placeholder data (1=Test, 2=test2, 3=test3), suggesting that the actual production values may be managed through a different mechanism or the table is in early deployment. The structure with a unique constraint on Name ensures each status label is distinct.

---

## 2. Business Logic

### 2.1 Payment Service Availability Control

**What**: Payment services are assigned a status that controls their operational availability in the billing system.

**Columns/Parameters Involved**: `PaymentServiceStatusID`, `Name`

**Rules**:
- Each payment service in Billing.PaymentService references a PaymentServiceStatusID to indicate its current operational state.
- Billing.PaymentServiceEdit allows operators to change a payment service's status (e.g., taking a provider offline for maintenance).
- Billing.LoadPaymentServiceStatuses loads all status definitions for the billing engine's routing logic.
- The unique constraint on Name prevents duplicate status labels.

**Diagram**:
```
Billing.PaymentService
    │
    ├── PaymentServiceStatusID → Dictionary.PaymentServiceStatus
    │                              ├── Status controls availability
    │                              └── Unique Name constraint
    │
    ├── Billing.PaymentServiceEdit (modifies status)
    └── Billing.LoadPaymentServiceStatuses (reads all statuses)
```

---

## 3. Data Overview

| PaymentServiceStatusID | Name | Meaning |
|---|---|---|
| 1 | Test | Placeholder/test value — indicates the table is in staging or early development. Not representative of production business logic. |
| 2 | test2 | Placeholder/test value — second test entry. |
| 3 | test3 | Placeholder/test value — third test entry. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentServiceStatusID | int | NO | - | VERIFIED | Primary key identifying the payment service status. Currently contains test values (1-3). Referenced by Billing.PaymentService to control payment service availability. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Unique human-readable label for the status. Enforced unique by DPSS_NAME index. Used in billing configuration screens and service management. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.PaymentService | PaymentServiceStatusID | Implicit | Stores the operational status of each payment service |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PaymentService | Table | Stores PaymentServiceStatusID per payment service |
| Billing.PaymentServiceEdit | Stored Procedure | Modifier — changes payment service status |
| Billing.LoadPaymentServiceStatuses | Stored Procedure | Reader — loads all statuses for billing engine |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPSS | NC PK | PaymentServiceStatusID ASC | - | - | Active |
| DPSS_NAME | UNIQUE NC | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPSS | PRIMARY KEY | Unique payment service status identifier |
| DPSS_NAME | UNIQUE | Ensures each status has a unique name |

---

## 8. Sample Queries

### 8.1 List all payment service statuses
```sql
SELECT  PaymentServiceStatusID,
        Name
FROM    [Dictionary].[PaymentServiceStatus] WITH (NOLOCK)
ORDER BY PaymentServiceStatusID;
```

### 8.2 Find payment services by status
```sql
SELECT  ps.PaymentServiceID,
        ps.Name AS ServiceName,
        pss.Name AS StatusName
FROM    [Billing].[PaymentService] ps WITH (NOLOCK)
JOIN    [Dictionary].[PaymentServiceStatus] pss WITH (NOLOCK)
        ON ps.PaymentServiceStatusID = pss.PaymentServiceStatusID;
```

### 8.3 Count payment services per status
```sql
SELECT  pss.Name AS StatusName,
        COUNT(ps.PaymentServiceID) AS ServiceCount
FROM    [Dictionary].[PaymentServiceStatus] pss WITH (NOLOCK)
LEFT JOIN [Billing].[PaymentService] ps WITH (NOLOCK)
        ON ps.PaymentServiceStatusID = pss.PaymentServiceStatusID
GROUP BY pss.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PaymentServiceStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PaymentServiceStatus.sql*

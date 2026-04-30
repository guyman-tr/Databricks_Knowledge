# Billing.LoadVolumes

> Data loader that returns all rows from Billing.Volume, providing the billing engine with the per-payment-service, payment-type, and currency volume enforcement and restriction thresholds.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full Billing.Volume table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadVolumes is a bulk data loader that returns all rows from Billing.Volume. This configuration table stores per-payment-service, per-payment-type, and per-currency volume thresholds that the billing engine uses to enforce deposit limits and restrictions. Each row defines two limits for a given combination: `Enforcement` (the threshold at which enforcement actions trigger) and `Restrictions` (a hard ceiling beyond which transactions are blocked).

The billing engine loads this table at startup to configure volume-based access controls. For example, PaymentServiceID=1 (credit card) + PaymentTypeID=1 (Deposit) + CurrencyID=1 (USD) has Enforcement=5,000 and Restrictions=100,000, meaning enforcement actions begin at 5,000 units and hard restrictions kick in at 100,000 units (values are in minor units - cents - based on the billing system's convention).

---

## 2. Business Logic

### 2.1 Volume Threshold Configuration

**What**: Defines per-service, per-type, and per-currency deposit volume enforcement levels.

**Columns/Parameters Involved**: (none - no parameters)

**Rules**:
- Returns all columns from Billing.Volume via SELECT * WITH (NOLOCK).
- Key: (PaymentServiceID, PaymentTypeID, CurrencyID) identifies the specific volume rule.
- Enforcement: threshold at which enforcement actions begin (warnings, additional checks).
- Restrictions: hard limit; transactions exceeding this are blocked.
- Amounts are likely stored in minor currency units (cents) consistent with other Billing tables.

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
| (SELECT *) | Billing.Volume | READ | Reads all volume threshold configurations. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing Engine (BILLING_MANAGER role) | - | EXEC | Called during initialization to cache volume enforcement thresholds. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadVolumes (procedure)
└── Billing.Volume (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Volume | Table | SELECT * - reads all volume enforcement thresholds. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing Engine (BILLING_MANAGER) | Application | EXEC - loads volume limits at startup. |

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
EXEC Billing.LoadVolumes;
```

### 8.2 Query thresholds for a specific payment service and type
```sql
SELECT v.PaymentServiceID, v.PaymentTypeID, v.CurrencyID,
       v.Enforcement, v.Restrictions
FROM Billing.Volume v WITH (NOLOCK)
WHERE v.PaymentServiceID = 1 AND v.PaymentTypeID = 1
ORDER BY v.CurrencyID;
```

### 8.3 View all volume limits with decoded names
```sql
SELECT ps.Name AS ServiceName, pt.Name AS PaymentType,
       v.CurrencyID, v.Enforcement, v.Restrictions
FROM Billing.Volume v WITH (NOLOCK)
INNER JOIN Billing.PaymentService ps WITH (NOLOCK)
    ON v.PaymentServiceID = ps.PaymentServiceID
INNER JOIN Dictionary.PaymentType pt WITH (NOLOCK)
    ON v.PaymentTypeID = pt.PaymentTypeID
ORDER BY v.PaymentServiceID, v.PaymentTypeID, v.CurrencyID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.2/10 (Elements: 10/10, Logic: 6/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadVolumes | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadVolumes.sql*

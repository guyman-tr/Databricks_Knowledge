# Dictionary.BillingMaintenanceStatus

> Lookup table defining the 3 billing system maintenance states — Active, UnderMaintenance, and InActive — controlling whether payment processing services are operational, under maintenance, or disabled.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY(1,2), PK CLUSTERED) |
| **Partition** | PRIMARY filegroup (PAGE compression) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.BillingMaintenanceStatus defines the operational states for billing/payment processing services. Each payment service (deposit gateway, withdrawal processor, etc.) tracked in Billing.Maintenance has a status from this table indicating whether it's fully operational, under maintenance, or disabled.

This table is critical for controlling payment service availability. When a payment gateway needs maintenance (e.g., provider-side updates, certificate rotations, or troubleshooting), operators set the service to "UnderMaintenance" — which prevents new transactions from being routed to that gateway while allowing in-flight transactions to complete. "InActive" fully disables a service.

The notable IDENTITY(1,2) seed (incrementing by 2) creates odd-numbered IDs (1, 3, 5), suggesting the table was designed to leave room for inserting intermediate states (2, 4) if finer-grained status control was needed in the future. Referenced by Billing.Maintenance which stores the current status of each billing service.

---

## 2. Business Logic

### 2.1 Service Availability States

**What**: Operational status of billing/payment processing services.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- **Active (1)**: Service is fully operational. New transactions are accepted and routed normally. This is the default/desired state for all services.
- **UnderMaintenance (3)**: Service is temporarily unavailable. New transactions should NOT be routed to this service, but in-flight transactions may continue. Used during scheduled maintenance windows, provider outages, or troubleshooting.
- **InActive (5)**: Service is permanently or indefinitely disabled. No transactions accepted. Used for decommissioned services or those with unresolved critical issues.

**Diagram**:
```
Service Lifecycle:

  New Service ──► Active (1) ◄──┐
                    │            │
                    │ Maintenance│ Restored
                    ▼            │
              UnderMaintenance (3)
                    │
                    │ Decommission
                    ▼
               InActive (5)
```

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 1 | Active | Service is fully operational. All transaction types (deposits, withdrawals, refunds) are accepted and processed normally. Default state for healthy services. |
| 3 | UnderMaintenance | Service temporarily taken offline. No new transactions routed to this gateway/processor. Used during scheduled maintenance, provider outages, or certificate renewals. Can transition back to Active when maintenance is complete. |
| 5 | InActive | Service permanently disabled or decommissioned. No transactions processed. Used for retired payment gateways or services with unresolvable issues. Requires manual intervention to reactivate. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,2) | CODE-BACKED | Primary key with unusual IDENTITY(1,2) — increments by 2, producing odd IDs (1, 3, 5). This leaves even ID slots (2, 4) available for future intermediate states without reseeding. Referenced by Billing.Maintenance.StatusID to track service availability. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable service state name. Values: 'Active', 'UnderMaintenance', 'InActive'. Displayed in billing system dashboards and maintenance management interfaces. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Maintenance | StatusID | Implicit | Tracks operational status of each billing service |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Maintenance | Table | Stores service maintenance status |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_BillingMaintenanceStatus | CLUSTERED PK | ID ASC | - | - | Active (FILLFACTOR 95, PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_BillingMaintenanceStatus | PRIMARY KEY | Unique status identifier. IDENTITY(1,2) creates odd-numbered sequence. |

---

## 8. Sample Queries

### 8.1 List all billing maintenance statuses
```sql
SELECT  ID,
        Name
FROM    Dictionary.BillingMaintenanceStatus WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find services currently under maintenance
```sql
SELECT  bm.*,
        bms.Name            AS StatusName
FROM    Billing.Maintenance bm WITH (NOLOCK)
JOIN    Dictionary.BillingMaintenanceStatus bms WITH (NOLOCK)
        ON bm.StatusID = bms.ID
WHERE   bms.ID = 3;
```

### 8.3 Count services by status
```sql
SELECT  bms.Name            AS Status,
        COUNT(*)            AS ServiceCount
FROM    Billing.Maintenance bm WITH (NOLOCK)
JOIN    Dictionary.BillingMaintenanceStatus bms WITH (NOLOCK)
        ON bm.StatusID = bms.ID
GROUP BY bms.Name
ORDER BY bms.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.BillingMaintenanceStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.BillingMaintenanceStatus.sql*

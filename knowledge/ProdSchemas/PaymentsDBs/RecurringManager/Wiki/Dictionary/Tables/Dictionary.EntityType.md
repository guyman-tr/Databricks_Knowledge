# Dictionary.EntityType

> Lookup table classifying the two fundamental entity types in the RecurringManager system: the recurring payment container (Payment) and a single execution attempt within it (PaymentExecution).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | EntityTypeID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.EntityType classifies the two fundamental entity levels in the RecurringManager domain. The system distinguishes between a "Payment" - the overarching recurring payment plan subscription - and a "PaymentExecution" - a single scheduled charge attempt within that payment. This distinction is essential for routing events, logging, and auditing to the correct level of granularity.

This table exists because many operations in the RecurringManager system (notifications, status changes, message routing) can apply to either the plan-level payment or a specific execution attempt. Without this classification, the system could not determine whether an event or log entry refers to the whole recurring subscription or just one charge cycle.

Data in this table is static reference data, populated outside the SSDT deployment process. No stored procedures, views, or DML operations within the SSDT project modify this table. It is consumed by application code and other schemas via implicit foreign key relationships using the EntityTypeID column.

---

## 2. Business Logic

### 2.1 Two-Level Entity Hierarchy

**What**: The RecurringManager domain models recurring payments as a two-level hierarchy - a parent Payment and child PaymentExecution records.

**Columns/Parameters Involved**: `EntityTypeID`, `Name`

**Rules**:
- EntityTypeID=1 (Payment) represents the top-level recurring payment plan - the user's subscription to automatic deposits or investments
- EntityTypeID=2 (PaymentExecution) represents a single execution attempt within a plan - one scheduled charge for a specific cycle
- A Payment contains multiple PaymentExecutions over its lifetime (one per scheduled frequency cycle plus any dunning retries)

**Diagram**:
```
Payment (EntityTypeID=1)
  |-- The recurring plan subscription
  |
  +-- PaymentExecution (EntityTypeID=2)
  |     |-- Cycle 1: Planned -> Sent -> Approved
  |
  +-- PaymentExecution (EntityTypeID=2)
  |     |-- Cycle 2: Planned -> Sent -> SoftDeclined -> Retry
  |
  +-- PaymentExecution (EntityTypeID=2)
        |-- Cycle 2 Dunning: Planned -> Sent -> Approved
```

---

## 3. Data Overview

| EntityTypeID | Name | Meaning |
|---|---|---|
| 1 | Payment | The parent recurring payment plan - represents the user's entire subscription to automatic recurring deposits or investments. Lifecycle governed by PlanStatus (Active, Cancelled, Stopped, etc.) |
| 2 | PaymentExecution | A single charge attempt within a payment plan - one scheduled execution cycle. Lifecycle governed by PaymentExecutionStatus (Planned through Approved/Declined) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EntityTypeID | int | NO | - | CODE-BACKED | Primary key identifying the entity type. 1=Payment (the recurring plan subscription), 2=PaymentExecution (a single charge attempt within the plan). See [Entity Type](../../_glossary.md#entity-type) for full definitions. (Dictionary.EntityType) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the entity type. Values: "Payment", "PaymentExecution". Used for display and logging purposes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Implicit consumers) | EntityTypeID | Implicit | Application code and other schemas use EntityTypeID to classify whether an event, log entry, or notification pertains to the plan-level Payment or a specific PaymentExecution attempt |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No explicit dependents found in SSDT. Consumed implicitly by application code for entity classification.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_EntityType | CLUSTERED PK | EntityTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_EntityType | PRIMARY KEY | Ensures each entity type has a unique integer identifier |

Storage: DATA_COMPRESSION = PAGE

---

## 8. Sample Queries

### 8.1 List all entity types
```sql
SELECT EntityTypeID, Name
FROM Dictionary.EntityType WITH (NOLOCK)
ORDER BY EntityTypeID
```

### 8.2 Resolve an EntityTypeID to its name
```sql
SELECT e.Name AS EntityTypeName
FROM Dictionary.EntityType e WITH (NOLOCK)
WHERE e.EntityTypeID = 1
```

### 8.3 Use in a JOIN to classify records by entity type
```sql
SELECT r.*, et.Name AS EntityTypeName
FROM Recurring.SomeTable r WITH (NOLOCK)
INNER JOIN Dictionary.EntityType et WITH (NOLOCK) ON r.EntityTypeID = et.EntityTypeID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Manager](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1922891833) | Confluence | Architecture context: RecurringManager is a Worker+API service on K8S, owned by MIMO US team, called by Payments API |
| [Recurring Scheduler](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1922891789) | Confluence | Architecture context: RecurringScheduler is a separate Worker service that shares the RecurringManager database |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Business glossary: Plan = recurring investment subscription per user per instrument; Recurring Deposit = monthly deposit plan managed by Money Group |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.EntityType | Type: Table | Source: RecurringManager/Dictionary/Tables/Dictionary.EntityType.sql*

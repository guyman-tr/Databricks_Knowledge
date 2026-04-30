# Dictionary.MirrorOrderCreated

> Lookup table providing a boolean flag indicating whether a mirror (copy) order was created for a copy trading plan instance.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table provides a flag to indicate that a mirror order was successfully created for a copy trading recurring investment instance. In copy trading plans (PlanType=2), when the system processes an instance, it creates a "mirror order" that replicates the position in the parent trader's portfolio. This table records whether that mirror order creation step was completed.

Without this table, the system would have no standardized way to track whether the copy order initiation step succeeded, making it difficult to troubleshoot incomplete copy trading cycles.

Only a single value (1=TRUE) exists, making this effectively a boolean flag. NULL or absence of a value in PlanInstances.MirrorOrderCreated means no mirror order was created (either the plan is not a copy type, or the creation has not yet occurred/failed).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a single-value boolean flag lookup.

---

## 3. Data Overview

| ID | Name | Meaning |
|----|------|---------|
| 1 | TRUE | A mirror order was successfully created for this copy trading instance. This means the copy trading pipeline initiated the order replication to mirror the parent trader's portfolio. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Unique numeric identifier. Only value is 1 (TRUE). NULL in referencing tables means no mirror order created. See [Mirror Order Created](../../_glossary.md#mirror-order-created). |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable label. Only value is "TRUE". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.PlanInstances | MirrorOrderCreated | Implicit Lookup | Flags whether a mirror order was created for a copy trading instance |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | MirrorOrderCreated column references this domain |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MirrorOrderCreated | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all mirror order values
```sql
SELECT ID, Name
FROM [Dictionary].[MirrorOrderCreated] WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Find copy instances with mirror orders
```sql
SELECT pi.InstanceID, pi.PlanID, pi.MirrorOrderCreated, pi.MirrorID
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
WHERE pi.MirrorOrderCreated IS NOT NULL
```

### 8.3 Count instances with and without mirror orders
```sql
SELECT
  CASE WHEN pi.MirrorOrderCreated = 1 THEN 'Mirror Order Created'
       ELSE 'No Mirror Order' END AS MirrorStatus,
  COUNT(*) AS InstanceCount
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
GROUP BY CASE WHEN pi.MirrorOrderCreated = 1 THEN 'Mirror Order Created'
              ELSE 'No Mirror Order' END
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Copy trading flow involves mirror order creation as part of the position opening pipeline |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MirrorOrderCreated | Type: Table | Source: RecurringInvestment/Dictionary/Tables/Dictionary.MirrorOrderCreated.sql*

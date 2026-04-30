# Customer.RiskClassificationUpdatedUsers

> Tracks users whose risk classification was recently updated, enabling batch processing of classification changes.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Customer.RiskClassificationUpdatedUsers is a work queue table that tracks which users have had their risk classification updated. When a user's risk classification changes, a row is inserted/updated here. Downstream batch processes read from this table to propagate classification changes to other systems or trigger follow-up actions.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Work queue pattern.

---

## 3. Data Overview

N/A - transactional work queue.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Primary key. Global Customer ID whose risk classification was updated. |
| 2 | RiskClassificationId | int | YES | - | CODE-BACKED | The new risk classification assigned to the user. |
| 3 | UpdatedAt | datetime | NO | getdate() | CODE-BACKED | When the classification was updated. Default: current datetime. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.GetRiskClassificationUpdatedUsers | GCID | SP reads | Reads the queue |
| Customer.DeleteRiskClassificationUpdatedUsers | GCID | SP deletes | Clears processed entries |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.GetRiskClassificationUpdatedUsers | Stored Procedure | Reads from |
| Customer.DeleteRiskClassificationUpdatedUsers | Stored Procedure | Deletes from |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RiskClassificationUpdatedUsers | CLUSTERED PK | GCID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_RiskClassificationUpdatedUsers_UpdatedAt | DEFAULT | getdate() |

---

## 8. Sample Queries

### 8.1 Get pending classification updates
```sql
SELECT GCID, RiskClassificationId, UpdatedAt FROM Customer.RiskClassificationUpdatedUsers WITH (NOLOCK) ORDER BY UpdatedAt
```

### 8.2 Count pending updates
```sql
SELECT COUNT(*) AS PendingCount FROM Customer.RiskClassificationUpdatedUsers WITH (NOLOCK)
```

### 8.3 Find updates in a date range
```sql
SELECT GCID, RiskClassificationId FROM Customer.RiskClassificationUpdatedUsers WITH (NOLOCK) WHERE UpdatedAt > @Since
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.RiskClassificationUpdatedUsers | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.RiskClassificationUpdatedUsers.sql*

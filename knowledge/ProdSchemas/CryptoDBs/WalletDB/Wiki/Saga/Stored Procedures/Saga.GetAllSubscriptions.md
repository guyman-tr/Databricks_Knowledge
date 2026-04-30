# Saga.GetAllSubscriptions

> Retrieves all active (non-deleted) subscriptions that have expired before a specified timestamp, ordered by least-recently-updated first.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: result set of expired active subscriptions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves subscriptions that are active (not soft-deleted) but have expired before a given timestamp. Despite its name "GetAll", it actually filters to expired subscriptions - it is used by the subscription management layer to find subscriptions eligible for renewal or cleanup.

The ordering by `LastUpdated ASC` (oldest first) ensures that the most stale subscriptions are processed first, enabling fair round-robin reclamation when multiple service instances compete for expired subscriptions.

---

## 2. Business Logic

### 2.1 Expired Subscription Discovery

**What**: Finds active but expired subscriptions for renewal or reclamation.

**Columns/Parameters Involved**: `@Expired`, `IsDeleted`, `LastUpdated`

**Rules**:
- Filters WHERE Expired < @Expired AND IsDeleted = 0
- Orders by LastUpdated ASC (oldest activity first)
- Returns 7 columns: Id, Topic, Routing, SubscriptionName, Created, LastUpdated, Expired

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Expired | datetime2(7) | NO | - | CODE-BACKED | Cutoff timestamp. Returns subscriptions whose Expired column is before this value. Typically set to GETUTCDATE() to find currently-expired subscriptions. |
| 2-8 | (output columns) | - | - | - | CODE-BACKED | Id, Topic, Routing, SubscriptionName, Created, LastUpdated, Expired from Saga.Subscriptions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.Subscriptions | SELECT FROM | Reads active expired subscriptions |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetAllSubscriptions (procedure)
└── Saga.Subscriptions (table) [SELECT FROM]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.Subscriptions | Table | SELECT FROM |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all currently expired subscriptions
```sql
EXEC Saga.GetAllSubscriptions @Expired = '2026-04-15T12:00:00.000Z'
```

### 8.2 Equivalent direct query
```sql
SELECT Id, Topic, Routing, SubscriptionName, Created, LastUpdated, Expired
FROM Saga.Subscriptions WITH (NOLOCK)
WHERE Expired < GETUTCDATE() AND IsDeleted = 0
ORDER BY LastUpdated ASC
```

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetAllSubscriptions | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.GetAllSubscriptions.sql*

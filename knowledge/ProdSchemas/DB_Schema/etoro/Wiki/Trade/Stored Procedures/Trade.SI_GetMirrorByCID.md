# Trade.SI_GetMirrorByCID

> System Integration query that returns the basic mirror records (MirrorID, CID, ParentCID, ParentUserName, Amount, IsActive) for a given customer.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a lightweight System Integration (SI_) endpoint that returns the list of copy-trade mirrors owned by a specific customer. The SI_ prefix conventionally identifies procedures designed for system-to-system integration calls, as opposed to user-facing or transactional procedures.

It exposes just the essential mirror identification fields: the mirror ID, the customer owning it, the parent (leader) they are copying, the leader's username, the invested amount, and whether the mirror is currently active. This is used by integration systems that need to check what copy-trade relationships a customer has without querying the full Trade.Mirror schema.

---

## 2. Business Logic

### 2.1 NOLOCK Read for Low-Latency Integration

**What**: The procedure uses WITH (NOLOCK) to return data without acquiring shared locks, prioritizing read performance for integration consumers.

**Columns/Parameters Involved**: `@CID`

**Rules**:
- WITH (NOLOCK) allows reads of uncommitted data (dirty reads) - acceptable for integration polling scenarios
- Filters by CID (follower/copier customer ID) - returns all active and inactive mirrors for this customer
- No filtering on IsActive - returns both active and inactive mirrors

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID of the follower/copier. Filters Trade.Mirror to return all mirrors owned by this customer. |
| Output: MirrorID | int | NO | - | CODE-BACKED | Unique identifier of the mirror (copy-trade relationship). |
| Output: CID | int | NO | - | CODE-BACKED | Customer ID of the follower - same as @CID input. Identifies the copier. |
| Output: ParentCID | int | NO | - | CODE-BACKED | Customer ID of the leader being copied. |
| Output: ParentUserName | varchar | NO | - | CODE-BACKED | Username of the leader being copied. Useful for display without joining to Customer schema. |
| Output: Amount | money | NO | - | CODE-BACKED | Current invested amount in the mirror copy relationship, in USD. |
| Output: IsActive | bit | NO | - | CODE-BACKED | 1 = mirror is currently active (copying in progress), 0 = mirror is stopped/closed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.Mirror | Reader | Reads mirror records filtered by CID (the follower customer) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SI_GetMirrorByCID (procedure)
└── Trade.Mirror (table) [SELECT MirrorID, CID, ParentCID, ParentUserName, Amount, IsActive WHERE CID=@CID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Read with NOLOCK: returns basic mirror fields filtered by CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No callers found in Trade SP folder | - | Called by external integration systems (SI_ prefix convention) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SI_ prefix convention | Design | Indicates this is a System Integration endpoint designed for polling by external services, not for transactional use |

---

## 8. Sample Queries

### 8.1 Get all mirrors for a customer

```sql
EXEC Trade.SI_GetMirrorByCID @CID = 12345;
```

### 8.2 Direct query equivalent

```sql
SELECT MirrorID, CID, ParentCID, ParentUserName, Amount, IsActive
FROM Trade.Mirror WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 Count active mirrors per customer (via base table)

```sql
SELECT CID, COUNT(*) AS ActiveMirrorCount
FROM Trade.Mirror WITH (NOLOCK)
WHERE IsActive = 1
GROUP BY CID
HAVING COUNT(*) > 1
ORDER BY ActiveMirrorCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SI_GetMirrorByCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SI_GetMirrorByCID.sql*

# Customer.OpenAndClosePositions

> Combined open and closed position identifier view: UNION ALL of Trade.Position (open) and History.Position (closed) returning only PositionID and CID for a complete cross-history position lookup.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.OpenAndClosePositions is a minimal two-column view that unifies Trade.Position (all currently open positions) and History.Position (all closed positions) using UNION ALL. It answers the question: "Given a PositionID, which customer owns it, and does it matter if it's still open or already closed?" - without requiring callers to query both tables separately.

The view is intentionally narrow (PositionID + CID only). Consumers who need position details will JOIN their additional columns from Trade.Position or History.Position; this view provides only the universal (PositionID, CID) mapping that is valid regardless of whether the position is still open.

Common use cases: checking if a customer has ever held a position (open or closed), looking up a position owner when the open/closed state is unknown, and cross-position reconciliation queries that span the entire position lifecycle.

---

## 2. Business Logic

### 2.1 UNION ALL vs UNION

**What**: The view uses UNION ALL (not UNION) to combine open and closed positions.

**Columns/Parameters Involved**: `PositionID`, `CID`

**Rules**:
- UNION ALL is correct here because a PositionID cannot appear in both Trade.Position AND History.Position simultaneously (when a position is closed, it is moved from Trade.Position to History.Position)
- Using UNION ALL avoids the sort/dedup overhead of UNION while being semantically safe
- If a PositionID ever appears in both tables due to a data anomaly, UNION ALL would return duplicate rows (no deduplication)

---

## 3. Data Overview

N/A for view - the data comes directly from Trade.Position and History.Position which contain open and closed position records respectively.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | VERIFIED | Unique position identifier. From Trade.Position (open) or History.Position (closed). The same PositionID namespace spans both tables; a position moves from Trade.Position to History.Position when closed. |
| 2 | CID | int | NO | - | VERIFIED | Customer who owns the position. From Trade.Position or History.Position. Links to Customer.CustomerStatic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID, CID | Trade.Position | UNION ALL (first leg) | Open positions |
| PositionID, CID | History.Position | UNION ALL (second leg) | Closed/historical positions |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.OpenAndClosePositions (view)
├── Trade.Position (table)
└── History.Position (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | Table | UNION ALL first leg - open positions |
| History.Position | Table | UNION ALL second leg - closed positions |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. Note: no NOLOCK hint in the view DDL - callers should add WITH (NOLOCK) when reading this view to match the typical platform read pattern.

### 7.2 Constraints

None. No SCHEMABINDING declared.

---

## 8. Sample Queries

### 8.1 Check if a specific position exists (open or closed)
```sql
SELECT PositionID, CID
FROM Customer.OpenAndClosePositions WITH (NOLOCK)
WHERE PositionID = 123456789;
```

### 8.2 Count all positions (open + closed) for a customer
```sql
SELECT CID, COUNT(*) AS TotalPositions
FROM Customer.OpenAndClosePositions WITH (NOLOCK)
WHERE CID = 12345
GROUP BY CID;
```

### 8.3 Find customers who have any position (open or closed) in a set of PositionIDs
```sql
SELECT DISTINCT ocp.CID, ocp.PositionID
FROM Customer.OpenAndClosePositions ocp WITH (NOLOCK)
WHERE ocp.PositionID IN (111, 222, 333, 444)
ORDER BY ocp.CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.OpenAndClosePositions | Type: View | Source: etoro/etoro/Customer/Views/Customer.OpenAndClosePositions.sql*

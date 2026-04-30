# Trade.PositionsIsUS

> Bulk lookup that returns the IsUS flag for a set of positions, joining the position list against Trade.IsUsUser to identify US brokerage accounts.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ids TVP (Trade.IdIntList) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionsIsUS is a bulk query SP that determines whether a batch of positions belong to US brokerage customers. Callers pass a list of PositionIDs via the Trade.IdIntList TVP, and the SP returns a result set with PositionID, CID, InstrumentID, and an IsUS BIT flag for each position found in Trade.Position.

The IsUS classification is critical because US positions (Apex/broker-dealer accounts) follow different rules for execution, reporting, compliance, and P&L calculation. Many SPs and monitoring jobs filter on IsUsUser=0 to exclude US positions; this SP enables that check at the position-batch level rather than per-position.

---

## 2. Business Logic

### 2.1 Batch US Classification

**What**: Joins the input PositionID list to Trade.Position and applies Trade.IsUsUser per CID.

**Columns/Parameters Involved**: Trade.Position, Trade.IsUsUser, @ids

**Rules**:
- INNER JOIN @ids ON ids.Id = PositionID: only positions in the input list are returned (positions not found in Trade.Position are silently excluded)
- CROSS APPLY Trade.IsUsUser(CID): evaluates US status per customer
- Result: PositionID, CID, InstrumentID, IsUS (CAST of IsUsUser BIT)
- No NOLOCK hint: reads committed data from Trade.Position

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | Trade.IdIntList | NO | - | CODE-BACKED | READONLY TVP of PositionIDs to look up. Trade.IdIntList has a single column Id INT. |

**Result set columns:**

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | PositionID | BIGINT | Position identifier from Trade.Position |
| 2 | CID | INT | Customer ID |
| 3 | InstrumentID | INT | Instrument FK |
| 4 | IsUS | BIT | 1=US brokerage customer (Apex), 0=non-US |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids parameter type | Trade.IdIntList | User Defined Type | TVP input type - single INT column |
| INNER JOIN | Trade.Position | DML read | Position lookup for PositionID, CID, InstrumentID |
| CROSS APPLY | Trade.IsUsUser | Function call | US user classification per CID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No callers found in SSDT repo. Called by external services needing bulk US classification.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionsIsUS (procedure)
+-- Trade.IdIntList (UDT) - TVP parameter type
+-- Trade.Position (view/table) - position data
+-- Trade.IsUsUser (function) - US classification
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IdIntList | User Defined Type | READONLY TVP parameter type |
| Trade.Position | View/Table | INNER JOIN on PositionID to get CID, InstrumentID |
| Trade.IsUsUser | Function | CROSS APPLY to determine IsUS per CID |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- INNER JOIN: positions not in Trade.Position (already closed, not found) are excluded from the result set silently

---

## 8. Sample Queries

### 8.1 Classify a batch of positions as US or non-US

```sql
DECLARE @ids Trade.IdIntList;
INSERT INTO @ids VALUES (123456789), (987654321), (111222333);

EXEC Trade.PositionsIsUS @ids = @ids;
-- Returns: PositionID, CID, InstrumentID, IsUS
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionsIsUS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionsIsUS.sql*

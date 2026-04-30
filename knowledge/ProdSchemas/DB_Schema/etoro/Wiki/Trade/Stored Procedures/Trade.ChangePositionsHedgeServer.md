# Trade.ChangePositionsHedgeServer

> Reassigns a list of positions to a different hedge server, optionally resetting the hedge query flag for re-hedging when the target server is not a dummy.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @HedgeServerID, @PositionsIDs (XML) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ChangePositionsHedgeServer is an operations/admin utility that moves positions from one hedge server to another. In eToro's trading architecture, positions are hedged through external liquidity providers via hedge servers. When a hedge server needs maintenance or positions must be redistributed, this procedure bulk-updates the HedgeServerID on the specified positions.

This procedure exists for operational scenarios: hedge server failover, load balancing, migration between providers, or moving positions to a "dummy" (non-hedging) server for internal positions that don't require external hedging.

When the target hedge server is not a dummy (IsDummy=0), the procedure also resets EntryHedgeQuery to -1, signaling that the position needs to be re-hedged on the new server. For dummy servers, EntryHedgeQuery is left unchanged since no hedging action is needed.

---

## 2. Business Logic

### 2.1 Hedge Server Assignment with Re-hedge Flag

**What**: Updates positions to a new hedge server and conditionally triggers re-hedging.

**Columns/Parameters Involved**: `@HedgeServerID`, `Trade.Position.HedgeServerID`, `Trade.Position.EntryHedgeQuery`, `Trade.HedgeServer.IsDummy`

**Rules**:
- Looks up IsDummy flag from Trade.HedgeServer for the target @HedgeServerID
- If IsDummy=0 (real hedge server): sets EntryHedgeQuery=-1 to trigger re-hedging
- If IsDummy=1 (dummy server): keeps existing EntryHedgeQuery unchanged
- Updates all positions whose PositionID appears in the XML input

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INT | NO | - | CODE-BACKED | Target hedge server ID. Looked up in Trade.HedgeServer to check IsDummy flag. |
| 2 | @PositionsIDs | XML | NO | - | CODE-BACKED | XML list of position IDs to reassign. Format: `<Root><ID>123</ID><ID>456</ID></Root>`. Parsed via `.nodes('Root/ID')`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeServerID | Trade.HedgeServer | SELECT | Reads IsDummy flag to determine re-hedge behavior |
| @PositionsIDs | Trade.Position | UPDATE | Updates HedgeServerID and conditionally EntryHedgeQuery |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DBA/Operations | (manual) | EXEC | Called for hedge server maintenance or position redistribution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ChangePositionsHedgeServer (procedure)
+-- Trade.HedgeServer (table)
+-- Trade.Position (view)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | SELECT IsDummy flag |
| Trade.Position | View | UPDATE HedgeServerID, EntryHedgeQuery |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations team | Manual | Ad-hoc execution for hedge server management |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| XML parsing | Input | Uses .nodes('Root/ID') to shred XML into temp table #IDs |

---

## 8. Sample Queries

### 8.1 Check current hedge server assignments for positions

```sql
SELECT PositionID, HedgeServerID, EntryHedgeQuery
FROM   Trade.Position WITH (NOLOCK)
WHERE  PositionID IN (123, 456, 789);
```

### 8.2 List available hedge servers

```sql
SELECT HedgeServerID, IsDummy
FROM   Trade.HedgeServer WITH (NOLOCK);
```

### 8.3 Reassign positions to hedge server 5

```sql
EXEC Trade.ChangePositionsHedgeServer
    @HedgeServerID = 5,
    @PositionsIDs = '<Root><ID>100001</ID><ID>100002</ID></Root>';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ChangePositionsHedgeServer | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ChangePositionsHedgeServer.sql*

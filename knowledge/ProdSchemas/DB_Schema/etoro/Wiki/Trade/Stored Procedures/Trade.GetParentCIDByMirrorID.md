# Trade.GetParentCIDByMirrorID

> Returns the parent (leader) customer ID for a given copy-trade mirror relationship.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID - the copy relationship ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetParentCIDByMirrorID` is a simple lookup procedure that retrieves the `ParentCID` (leader's customer ID) for a given copy-trade `MirrorID`. In eToro's CopyTrader system, a Mirror represents an active copy relationship between a copier and a leader; the MirrorID identifies the relationship and the ParentCID identifies the leader being copied.

**WHY:** Many trade processing flows need to know which leader initiated an action in a copy relationship. Rather than requiring callers to join Trade.Mirror directly, this SP provides a clean, indexed lookup of that single field.

**HOW:** Single-table SELECT from Trade.Mirror with NOLOCK, filtered by MirrorID, returning ParentCID.

---

## 2. Business Logic

### 2.1 Mirror-to-Leader Resolution

**What:** MirrorID uniquely identifies a copy relationship; ParentCID is the leader within that relationship.

**Columns/Parameters Involved:** `@MirrorID`, `ParentCID`

**Rules:**
- `SELECT ParentCID FROM Trade.Mirror WHERE MirrorID = @MirrorID`
- Returns 0 or 1 rows (MirrorID is unique in Trade.Mirror)
- NULL result if MirrorID does not exist

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | Copy relationship ID. Identifies the specific copier-leader relationship in Trade.Mirror. |
| 2 | ParentCID | INT | YES | - | CODE-BACKED | Leader (parent) customer ID. The CID of the trader being copied in this Mirror. NULL if MirrorID not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Trade.Mirror | Lookup | MirrorID -> ParentCID lookup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetParentCIDByMirrorID (procedure)
|- Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Single-field lookup: MirrorID -> ParentCID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by copy-trade processing services |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH (NOLOCK) | Hint | Dirty read acceptable; used for performance in high-frequency lookup context |

---

## 8. Sample Queries

### 8.1 Get leader CID for a mirror

```sql
EXEC Trade.GetParentCIDByMirrorID @MirrorID = 12345
```

### 8.2 Inline equivalent query

```sql
SELECT ParentCID FROM Trade.Mirror WITH (NOLOCK) WHERE MirrorID = 12345
```

### 8.3 Verify a mirror relationship

```sql
DECLARE @ParentCID INT
EXEC @ParentCID = Trade.GetParentCIDByMirrorID @MirrorID = 12345
SELECT @ParentCID AS LeaderCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetParentCIDByMirrorID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetParentCIDByMirrorID.sql*

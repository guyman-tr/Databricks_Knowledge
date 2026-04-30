# History.FindDetachedPositionsTest

> Active-table variant of History.FindDetachedPositions: same detached CopyTrader position detection logic but queries History.ActiveCredit and History.PositionSlim instead of the closed-position tables, targeting currently open/active positions.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MinID pagination cursor; result set: CreditID, Occurred, MirrorID, PositionID, NetProfit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure applies the identical "detached position" detection logic as `History.FindDetachedPositions` but targets the **active/open position tables** - `History.ActiveCredit` and `History.PositionSlim` - rather than the closed-position tables (`History.Credit` and `History.Position`). It finds currently active CopyTrader positions that have a type-27 "Stock Position Disconnected" credit but are missing the corresponding type-4 financial settlement credit (or have a Payment anomaly).

The name "Test" suggests this was originally created for testing or debugging purposes against the active tables (to detect issues before positions fully close), but it serves a legitimate production diagnostic role for identifying detached active copy positions that need real-time remediation.

---

## 2. Business Logic

### 2.1 Same Detection Pattern as FindDetachedPositions (Active Tables)

**What**: Same three-table LEFT JOIN query logic as FindDetachedPositions, but uses active-position tables.

**Table Substitutions vs FindDetachedPositions**:
| FindDetachedPositions | FindDetachedPositionsTest | Reason |
|----------------------|--------------------------|--------|
| History.Credit | History.ActiveCredit | Active credits for open positions |
| History.Position | History.PositionSlim | Slim/summary view of active positions |

**Rules** (identical to FindDetachedPositions):
- Scan ActiveCredit `a` WHERE CreditTypeID=27 AND MirrorID IS NOT NULL AND CreditID > @MinID.
- Left join ActiveCredit `c` for same CID+PositionID WHERE CreditTypeID=4.
- Detached when: c.CreditID IS NULL OR c.Payment <> 0.
- Left join PositionSlim `b` for NetProfit.
- TOP(@TOP) ORDER BY CreditID ASC, OPTION (RECOMPILE).
- Note: No `WHERE 1=0` or test-specific filters - this runs against live active data.

See `History.FindDetachedPositions` for full business logic documentation, including the CreditTypeID reference table and detection diagram.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinID | BIGINT | NO | - | CODE-BACKED | Pagination cursor: returns only records with CreditID > @MinID. Pass 0 for the first page. |
| 2 | @TOP | INT | NO | - | CODE-BACKED | Maximum rows to return. Controls TOP(@TOP) in the result set. |

**Result set columns** (same as FindDetachedPositions):

| Column | Source | Description |
|--------|--------|-------------|
| CreditID | History.ActiveCredit.CreditID | The type-27 disconnect credit ID |
| Occurred | History.ActiveCredit.Occurred | Timestamp of the mirror disconnection |
| MirrorID | History.ActiveCredit.MirrorID | CopyTrader mirror ID that was disconnected |
| PositionID | History.ActiveCredit.PositionID | The active copied position that is detached |
| NetProfit | History.PositionSlim.NetProfit | Current unrealized PnL of the active position |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (a) | History.ActiveCredit | Read | Primary scan: type-27 credits on active/open positions. |
| LEFT JOIN (b) | History.PositionSlim | Read | Retrieves NetProfit for the active detached position. |
| LEFT JOIN (c) | History.ActiveCredit | Read | Self-join to find matching type-4 close credit on active credits. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SuperRank or diagnostic tools | EXECUTE | Direct call | Diagnostic callers checking for detached active (not yet closed) copy positions. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.FindDetachedPositionsTest (procedure)
├── History.ActiveCredit (table) [x2 - main scan + self-join]
└── History.PositionSlim (table) [LEFT JOIN for NetProfit]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | Table | Primary scan (type-27 credits) and self-join (type-4 close credits). Two references aliased as `a` and `c`. |
| History.PositionSlim | Table | Left outer join to retrieve current NetProfit for active positions. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Diagnostic/reconciliation tools | External | Called to find currently open CopyTrader positions that are financially detached. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (RECOMPILE) | Query hint | Fresh plan per execution (same as FindDetachedPositions, prevents @MinID sniffing). |

---

## 8. Sample Queries

### 8.1 Get first page of detached active positions

```sql
EXEC History.FindDetachedPositionsTest @MinID = 0, @TOP = 100;
```

### 8.2 Compare detached count in active vs closed tables

```sql
-- Detached in closed positions
SELECT COUNT(*) AS ClosedDetached
FROM History.Credit a WITH (NOLOCK)
LEFT OUTER JOIN History.Credit c WITH (NOLOCK)
    ON a.PositionID = c.PositionID AND a.CID = c.CID AND c.CreditTypeID = 4
WHERE a.CreditTypeID = 27 AND a.MirrorID IS NOT NULL
  AND (c.CreditID IS NULL OR c.Payment <> 0);
```

### 8.3 Check active credits for a specific PositionID

```sql
SELECT CreditID, CreditTypeID, MirrorID, Payment, Occurred
FROM History.ActiveCredit WITH (NOLOCK)
WHERE PositionID = 123456
  AND CreditTypeID IN (4, 27)
ORDER BY Occurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FindDetachedPositionsTest | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.FindDetachedPositionsTest.sql*

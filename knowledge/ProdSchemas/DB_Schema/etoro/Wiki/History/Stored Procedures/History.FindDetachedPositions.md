# History.FindDetachedPositions

> Diagnostic query that finds closed CopyTrader positions (MirrorID IS NOT NULL) with a type-27 "Stock Position Disconnected" credit but a missing or zero-payment type-4 close credit, indicating an incomplete financial settlement.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MinID pagination cursor; result set: CreditID, Occurred, MirrorID, PositionID, NetProfit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

In eToro's CopyTrader feature, when a copied position is "disconnected" from its leader (e.g., the copier manually exits the copy relationship or the leader closes their account), a credit of type 27 is generated: "Closing Mirror, Stock Position Disconnected." Under normal operation, a corresponding type-4 close credit (position PnL credit) is also created to settle the position's profit/loss. A "detached" position is one where the disconnection credit (type 27) exists but the financial settlement credit (type 4) is absent or has Payment=0 - meaning the customer may not have received their realized PnL from the closed copy position.

This procedure surfaces those anomalies to the SuperRank application (which has direct EXECUTE access) for reconciliation and remediation. It queries `History.Credit` + `History.Position` - the closed-position tables - meaning it covers already-closed positions. Its counterpart `FindDetachedPositionsTest` performs the same logic on active positions via `History.ActiveCredit` + `History.PositionSlim`.

---

## 2. Business Logic

### 2.1 Detached Position Detection Pattern

**What**: Identifies the gap between a mirror disconnection credit (type 27) and the expected financial settlement credit (type 4).

**Columns/Parameters Involved**: `CreditTypeID`, `MirrorID`, `Payment`, `@MinID`

**Rules**:
- Base scan: History.Credit aliased as `a` WHERE CreditTypeID=27 AND MirrorID IS NOT NULL AND CreditID > @MinID.
  - CreditTypeID=27 = "Closing Mirror, Stock Position Disconnected"
  - MirrorID IS NOT NULL = confirms this is a copy position (not a direct trade)
- Left outer join to History.Credit `c` for the same CID+PositionID WHERE CreditTypeID=4 (close credit).
- A position is "detached" when: `c.CreditID IS NULL` (no close credit at all) OR `c.Payment <> 0` (close credit exists but has non-zero payment, indicating an incomplete or anomalous settlement).
- Note: the condition `c.Payment <> 0` is likely inverted intent - it may be checking for a Payment that should be 0 in normal disconnection scenarios, meaning non-zero = unexpected.
- Left outer join to History.Position `b` for NetProfit - provides the position's final PnL for context.
- `OPTION (RECOMPILE)` prevents parameter sniffing, since @MinID + @TOP change between calls.

**Diagram**:
```
Normal CopyTrader disconnection:
  History.Credit (type=27, MirrorID=X, PositionID=Y) <- disconnect event
  History.Credit (type=4,  MirrorID=X, PositionID=Y, Payment=0) <- PnL settled

Detached (returned by this procedure):
  History.Credit (type=27, MirrorID=X, PositionID=Y) <- disconnect event
  History.Credit: NO type=4 credit found (c.CreditID IS NULL)
  -> Detached!

Also detached:
  History.Credit (type=27, MirrorID=X, PositionID=Y)
  History.Credit (type=4,  MirrorID=X, PositionID=Y, Payment != 0)
  -> Payment anomaly!
```

### 2.2 Pagination Pattern

**What**: @MinID + @TOP enables cursor-based pagination through results.

**Rules**:
- Caller passes @MinID = last seen CreditID from previous batch, or 0 for first call.
- Procedure returns TOP(@TOP) ordered by CreditID ASC from records with CreditID > @MinID.
- Caller advances @MinID to the highest CreditID in the returned result set.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinID | BIGINT | NO | - | CODE-BACKED | Pagination cursor: returns only records with CreditID > @MinID. Pass 0 for the first page, then advance to the last CreditID returned. |
| 2 | @TOP | INT | NO | - | CODE-BACKED | Maximum number of rows to return per call. Controls TOP(@TOP) in the result set. |

**Result set columns:**

| Column | Source | Description |
|--------|--------|-------------|
| CreditID | History.Credit.CreditID | The type-27 disconnect credit ID (pagination key) |
| Occurred | History.Credit.Occurred | Timestamp of the mirror disconnection event |
| MirrorID | History.Credit.MirrorID | The CopyTrader mirror/leader relationship ID that was disconnected |
| PositionID | History.Credit.PositionID | The copied position that was detached |
| NetProfit | History.Position.NetProfit | The position's recorded PnL at close (NULL if not found in History.Position) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (a) | History.Credit | Read | Primary scan: finds type-27 credits with MirrorID (copy disconnections). |
| LEFT JOIN (b) | History.Position | Read | Retrieves NetProfit for the detached position. |
| LEFT JOIN (c) | History.Credit | Read | Self-join to find the corresponding type-4 close credit (or confirm its absence). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SuperRank application | EXECUTE grant | Direct call | SuperRank reconciliation system calls this to detect and remediate detached CopyTrader positions. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.FindDetachedPositions (procedure)
├── History.Credit (table) [x2 - main scan + self-join for type-4]
└── History.Position (table) [LEFT JOIN for NetProfit]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | Primary scan (type-27 credits) and self-join (type-4 close credits). Two separate references aliased as `a` and `c`. |
| History.Position | Table | Left outer join to retrieve NetProfit for the identified detached position. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SuperRank application | External | Calls periodically to find and remediate detached CopyTrader positions needing financial settlement. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (RECOMPILE) | Query hint | Forces fresh plan generation each execution. Prevents parameter sniffing on @MinID and @TOP which vary per call. |
| MirrorID IS NOT NULL | Filter | Ensures only copy positions are returned - direct trades with type-27 credits (if any) are excluded. |

---

## 8. Sample Queries

### 8.1 Get first page of detached positions (up to 100)

```sql
EXEC History.FindDetachedPositions @MinID = 0, @TOP = 100;
```

### 8.2 Manually verify detached positions for a specific PositionID

```sql
-- Check credits for a given PositionID
SELECT CreditID, CreditTypeID, MirrorID, Payment, Occurred
FROM History.Credit WITH (NOLOCK)
WHERE PositionID = 123456  -- replace with actual PositionID
  AND CreditTypeID IN (4, 27)
ORDER BY Occurred;
```

### 8.3 Count total detached positions (without pagination)

```sql
SELECT COUNT(*) AS DetachedCount
FROM History.Credit a WITH (NOLOCK)
LEFT OUTER JOIN History.Credit c WITH (NOLOCK)
    ON a.PositionID = c.PositionID AND a.CID = c.CID AND c.CreditTypeID = 4
WHERE a.CreditTypeID = 27
  AND a.MirrorID IS NOT NULL
  AND (c.CreditID IS NULL OR c.Payment <> 0);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FindDetachedPositions | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.FindDetachedPositions.sql*

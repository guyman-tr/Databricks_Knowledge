# History.Detach

> Legacy/orphaned table designed to track copy-trading position detachments - recording when a mirrored position was severed from its copy relationship - but currently contains 0 rows and is not referenced by any stored procedures in the codebase.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PositionID (bigint, CLUSTERED PK - one row per detached position) |
| **Partition** | No |
| **Indexes** | 4 active (CLUSTERED PK on PositionID, NC on FirstCreditIDAfterDetach, NC on Occurred, NC on PositionID duplicate) |

---

## 1. Business Meaning

This table was designed to record **copy-trading position detachments** - the event when a position that was being copied from a Popular Investor (mirror/guru) is severed from that copy relationship. In eToro's CopyTrading feature, a "copier" can allocate funds to automatically copy a Popular Investor's trades. When a copier "detaches" a specific position, that position continues to exist independently in the copier's account but is no longer synchronized with the PI's trades.

The schema captures: which customer detached (`CID`), from which mirror relationship (`MirrorID`), which specific position was detached (`PositionID`), when it happened (`Occurred`), and two post-detach reference points: the first credit event after detach (`FirstCreditIDAfterDetach`) and the associated market maker log entry (`MMLogID`).

**Current status: 0 rows and orphaned.** No stored procedures in the SSDT repository reference `History.Detach` as a target for INSERT or as a source for SELECT. The detach tracking has migrated to other tables:
- `History.PositionChangeLog_Active_BIGINT` is written by `History.PostDetachMirrorPosition` (the main detach handler)
- `History.FindDetachedPositions` reads from `History.Credit` (CreditTypeID=27) to find detach events

This table appears to be a legacy artifact from an earlier iteration of the detach tracking system, preserved in the schema but no longer active. The `OPTIMIZE_FOR_SEQUENTIAL_KEY = ON` on the clustered index (a SQL Server 2019+ feature for high-concurrency IDENTITY inserts) suggests the DDL was modernized but the table was never re-populated.

---

## 2. Business Logic

### 2.1 Copy Trading Detach Context

**What**: A "detach" in eToro copy trading is the act of disconnecting a specific copied position from its parent mirror relationship.

**Columns/Parameters Involved**: `CID`, `MirrorID`, `PositionID`, `Occurred`

**Rules** (inferred from schema and related SP analysis):
- `PositionID` is the CLUSTERED PK - one row per detached position (a position can only be detached once).
- `CID` = the customer (copier) who was copying this position.
- `MirrorID` = the mirror/copy relationship ID under which the position was being copied.
- `Occurred` = when the detach happened. NC index on Occurred enables time-range queries ("how many detaches happened this week?").
- `FirstCreditIDAfterDetach` = the first credit event generated after the detach, linking the detach to the subsequent credit record in `History.Credit`. NC index on this column supports the "find credit for this detach" lookup pattern.
- `MMLogID` = market maker log entry ID associated with this detach. FK to `History.MMLog` (implicit). Provides the market-maker perspective on the detach event.

### 2.2 Related Active Detach Tracking (Current System)

The detach workflow that replaced this table uses:
- `History.PositionChangeLog_Active_BIGINT`: written by `History.PostDetachMirrorPosition` via XML parameter parsing - captures full position state changes including detach events with MirrorID, TreeID, PrevTreeID context.
- `History.Credit` with `CreditTypeID=27`: tracks the credit event generated when a position is detached from a mirror.
- `History.FindDetachedPositions`: reads `History.Credit` (CreditTypeID=27) to find detach credits and their associated net profit.

---

## 3. Data Overview

The table currently contains **0 rows**. No historical data is available for analysis. The table structure is consistent with a pre-2019 design that tracked detach events one row per position, but this data was either never migrated here or was cleared.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | Customer ID of the copier who had the detached position. FK to Customer.CustomerStatic (implicit). NULL-allowed despite being a key field, suggesting the design allowed for system-initiated detaches without a specific customer context. |
| 2 | MirrorID | int | YES | - | CODE-BACKED | The copy relationship (mirror) ID from which the position was detached. FK to Trade.Mirror (implicit). Identifies which Popular Investor's copy program the position was being copied from. NULL for system-detaches or where the mirror context was not recorded. |
| 3 | PositionID | bigint | NO | - | CODE-BACKED | The specific position that was detached. CLUSTERED PRIMARY KEY - each position can be detached at most once (one row per PositionID). FK to Trade.PositionTbl (implicit). bigint accommodates the high-volume position ID space. |
| 4 | Occurred | datetime | YES | - | CODE-BACKED | UTC datetime when the detach occurred. NC index on Occurred enables time-range queries. NULL-allowed suggests some historical rows may have had unknown detach timestamps. |
| 5 | FirstCreditIDAfterDetach | int | YES | - | CODE-BACKED | The CreditID of the first credit event in History.Credit generated after this position was detached. Links the detach record to the credit settlement that followed. NC index on this column supports the pattern: "given a credit, was this position recently detached?" Used to identify detach-driven credit payments. |
| 6 | MMLogID | int | YES | - | NAME-INFERRED | Market Maker log entry ID associated with this detach event. FK to History.MMLog (implicit). Provides the market-maker system's perspective on the detach - recording how the detach was handled from a hedging/position management standpoint. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | The copier customer who detached the position |
| MirrorID | Trade.Mirror | Implicit | The copy relationship from which the position was detached |
| PositionID | Trade.PositionTbl | Implicit | The specific position that was detached |
| FirstCreditIDAfterDetach | History.Credit | Implicit | The first credit event after detach |
| MMLogID | History.MMLog | Implicit | The market maker log entry for this detach |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none found) | - | - | No stored procedures in the SSDT repository reference this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Detach (table)
- Leaf node - no code-level dependencies
- Orphaned: no writers or readers found in SSDT
- Logically related to: Trade.PositionTbl, Trade.Mirror, History.Credit, History.MMLog
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No objects depend on this table (orphaned).

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Detach | CLUSTERED (PK) | PositionID ASC | - | - | Active |
| IX_HistoryDetach_FirstCreditIDAfterDetach | NONCLUSTERED | FirstCreditIDAfterDetach ASC | - | - | Active |
| IX_HistoryDetach_Occurred | NONCLUSTERED | Occurred ASC | - | - | Active |
| IX_HistoryDetach_PositionID | NONCLUSTERED | PositionID ASC | - | - | Active |

Note: `IX_HistoryDetach_PositionID` is a NONCLUSTERED index on the same column as the CLUSTERED PK - this is redundant. The clustered index already provides fast lookup by PositionID.

**Filegroup**: [PRIMARY] (not [HISTORY] - consistent with earlier tables in this schema before the [HISTORY] filegroup convention was established).
**Compression**: DATA_COMPRESSION = PAGE on CLUSTERED PK only. NC indexes have no compression.
**OPTIMIZE_FOR_SEQUENTIAL_KEY = ON**: Set on the clustered PK - a SQL Server 2019+ feature that reduces last-page contention for high-concurrency IDENTITY inserts. Suggests the DDL was updated for SQL Server 2019 compatibility but the table is no longer active.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Detach | PRIMARY KEY (CLUSTERED) | Uniqueness on PositionID - one detach record per position |

---

## 8. Sample Queries

### 8.1 Check if any data exists (current status verification)
```sql
SELECT COUNT(*) AS RowCount, MIN(Occurred) AS OldestDetach, MAX(Occurred) AS NewestDetach
FROM [History].[Detach] WITH (NOLOCK)
```

### 8.2 Find detach record for a specific position (if populated)
```sql
SELECT CID, MirrorID, PositionID, Occurred, FirstCreditIDAfterDetach, MMLogID
FROM [History].[Detach] WITH (NOLOCK)
WHERE PositionID = @PositionID
```

### 8.3 Cross-reference with active detach tracking (current system)
```sql
-- Current system: find detach events via History.Credit (CreditTypeID=27)
SELECT c.CreditID, c.CID, c.MirrorID, c.PositionID, c.Occurred, p.NetProfit
FROM History.Credit c WITH (NOLOCK)
LEFT JOIN History.Position p WITH (NOLOCK) ON c.PositionID = p.PositionID
WHERE c.CreditTypeID = 27       -- detach credit type
  AND c.MirrorID IS NOT NULL
ORDER BY c.CreditID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 7.5/10 (Elements: 7.5/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Note: Table has 0 rows and is orphaned - no SPs write to or read from it. Business logic inferred from column semantics and related detach SPs.*
*Object: History.Detach | Type: Table | Source: etoro/etoro/History/Tables/History.Detach.sql*

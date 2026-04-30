# Trade.GetUsersUnrealizedEquityDataJunk

> Obsolete/junk version of GetUsersUnrealizedEquityData - contains an @IsReal branching pattern where Demo (IsReal=0) uses the same Pnl DB routing as production, but Real (IsReal=1) computes equity from etoro.Trade.PnL + etoro.Customer.Customer directly (slower, compute-heavy approach). Retained as reference code.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cidToMirrorId TVP - Trade.CidToMirrorId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUsersUnrealizedEquityDataJunk` is the "junk" (obsolete, retained for reference) predecessor to `Trade.GetUsersUnrealizedEquityData`. The "Junk" suffix explicitly marks it as non-production code retained for historical reference or ad-hoc debugging. It implements the same TVP-based unrealized equity retrieval but uses a different strategy for the Real DB case.

The key difference is the `@IsReal` branching:
- **@IsReal=0 (Demo)**: Same dual-source pattern as the production SP (SynReal for MirrorID=0, Pnl DB for MirrorID!=0). However, it uses the raw TVP `@cidToMirrorId` directly (no temp table materialization).
- **@IsReal=1 (Real)**: Computes unrealized equity on-the-fly by summing `etoro.Trade.PnL.PnLInDollars` and adding `RealizedEquity` from Customer. This is the old, compute-heavy approach that was replaced by the PortfolioEquitySnapshotTbl pattern.

The @IsReal=1 branch also has a commented-out code block and several quirks: it accesses tables via fully qualified names (`etoro.Customer.Customer`, `etoro.Trade.PnL`), handles MirrorID NULL vs 0 inconsistently, and omits the temp table optimization. This confirms its "junk" status.

---

## 2. Business Logic

### 2.1 IsReal Branching

**What**: Different computation strategy based on IsRealDB feature flag.

**Rules**:
- `@IsReal = CAST(Value AS INT) FROM Maintenance.Feature WHERE FeatureID = 22`
- `@IsReal=0` branch: reads from PortfolioEquitySnapshotTbl (same as production) - fast
- `@IsReal=1` branch: computes from PnL table (SUM of PnLInDollars + RealizedEquity) - slower, legacy approach

### 2.2 @IsReal=0 Branch (Demo - PortfolioEquitySnapshotTbl)

**What**: Identical logic to production SP but without temp table materialization.

**Rules**:
- Same UNION ALL of SynRealPortfolioEquitySnapshotTbl (MirrorID=0) + Pnl.Trade.PortfolioEquitySnapshotTbl (MirrorID!=0)
- Joins directly on `@cidToMirrorId` TVP (no temp table)
- Partially commented-out code visible at top (`--SELECT CID, MirrorID INTO #CidToMirrorId`)

### 2.3 @IsReal=1 Branch (Real - Legacy PnL Compute)

**What**: On-the-fly equity computation from PnL table (old approach).

**Rules**:
- CTE aggregates `SUM(PnL.PnLInDollars) AS PnL` from `etoro.Trade.PnL` grouped by CID+MirrorID
- Joins `etoro.Customer.Customer` for RealizedEquity
- Final select: `UnRealizedEquity = PnL + (CASE WHEN MirrorID IS NULL THEN RealizedEquity ELSE mirror.RealizedEquity END)`
- Excludes `MirrorID=0`: `WHERE (a.MirrorID != 0 OR a.MirrorID IS NULL)` - note: this is the opposite of expected (excludes 0, keeps non-0 and NULL)
- The `ISNULL(a.MirrorID, 0) AS MirrorID` output normalizes NULL to 0

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cidToMirrorId | Trade.CidToMirrorId READONLY | NO | - | CODE-BACKED | TVP of CID+MirrorID pairs. Same type as production SP. |

**Output columns (same as production SP in both branches):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 3 | MirrorID | INT | NO | - | CODE-BACKED | Mirror ID. 0 (or ISNULL to 0) = direct position; >0 = copy. |
| 4 | UnRealizedEquity | MONEY | YES | - | CODE-BACKED | Unrealized equity from snapshot table (@IsReal=0) or computed from PnL table (@IsReal=1). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TVP | Trade.CidToMirrorId | User Defined Type | Input TVP type |
| @IsReal gate | Maintenance.Feature | SELECT | FeatureID=22 |
| @IsReal=0 branch | Trade.SynRealPortfolioEquitySnapshotTbl | INNER JOIN | Real Pnl synonym (MirrorID=0) |
| @IsReal=0 branch | [Pnl].[Trade].[PortfolioEquitySnapshotTbl] | INNER JOIN | Pnl DB (MirrorID!=0) |
| @IsReal=1 branch | etoro.Customer.Customer | INNER JOIN | RealizedEquity for equity computation |
| @IsReal=1 branch | etoro.Trade.PnL | INNER JOIN | PnLInDollars aggregation |
| @IsReal=1 branch | etoro.Trade.Mirror | LEFT JOIN | Mirror RealizedEquity |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (debug/ad-hoc use only) | - | - | Not referenced by production code |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUsersUnrealizedEquityDataJunk (procedure)
+-- Trade.CidToMirrorId (UDT)
+-- Maintenance.Feature (table)
+-- [IsReal=0] Trade.SynRealPortfolioEquitySnapshotTbl (synonym)
+-- [IsReal=0] [Pnl].[Trade].[PortfolioEquitySnapshotTbl] (cross-DB)
+-- [IsReal=1] etoro.Customer.Customer (cross-DB)
+-- [IsReal=1] etoro.Trade.PnL (cross-DB)
+-- [IsReal=1] etoro.Trade.Mirror (cross-DB)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CidToMirrorId | User Defined Type | TVP type |
| Maintenance.Feature | Table | IsRealDB flag (FeatureID=22) |
| Trade.SynRealPortfolioEquitySnapshotTbl | Synonym | Demo branch: Real Pnl snapshot |
| [Pnl].[Trade].[PortfolioEquitySnapshotTbl] | Cross-DB Table | Demo branch: Pnl snapshot |
| etoro.Customer.Customer | Cross-DB Table | Real branch: RealizedEquity |
| etoro.Trade.PnL | Cross-DB Table | Real branch: PnLInDollars |
| etoro.Trade.Mirror | Cross-DB Table | Real branch: mirror RealizedEquity |

### 6.2 Objects That Depend On This

No dependents. Junk/obsolete procedure.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @IsReal branch | Runtime flag | Execution path differs between Demo and Real environments |
| No temp table | Performance gap | @IsReal=0 branch uses raw TVP scan (no clustered index optimization) |
| MirrorID != 0 OR MirrorID IS NULL | Quirk | @IsReal=1 branch excludes MirrorID=0 rows entirely |

---

## 8. Sample Queries

### 8.1 Call the junk version (debug comparison)
```sql
DECLARE @pairs Trade.CidToMirrorId;
INSERT INTO @pairs VALUES (123456, 0), (123456, 99887766);
EXEC Trade.GetUsersUnrealizedEquityDataJunk @cidToMirrorId = @pairs;
-- Compare output with production version:
EXEC Trade.GetUsersUnrealizedEquityData @cidToMirrorId = @pairs;
```

### 8.2 Verify IsRealDB in current environment
```sql
SELECT CAST(Value AS INT) AS IsRealDB
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID = 22
```

### 8.3 N/A - third query not applicable for junk procedure

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Junk/obsolete procedure not documented.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUsersUnrealizedEquityDataJunk | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUsersUnrealizedEquityDataJunk.sql*

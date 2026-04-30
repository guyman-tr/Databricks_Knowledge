# Trade.DividendsSetSnapshotIsReady_DryRun

> Marks dividend records as snapshot-ready (Status=4) in the sandbox Trade.IndexDividends_DryRun table, mirroring the production procedure for testing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DividendIDs, @MarketCloseDateTime |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the **dry-run (sandbox) equivalent** of `Trade.DividendsSetSnapshotIsReady`. It performs the identical Status=3→4 transition with snapshot timestamp recording, but against `Trade.IndexDividends_DryRun` instead of the production table. This allows the dividend service to validate the snapshot-ready workflow end-to-end in a sandbox environment before committing to production.

---

## 2. Business Logic

### 2.1 Snapshot Completion Update (Dry Run)

**What**: Transitions dry-run dividend records to snapshot-ready and records timing data.

**Columns/Parameters Involved**: `Trade.IndexDividends_DryRun.Status`, `Trade.IndexDividends_DryRun.PositionsSnapshotMarketClose`, `Trade.IndexDividends_DryRun.PositionsSnapshotCompleted`

**Rules**:
- UPDATE Trade.IndexDividends_DryRun SET Status = 4, PositionsSnapshotMarketClose = @MarketCloseDateTime, PositionsSnapshotCompleted = GETUTCDATE()
- JOIN @DividendIDs TVP on DividendID = Id
- WHERE Status = 3 (same guard as production version)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DividendIDs | Trade.IdIntList (TVP) | READONLY | - | CODE-BACKED | List of DividendID values whose snapshots are complete in the dry-run table. |
| 2 | @MarketCloseDateTime | DateTime | NO | - | CODE-BACKED | The market close time for the ex-dividend date. Stored for audit reference. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DividendIDs | Trade.IndexDividends_DryRun | Write | Updates Status, PositionsSnapshotMarketClose, PositionsSnapshotCompleted |
| @DividendIDs | Trade.IdIntList | UDT (TVP) | Integer list table type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Dividends/Snapshot service) | N/A | Application caller | Called during dry-run snapshot cycles |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DividendsSetSnapshotIsReady_DryRun (procedure)
+-- Trade.IndexDividends_DryRun (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends_DryRun | Table | Sandbox dividend state and snapshot tracking |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: Identical logic to `Trade.DividendsSetSnapshotIsReady` but targeting the _DryRun table.

---

## 8. Sample Queries

### 8.1 Check dry-run snapshot status

```sql
SELECT  DividendID, Status, PositionsSnapshotMarketClose, PositionsSnapshotCompleted
FROM    Trade.IndexDividends_DryRun WITH (NOLOCK)
WHERE   Status IN (3, 4)
ORDER BY DividendID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DividendsSetSnapshotIsReady_DryRun | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DividendsSetSnapshotIsReady_DryRun.sql*

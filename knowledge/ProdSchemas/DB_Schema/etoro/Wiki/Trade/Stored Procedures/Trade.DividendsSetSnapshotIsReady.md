# Trade.DividendsSetSnapshotIsReady

> Marks dividend records as snapshot-ready (Status=4) in Trade.IndexDividends after position snapshots are captured at market close, recording the snapshot timestamp.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DividendIDs, @MarketCloseDateTime |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure handles a critical step in the **dividend payment pipeline**: marking that position snapshots have been captured. Before dividends can be paid, the system must know exactly which positions were open at market close on the ex-dividend date. After the snapshot service completes position capture, it calls this procedure to transition dividend records from Status=3 (Snapshot Pending) to Status=4 (Snapshot Ready), recording both the market close time and when the snapshot completed.

This enables downstream payment processing to proceed with confidence that position data is finalized.

---

## 2. Business Logic

### 2.1 Snapshot Completion Update

**What**: Transitions dividends to snapshot-ready and records timing data.

**Columns/Parameters Involved**: `Trade.IndexDividends.Status`, `Trade.IndexDividends.PositionsSnapshotMarketClose`, `Trade.IndexDividends.PositionsSnapshotCompleted`

**Rules**:
- UPDATE Trade.IndexDividends SET Status = 4, PositionsSnapshotMarketClose = @MarketCloseDateTime, PositionsSnapshotCompleted = GETUTCDATE()
- JOIN @DividendIDs TVP on DividendID = Id
- WHERE Status = 3 (only transitions from "Snapshot Pending")
- PositionsSnapshotMarketClose = the market close time (input parameter, exchange-specific)
- PositionsSnapshotCompleted = current UTC time (when processing actually finished)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DividendIDs | Trade.IdIntList (TVP) | READONLY | - | CODE-BACKED | List of DividendID values whose snapshots are complete. |
| 2 | @MarketCloseDateTime | DateTime | NO | - | CODE-BACKED | The market close time for the ex-dividend date. Exchange-specific (e.g., NYSE 16:00 ET). Stored for audit and payment calculation reference. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DividendIDs | Trade.IndexDividends | Write | Updates Status, PositionsSnapshotMarketClose, PositionsSnapshotCompleted |
| @DividendIDs | Trade.IdIntList | UDT (TVP) | Integer list table type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Dividends/Snapshot service) | N/A | Application caller | Called after position snapshot capture completes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DividendsSetSnapshotIsReady (procedure)
+-- Trade.IndexDividends (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends | Table | Dividend state and snapshot tracking |

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

**Note**: Created by Adam Porat on 16/03/2022. The PositionsSnapshotCompleted timestamp uses GETUTCDATE() (server time at execution), while PositionsSnapshotMarketClose is the exchange-specific close time passed by the caller. See also `Trade.DividendsSetSnapshotIsReady_DryRun` for the sandbox equivalent.

---

## 8. Sample Queries

### 8.1 Check dividends awaiting or with completed snapshots

```sql
SELECT  DividendID, Status, PositionsSnapshotMarketClose, PositionsSnapshotCompleted
FROM    Trade.IndexDividends WITH (NOLOCK)
WHERE   Status IN (3, 4)
ORDER BY DividendID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DividendsSetSnapshotIsReady | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DividendsSetSnapshotIsReady.sql*

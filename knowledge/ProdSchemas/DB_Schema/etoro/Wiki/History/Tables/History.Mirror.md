# History.Mirror

> Complete audit log for all successful copy-trading mirror operations. Every operation on a mirror relationship (register, unregister, edit balance, change state, pause, resume, detach, alignment) is recorded here by the Mirror Operation Engine (MOE). Each row represents one completed operation, identified by MirrorOperationID. Companion to History.MirrorFail (unsuccessful operations); together they form the full operation audit trail queried by History.GetMirrorOperationDetails.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY PK) |
| **Partition** | No - CLUSTERED PK on [PRIMARY], 6 additional NC indexes |
| **Indexes** | 7 (CLUSTERED PK on ID, 6 NC including 1 filtered) |

---

## 1. Business Meaning

This table is the primary audit log for all successful Copy Trading mirror operations. A "mirror" (Trade.Mirror) is the persistent copy-trading relationship between a copier (CID) and a popular investor (ParentCID). Every time the mirror state changes - from initial registration through balance edits, pause/resume, position detaches, alignment events, and final deregistration - one row is inserted here with the operation type, the post-operation mirror state, and financial context.

The table spans 2011-08-02 to 2025-12-17, covering 71,151 distinct mirrors across 19,108 copiers, with 166,902 operation records. The 71,148 rows with MirrorOperationID=1 (Register) confirms that the table stores approximately one registration per distinct mirror - the complete mirror lifecycle is tracked end-to-end.

**The MOE (Mirror Operation Engine)** is the primary writer via its `HistoryMirrorRepository`. Where `History.MirrorFail` captures failed operations, this table captures successful ones. The view `History.GetMirrorOperationDetails` (SP) uses a UNION of History.Mirror (Ordinal=1) and History.MirrorFail (Ordinal=2) to return the first matching record (success preferred over failure).

**Companion table**: `History.MirrorFail` (failed operations, written by MOE via SqlBulkCopy).
**FK dependency**: `History.MirrorDividend` (MirrorDividendID) - documented as #12 in this batch.

---

## 2. Business Logic

### 2.1 MirrorOperationID - Operation Type Classification

**What**: Every row's meaning is defined by its MirrorOperationID. This is the central classification column.

**Columns/Parameters Involved**: `MirrorOperationID`, `IsActive`, `CloseMirrorActionType`

**Values** (from Dictionary.MirrorOperation):

| MirrorOperationID | Name | Count | Pct | Key Columns |
|-------------------|------|-------|-----|-------------|
| 1 | Register Mirror | 71,148 | 42.6% | IsActive=1, Amount=initial investment, InitialInvestment populated |
| 4 | Change mirror's state | 52,689 | 31.6% | IsActive changes, most common non-register operation |
| 2 | UnRegister Mirror | 18,138 | 10.9% | IsActive=0, CloseMirrorActionType populated, filtered index |
| 10 | Position Detach | 8,662 | 5.2% | Amount=detached position equity, MirrorDividendID=0 in data |
| 3 | Edit Mirror's balance | 6,528 | 3.9% | Amount=new balance amount |
| 12 | alignment_started | 3,089 | 1.9% | Alignment process initiated |
| 13 | alignment_ended | 2,873 | 1.7% | Alignment process completed |
| 7 | Pause Copy | 1,809 | 1.1% | PauseCopy=1 |
| 9 | Edit Mirror SL Percentage | 1,804 | 1.1% | MirrorSLPercentage updated |
| 8 | Resume Copy | 137 | 0.1% | PauseCopy=0 |
| 11 | Update MirrorCalculationType | 25 | 0.01% | MirrorCalculationType updated |

Note: MirrorOperationID=5 (Edit Mirror SL) and MirrorOperationID=6 (Close Position) appear in Dictionary.MirrorOperation but have 0 rows in this table (operations likely handled via other paths or deprecated).

### 2.2 MOE Write Pattern

**What**: The Mirror Operation Engine (MOE) inserts rows here upon successful completion of each mirror operation.

**Rules** (from MOE architecture documentation, Confluence 12857836033):
- MOE is an AKS-deployed .NET microservice (DDD architecture)
- Uses `HistoryMirrorRepository` (standard SQL INSERT, not SqlBulkCopy - unlike MirrorFail)
- Each of 9 MOE processors writes to History.Mirror on success: MirrorAlignmentStatusUpdateRequestProcessor, MirrorCloseRequestProcessor, MirrorDeactivateRequestProcessor, MirrorEditAmountRequestProcessor, MirrorEditRequestProcessor, MirrorEditStopLossPercentageRequestProcessor, MirrorRegisterRequestProcessor, ExternalCopyRequestPreProcessor, MirrorCalculationTypeUpdateRequestProcessor
- Row is inserted with the full mirror state snapshot post-operation
- If the operation fails, MOE writes to History.MirrorFail instead (no row here)

**Legacy writers** (still active SPs):
- `History.LogMirrorSLClose` / `History.LogMirrorSLCloseFail`: SL-triggered mirror close (MirrorOperationID=2)
- `Trade.ChangeMirrorCalculationType`: MirrorOperationID=11
- `Trade.MirrorPauseCopy`: MirrorOperationID=7
- `Trade.MirrorReopen`: MirrorOperationID=1, ReopenForMirrorID populated
- `Trade.SetMirrorAlignmentStatus`: MirrorOperationID=12 or 13
- `Trade.PostDetachPositionFromMirror`: MirrorOperationID=10

### 2.3 Amount Column Semantics by Operation

**What**: Amount meaning varies by MirrorOperationID.

**Columns/Parameters Involved**: `Amount`, `RealizedEquity`, `InitialInvestment`, `DepositSummary`, `WithdrawalSummary`, `NetProfit`

**Rules** (observed):
- **Register (1)**: Amount = initial investment in USD (e.g., min=$10, max=$3,000,000). Always positive.
- **Unregister (2)**: Amount = realized equity at close. Can be positive (profit) or negative (loss). Range: -$22.5M to +$21.7M.
- **Edit Balance (3)**: Amount = new balance amount after edit. Can be positive (add funds) or negative (withdrawal from mirror).
- **Position Detach (10)**: Amount = equity of the detached position.
- `RealizedEquity`: The cumulative realized P&L at operation time. Positive = profit, negative = loss.
- `GuruTPV`: Total Portfolio Value (TPV) of the popular investor being copied at the time of operation. Used for proportional position sizing.

### 2.4 Mirror Registration and Reopening

**What**: The same copier can re-register a mirror to the same popular investor. ReopenForMirrorID links the new mirror to the one it replaced.

**Columns/Parameters Involved**: `ReopenForMirrorID`, `MirrorOperationID`

**Rules**:
- When a copier restarts copying the same popular investor, a new MirrorID is created (in Trade.Mirror) and a new Registration row (MirrorOperationID=1) is inserted here
- `ReopenForMirrorID` = the old MirrorID that was closed and reopened. NULL for first-time registrations.
- `Trade.MirrorReopen` SP handles this: `@IsReopenMirror = 1` flag in Trade.RegisterMirror triggers ReopenForMirrorID population

### 2.5 MIMOOperationTypeID - Mirror-Initiated Money Operations

**What**: Classifies whether the balance change was initiated by a money operation type.

**Columns/Parameters Involved**: `MIMOOperationTypeID`, `MirrorDividendID`

**Rules** (from Dictionary.MirrorMIMOOperation):
- 0 = Manual (default): Standard user or system-initiated operation
- 1 = CopyDividend: Mirror balance change triggered by a copy dividend event. MirrorDividendID will reference History.MirrorDividend
- 2 = Fees: Balance change due to fees
- 3 = IndexDividend: Balance change from index dividend

When MIMOOperationTypeID=1 (CopyDividend), `MirrorDividendID` links to `History.MirrorDividend.ID` for the dividend record.

### 2.6 IsActive State Tracking

**What**: IsActive records the state of the mirror at the time of the operation.

**Rules**:
- 1 = Mirror relationship is active (copier still following popular investor)
- 0 = Mirror relationship is inactive/closed
- Register operations (ID=1): IsActive=1
- Unregister operations (ID=2): IsActive=0
- Change state (ID=4): either value depending on transition direction

### 2.7 Filtered Index for Unregister Queries

**What**: IX_HistoryMirror_MirrorID_Filtered covers frequent "is this mirror unregistered?" queries.

**Rules**:
```sql
-- Index definition:
CREATE NONCLUSTERED INDEX [IX_HistoryMirror_MirrorID_Filtered] ON [History].[Mirror] (MirrorID ASC)
INCLUDE (CID, IsActive)
WHERE (MirrorOperationID = 2)  -- UnRegister Mirror only
```
- Scanning this index returns only the ~18K unregistration rows (vs 166K full table scan)
- Covers queries like: "Find all mirrors that have been deregistered" or "Has MirrorID X been deregistered?"

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 166,902 |
| Distinct MirrorIDs | 71,151 |
| Distinct copier CIDs | 19,108 |
| Date range | 2011-08-02 to 2025-12-17 |

Recent sample (most recent rows, MirrorID=1883762):

| ID | MirrorOperationID | IsActive | Amount | CloseMirrorActionType | Occurred |
|----|------------------|----------|--------|-----------------------|----------|
| 167893 | 2 (UnRegister) | 0 | -7,787,829.87 | 1 | 2025-12-17 |
| 167892 | 10 (Detach) | 0 | -21.35 | null | 2025-12-17 |
| 167891 | 10 (Detach) | 0 | -118.84 | null | 2025-12-17 |

The last 5 rows for MirrorID=1883762 show a mirror deregistration: multiple position detach events (ID=10, each detaching one position's equity) followed by the final UnRegister (ID=2) with total realized equity of -$7.8M.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incremented audit row ID. CLUSTERED PK. Does NOT equal MirrorID. |
| 2 | MirrorID | int | NO | - | CODE-BACKED | The copy-trading relationship ID (FK to Trade.Mirror while active, or the historical MirrorID after deregistration). 71,151 distinct MirrorIDs in current data. |
| 3 | CID | int | NO | - | CODE-BACKED | The copier customer ID. NC index IX_HistoryMirror_CID for efficient lookup of all operations by a copier. |
| 4 | ParentCID | int | NO | - | CODE-BACKED | The popular investor's customer ID. NC index IX_HistoryMirror_ParentCIDCID for queries like "all copiers who ever copied this PI". |
| 5 | ParentUserName | varchar(50) | NO | - | CODE-BACKED | The popular investor's username at the time of the operation. Snapshot value - may differ from current username if PI changed their name. |
| 6 | Amount | dbo.dtPrice | NO | - | CODE-BACKED | The amount associated with this operation, in USD. Semantics vary by MirrorOperationID: registration=initial investment, unregister=realized equity, edit balance=new balance, detach=detached position equity. Can be negative (loss). Uses dbo.dtPrice precision decimal UDT. |
| 7 | Occurred | datetime | NO | - | CODE-BACKED | When the mirror operation was processed by MOE (or legacy SP). NC index IX_HistoryMirror_Occurred for time-range queries. |
| 8 | IsActive | tinyint | NO | - | CODE-BACKED | Mirror state after this operation: 1=active, 0=deregistered/inactive. Enables reconstruction of mirror lifecycle from this table alone. |
| 9 | ModificationDate | datetime | NO | getutcdate() | CODE-BACKED | When this row was written to History.Mirror. Defaults to getutcdate(). May differ from Occurred by milliseconds (async processing lag). |
| 10 | MirrorOperationID | int | YES | - | CODE-BACKED | The operation type. FK to Dictionary.MirrorOperation WITH CHECK. Values: 1=Register, 2=UnRegister, 3=EditBalance, 4=ChangeState, 7=Pause, 8=Resume, 9=EditSLPct, 10=Detach, 11=UpdateCalcType, 12=AlignmentStarted, 13=AlignmentEnded. NULL very rare. |
| 11 | MirrorTypeID | int | NO | 1 | CODE-BACKED | Type of mirror (FK to Dictionary.MirrorType). DEFAULT=1. All current data has MirrorTypeID=1 (standard copy-trading mirror). |
| 12 | IsOpenOpen | bit | YES | - | CODE-BACKED | Whether the "open-open" copy mode was enabled for this mirror. When true, the copier mirrors all future positions opened by the PI. |
| 13 | GuruTPV | money | YES | - | CODE-BACKED | Total Portfolio Value of the popular investor at the time of operation. Used to calculate proportional position sizing for the copier. May be NULL for some operation types. |
| 14 | MirrorSL | money | YES | - | CODE-BACKED | The mirror-level stop-loss amount in USD at time of operation. DEFAULT=0 (no SL). The amount at which the entire copy relationship auto-closes. |
| 15 | CloseMirrorActionType | int | YES | - | CODE-BACKED | How the mirror was closed, populated on UnRegister (ID=2) operations. NULL for all other operations. Values: 1=normal close (observed in recent data). |
| 16 | RealizedEquity | money | YES | - | CODE-BACKED | The cumulative realized P&L on the mirror at this operation's time. The snapshot of closed-position profit/loss. Can be positive (profitable copying) or negative. |
| 17 | PauseCopy | bit | YES | - | CODE-BACKED | Whether copy was paused at time of this operation. Set to 1 by Pause (ID=7), 0 by Resume (ID=8). NULL for other operations. DEFAULT NOT specified - NULL means not explicitly set during this operation. |
| 18 | MirrorSLPercentage | money | YES | - | CODE-BACKED | The mirror stop-loss as a percentage of invested amount (e.g., 2.0 = 2%). Updated by EditSLPercentage (ID=9) operations. |
| 19 | InitialInvestment | money | YES | - | CODE-BACKED | The original amount invested when the mirror was first registered. Preserved across subsequent operations for reference. |
| 20 | DepositSummary | money | YES | - | CODE-BACKED | Cumulative deposits added to the mirror since registration. Updated on EditBalance (ID=3) operations. |
| 21 | WithdrawalSummary | money | YES | - | CODE-BACKED | Cumulative withdrawals from the mirror since registration. Updated on EditBalance (ID=3) operations. |
| 22 | SessionID | bigint | YES | - | CODE-BACKED | Browser/app session ID at time of operation. Used for analytics attribution of user actions. NULL for system-triggered operations. |
| 23 | NetProfit | money | YES | - | CODE-BACKED | Net profit on the mirror at this operation's time. = RealizedEquity + unrealized. Snapshot value. |
| 24 | UseCopyDividend | tinyint | NO | 1 | CODE-BACKED | Whether the mirror participates in copy dividends. DEFAULT=1 (enabled). When 1, dividends received by the PI's positions are proportionally credited to the copier. |
| 25 | MIMOOperationTypeID | tinyint | NO | 0 | CODE-BACKED | Mirror-Initiated Money Operation type. FK to Dictionary.MirrorMIMOOperation. DEFAULT=0 (Manual). Values: 0=Manual, 1=CopyDividend, 2=Fees, 3=IndexDividend. Non-zero when a balance change is triggered by a dividend or fee event. |
| 26 | MirrorDividendID | int | YES | - | CODE-BACKED | FK to History.MirrorDividend.ID. Populated when MIMOOperationTypeID=1 (CopyDividend), linking this operation to the specific dividend distribution event. 0 in some rows (Position Detach operations) - 0 indicates not linked, not NULL. |
| 27 | ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | A GUID identifying the original client API request. Used for idempotency - prevents duplicate operations if the same request is retried. NULL for system-initiated operations. |
| 28 | ReopenForMirrorID | int | YES | - | CODE-BACKED | When a copier restarts copying the same PI, this references the previous MirrorID that was closed. NULL for initial registrations. Links the new mirror to its predecessor for lifecycle analysis. |
| 29 | MirrorCalculationType | int | YES | - | CODE-BACKED | How the copy proportions are calculated. Updated by UpdateMirrorCalculationType (ID=11) operations. Values: 0=proportional (default), other values = alternative calculation modes. |
| 30 | ReferenceID | varchar(36) | YES | - | CODE-BACKED | External reference identifier for the operation. Used for correlation with external systems (e.g., MOE event IDs). |
| 31 | ExternalOperationType | smallint | YES | - | CODE-BACKED | Classifies the external system or trigger that initiated this operation (from ExternalCopyRequestPreProcessor). NULL for internally-initiated operations. |
| 32 | (ParentUserName - see #5) | - | - | - | - | (see above - column counted above) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Dictionary.MirrorOperation | MirrorOperationID | FK WITH CHECK | The operation type. 11 distinct operations tracked. |
| Dictionary.MirrorMIMOOperation | MIMOOperationTypeID | FK WITH CHECK | Mirror-initiated money operation type. 4 values. |
| History.MirrorDividend | MirrorDividendID | FK WITH CHECK | The copy dividend event that triggered this operation (when MIMOOperationTypeID=1). |
| Trade.Mirror | MirrorID | Implicit FK | The live mirror record (during mirror lifetime). |
| Customer.Customer | CID, ParentCID | Implicit FK | The copier and popular investor. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MOE (HistoryMirrorRepository) | MirrorID | Writer (INSERT) | Primary writer for all 9 MOE processors on successful operations. |
| History.LogMirrorSLClose | MirrorID | Writer (INSERT) | Legacy SP for SL-triggered mirror closes (MirrorOperationID=2). |
| Trade.MirrorPauseCopy | MirrorID | Writer (INSERT) | Pause Copy operations (MirrorOperationID=7). |
| Trade.SetMirrorAlignmentStatus | MirrorID | Writer (INSERT) | Alignment events (MirrorOperationID=12/13). |
| Trade.PostDetachPositionFromMirror | MirrorID | Writer (INSERT) | Position detach operations (MirrorOperationID=10). |
| Trade.MirrorReopen | MirrorID | Writer (INSERT) | Mirror reopen (MirrorOperationID=1, ReopenForMirrorID set). |
| Trade.ChangeMirrorCalculationType | MirrorID | Writer (INSERT) | Calculation type updates (MirrorOperationID=11). |
| History.GetMirrorOperationDetails | ID | Reader (UNION) | Returns this table (Ordinal=1, success) UNION History.MirrorFail (Ordinal=2, failure). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Mirror (table)
- Written by: MOE HistoryMirrorRepository (primary - all 9 processors)
  - On successful: Register, UnRegister, EditBalance, ChangeState, Pause, Resume,
    EditSLPct, Detach, UpdateCalcType, AlignmentStart/End
- Written by: Legacy SPs (Trade.MirrorPauseCopy, Trade.SetMirrorAlignmentStatus, etc.)
- FK dependency: History.MirrorDividend (must be documented first)
- FK dependency: Dictionary.MirrorOperation (13 operations)
- FK dependency: Dictionary.MirrorMIMOOperation (4 MIMO types)
- Read by: History.GetMirrorOperationDetails (UNION with History.MirrorFail)
```

### 6.1 Objects This Depends On

| Object | Dependency Type | Notes |
|--------|----------------|-------|
| Dictionary.MirrorOperation | FK WITH CHECK | MirrorOperationID (11 values active in data) |
| Dictionary.MirrorMIMOOperation | FK WITH CHECK | MIMOOperationTypeID (4 values: 0-3) |
| History.MirrorDividend | FK WITH CHECK | MirrorDividendID (copy dividend linkage) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.GetMirrorOperationDetails | SP | UNION query: History.Mirror (success, Ordinal=1) + History.MirrorFail (failure, Ordinal=2) |
| CopiersAPI | Service | Reads mirror operation history via History.GetMirrorOperationDetails |
| DailyEquity Component | Service | Reads mirror history for daily equity calculations (Confluence 13952778349) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryMirror | CLUSTERED | ID ASC | - | - | Active (PAGE compression, PRIMARY) |
| INX_CID_MOPID_ID | NONCLUSTERED | CID ASC, MirrorOperationID ASC, ID ASC | MirrorID, ParentCID, ParentUserName, Occurred, ModificationDate, InitialInvestment, DepositSummary, WithdrawalSummary, NetProfit | - | Active (FILLFACTOR=95, PRIMARY) |
| IX_HistoryMirror_CID | NONCLUSTERED | CID ASC | - | - | Active (PAGE compression, PRIMARY) |
| IX_HistoryMirror_MirrorID | NONCLUSTERED | MirrorID ASC, MirrorOperationID ASC | Amount, ParentCID, CID, Occurred | - | Active (FILLFACTOR=95, PAGE compression, PRIMARY) |
| IX_HistoryMirror_MirrorID_Filtered | NONCLUSTERED | MirrorID ASC | CID, IsActive | MirrorOperationID=2 (UnRegister only) | Active (PAGE compression, PRIMARY) |
| IX_HistoryMirror_Occurred | NONCLUSTERED | Occurred ASC | - | - | Active (PRIMARY) |
| IX_HistoryMirror_ParentCIDCID | NONCLUSTERED | ParentCID ASC | - | - | Active (PRIMARY) |

The INX_CID_MOPID_ID covering index (CID + MirrorOperationID + ID, includes financial summary columns) enables highly efficient queries like "all registrations/unregistrations by a copier with their financial summary" without touching the base table.

### 7.2 Constraints

| Name | Type | Definition |
|------|------|------------|
| PK_HistoryMirror | PRIMARY KEY | ID ASC - clustered |
| FK_HistoryMirror_DictionaryMirrorOperation | FOREIGN KEY | MirrorOperationID -> Dictionary.MirrorOperation(ID) WITH CHECK |
| FK_HistoryMirror_MIMOOperationTypeIID | FOREIGN KEY | MIMOOperationTypeID -> Dictionary.MirrorMIMOOperation(MirrorMIMOOperationID) WITH CHECK |
| FK_HistoryMirror_MirrorDividendID | FOREIGN KEY | MirrorDividendID -> History.MirrorDividend(ID) WITH CHECK |
| DF_HistoryMirror_ModificationDate | DEFAULT | ModificationDate = getutcdate() |
| DF_HistoryMirrorMirrorTypeID | DEFAULT | MirrorTypeID = 1 |
| (unnamed) | DEFAULT | MirrorSL = 0 |
| DF_HistoryMirror_UseCopyDividend | DEFAULT | UseCopyDividend = 1 |
| DF_HistoryMirror_MIMOOperationTypeIID | DEFAULT | MIMOOperationTypeID = 0 |

---

## 8. Sample Queries

### 8.1 Full operation lifecycle for a specific mirror

```sql
SELECT
    h.ID,
    h.MirrorOperationID,
    mo.MirrorOperation AS OperationName,
    h.IsActive,
    h.Amount,
    h.RealizedEquity,
    h.CloseMirrorActionType,
    h.PauseCopy,
    h.Occurred
FROM History.Mirror h WITH (NOLOCK)
    JOIN Dictionary.MirrorOperation mo ON h.MirrorOperationID = mo.ID
WHERE h.MirrorID = @MirrorID
ORDER BY h.ID;
```

### 8.2 All mirrors registered/unregistered by a copier (with financial summary)

```sql
-- Uses INX_CID_MOPID_ID covering index
SELECT
    h.MirrorID,
    h.ParentCID,
    h.ParentUserName,
    h.InitialInvestment,
    h.DepositSummary,
    h.WithdrawalSummary,
    h.NetProfit,
    h.Occurred AS RegisterDate
FROM History.Mirror h WITH (NOLOCK)
WHERE h.CID = @CID AND h.MirrorOperationID = 1  -- Register only
ORDER BY h.Occurred DESC;
```

### 8.3 Check if a mirror has been unregistered (filtered index)

```sql
-- Uses IX_HistoryMirror_MirrorID_Filtered (MirrorOperationID=2 only)
SELECT h.MirrorID, h.CID, h.IsActive
FROM History.Mirror h WITH (NOLOCK)
WHERE h.MirrorID = @MirrorID AND h.MirrorOperationID = 2;
-- Returns row = mirror was deregistered; no row = still active or never registered
```

### 8.4 All copiers who ever copied a popular investor (ParentCID index)

```sql
SELECT DISTINCT h.CID, h.MirrorID, MIN(h.Occurred) AS FirstCopyDate
FROM History.Mirror h WITH (NOLOCK)
WHERE h.ParentCID = @ParentCID AND h.MirrorOperationID = 1
GROUP BY h.CID, h.MirrorID
ORDER BY FirstCopyDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | ID | Title | Relevance |
|--------|----|-------|-----------|
| Confluence | 12857836033 | Moe - Mirror Operation Engine | MOE architecture, HistoryMirrorRepository, 9 processors, error handling, deployment (6 pods). Primary source for understanding who writes to this table. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.4/10 (Elements: 9.3/10, Logic: 9.5/10, Relationships: 9.3/10, Sources: 9.3/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 31 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED (ExternalOperationType) | Phases: 7/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 6 analyzed (Trade.RegisterMirror, Trade.MirrorPauseCopy, Trade.SetMirrorAlignmentStatus, Trade.PostDetachPositionFromMirror, Trade.MirrorReopen, Trade.ChangeMirrorCalculationType) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Mirror | Type: Table | Source: etoro/etoro/History/Tables/History.Mirror.sql*

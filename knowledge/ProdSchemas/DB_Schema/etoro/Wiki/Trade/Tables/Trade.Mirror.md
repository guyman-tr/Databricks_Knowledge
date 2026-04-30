# Trade.Mirror

> Copy-trading mirror/follow relationship table that links copiers (CID) to leaders (ParentCID) with allocation amount, stop-loss, and copy-state settings.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | MirrorID (INT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 8 total (4 active, 4 disabled) |

---

## 1. Business Meaning

Trade.Mirror is the core table for eToro's CopyTrader feature. Each row represents a follow relationship: a copier (CID) allocates an amount to copy trades from a leader (ParentCID). The table stores the allocation amount, realized equity, mirror stop-loss (MSL) settings, pause state, and whether the mirror is active or closed. When a user starts copying a leader, `Trade.RegisterMirror` inserts a row; when they stop or the mirror hits stop-loss, `Trade.ChangeMirrorState` or `Trade.PostClosePositionActions` updates IsActive or closes the mirror.

This table exists because CopyTrader is eToro's flagship social trading feature. Without it, the system could not track which users follow which leaders, how much each allocates, or enforce mirror stop-losses. Trade.Position stores MirrorID to link positions to mirrors; fee processes, equity calculations, and portfolio aggregates all JOIN here.

Data flows: rows are created via `Trade.RegisterMirror`, modified via `Trade.ChangeMirrorState`, `Trade.ChangeMirrorAmountForMoe`, `Trade.PostClosePositionActions`, `Trade.MirrorReopen`, and `Trade.UnRegisterMirrorForMoe` (DELETE). The INSTEAD OF DELETE trigger prevents deletion if open positions exist. Key readers: `Trade.GetMirrorsByCID`, `Trade.GetTreeNodesByParentCID_Inner`, `Trade.PositionClose`, `Trade.GetOrderForOpenContextData`, `Trade.GetOrderForCloseContextData`.

---

## 2. Business Logic

### 2.1 Mirror Status and Copy State

**What**: MirrorStatusID and IsActive/PauseCopy control whether the copier is actively copying and whether copy is paused.

**Columns/Parameters Involved**: `MirrorStatusID`, `IsActive`, `PauseCopy`

**Rules**:
- MirrorStatusID: 0=Active, 1=Pause, 2=PendingClose, 3=InAlignment (Dictionary.MirrorStatus)
- IsActive: 1=mirror is live (copier follows leader), 0=mirror closed
- PauseCopy: 0=copying, 1=paused (no new positions opened)
- Trade.GetTreeNodesByParentCID_Inner filters WHERE IsActive=1 AND PauseCopy=0 for active copiers

**Diagram**:
```
MirrorStatusID=0 + IsActive=1 + PauseCopy=0 -> Fully active copy
MirrorStatusID=1 + PauseCopy=1 -> Paused
IsActive=0 -> Mirror closed (detached or stopped)
```

### 2.2 Mirror Stop-Loss (MSL)

**What**: MirrorSL and MirrorSLPercentage define the equity-based stop-loss for the copy relationship.

**Columns/Parameters Involved**: `MirrorSL`, `MirrorSLPercentage`, `RealizedEquity`

**Rules**:
- MirrorSL is the absolute equity threshold (in dollars). MirrorSLPercentage is the percentage (default 2).
- MirrorCalculationType: 0=RealizedEquity, 1=UnrealizedEquity (Dictionary.MirrorCalculationType)
- Trade.RegisterMirror validates @MirrorSL against @MirrorSLPercentage
- When equity falls below threshold, mirror is closed (CloseMirrorActionType set)

### 2.3 Close Mirror Action

**What**: CloseMirrorActionType records why the mirror was closed.

**Columns/Parameters Involved**: `CloseMirrorActionType`

**Rules**:
- 0=Customer, 1=Stop Loss, 2=BSL, 3=Manual Liquidation, 4=BackOffice, 5=Customer Detach, 6=BackOffice Detach (Dictionary.CloseMirrorActionType)
- NULL when mirror is still active

---

## 3. Data Overview

| MirrorID | CID | ParentCID | ParentUserName | Amount | IsActive | PauseCopy | MirrorStatusID | MirrorCalculationType | Meaning |
|----------|-----|-----------|----------------|--------|----------|-----------|----------------|----------------------|---------|
| 372 | 1488218 | 460974 | Dashing4xPro | 5.60 | 1 | 0 | 0 | 0 | Copier 1488218 follows leader Dashing4xPro with $5.60 allocation. Active, not paused. MSL based on RealizedEquity. |
| 373 | 1488218 | 818634 | jawaher2 | 58.08 | 1 | 0 | 0 | 0 | Same copier follows second leader with $58.08. Multiple mirrors per copier allowed. |
| 1966 | 457126 | 142704 | santoshtiwari | 503.08 | 1 | 0 | 0 | 0 | Larger allocation ($503). RealizedEquity (644.47) exceeds Amount due to accumulated profit. |
| 3587 | 1586819 | 665310 | agnespolonia | 670.05 | 1 | 0 | 0 | 0 | High-value mirror ($670). Typical VIP or professional copier. |
| 1848 | 195448 | 1369868 | sadiqashanaz97 | 7.66 | 1 | 0 | 0 | 0 | Smaller allocation. RealizedEquity (9.67) slightly above Amount. |

**Selection criteria**: Picked from live TOP 10 - mix of small/medium/large allocations, single copier with multiple leaders, variety of ParentUserName.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorID | int | NO | IDENTITY | CODE-BACKED | Primary key. Allocated by identity on INSERT via Trade.RegisterMirror. Referenced by Trade.Position.MirrorID, History.Mirror. |
| 2 | CID | int | NO | - | CODE-BACKED | Copier customer ID. The user who allocates money to follow the leader. Trade.ValidateNumOfActiveMirrors counts mirrors per CID. |
| 3 | ParentCID | int | NO | - | CODE-BACKED | Leader customer ID. The user whose trades are copied. Trade.GetActiveCopiersForParents filters by ParentCID. |
| 4 | ParentUserName | varchar(50) | NO | - | CODE-BACKED | Leader username at mirror creation. Denormalized for display; Trade.RegisterMirror passes from caller. |
| 5 | Amount | dbo.dtPrice | NO | - | CODE-BACKED | Allocation amount in dollars. Credit allocated to this mirror. Trade.RegisterMirror sets from @AmountInCents/100. |
| 6 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | When the mirror was created. Default getutcdate(). Used for ordering and time-series. |
| 7 | IsActive | tinyint | NO | 1 | CODE-BACKED | 1=mirror is live (copier follows leader), 0=mirror closed. Trade.ChangeMirrorState, Trade.PostClosePositionActions update. |
| 8 | MirrorTypeID | int | NO | 1 | CODE-BACKED | 1=Regular, 2=CopyMe, 3=Social Index, 4=Fund (Dictionary.MirrorType). Determines mirror behavior. |
| 9 | IsOpenOpen | bit | YES | - | CODE-BACKED | Flag for open-on-open copy behavior. NULL in sample data. Used by copy logic. |
| 10 | GuruTPV | money | YES | - | CODE-BACKED | Guru/leader take-profit value. NULL in sample. Optional override. |
| 11 | MirrorSL | money | NO | 0 | CODE-BACKED | Absolute mirror stop-loss threshold in dollars. Trade.RegisterMirror validates against MirrorSLPercentage. |
| 12 | CloseMirrorActionType | int | YES | - | CODE-BACKED | Why mirror closed: 0=Customer, 1=Stop Loss, 2=BSL, 3=Manual Liquidation, 4=BackOffice, 5=Customer Detach, 6=BackOffice Detach (Dictionary.CloseMirrorActionType). NULL when active. |
| 13 | RealizedEquity | money | NO | - | CODE-BACKED | Realized equity for this mirror. Used with MirrorCalculationType=0 for MSL. Updated on position close. |
| 14 | PauseCopy | bit | NO | 0 | CODE-BACKED | 0=copying, 1=paused. No new positions when paused. Trade.MirrorPauseCopy updates. |
| 15 | MirrorSLPercentage | money | NO | 2 | CODE-BACKED | MSL as percentage. Default 2. Trade.RegisterMirror validates MirrorSL = Amount * (MirrorSLPercentage/100). |
| 16 | InitialInvestment | money | NO | 0 | CODE-BACKED | Initial allocation. Trade.RegisterMirror sets from @AmountInDollars or @InitialInvestment. |
| 17 | DepositSummary | money | NO | 0 | CODE-BACKED | Sum of deposits into mirror. Trade.RegisterMirror accepts from caller. |
| 18 | WithdrawalSummary | money | NO | 0 | CODE-BACKED | Sum of withdrawals from mirror. |
| 19 | NetProfit | money | YES | 0 | CODE-BACKED | Net profit for mirror. Trade.RegisterMirror accepts from caller. |
| 20 | UseCopyDividend | tinyint | NO | 1 | CODE-BACKED | 1=copy dividends to copier, 0=do not. Trade.MirrorDividendWithdrawal checks. |
| 21 | ReopenForMirrorID | int | YES | - | CODE-BACKED | When mirror reopened, points to closed MirrorID. Trade.MirrorReopen sets. Prevents duplicate reopens. |
| 22 | MirrorCalculationType | int | NO | 0 | CODE-BACKED | 0=RealizedEquity, 1=UnrealizedEquity (Dictionary.MirrorCalculationType). Which equity drives MSL. |
| 23 | MirrorStatusID | int | NO | 0 | CODE-BACKED | 0=Active, 1=Pause, 2=PendingClose, 3=InAlignment (Dictionary.MirrorStatus). IX_MirrorStatusID supports lookups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | Copier customer |
| ParentCID | Customer.Customer | Implicit | Leader customer |
| MirrorTypeID | Dictionary.MirrorType | Lookup | Regular, CopyMe, Social Index, Fund |
| MirrorStatusID | Dictionary.MirrorStatus | Lookup | Active, Pause, PendingClose, InAlignment |
| CloseMirrorActionType | Dictionary.CloseMirrorActionType | Lookup | Why mirror closed |
| MirrorCalculationType | Dictionary.MirrorCalculationType | Lookup | RealizedEquity vs UnrealizedEquity |
| ReopenForMirrorID | Trade.Mirror | Self-Reference | Points to closed mirror when reopened |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.Position | MirrorID | FK | Positions link to mirror for copy-trade attribution |
| History.Mirror | MirrorID | History | Trigger-maintained history |
| Trade.RegisterMirror | INSERT | Writer | Creates mirrors |
| Trade.ChangeMirrorState | UPDATE | Modifier | Updates IsActive, MirrorStatusID, etc. |
| Trade.ChangeMirrorAmountForMoe | UPDATE | Modifier | Updates Amount |
| Trade.PostClosePositionActions | UPDATE | Modifier | Updates RealizedEquity, IsActive on close |
| Trade.MirrorReopen | UPDATE | Modifier | Sets ReopenForMirrorID |
| Trade.UnRegisterMirrorForMoe | DELETE | Deleter | Removes mirror (trigger blocks if open positions) |
| Trade.GetMirrorsByCID | - | Reader | Mirrors by copier |
| Trade.GetTreeNodesByParentCID_Inner | - | Reader | Active copiers by leader |
| Trade.GetOrderForOpenContextData | MirrorID | Reader | Mirror credit for order |
| Trade.PositionClose | MirrorID | Reader | Reads RealizedEquity, IsActive |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Mirror (table)
```

Tables have no code-level dependencies. Trade.Mirror is a leaf table.

### 6.1 Objects This Depends On

No explicit FK targets in CREATE TABLE. Implicit lookups: Dictionary.MirrorStatus, Dictionary.MirrorType, Dictionary.CloseMirrorActionType, Dictionary.MirrorCalculationType.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | Table | MirrorID FK |
| Trade.RegisterMirror | Procedure | INSERT |
| Trade.ChangeMirrorState | Procedure | UPDATE |
| Trade.ChangeMirrorAmountForMoe | Procedure | UPDATE |
| Trade.PostClosePositionActions | Procedure | UPDATE |
| Trade.MirrorReopen | Procedure | UPDATE |
| Trade.UnRegisterMirrorForMoe | Procedure | DELETE |
| Trade.GetMirrorsByCID | Procedure | SELECT |
| Trade.GetTreeNodesByParentCID_Inner | Procedure | SELECT |
| Trade.GetOrderForOpenContextData | Procedure | SELECT |
| Trade.PositionClose | Procedure | SELECT |
| Trade.GetPositionData, Trade.GetPositionsTree | View | LEFT JOIN |
| History.Mirror | Table | History via triggers |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeMirror | CLUSTERED | MirrorID | - | - | Active |
| IX_CIDMirrorID | NC | CID, MirrorID | ParentCID, Amount | - | Active |
| IX_CIDParentCID | NC | ParentCID, CID, Occurred, IsActive, PauseCopy | Amount, MirrorTypeID, RealizedEquity, MirrorCalculationType | - | Active |
| IX_MirrorStatusID | NC | MirrorStatusID | - | - | Active |
| IX_ParentCID_IsActive_PauseCopy_Occurred_Inc | NC | ParentCID, IsActive, PauseCopy, Occurred | CID, Amount, MirrorTypeID, RealizedEquity, MirrorCalculationType | - | DISABLED |
| IX_TradeMirrorCID | NC | CID | ParentCID, MirrorID, Amount | - | DISABLED |
| IX_TradeMirror_ParentCIDCID | NC UNIQUE | ParentCID, CID | Amount, MirrorID | - | DISABLED |
| IX_TradeMirror_ParentCIDCID_INC | NC | ParentCID, Occurred, CID | MirrorID, Amount, RealizedEquity, IsActive, PauseCopy | - | DISABLED |
| Mirror_Covering_UserPortfolio | NC | CID, MirrorID | ParentCID, ParentUserName, Amount, Occurred, IsActive, IsOpenOpen, MirrorSL, PauseCopy, MirrorSLPercentage, InitialInvestment, WithdrawalSummary, DepositSummary, NetProfit, MirrorCalculationType, MirrorStatusID | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_TradeMirror_Occurred | DEFAULT | Occurred = getutcdate() |
| DF_TradeMirror_IsActive | DEFAULT | IsActive = 1 |
| DF_TradeMirrorMirrorTypeID | DEFAULT | MirrorTypeID = 1 |
| DF_TradeMirror_MirrorSL | DEFAULT | MirrorSL = 0 |
| DF_TradeMirror_PauseCopy | DEFAULT | PauseCopy = 0 |
| DF_TradeMirror_MirrorSLPercentage | DEFAULT | MirrorSLPercentage = 2 |
| DF_TradeMirror_InitialInvestment | DEFAULT | InitialInvestment = 0 |
| DF_TradeMirror_DepositSummary | DEFAULT | DepositSummary = 0 |
| DF_TradeMirror_WithdrawalSummary | DEFAULT | WithdrawalSummary = 0 |
| DF_TradeMirror_NetProfit | DEFAULT | NetProfit = 0 |
| DF_TradeMirror_UseCopyDividend | DEFAULT | UseCopyDividend = 1 |
| DF_MirrorCalculationType | DEFAULT | MirrorCalculationType = 0 |
| (unnamed) | DEFAULT | MirrorStatusID = 0 |

---

## 8. Sample Queries

### 8.1 Get active mirrors for a copier with lookup labels
```sql
SELECT M.MirrorID, M.CID, M.ParentCID, M.ParentUserName, M.Amount, M.RealizedEquity,
       MS.Name AS MirrorStatus, MT.MirrorTypeName, M.PauseCopy
  FROM Trade.Mirror M WITH (NOLOCK)
  JOIN Dictionary.MirrorStatus MS WITH (NOLOCK) ON M.MirrorStatusID = MS.ID
  JOIN Dictionary.MirrorType MT WITH (NOLOCK) ON M.MirrorTypeID = MT.MirrorTypeID
 WHERE M.CID = 1488218 AND M.IsActive = 1
 ORDER BY M.Occurred DESC
```

### 8.2 Count active copiers per leader
```sql
SELECT M.ParentCID, M.ParentUserName, COUNT(*) AS ActiveCopierCount
  FROM Trade.Mirror M WITH (NOLOCK)
 WHERE M.IsActive = 1 AND M.PauseCopy = 0
 GROUP BY M.ParentCID, M.ParentUserName
 ORDER BY ActiveCopierCount DESC
```

### 8.3 Mirrors with close reason (closed mirrors only)
```sql
SELECT M.MirrorID, M.CID, M.ParentCID, M.Amount, M.RealizedEquity,
       CMAT.CloseMirrorActionName AS CloseReason
  FROM Trade.Mirror M WITH (NOLOCK)
  JOIN Dictionary.CloseMirrorActionType CMAT WITH (NOLOCK) ON M.CloseMirrorActionType = CMAT.ID
 WHERE M.IsActive = 0 AND M.CloseMirrorActionType IS NOT NULL
 ORDER BY M.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 50+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Mirror | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.Mirror.sql*

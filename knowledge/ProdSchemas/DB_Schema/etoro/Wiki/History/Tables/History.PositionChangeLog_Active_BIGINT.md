# History.PositionChangeLog_Active_BIGINT

> Partitioned audit log capturing every lifecycle change to open positions - opens, edits (stop loss, take profit, TSL), partial closes, mirror detachments, redeem operations, and close events - with before/after snapshots of all modified fields.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PositionChangeID (BIGINT IDENTITY, NONCLUSTERED PK on PositionChangeID + Occurred) |
| **Partition** | Yes - PositionChangeLog_PS_EndDay partition scheme on Occurred; CHECK (Occurred >= '2022-08-01') |
| **Indexes** | 5 (NONCLUSTERED PK, CLUSTERED on CID+Occurred, NC on ChangeTypeID+Occurred+MirrorID, NC on Occurred DESC, NC on PositionID DESC) |

---

## 1. Business Meaning

History.PositionChangeLog_Active_BIGINT is the primary position change audit log for the eToro trading platform. Every time an open position is modified - whether opened, stop loss edited, take profit changed, partially closed, detached from a mirror, or closed - a row is inserted here with the before and after values for every relevant field.

The "_BIGINT" suffix indicates this is the version that supports 64-bit PositionIDs (migrated Nov 2021; the IDENTITY starts at 4,460,306,840 to avoid collision with any legacy INT rows). The "_Active_" name refers to the partition management strategy: a rolling 6-month window of partitions is kept active (via dbo.HistoryPositionChangeLog_MaintainPartitions), with older data purged. The CHECK constraint `Occurred >= '2022-08-01'` marks the earliest partition currently enforced.

The single writer is History.PositionChangeLog_Insert, called by the trading engine for all position lifecycle events. 5.77 million rows span May 2023 through March 2026 in this environment.

The table uses the `dbo.dtPrice` UDT (`decimal(16,8)`) for all rate/price columns, providing uniform 8-decimal precision for stop loss, take profit, and conversion rates.

---

## 2. Business Logic

### 2.1 Position Change Type State Machine

**What**: ChangeTypeID identifies which type of position lifecycle event occurred.

**Columns/Parameters Involved**: `ChangeTypeID`, `PreviousAmount`, `AmountChanged`, `PreviousLimitRate`, `LimitRate`, `PreviousStopRate`, `StopRate`

**Rules** (from Dictionary.PCL_ChangeType):

| ChangeTypeID | Name | Count (env) | Key Fields Changed |
|-------------|------|------------|-------------------|
| 0 | Open Position | 2,467,641 | All fields - initial snapshot |
| 1 | Edit Stop Loss | 386,314 | PreviousStopRate/StopRate |
| 2 | Edit Take Profit | 13,991 | PreviousLimitRate/LimitRate |
| 3 | Edit Over Weekend | - | PreviousCloseOnEndOfWeek/CloseOnEndOfWeek |
| 4 | EOW Fee (End Of Week Fee) | - | PreviousEndOfWeekFee/EndOfWeekFee |
| 5 | Detach from Mirror | 8,643 | ParentPositionID set to NULL |
| 6 | Close Position | 2,436,715 | Final snapshot at close |
| 7 | Enable/Disable TSL | 344,857 | IsTslEnabled toggled |
| 8 | PositionRedeemCancel | 6,642 | RedeemStatus -> 0 |
| 9 | PositionRedeemPending | 19,034 | RedeemStatus -> pending state |
| 10 | PositionRedeemClose | - | RedeemStatus -> closed |
| 11 | Partial close | 45,347 | AmountInUnits/AmountChanged for partial |
| 12 | Edit due to partial close | 45,347 | Parent position amount adjusted |
| 13 | Edit Is Settled | - | PreviousIsSettled/IsSettled |
| 14 | Data Fix | - | Correction after data reconciliation |

### 2.2 Before/After Field Pattern

**What**: For each event type, specific Previous*/New* field pairs capture the state change.

**Columns/Parameters Involved**: `PreviousCloseOnEndOfWeek`, `CloseOnEndOfWeek`, `PreviousEndOfWeekFee`, `EndOfWeekFee`, `PreviousAmount`, `AmountChanged`, `PreviousLimitRate`, `LimitRate`, `PreviousStopRate`, `StopRate`, `PreviousIsSettled`, `IsSettled`, `PreviousAmountInUnits`, `AmountInUnits`, `PreviousLotCountDecimal`, `LotCountDecimal`, `PreviousSettlementTypeID`, `SettlementTypeID`, `PreviousIsNoStopLoss`, `IsNoStopLoss`, `PreviousIsNoTakeProfit`, `IsNoTakeProfit`

**Rules**:
- On Open Position (ChangeTypeID=0): Previous* fields reflect the initial state (often same as new), all fields populated.
- AmountChanged = the delta applied (0 for non-amount changes like stop loss edits).
- PreviousLimitRate/LimitRate: take profit rate pair. 0 = no take profit set.
- PreviousStopRate/StopRate: stop loss rate pair. 0.01 = minimum stop loss.
- UnAdjusted variants (PreviousLimitRateUnAdjusted, StopRateUnAdjusted etc.): the raw user-set rate before platform adjustments.

### 2.3 Partition Management (Rolling 6-Month Window)

**What**: Older partitions are automatically purged, keeping ~6 months of active data.

**Columns/Parameters Involved**: `Occurred`

**Rules**:
- dbo.HistoryPositionChangeLog_MaintainPartitions runs periodically, computing @DaysToKeep = DATEDIFF(DAY, DATEADD(MONTH,-6,GETDATE()), GETDATE()).
- Partition scheme: PositionChangeLog_PS_EndDay (daily boundaries on Occurred).
- Old partitions beyond the 6-month window are truncated/dropped.
- CHECK constraint (Occurred >= '2022-08-01') is the historical minimum; the actual enforced minimum moves forward as partitions are purged.
- 30 future partition boundaries are pre-created (@in_num_needed = 30).

### 2.4 RedeemStatus

**What**: Tracks the redemption state for positions undergoing the redeem (stock ownership delivery) workflow.

**Columns/Parameters Involved**: `RedeemStatus`, `ChangeTypeID` (8, 9, 10)

**Rules**:
- Default = 0 (not in redeem workflow).
- ChangeTypeID=9: PositionRedeemPending - redeem request initiated.
- ChangeTypeID=8: PositionRedeemCancel - redeem cancelled.
- ChangeTypeID=10: PositionRedeemClose - redeem completed.
- FK to Dictionary implied but not enforced.

---

## 3. Data Overview

| PositionID | ChangeTypeID | PreviousAmount | AmountChanged | PreviousStopRate | StopRate | CID | Occurred |
|------------|-------------|----------------|--------------|-----------------|----------|-----|----------|
| 2152976742 | 0 (Open) | 35.33 | 0 | 0.01 | 0.01 | 25132377 | 2026-03-21 |
| 2152976741 | 0 (Open) | 99.97 | 0 | 0.01 | 0.01 | 14952810 | 2026-03-21 |
| 2152976740 | 6 (Close) | 99.97 | 0 | 0.01 | 0.01 | 14952810 | 2026-03-21 |

5,774,531 rows | Oldest: 2023-05-09 | Newest: 2026-03-21 (live; updated continuously)
IDENTITY seed: 4,460,306,840 (migrated from prior INT table)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionChangeID | bigint IDENTITY(4460306840,1) | NO | - | CODE-BACKED | Surrogate PK. IDENTITY seed starts at ~4.46B to avoid collision with rows migrated from the prior INT version of this table. NONCLUSTERED PK on (PositionChangeID, Occurred) - Occurred included because table is partitioned. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | The open position this change relates to. NC index for fast position-centric queries. BIGINT since Nov 2021. Not an FK constraint - references Trade.Position (open) or History.Position (after close). |
| 3 | PreviousCloseOnEndOfWeek | bit | NO | - | CODE-BACKED | Whether the position was set to close at end-of-week before this change. Used for ChangeTypeID=3 (Edit Over Weekend). |
| 4 | CloseOnEndOfWeek | bit | NO | - | CODE-BACKED | Whether the position is set to close at end-of-week after this change. |
| 5 | PreviousEndOfWeekFee | money | NO | - | CODE-BACKED | End-of-week fee before this change (in USD). Updated on ChangeTypeID=4 (EOW Fee). |
| 6 | EndOfWeekFee | money | NO | - | CODE-BACKED | End-of-week fee after this change. |
| 7 | PreviousAmount | money | NO | - | CODE-BACKED | Position investment amount (USD) before this change. On open, this is the initial investment. |
| 8 | AmountChanged | money | NO | - | CODE-BACKED | Delta applied to amount. 0 for non-amount changes (stop loss edits, etc.). |
| 9 | PreviousLimitRate | dbo.dtPrice | NO | - | CODE-BACKED | Take profit rate before this change. 0 = no take profit. dbo.dtPrice = decimal(16,8). |
| 10 | LimitRate | dbo.dtPrice | NO | - | CODE-BACKED | Take profit rate after this change. Updated on ChangeTypeID=2 (Edit Take Profit). |
| 11 | PreviousStopRate | dbo.dtPrice | NO | - | CODE-BACKED | Stop loss rate before this change. 0.01 = minimum platform SL. |
| 12 | StopRate | dbo.dtPrice | NO | - | CODE-BACKED | Stop loss rate after this change. Updated on ChangeTypeID=1 (Edit Stop Loss). |
| 13 | Occurred | datetime | NO | - | CODE-BACKED | Server UTC datetime when the change occurred. Partition key for PositionChangeLog_PS_EndDay. Also part of the NONCLUSTERED PK. |
| 14 | ParentPositionID | bigint | YES | - | CODE-BACKED | Copy trade parent position ID. NULL when position is not in a copy trade or after detachment (ChangeTypeID=5). |
| 15 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent position ID before any detachment. Preserved for audit trail even after detachment. |
| 16 | LastOpPriceRate | dbo.dtPrice | YES | - | CODE-BACKED | Instrument price rate at the time of this operation. Snapshot of the market rate when the change was executed. |
| 17 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Reference to the price rate record ID for the rate used in this operation. |
| 18 | LastOpConversionRate | dbo.dtPrice | YES | - | CODE-BACKED | Currency conversion rate applied at operation time (for non-USD instruments). |
| 19 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Reference to the conversion rate record ID. |
| 20 | MirrorID | int | YES | - | CODE-BACKED | Copy portfolio (mirror) ID this position belongs to. NULL for non-mirror positions. NC index includes MirrorID for mirror-based queries. |
| 21 | ClientVersion | varchar(20) | YES | - | CODE-BACKED | Client app version string from which the change was initiated (e.g., platform version). |
| 22 | CID | int | YES | - | CODE-BACKED | Customer who owns this position. CLUSTERED INDEX key (CID ASC, Occurred ASC) for customer-centric time-range queries. |
| 23 | ChangeTypeID | tinyint | YES | - | CODE-BACKED | The type of change. FK to Dictionary.PCL_ChangeType. Values: 0=Open, 1=EditSL, 2=EditTP, 3=EditOverWeekend, 4=EOWFee, 5=DetachFromMirror, 6=Close, 7=Enable/DisableTSL, 8=RedeemCancel, 9=RedeemPending, 10=RedeemClose, 11=PartialClose, 12=EditDueToPartialClose, 13=EditIsSettled, 14=DataFix. NC index key. |
| 24 | NewAmount | dbo.dtPrice | YES | - | CODE-BACKED | New investment amount after this change. Complements PreviousAmount + AmountChanged. |
| 25 | PreviousLimitRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | User's original take profit rate before platform adjustments (e.g., spreads, overnight fee adjustments). |
| 26 | PreviousStopRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | User's original stop loss rate before platform adjustments. |
| 27 | StopRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Stop loss rate as set by user (unadjusted). |
| 28 | LimitRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Take profit rate as set by user (unadjusted). |
| 29 | AccountRealizedEquity | money | YES | - | CODE-BACKED | Customer account realized equity snapshot at time of this change. |
| 30 | MirrorRealizedEquity | money | YES | - | CODE-BACKED | Copy portfolio realized equity snapshot at time of this change. |
| 31 | TreeID | bigint | YES | - | CODE-BACKED | Current copy tree ID this position belongs to (the copy relationship chain). |
| 32 | PrevTreeID | bigint | YES | - | CODE-BACKED | Previous tree ID before this change (for detach/re-attach operations). |
| 33 | SessionID | bigint | YES | - | CODE-BACKED | Trading session ID in which this change occurred. NC index includes SessionID for session-based lookups. |
| 34 | IsTslEnabled | tinyint | YES | - | CODE-BACKED | Trailing stop loss enabled flag after this change. 1=enabled, 0=disabled. Updated on ChangeTypeID=7. |
| 35 | RedeemStatus | tinyint | NO | 0 | CODE-BACKED | Stock redemption status. 0=not in redeem workflow. Updated on ChangeTypeID 8/9/10 for redeem lifecycle. Default 0. |
| 36 | ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client-generated GUID for this change request. Used for idempotency and request correlation. |
| 37 | PreviousIsSettled | bit | YES | - | CODE-BACKED | Settlement flag before this change. For ChangeTypeID=13 (Edit Is Settled). |
| 38 | IsSettled | bit | YES | - | CODE-BACKED | Settlement flag after this change. Indicates if the position has been settled (stock delivery). |
| 39 | PreviousAmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Position size in instrument units before this change. Used for fractional shares trading. |
| 40 | AmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Position size in instrument units after this change. |
| 41 | UnitsBaseValueCents | int | YES | - | CODE-BACKED | Current base value of position in cents. |
| 42 | PreviouseUnitsBaseValueCents | int | YES | - | CODE-BACKED | Previous base value of position in cents. Note: "Previouse" is a typo in the column name. |
| 43 | ClientViewRateID | bigint | YES | - | CODE-BACKED | Rate ID as displayed to the client at time of change. May differ from execution rate due to display rounding. |
| 44 | ClientViewRate | decimal(16,6) | YES | - | CODE-BACKED | Rate as displayed to the client at change time. |
| 45 | ClientRateForCalcID | bigint | YES | - | CODE-BACKED | Rate ID used for P&L calculation from client perspective. |
| 46 | ClientRateForCalc | decimal(16,6) | YES | - | CODE-BACKED | Rate used for P&L calculation from client perspective. |
| 47 | ExecutedWithoutSettings | bit | YES | - | CODE-BACKED | Indicates this change was executed without user-provided settings (system-generated). |
| 48 | PreviousSettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement type before this change. FK to Dictionary.SettlementType (implied). |
| 49 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement type after this change. Determines how the position is settled (cash vs. stock delivery). |
| 50 | PreviousPnLVersion | tinyint | YES | - | CODE-BACKED | P&L calculation version before this change (platform versioning for calculation methodology). |
| 51 | PnLVersion | tinyint | YES | - | CODE-BACKED | P&L calculation version after this change. |
| 52 | PreviousLotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count before this change. Used for fractional lot sizing. |
| 53 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count after this change. |
| 54 | IsNoStopLoss | bit | YES | - | CODE-BACKED | After change: whether the position has no stop loss (uses platform safety net). |
| 55 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | After change: whether the position has no take profit. |
| 56 | PreviousIsNoStopLoss | bit | YES | - | CODE-BACKED | Before change: no stop loss flag. |
| 57 | PreviousIsNoTakeProfit | bit | YES | - | CODE-BACKED | Before change: no take profit flag. |
| 58 | SnapshotTimestamp | datetime | YES | - | CODE-BACKED | Timestamp of the position state snapshot that triggered this change log entry. May differ from Occurred for delayed/async processing. |
| 59 | PriceType | int | YES | - | CODE-BACKED | Price type used for this operation (e.g., bid/ask/mid). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ChangeTypeID | Dictionary.PCL_ChangeType | Implicit | Position change type lookup. |
| PositionID | Trade.Position (open) / History.Position (closed) | Implicit | The position being changed. |
| CID | Customer.Customer | Implicit | The customer who owns the position. |
| MirrorID | Trade.Mirror | Implicit | Copy portfolio the position belongs to. |
| RedeemStatus | Dictionary.RedeemStatus (implied) | Implicit | Redemption state lookup. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.PositionChangeLog_Insert | Direct INSERT | WRITER | Single entry point for all position change log writes. |
| History.PositionChangeLog_Active (View) | PositionChangeID | READER | View over this table for simplified access. |
| Monitor.CheckClosePositionPrice | PositionID+ChangeTypeID | READER | Monitors for anomalous position close prices. |
| Trade.PositionAdjustment | PositionID | READER | Reads historical changes during adjustments. |

---

## 6. Dependencies

### 6.0 Dependency Chain

`Dictionary.PCL_ChangeType` <- ChangeTypeID (implicit FK, no enforcement)

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PCL_ChangeType | Table | Implicit FK for ChangeTypeID values |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.PositionChangeLog_Insert | Stored Procedure | WRITER - single writer for all events |
| dbo.HistoryPositionChangeLog_MaintainPartitions | Stored Procedure | MAINTENANCE - manages partition lifecycle (6-month rolling window) |
| History.PositionChangeLog_Active | View | READER - view over this table |
| Monitor.CheckClosePositionPrice | Stored Procedure | READER - anomaly detection |
| Monitor.CheckClosePositionPricePerHour | Stored Procedure | READER - hourly price check |
| Trade.PositionAdjustment | Stored Procedure | READER |
| History.PostPositionOpen | Stored Procedure | WRITER (via PositionChangeLog_Insert) |
| History.PostDetachMirrorPosition | Stored Procedure | WRITER (via PositionChangeLog_Insert) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HPCL_BIGINT1 | NONCLUSTERED PK | PositionChangeID ASC, Occurred ASC | - | Partitioned on Occurred | Active |
| CLU_IDX_HPCL_BIGINT_New | CLUSTERED | CID ASC, Occurred ASC | - | Partitioned on Occurred | Active |
| IDX_...ChangeTypeID_New | NONCLUSTERED | ChangeTypeID ASC, Occurred ASC, MirrorID ASC | PositionID, CID, SessionID | Partitioned on Occurred | Active |
| IDX_...Occurred_New | NONCLUSTERED | Occurred DESC | - | Partitioned on Occurred | Active |
| IDX_...PositionID_New | NONCLUSTERED | PositionID DESC | - | Partitioned on Occurred | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HPCL_BIGINT1 | PRIMARY KEY | Unique per change record |
| DF_...RedeemStatus1 | DEFAULT | RedeemStatus = 0 on INSERT |
| chk_HPCL_Active_BIGINT_Occurred1 | CHECK | Occurred >= '2022-08-01' (partition boundary enforcement) |

### 7.3 Storage

| Property | Value |
|----------|-------|
| Filegroup/Partition | PositionChangeLog_PS_EndDay (on Occurred) |
| Data Compression | PAGE (table and all indexes) |
| IDENTITY seed | 4,460,306,840 (migrated from prior INT version) |
| Fillfactor | 80% (clustered/most NCs), 100% (Occurred DESC NC), 90% (PK) |

---

## 8. Sample Queries

### 8.1 Get all changes for a specific position

```sql
SELECT PositionChangeID, ChangeTypeID, PreviousStopRate, StopRate,
       PreviousLimitRate, LimitRate, AmountChanged, Occurred
FROM History.PositionChangeLog_Active_BIGINT WITH (NOLOCK)
WHERE PositionID = 2152976742
ORDER BY Occurred;
```

### 8.2 Get a customer's position changes in the last 30 days

```sql
SELECT PositionID, ChangeTypeID, PreviousAmount, AmountChanged,
       PreviousStopRate, StopRate, Occurred
FROM History.PositionChangeLog_Active_BIGINT WITH (NOLOCK)
WHERE CID = 25132377
  AND Occurred >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY Occurred DESC;
```

### 8.3 Count changes by type in the last 7 days

```sql
SELECT ct.ChangeTypeName, COUNT(*) AS ChangeCount
FROM History.PositionChangeLog_Active_BIGINT pcl WITH (NOLOCK)
JOIN Dictionary.PCL_ChangeType ct WITH (NOLOCK) ON ct.ChangeTypeID = pcl.ChangeTypeID
WHERE pcl.Occurred >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY ct.ChangeTypeName
ORDER BY ChangeCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 59 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionChangeLog_Active_BIGINT | Type: Table | Source: etoro/etoro/History/Tables/History.PositionChangeLog_Active_BIGINT.sql*

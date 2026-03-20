# DWH_dbo.Dim_RedeemStatus

> Lookup table defining the 13 lifecycle states of a copy-trading fund redemption (stop-copy with positions-close and funds return), including cancellability flag at each stage.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.RedeemStatus |
| **Refresh** | Daily via SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (RedeemStatusID ASC) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_RedeemStatus tracks the lifecycle of a "redeem" operation - the process of stopping a copy-trading relationship and returning funds to the copier. When a user stops copying another trader, all mirrored positions must be closed, PnL calculated, and remaining equity returned to the copier's available balance. (Tier 1 - upstream wiki, Dictionary.RedeemStatus)

The DWH version has significantly more granular states (13 rows, IDs 0-100) compared to what was documented in the upstream wiki (5 rows, IDs 1-3,5,6). The production Dictionary.RedeemStatus table appears to have evolved substantially since the upstream wiki was written. The DWH reflects the current production state with states covering the full position-closing and transaction processing sub-workflow (PositionPending -> Approved -> ReadyToRedeem -> PositionClosing -> PositionClosed -> TransactionInProcess -> TransactionDone).

Loaded daily by SP_Dictionaries_DL_To_Synapse via TRUNCATE+INSERT from DWH_staging.etoro_Dictionary_RedeemStatus. ID=0 (N/A) is a synthetic ETL sentinel inserted with midnight timestamp (@ddate = CAST(GETDATE() AS DATE)). All other rows use GETDATE() timestamps.

---

## 2. Business Logic

### 2.1 Redeem Lifecycle State Machine

**What**: The copy-fund redemption flows through progressive processing stages with a clear point-of-no-return.

**Columns Involved**: `RedeemStatusID`, `Name`, `IsCancelable`

**Rules**:
- IsCancelable=1 (True): User can still abort the redemption (pre-closure states)
- IsCancelable=0 (False): Point of no return - positions are closing or closed
- Final success states: TransactionDone (8), Terminated (20)
- Error/special states: FailedToCancel (21), TransferNegativeBalance (25)

**Diagram**:
```
New (100, cancelable)
  -> PositionPending (1, cancelable)
  -> Approved (3, cancelable)
  -> ReadyToRedeem (4, cancelable)
  -> PositionClosing (5, cancelable)
  -> PositionClosed (6, NOT cancelable) <- point of no return
  -> TransactionInProcess (7, NOT cancelable)
  -> TransactionDone (8, NOT cancelable) <- success terminal

Special states:
  Rejected (2, cancelable)         <- pre-processing rejection
  Terminated (20, NOT cancelable)  <- terminated terminal
  FailedToCancel (21, cancelable)  <- cancel attempt failed
  TransferNegativeBalance (25, cancelable)

Sentinel: N/A (0, cancelable) <- ETL placeholder
```

### 2.2 IsCancelable Boundary

**What**: The cancellability flag marks the point at which the user loses control.

**Columns Involved**: `IsCancelable`

**Rules**:
- All statuses BEFORE PositionClosed (ID=6): IsCancelable=True
- PositionClosed (6), TransactionInProcess (7), TransactionDone (8), Terminated (20): IsCancelable=False
- Exception: FailedToCancel (21) - cancel failed but flag remains True (system retry possible)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with CLUSTERED INDEX on RedeemStatusID. With 13 rows, REPLICATE is optimal. Join on RedeemStatusID directly.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus` is Parquet. Read the entire table for any lookup.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve RedeemStatusID in Fact_BillingRedeem | `LEFT JOIN DWH_dbo.Dim_RedeemStatus rs ON ISNULL(fbr.RedeemStatusID, 0) = rs.RedeemStatusID` |
| In-progress (not yet final) redeems | `WHERE IsCancelable = 1 AND RedeemStatusID NOT IN (0, 2, 21, 25)` |
| Completed redeems | `WHERE RedeemStatusID IN (8, 20)` |
| Failed/problematic redeems | `WHERE RedeemStatusID IN (2, 21, 25)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_BillingRedeem | ON fbr.RedeemStatusID = rs.RedeemStatusID | Resolve redeem lifecycle state names |

### 3.4 Gotchas

- **Production schema evolution**: The upstream wiki documented 5 states; DWH now has 13. The IDs in production have different names than documented (e.g., ID=2 was "InProcess" in old docs, now "Rejected"). The DWH reflects current production data.
- **ID gaps**: IDs 9-19, 22-24, 26-99 are absent - reserved for future states.
- **ID=100 (New)**: Highest ID is 100 despite otherwise sequential IDs. May be a special "initial submission" state.
- **ID=0 is @ddate sentinel**: InsertDate = midnight (00:00:00), distinguishing it from SP-inserted rows (02:12 timestamp).
- **DWH adds InsertDate**: Production Dictionary.RedeemStatus does not have InsertDate. DWH adds it via GETDATE() in ETL.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 - Upstream wiki verbatim | `(Tier 1 - upstream wiki, Dictionary.RedeemStatus)` |
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3 - Live data | `(Tier 3 - live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RedeemStatusID | int | NO | Primary key identifying the redeem lifecycle state. Range: 0 (sentinel), 1-8, 20-21, 25, 100. See full state machine in Section 2. (Tier 1 - upstream wiki, Dictionary.RedeemStatus) |
| 2 | Name | varchar(50) | NO | Internal state code name used in procedures. Values: N/A(0), PositionPending(1), Rejected(2), Approved(3), ReadyToRedeem(4), PositionClosing(5), PositionClosed(6), TransactionInProcess(7), TransactionDone(8), Terminated(20), FailedToCancel(21), TransferNegativeBalance(25), New(100). DWH note: production has evolved significantly since upstream wiki documented 5 states. (Tier 1 concept, Tier 3 values - live data) |
| 3 | DisplayName | varchar(50) | NO | User-facing label. Currently matches Name for most rows. Shown in copy-trading UI and notifications. (Tier 1 - upstream wiki, Dictionary.RedeemStatus) |
| 4 | IsCancelable | bit | NO | Whether user can cancel the redeem at this stage. True=cancelable, False=positions are closing or closed (point of no return). False: PositionClosed(6), TransactionInProcess(7), TransactionDone(8), Terminated(20). (Tier 1 - upstream wiki, Dictionary.RedeemStatus) |
| 5 | InsertDate | datetime | YES | ETL insertion timestamp. ID=0 sentinel: midnight (CAST(GETDATE() AS DATE)). All other rows: SP execution time. DWH note: not present in production Dictionary.RedeemStatus - added by ETL. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | UpdateDate | datetime | YES | ETL reload timestamp - set to GETDATE() on each daily reload. Not a business date. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RedeemStatusID | etoro.Dictionary.RedeemStatus | RedeemStatusID | passthrough |
| Name | etoro.Dictionary.RedeemStatus | Name | passthrough |
| DisplayName | etoro.Dictionary.RedeemStatus | DisplayName | passthrough |
| IsCancelable | etoro.Dictionary.RedeemStatus | IsCancelable | passthrough |
| InsertDate | - | - | ETL-computed: GETDATE() (or @ddate for ID=0) |
| UpdateDate | - | - | ETL-computed: GETDATE() |

Full production documentation: see upstream wiki Dictionary/Tables/Dictionary.RedeemStatus.md (note: outdated - documents 5 states; DWH has 13 current states)

### 5.2 ETL Pipeline

```
etoro.Dictionary.RedeemStatus -> Generic Pipeline -> DWH_staging.etoro_Dictionary_RedeemStatus -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_RedeemStatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.RedeemStatus | 13 current rows (evolved significantly from 5 in 2026-03-13 upstream wiki) |
| Staging | DWH_staging.etoro_Dictionary_RedeemStatus | Raw import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Adds InsertDate and UpdateDate (not in production). |
| Sentinel | Additional INSERT | ID=0 N/A row inserted with @ddate midnight timestamp |
| Target | DWH_dbo.Dim_RedeemStatus | 13 rows |
| Export | Generic Pipeline (daily) | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - no foreign key columns.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_BillingRedeem | RedeemStatusID | Billing redeem transactions reference lifecycle status |

---

## 7. Sample Queries

### 7.1 List all statuses with cancellability
```sql
SELECT
    RedeemStatusID,
    Name,
    DisplayName,
    CASE IsCancelable WHEN 1 THEN 'Yes' ELSE 'No' END AS CanCancel
FROM [DWH_dbo].[Dim_RedeemStatus]
WHERE RedeemStatusID <> 0
ORDER BY RedeemStatusID
```

### 7.2 Count redeems by status
```sql
SELECT
    rs.DisplayName AS Status,
    COUNT(*) AS redeem_count
FROM [DWH_dbo].[Fact_BillingRedeem] fbr
LEFT JOIN [DWH_dbo].[Dim_RedeemStatus] rs
    ON ISNULL(fbr.RedeemStatusID, 0) = rs.RedeemStatusID
GROUP BY rs.DisplayName
ORDER BY redeem_count DESC
```

### 7.3 Completed vs in-progress redeems
```sql
SELECT
    CASE
        WHEN RedeemStatusID IN (8, 20) THEN 'Completed'
        WHEN RedeemStatusID IN (2, 21, 25) THEN 'Failed/Problematic'
        WHEN IsCancelable = 1 AND RedeemStatusID > 0 THEN 'In Progress (Cancelable)'
        WHEN IsCancelable = 0 THEN 'In Progress (Non-Cancelable)'
        ELSE 'Sentinel'
    END AS stage,
    COUNT(*) AS status_count
FROM [DWH_dbo].[Dim_RedeemStatus]
GROUP BY
    CASE
        WHEN RedeemStatusID IN (8, 20) THEN 'Completed'
        WHEN RedeemStatusID IN (2, 21, 25) THEN 'Failed/Problematic'
        WHEN IsCancelable = 1 AND RedeemStatusID > 0 THEN 'In Progress (Cancelable)'
        WHEN IsCancelable = 0 THEN 'In Progress (Non-Cancelable)'
        ELSE 'Sentinel'
    END
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 8.2/10 (★★★★☆) | Phases: 7/14 (fast-path)*
*Tiers: 4 T1, 2 T2, 1 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 9/10*
*Object: DWH_dbo.Dim_RedeemStatus | Type: Table | Production Source: etoro.Dictionary.RedeemStatus*

# History.CreditExtended

> Canonical read interface for the running-total financial snapshot table - wraps History.ActiveCreditExtended and casts the stored int CreditID to bigint to handle values that exceed int range.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | CreditExtendedID (int) from base table History.ActiveCreditExtended |
| **Partition** | N/A (view - base table is unpartitioned) |
| **Indexes** | N/A (view - queries use base table indexes) |

---

## 1. Business Meaning

History.CreditExtended is the standard query interface for the running-total financial snapshot data stored in `History.ActiveCreditExtended`. Every credit event that flows into `History.ActiveCredit` has a corresponding row here capturing the customer's complete financial state at that moment - total cash, open positions, in-process cashouts, copy-trade Mirror balances, and stock orders.

The view exists for two reasons. First, it is the recommended access layer that decouples consumers from the physical table name (per the base table's documented convention: "All consumers should use History.CreditExtended not History.ActiveCreditExtended directly"). Second, it fixes a data type mismatch: `CreditID` is stored as int in the base table (a legacy constraint from the original schema), but CreditID values from merged server data can exceed 2,147,483,647. The view casts CreditID to bigint (`CAST(CreditID AS BigInt) CreditID`), ensuring downstream consumers receive correct numeric values without overflow errors.

Consumers include SSRS/dashboard reports (`dbo.PR_Dashboard_ORG`, `dbo.PR_NFA_Account_Statment`), the account statement realized equity query (`dbo.AccountStatement_GetRealizedEquity`), and the scheduled maintenance job that generates the data (`Maintenance.JOB_InsertHistoryCreditExtendedAction`). The view has a narrow consumer footprint relative to `History.ActiveCredit` - it is primarily used for reporting and analytics, not real-time trading operations.

---

## 2. Business Logic

### 2.1 CreditID Type Bridge (int to bigint)

**What**: The single transformation this view applies - casting the stored int CreditID to bigint to handle cross-server merged data.

**Columns/Parameters Involved**: `CreditID`

**Rules**:
- `History.ActiveCreditExtended.CreditID` is stored as int (legacy constraint from Dec 2016 migration)
- Some CreditID values from merged/secondary server data (e.g., CreditID=500001094) exceed standard int range on certain secondary server offset schemes
- This view applies `CAST(CreditID AS BigInt)` to safely expose all CreditID values
- All other 17 columns are direct pass-throughs with no transformation

**Diagram**:
```
History.ActiveCreditExtended.CreditID (int, stored)
    |
    | CAST(CreditID AS BigInt)
    v
History.CreditExtended.CreditID (bigint, exposed)
    - Safe for all CreditID ranges including cross-server merged values
    - History.ActiveCredit_BIGINT uses bigint natively (no cast needed there)
```

### 2.2 Running Financial State per Credit Event

**What**: Each row captures a complete financial snapshot of the customer's state at one credit event moment.

**Columns/Parameters Involved**: `CreditExtendedID`, `CreditID`, `CID`, `TotalPositionsAmount`, `TotalCash`, `InProcessCashouts`, `TotalMirrorPositionsAmount`, `TotalMirrorCash`, `TotalStockOrders`

**Rules**:
- CreditID has a UNIQUE constraint in the base table: one snapshot per credit event, no duplicates
- TotalCash + TotalPositionsAmount + InProcessCashouts + TotalStockOrders approximately = total customer equity at this point
- TotalMirrorPositionsAmount and TotalMirrorCash are subsets of the total (copy-trading allocations)
- The per-Mirror breakdown (MirrorID, MirrorPositionsAmount, MirrorCash, MirrorStockOrders) appears as MirrorID=0 rows for the customer's non-mirror activity and MirrorID>0 rows for each specific Mirror
- Produced by `Maintenance.JOB_InsertHistoryCreditExtendedAction` running as a scheduled job, processing credit events in CreditID-order batches with a sequential running total algorithm

---

## 3. Data Overview

| CreditExtendedID | CreditID | CID | CreditTypeID | TotalCash | TotalPositionsAmount | InProcessCashouts | MirrorID | Meaning |
|---|---|---|---|---|---|---|---|---|
| 1094 | 500001094 | 3634278 | 7 (Bonus) | 20 | 0 | 0 | 0 | A bonus-related credit event (CreditTypeID=7) for a customer with only $20 cash, no open positions, no cashouts in-flight, and no Mirror activity. CreditID=500001094 is in the secondary-server offset range, confirming the bigint cast is necessary. This is the only row in the staging environment; production IDENTITY seed of 722,463,994 implies ~722M rows. |

---

## 4. Elements

All 18 columns. CreditID is cast from int to bigint; all others are direct pass-throughs from History.ActiveCreditExtended.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditExtendedID | int | NO | - | CODE-BACKED | Surrogate PK of the underlying table. IDENTITY starts at 722,463,994 (set at Dec 2016 migration). Does NOT correspond to CreditID. Exposes the base table's physical row ordering. |
| 2 | CreditID | bigint | YES | - | VERIFIED | The credit event this snapshot corresponds to. Cast from int (base table storage) to bigint here to handle values from merged server data exceeding int range (e.g., CreditID=500001094). UNIQUE in base table - one snapshot per credit event. |
| 3 | CreditTypeID | int | NO | - | VERIFIED | The type of credit event this snapshot accompanies. Determines which delta formulas were applied to compute the running totals. Key values: 1=Deposit, 2=Cashout, 3=Open Position, 4=Close Position, 7=Bonus, 13=Edit SL, 27=Detach, 29/30=Stock Orders. (Source: Dictionary.CreditType) |
| 4 | MMLogID | int | YES | - | VERIFIED | FK to History.MMLog.ID. Links this snapshot to a Money Management failure log entry. Currently always NULL in processing (JOB_InsertHistoryCreditExtendedAction inserts NULL). Represents planned but not yet implemented MM-credit linkage. |
| 5 | PositionID | bigint | YES | - | VERIFIED | The position involved in this credit event. Supports queries like "what was this customer's balance when position X was opened/closed?" NULL for non-position credits (deposits, withdrawals, fees). NC index in base table on this column. |
| 6 | CID | int | NO | - | CODE-BACKED | Customer ID whose financial state this snapshot captures. All rows for one CID form a chronological running-total sequence. FK to Customer.CustomerStatic (NOCHECK). |
| 7 | Occurred | datetime | NO | - | VERIFIED | UTC timestamp of the original credit event (inherited from History.ActiveCredit). The running totals reflect the customer's financial state at this exact moment. |
| 8 | TotalPositionsAmount | money | NO | - | VERIFIED | Running total of the customer's amount invested in all open positions at this moment. Increases on position open (type 3), decreases on close (type 4). Does not include stock orders or mirror-only positions. |
| 9 | TotalCash | money | NO | - | VERIFIED | Running total of the customer's available cash balance at this moment. Inherited from History.ActiveCredit.TotalCash after the credit event delta was applied. |
| 10 | InProcessCashouts | money | NO | - | VERIFIED | Running total of pending cashout amounts not yet processed. Increases when withdrawal initiated (types 8, 9, 15), decreases when the withdrawal is processed (type 2) or reversed. |
| 11 | TotalMirrorPositionsAmount | money | NO | - | VERIFIED | Running total of ALL copy-trading (Mirror) position amounts across all Mirrors for this customer. Always <= TotalPositionsAmount. |
| 12 | TotalMirrorCash | money | NO | - | VERIFIED | Running total of cash tied to ALL copy-trading Mirrors for this customer. |
| 13 | MirrorID | int | NO | - | VERIFIED | The specific copy-trading Mirror this row's per-mirror columns relate to. 0 = non-mirror (customer's own account, columns 8-12 are the totals). >0 = a specific Mirror, and MirrorPositionsAmount/MirrorCash/MirrorStockOrders are that Mirror's individual sub-totals. |
| 14 | MirrorPositionsAmount | money | YES | - | VERIFIED | Position amount within the specific Mirror (MirrorID). NULL when MirrorID=0. Tracks how much of the customer's total is invested within this particular Mirror. |
| 15 | MirrorCash | money | YES | - | VERIFIED | Cash amount associated with the specific Mirror (MirrorID). NULL when MirrorID=0. Represents undeployed cash allocated to this Mirror strategy. |
| 16 | TotalStockOrders | money | YES | - | VERIFIED | Running total of all pending stock order amounts. Increases on stock order open (type 29/30), adjusted on close or detach. NULL for older records predating stock order tracking. |
| 17 | TotalMirrorStockOrders | money | YES | - | VERIFIED | Running total of stock orders within all Mirror accounts. Subset of TotalStockOrders. NULL for non-stock or pre-stock-order records. |
| 18 | MirrorStockOrders | money | YES | - | VERIFIED | Stock order amount for the specific Mirror (MirrorID). NULL when MirrorID=0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | History.ActiveCreditExtended | View | Simple wrapper - all data originates from this base table with CreditID cast to bigint |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Maintenance.JOB_InsertHistoryCreditExtendedAction | CreditID | Reader+Writer | Reads credit events to compute running totals, then inserts into base table via synonym |
| dbo.AccountStatement_GetRealizedEquity | CreditID/PositionID | Reader | Account statement SP calculating realized equity per customer |
| dbo.PR_Dashboard_ORG | CreditID | Reader | SSRS dashboard report for organizational metrics |
| dbo.PR_NFA_Account_Statment | CreditID | Reader | SSRS report for NFA-regulated account statements |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CreditExtended (view)
└── History.ActiveCreditExtended (table - leaf node)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCreditExtended | Table | Sole data source - SELECT all 18 columns with CAST(CreditID AS BigInt) on column 2 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.JOB_InsertHistoryCreditExtendedAction | Stored Procedure | Reader (checks processed watermark) and indirectly the writer of the base table |
| dbo.AccountStatement_GetRealizedEquity | Stored Procedure | Reader - equity calculations for account statements |
| dbo.PR_Dashboard_ORG | Stored Procedure | Reader - SSRS dashboard |
| dbo.PR_NFA_Account_Statment | Stored Procedure | Reader - regulatory account statement report |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Queries against this view use the underlying `History.ActiveCreditExtended` indexes:
- CLUSTERED PK: CreditExtendedID (sequential insert access)
- UNIQUE NC: CreditID (one snapshot per credit event enforcement + lookup)
- NC: PositionID (position-to-snapshot queries)

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Get financial state snapshots for a customer around a specific date
```sql
SELECT TOP 20
    ce.CreditExtendedID,
    ce.CreditID,
    ce.CreditTypeID,
    ce.TotalCash,
    ce.TotalPositionsAmount,
    ce.InProcessCashouts,
    ce.Occurred
FROM History.CreditExtended ce WITH (NOLOCK)
WHERE ce.CID = 12345678
ORDER BY ce.Occurred DESC;
```

### 8.2 Look up the customer's financial state at the time a specific position was closed
```sql
SELECT
    ce.CreditID,
    ce.CreditTypeID,
    ce.TotalCash,
    ce.TotalPositionsAmount,
    ce.InProcessCashouts,
    ce.TotalMirrorPositionsAmount,
    ce.Occurred
FROM History.CreditExtended ce WITH (NOLOCK)
WHERE ce.PositionID = 9876543210
  AND ce.CreditTypeID = 4  -- Close position
ORDER BY ce.Occurred DESC;
```

### 8.3 Get Mirror-level breakdown for a customer at the latest credit event
```sql
SELECT TOP 10
    ce.CreditID,
    ce.MirrorID,
    ce.TotalCash,
    ce.TotalPositionsAmount,
    ce.TotalMirrorPositionsAmount,
    ce.MirrorPositionsAmount,
    ce.MirrorCash,
    ce.Occurred
FROM History.CreditExtended ce WITH (NOLOCK)
WHERE ce.CID = 12345678
ORDER BY ce.CreditExtendedID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.CreditExtended (view). Business context inherited from History.ActiveCreditExtended documentation and code analysis.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 9.0/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 16 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 files analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: History.CreditExtended | Type: View | Source: etoro/etoro/History/Views/History.CreditExtended.sql*

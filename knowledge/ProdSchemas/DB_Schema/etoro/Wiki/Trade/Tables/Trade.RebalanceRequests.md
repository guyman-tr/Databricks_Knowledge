# Trade.RebalanceRequests

> Logs rebalance requests - operations to adjust position sizes or weights in copy portfolios or fund allocations. Each row records one rebalance action on a specific position.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | RebalanceRequestsId (INT, IDENTITY PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK on DICTIONARY filegroup |

---

## 1. Business Meaning

Trade.RebalanceRequests is an audit and operational log for rebalance operations on the eToro platform. A rebalance is an adjustment to the size or weight of positions within a copy portfolio or fund allocation - for example, when a portfolio manager reallocates capital across instruments or when copy-trade positions need to be resized to match a leader's updated portfolio distribution. Each row represents one rebalance action on a specific position, capturing the closing rate used, who triggered it, whether the position received a discounted rate, and any errors that occurred.

This table exists to provide traceability and troubleshooting for rebalance operations. Without it, the operations team could not audit who rebalanced which positions, at what rates, or diagnose failures. It supports copy-trade fund rebalancing and manual rebalance workflows where positions are closed or adjusted at specific rates.

Data flows: Trade.InsertRebalanceRequests INSERTs new rows when rebalance operations are initiated. Trade.GetRebalancePositions reads from this table to retrieve positions eligible for or pending rebalance. Rows are typically read-only after insert; the table serves as an append-only audit log.

---

## 2. Business Logic

### 2.1 Rebalance Request Lifecycle

**What**: A rebalance request is created when a position needs to be adjusted (resized, closed, or reallocated) as part of a portfolio rebalance.

**Columns/Parameters Involved**: `RebalanceRequestsId`, `PositionID`, `CID`, `IsBuy`, `IsDiscounted`, `CloseRate`, `Occurred`, `Error`, `OccurredByUser`

**Rules**:
- Each row = one rebalance action on one position. PositionID links to Trade.PositionTbl.
- IsBuy and direction (long/short) are recorded for PnL and audit context.
- CloseRate is the rate at which the position was (or will be) closed during rebalance.
- Error is NULL on success; populated with error message when the rebalance failed.
- OccurredByUser tracks who triggered the rebalance (e.g., "trad\be-user", service account).

**Diagram**:
```
[Rebalance Trigger] -> Trade.InsertRebalanceRequests
        |
        v
  INSERT RebalanceRequests (PositionID, CID, IsBuy, IsDiscounted, Bid, Ask, CloseRate, OccurredByUser, Occurred)
        |
        v
[Success: Error=NULL]   [Failure: Error=<message>]
        |
        v
  Trade.GetRebalancePositions reads for processing/display
```

### 2.2 Discounted vs Standard Rate

**What**: Indicates whether the rebalance used a discounted or standard closing rate.

**Columns/Parameters Involved**: `IsDiscounted`, `Bid`, `Ask`, `CloseRate`

**Rules**:
- IsDiscounted = 1: Position received a discounted rate (e.g., internal pricing, special terms).
- IsDiscounted = 0: Standard market rate applied.
- Bid, Ask, CloseRate capture the rate snapshot at rebalance time for audit.

---

## 3. Data Overview

| RebalanceRequestsId | PositionID | CID | IsBuy | IsDiscounted | CloseRate | OccurredByUser | Occurred | Error | Meaning |
|---------------------|------------|-----|-------|--------------|-----------|----------------|----------|-------|---------|
| 26 | 2150002016 | 9785155 | 1 | 0 | 210.25 | trad\be-user | 2023-09-18 | - | Successful rebalance at standard rate. Long position closed at 210.25. |
| 24 | (varies) | (varies) | (varies) | 1 | 43.888 | (varies) | (varies) | - | Rebalance with discounted rate. Position received internal/discounted pricing. |
| (sample) | (varies) | (varies) | (varies) | (varies) | (varies) | (varies) | (varies) | (non-null) | Failed rebalance. Error column holds failure message for troubleshooting. |

**Selection criteria**: Rows showing successful vs discounted vs failed rebalances. Mix of IsDiscounted true/false and Error null/non-null.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RebalanceRequestsId | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Sequential identifier for each rebalance request. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | FK to Trade.PositionTbl. The position being rebalanced. |
| 3 | CID | bigint | NO | - | CODE-BACKED | Customer ID. References Customer.Customer. Owner of the position. |
| 4 | IsBuy | bit | NO | - | CODE-BACKED | 1 = Long/Buy position, 0 = Short/Sell. Direction of the position at rebalance. |
| 5 | IsDiscounted | bit | NO | - | CODE-BACKED | 1 = Discounted rate applied, 0 = Standard rate. Affects CloseRate interpretation. |
| 6 | PriceRateID | bigint | NO | - | CODE-BACKED | References price rate snapshot. Links to Trade.CurrencyPrice or rate feed. |
| 7 | Bid | dbo.dtPrice | NO | - | CODE-BACKED | Bid rate at rebalance time. dbo.dtPrice is UDT (likely decimal for price). |
| 8 | Ask | dbo.dtPrice | NO | - | CODE-BACKED | Ask rate at rebalance time. Used for rate audit. |
| 9 | CloseRate | dbo.dtPrice | NO | - | CODE-BACKED | Rate at which the position was or will be closed during rebalance. |
| 10 | Error | varchar(500) | YES | - | CODE-BACKED | Error message when rebalance failed. NULL on success. |
| 11 | OccurredByUser | varchar(50) | NO | - | CODE-BACKED | Windows/user identifier of who triggered the rebalance. E.g., "trad\be-user". |
| 12 | Occurred | datetime2(7) | NO | - | CODE-BACKED | When the rebalance request was recorded. UTC. |
| 13 | Comment | varchar(500) | YES | - | CODE-BACKED | Optional free-form comment. Audit notes, reason for rebalance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | FK | The position being rebalanced. |
| CID | Customer.Customer | Lookup | Customer who owns the position. |
| PriceRateID | Trade.CurrencyPrice (or rate feed) | Lookup | Price rate snapshot at rebalance. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertRebalanceRequests | INSERT | Writer | Inserts new rebalance request rows. |
| Trade.GetRebalancePositions | SELECT | Reader | Reads positions eligible for or pending rebalance. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RebalanceRequests (table)
(no code-level dependencies - table is leaf)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type | Bid, Ask, CloseRate column types. |
| Trade.PositionTbl | Table | Implicit FK target for PositionID. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertRebalanceRequests | Stored Procedure | INSERTs rows. |
| Trade.GetRebalancePositions | Stored Procedure | SELECTs rows. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RebalanceRequests | CLUSTERED | RebalanceRequestsId | - | - | Active |

Index on DICTIONARY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RebalanceRequests | PRIMARY KEY | Enforces unique RebalanceRequestsId. |

---

## 8. Sample Queries

### 8.1 Recent rebalance requests by user

```sql
SELECT TOP 100
    RebalanceRequestsId,
    PositionID,
    CID,
    IsBuy,
    IsDiscounted,
    CloseRate,
    OccurredByUser,
    Occurred,
    Error
FROM Trade.RebalanceRequests WITH (NOLOCK)
ORDER BY Occurred DESC;
```

### 8.2 Failed rebalance requests for investigation

```sql
SELECT
    RebalanceRequestsId,
    PositionID,
    CID,
    CloseRate,
    OccurredByUser,
    Occurred,
    Error,
    Comment
FROM Trade.RebalanceRequests WITH (NOLOCK)
WHERE Error IS NOT NULL
ORDER BY Occurred DESC;
```

### 8.3 Rebalance requests with position details

```sql
SELECT
    rr.RebalanceRequestsId,
    rr.PositionID,
    rr.CID,
    rr.IsBuy,
    rr.IsDiscounted,
    rr.CloseRate,
    rr.OccurredByUser,
    rr.Occurred,
    rr.Error,
    p.InstrumentID,
    p.Amount
FROM Trade.RebalanceRequests rr WITH (NOLOCK)
JOIN Trade.PositionTbl p WITH (NOLOCK) ON p.PositionID = rr.PositionID
ORDER BY rr.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RebalanceRequests | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.RebalanceRequests.sql*

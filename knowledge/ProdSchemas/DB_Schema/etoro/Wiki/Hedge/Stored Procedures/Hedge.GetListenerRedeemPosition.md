# Hedge.GetListenerRedeemPosition

> Retrieves hedge-eligible positions from the HedgeRedeemDB redemption queue that are confirmed for redemption (Billing.Redeem status 8), filtered optionally by batch ID and hedge server, ordered for sequential hedge processing.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RedeemBatchID + @HedgeServerID - dual filter over the redemption queue |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetListenerRedeemPosition` is the hedge server's reader for the cross-database redemption position queue. When eToro customers request position redemptions (a process where the customer receives the actual underlying asset or cash equivalent), the `HedgeRedeem` microservice writes those positions to `[HedgeRedeem].[HedgeRedeemDB].[Hedge].[ListenerRedeemPosition]`. This procedure reads that queue through the `Hedge.ListenerRedeemPosition` synonym, applying two join conditions to ensure only confirmed, hedge-relevant positions are returned.

The JOIN with `Billing.Redeem WHERE RedeemStatusID = 8` is the key confirmation filter: only positions with billing redemption status 8 are returned. This prevents the hedge server from acting on redemption requests that have not yet been confirmed by the billing system. The `IsComputeForHedge = 1` filter ensures only positions that require hedge computation are processed - some redemption positions may be excluded from hedge calculations (e.g., if they are already fully hedged or are CFD positions with no physical delivery requirement).

Data flows as follows: the HedgeRedeem service writes positions to the listener table when customers initiate redemptions; Billing updates Billing.Redeem to RedeemStatusID=8 when the redemption payment is confirmed; the hedge server then calls this procedure to discover which positions need hedge unwinding. The `RedeemBatchID` parameter allows batch processing (NULL = unbatched positions; non-NULL = a specific processing batch). The `HedgeServerID` filter restricts to a specific server's positions (0 = all servers).

---

## 2. Business Logic

### 2.1 Dual-System Confirmation Gate

**What**: A position is returned only when BOTH the HedgeRedeem queue entry exists (IsComputeForHedge=1) AND the billing system has confirmed the redemption at status 8.

**Columns/Parameters Involved**: `LRP.IsComputeForHedge`, `BR.RedeemStatusID`, `LRP.RedeemBatchID`, `LRP.HedgeServerID`

**Rules**:
- JOIN with Billing.Redeem on PositionID - if no matching Billing.Redeem row with RedeemStatusID=8 exists, the position is excluded
- IsComputeForHedge = 1 filter: only positions requiring hedge computation are returned (0 = billing-only redemption, no hedge action needed)
- RedeemStatusID = 8: the specific billing confirmation status that marks a redemption as approved and ready for hedge action
- If @RedeemBatchID IS NULL: returns positions where RedeemBatchID IS NULL (unassigned to any batch - typically newly queued positions)
- If @RedeemBatchID IS NOT NULL: returns positions assigned to that specific batch GUID
- @HedgeServerID = 0: returns positions for all servers; non-zero: restricts to one server
- ORDER BY HedgeServerID, InstrumentID: enables ordered processing for predictable hedge order submission

**Diagram**:
```
Billing confirms redemption (RedeemStatusID=8)
         |
         v
GetListenerRedeemPosition(@RedeemBatchID=NULL, @HedgeServerID=0)
         |
    Hedge.ListenerRedeemPosition (cross-DB synonym)
    [IsComputeForHedge=1, RedeemBatchID IS NULL]
         |
    JOIN Billing.Redeem
    [RedeemStatusID=8, PositionID match]
         |
    Result: positions ready for hedge unwinding
    ordered by HedgeServerID, InstrumentID
```

### 2.2 Batch Processing Pattern

**What**: `RedeemBatchID` and `RedeemBatchDate` enable grouping positions into processing batches for atomic or sequential hedge operations.

**Columns/Parameters Involved**: `@RedeemBatchID`, `LRP.RedeemBatchID`, `LRP.RedeemBatchDate`

**Rules**:
- Positions start with RedeemBatchID=NULL (not yet assigned to a batch)
- The hedge server assigns a batch GUID when it picks up positions for processing
- Calling with a specific @RedeemBatchID retrieves a previously assigned batch (e.g., to resume processing or verify completion)
- Calling with @RedeemBatchID=NULL retrieves unprocessed positions waiting for hedge action

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RedeemBatchID | uniqueidentifier | YES | NULL | CODE-BACKED | Batch identifier for grouping redemption positions. NULL = retrieve unassigned positions (RedeemBatchID IS NULL in the queue). Non-NULL = retrieve all positions assigned to this specific batch GUID. Enables the hedge server to process redemptions in atomic batches rather than one at a time. |
| 2 | @HedgeServerID | int | YES | 0 | CODE-BACKED | Filter to a specific hedge server. 0 = return positions for all servers. Non-zero = restrict to positions owned by that server. Allows each hedge server instance to retrieve only its own positions in a multi-server deployment. |

**Output columns** (from Hedge.ListenerRedeemPosition via synonym):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | PositionID | bigint | NO | - | CODE-BACKED | eToro trading position identifier. Used to JOIN with Billing.Redeem and to identify which customer position is being redeemed and needs hedge unwinding. |
| 4 | HedgeServerID | int | NO | - | CODE-BACKED | The hedge server responsible for processing this redemption. Used as a partition key for ordered output (ORDER BY HedgeServerID). |
| 5 | InstrumentID | int | NO | - | CODE-BACKED | The financial instrument of the position being redeemed. Used for ordering (ORDER BY InstrumentID) enabling batch-grouped hedge order submission by instrument. |
| 6 | IsComputeForHedge | bit | NO | - | VERIFIED | Filter value - all returned rows have IsComputeForHedge=1. Indicates that this redemption requires the hedge server to unwind the corresponding hedge position. 0 = billing-only redemption with no hedge action required (excluded by WHERE clause). |
| 7 | IsBuy | bit | NO | - | CODE-BACKED | Direction of the original customer position being redeemed. 1=Long (buy), 0=Short (sell). Determines which direction the hedge unwind trade needs to be placed (opposite direction). |
| 8 | Units | decimal | YES | - | CODE-BACKED | Size of the position in eToro's internal unit denomination. The hedge engine uses this to calculate how much hedge exposure to unwind. |
| 9 | CID | int | NO | - | CODE-BACKED | Customer identifier. Present for audit purposes and to correlate the redemption with the customer account in reporting. |
| 10 | MessageType | int | YES | - | CODE-BACKED | Type of redemption message, distinguishing different redemption scenarios (e.g., full vs partial redemption, different redemption triggers). |
| 11 | Occurred | datetime | NO | - | CODE-BACKED | Timestamp when the redemption position was recorded in the listener queue by the HedgeRedeem service. |
| 12 | InitForexRate | decimal | YES | - | CODE-BACKED | The forex rate at which the position was originally opened, stored in the redemption record for PnL calculation during unwind. |
| 13 | UnitMargine | decimal | YES | - | CODE-BACKED | Unit margin value at the time of the redemption request, used for exposure calculations during the hedge unwind process. |
| 14 | EndRate | decimal | YES | - | CODE-BACKED | Closing/end rate of the position. Present when the position has already been closed at a known rate; may be NULL for open positions pending redemption at market. |
| 15 | PartialClosePositionID | bigint | YES | - | CODE-BACKED | For partial redemptions - links to the ID of a partial close position record. NULL for full-position redemptions. |
| 16 | RedeemBatchID | uniqueidentifier | YES | - | CODE-BACKED | The batch GUID this position is assigned to. NULL if not yet batched. Echoed in output to allow callers to confirm the batch assignment. |
| 17 | RedeemBatchDate | datetime | YES | - | CODE-BACKED | Timestamp when the position was assigned to a redemption batch. NULL if not yet batched. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LRP.* | Hedge.ListenerRedeemPosition (synonym) | SELECT | Cross-database synonym pointing to HedgeRedeem.HedgeRedeemDB.Hedge.ListenerRedeemPosition |
| BR.PositionID | Billing.Redeem | JOIN | Confirms billing-side redemption approval (RedeemStatusID=8) before returning a position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| HedgeRedeemUser permissions | - | Permission grant | A dedicated HedgeRedeemUser role has EXECUTE access to this procedure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetListenerRedeemPosition (procedure)
├── Hedge.ListenerRedeemPosition (synonym)
│     └── [HedgeRedeem].[HedgeRedeemDB].[Hedge].[ListenerRedeemPosition] (cross-DB table)
└── Billing.Redeem (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ListenerRedeemPosition | Synonym | Main data source - redemption queue from HedgeRedeemDB |
| Billing.Redeem | Table | JOINed to confirm RedeemStatusID=8 (billing-approved redemptions only) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | Called to retrieve redemption queue for hedge position unwinding |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all unassigned redemption positions pending hedge action (all servers)
```sql
EXEC [Hedge].[GetListenerRedeemPosition]
    @RedeemBatchID = NULL,
    @HedgeServerID = 0;
```

### 8.2 Get redemption positions for a specific hedge server awaiting processing
```sql
EXEC [Hedge].[GetListenerRedeemPosition]
    @RedeemBatchID = NULL,
    @HedgeServerID = 1;
```

### 8.3 Retrieve positions from a specific processing batch (e.g., to verify or resume)
```sql
EXEC [Hedge].[GetListenerRedeemPosition]
    @RedeemBatchID = '7B3E4A1C-8F2D-4E6B-9C1A-2D4F5E8B3C7A',
    @HedgeServerID = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetListenerRedeemPosition | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetListenerRedeemPosition.sql*

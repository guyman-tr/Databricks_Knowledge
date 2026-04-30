# History.AccountLiquidationSaga

> Completed account liquidation sagas, archived from Trade.AccountLiquidationSaga after the multi-step position-close process finishes for a customer.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: CID + CreateTime (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK, FILLFACTOR 95) |

---

## 1. Business Meaning

History.AccountLiquidationSaga stores the audit record of completed account liquidation processes. A "liquidation saga" is a multi-step orchestrated process that closes all open positions for a customer's account — triggered either manually by an operator (ActionTypeID=1) or automatically by the BSL (Balance Stop Loss) system (ActionTypeID=2) when a customer's balance falls below a threshold.

Without this table, there would be no permanent record of when a customer's account was liquidated, how the process was triggered, how many steps it took, and when it concluded. The history enables compliance audits ("was this customer's account liquidated on this date?"), customer support investigations, and BSL effectiveness analysis.

Data flows as follows: while a liquidation is in progress, the saga state lives in `Trade.AccountLiquidationSaga` (one active row per CID). `Trade.PersistAccountLiquidationSaga` upserts the current step progress via MERGE. When the final step completes, `Trade.ArchiveAccountLiquidationSaga` DELETEs the row from `Trade.AccountLiquidationSaga` and OUTPUTs it into History.AccountLiquidationSaga with a CloseTime timestamp. The column `CurrentStepIndex` in Trade maps to `LastStepIndex` in History (capturing the final step reached when archived).

---

## 2. Business Logic

### 2.1 Saga Lifecycle: Active to Archived

**What**: Account liquidation is a distributed saga - a sequence of steps (position closes, validations, notifications) tracked with a step counter. The History table captures the completed terminal state.

**Columns/Parameters Involved**: `LastStepIndex`, `CreateTime`, `CloseTime`, `InitialRequestGuid`

**Rules**:
- Active saga: stored in Trade.AccountLiquidationSaga with CurrentStepIndex advancing from 0 upward
- All observed completed sagas have LastStepIndex=4, suggesting the liquidation process is a fixed 4-step pipeline
- CloseTime = GETUTCDATE() at the moment Trade.ArchiveAccountLiquidationSaga executes (the moment the DELETE+OUTPUT runs, not when the last step ran)
- InitialRequestGuid is the distributed correlation ID assigned when the saga was first created, used to trace the liquidation request across services
- If InitialRequestGuid is NULL, the saga was triggered by an older code path that did not assign a GUID

**Diagram**:
```
Trade.PersistAccountLiquidationSaga (step 0 - INSERT)
          |
          v
Trade.AccountLiquidationSaga [CID=X, CurrentStepIndex=0]
          |
          | Trade.PersistAccountLiquidationSaga (steps 1, 2, 3, 4 - UPDATE)
          v
Trade.AccountLiquidationSaga [CID=X, CurrentStepIndex=4]
          |
          | Trade.ArchiveAccountLiquidationSaga (@CID=X)
          v
History.AccountLiquidationSaga [CID=X, LastStepIndex=4, CloseTime=now]
```

### 2.2 Trigger Types: Manual vs BSL

**What**: Two business processes trigger account liquidation, distinguishable by AccountLiquidationAcionTypeID.

**Columns/Parameters Involved**: `AccountLiquidationAcionTypeID`

**Rules**:
- 1 = Manual: initiated by an operator (back-office, compliance, or support). Represents deliberate, case-by-case decisions. ~2.5% of all completed liquidations.
- 2 = BSL (Balance Stop Loss): automatic system trigger when a customer's account balance falls below the required threshold. ~97.5% of all completed liquidations.
- Both types go through the same saga steps (same LastStepIndex=4 terminal state)

**Diagram**:
```
AccountLiquidationAcionTypeID:
  1 = Manual     (70 records, ~2.5%)  - operator-initiated
  2 = BSL        (2727 records, ~97.5%) - automatic balance stop-loss
```

---

## 3. Data Overview

| CID | CreateTime | LastStepIndex | AccountLiquidationAcionTypeID | InitialRequestGuid | CloseTime | Meaning |
|---|---|---|---|---|---|---|
| 3739199 | 2026-03-16 11:20:53 | 4 | 1 | 7DF01538-... | 2026-03-16 11:20:53 | Manual liquidation - operator closed this account. Fast completion (milliseconds between Create and Close) suggests positions were already minimal or the close was scripted. ActionType=1 (Manual). |
| 20625012 | 2025-08-03 16:34:53 | 4 | 2 | 70CE97F6-... | 2025-08-03 16:34:57 | BSL auto-liquidation - balance fell below stop-loss threshold. ~4 seconds to complete all 4 steps. One of multiple CIDs liquidated at exactly the same CreateTime (batch BSL event). |
| 18639685 | 2025-08-03 16:34:53 | 4 | 2 | 466CCF00-... | 2025-08-13 09:43:34 | BSL liquidation created same batch as above, but CloseTime is 10 days later - likely a saga that stalled (positions couldn't close immediately) and was eventually completed or forcibly archived. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID of the account that was liquidated. FK in Trade.AccountLiquidationSaga (source table) to Customer.CustomerStatic(CID). Part of composite PK - a customer can have multiple liquidation history records at different CreateTimes (e.g., re-opened and re-liquidated). |
| 2 | CreateTime | datetime | NO | - | CODE-BACKED | UTC timestamp when the liquidation saga was originally initiated in Trade.AccountLiquidationSaga. Set to GETUTCDATE() at INSERT time by Trade.PersistAccountLiquidationSaga. Together with CID forms the unique key. Multiple CIDs can share the same CreateTime when a batch BSL event fires simultaneously. |
| 3 | LastStepIndex | int | NO | - | CODE-BACKED | The final step number reached when the saga completed. Mapped from Trade.AccountLiquidationSaga.CurrentStepIndex via Trade.ArchiveAccountLiquidationSaga OUTPUT clause. All observed completed sagas show LastStepIndex=4, indicating a 4-step liquidation pipeline (steps 0 through 4). |
| 4 | AccountLiquidationAcionTypeID | int | NO | - | VERIFIED | What triggered this liquidation (note: "Acion" is a typo in the schema - should be "Action"). FK in source table to Dictionary.AccountLiquidationActionType: 1=Manual (operator-initiated), 2=BSL (automatic Balance Stop Loss - customer balance fell below threshold). 97.5% of liquidations are BSL. |
| 5 | InitialRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Distributed correlation GUID assigned when the saga was first created by the application layer. Enables tracing the liquidation request across microservices, message queues, and logs. NULL for sagas initiated by older code paths without GUID support. Used as the saga identity in distributed tracing. |
| 6 | CloseTime | datetime | NO | - | CODE-BACKED | UTC timestamp when Trade.ArchiveAccountLiquidationSaga executed - the moment the saga was moved from active to history. Set to GETUTCDATE() in the OUTPUT clause. Normally very close to CreateTime (seconds apart for successful fast liquidations). If significantly later than CreateTime, indicates the saga stalled and was eventually force-closed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no FK constraints (History tables typically drop FKs for performance). Logical relationships:

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit (no FK) | Identifies the customer whose account was liquidated. FK exists in source Trade.AccountLiquidationSaga. |
| AccountLiquidationAcionTypeID | Dictionary.AccountLiquidationActionType | Implicit (no FK) | Classifies the trigger type (1=Manual, 2=BSL). FK exists in source table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ArchiveAccountLiquidationSaga | CID | Writer | The only write path - DELETEs from Trade.AccountLiquidationSaga and OUTPUTs here with CloseTime. Called when a saga is complete. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AccountLiquidationSaga (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies. History table has no FK constraints.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ArchiveAccountLiquidationSaga | Stored Procedure | Writer - moves completed sagas from Trade.AccountLiquidationSaga here |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryAccountLiquidationSaga | CLUSTERED PK | CID ASC, CreateTime ASC | - | - | Active |

**FILLFACTOR = 95**: Slightly reduced from 100% to leave room for concurrent insertions without page splits, appropriate for an append-heavy archive table.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryAccountLiquidationSaga | PRIMARY KEY CLUSTERED | CID + CreateTime - allows multiple liquidation records per customer at different times |

---

## 8. Sample Queries

### 8.1 Get all liquidation history for a specific customer
```sql
SELECT
    h.CID,
    h.CreateTime,
    h.LastStepIndex,
    alat.[Description]       AS TriggerType,
    h.InitialRequestGuid,
    h.CloseTime,
    DATEDIFF(second, h.CreateTime, h.CloseTime) AS DurationSeconds
FROM History.AccountLiquidationSaga h WITH (NOLOCK)
INNER JOIN Dictionary.AccountLiquidationActionType alat WITH (NOLOCK)
    ON h.AccountLiquidationAcionTypeID = alat.ActionTypeID
WHERE h.CID = 3739199
ORDER BY h.CreateTime DESC;
```

### 8.2 Count liquidations by trigger type and month
```sql
SELECT
    YEAR(CreateTime)  AS [Year],
    MONTH(CreateTime) AS [Month],
    alat.[Description] AS TriggerType,
    COUNT(*) AS LiquidationCount,
    AVG(DATEDIFF(second, CreateTime, CloseTime)) AS AvgDurationSeconds
FROM History.AccountLiquidationSaga h WITH (NOLOCK)
INNER JOIN Dictionary.AccountLiquidationActionType alat WITH (NOLOCK)
    ON h.AccountLiquidationAcionTypeID = alat.ActionTypeID
GROUP BY YEAR(CreateTime), MONTH(CreateTime), alat.[Description]
ORDER BY [Year] DESC, [Month] DESC;
```

### 8.3 Find stalled sagas (CloseTime far from CreateTime)
```sql
SELECT
    CID,
    CreateTime,
    CloseTime,
    DATEDIFF(minute, CreateTime, CloseTime) AS StalledMinutes,
    AccountLiquidationAcionTypeID,
    InitialRequestGuid
FROM History.AccountLiquidationSaga WITH (NOLOCK)
WHERE DATEDIFF(minute, CreateTime, CloseTime) > 60
ORDER BY StalledMinutes DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.AccountLiquidationSaga | Type: Table | Source: etoro/etoro/History/Tables/History.AccountLiquidationSaga.sql*

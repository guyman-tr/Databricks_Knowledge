# Customer.GenerateMirrorDataForDynamics

> Processes copy-trading (mirror) activity from a time window into BackOffice cumulative stats tables and then enqueues each updated customer's mirror statistics as an XML message to Microsoft Dynamics CRM via SQL Server Service Broker, advancing the last-processed timestamp in Maintenance.Feature.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Occurred (start of processing window), @LastDate OUTPUT (end of window) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GenerateMirrorDataForDynamics is the copy-trading statistics aggregation and CRM sync procedure. It reads new mirror/copy-trading activity from History.Mirror, computes cumulative statistics per customer, updates two BackOffice staging tables, and then pushes each updated customer's mirror stats to Dynamics CRM via Service Broker for use in sales and retention analytics.

The procedure exists because the eToro CRM needs to know each customer's copy-trading behavior: how many traders they follow, how much they've invested, and when they started/last copied. This data drives CRM segmentation, sales outreach, and customer lifecycle management. The procedure runs on a schedule (called externally - not in SSDT), processing each batch from the last-processed point up to the current Trade.Mirror max timestamp.

The time-window pattern (`@Occurred` to `@LastDate`) is a cursor-advance mechanism: each run processes only new activity. `@LastDate` is returned as an OUTPUT parameter so the caller can pass it as `@Occurred` in the next run, implementing a "watermark" advance. `Maintenance.Feature FeatureID=10001` stores the last processed timestamp between runs as a durable watermark.

Created 2012 (FB 8686 - added time-period restriction). The inline comments show simplified fields: `NumOfCurrentCopies`, `NumOfUniqueCopiedTraders`, and `CurrentInvestedAmount` were originally computed from aggregates but were reset to 0 in the initial INSERT and then updated separately in subsequent UPDATE statements for accuracy against live data.

---

## 2. Business Logic

### 2.1 Time-Window Resolution and Watermark Advance

**What**: Determines the processing window and advances the durable watermark.

**Columns/Parameters Involved**: `@Occurred` (input), `@LastDate` (OUTPUT), `Trade.Mirror.Occurred`, `Maintenance.Feature.FeatureID=10001`

**Rules**:
- @LastDate = MAX(Occurred) FROM Trade.Mirror (current max = end of this processing window)
- @Occurred = start of window (passed by caller from last run's @LastDate)
- All History.Mirror queries use: Occurred >= @Occurred AND Occurred < @LastDate
- After successful processing: Maintenance.Feature FeatureID=10001 Value = @LastDate (advances watermark)
- On next run: caller passes previous @LastDate as new @Occurred - no overlap, no gap

### 2.2 Mirror Unique Traders Deduplication

**What**: Maintains a deduplicated log of which customers have ever copied which traders.

**Columns/Parameters Involved**: `BackOffice.MirrorUniqueTraders.CID`, `BackOffice.MirrorUniqueTraders.ParentCID`

**Rules**:
- INSERT INTO BackOffice.MirrorUniqueTraders new (CID, ParentCID) pairs from History.Mirror in the window
- LEFT JOIN anti-join pattern: only inserts pairs not already present
- Used downstream to count NumOfUniqueCopiedTraders per customer

### 2.3 Mirror Cumulative Stats - Initial Population

**What**: Inserts first-time cumulative record for customers whose mirror activity appears for the first time.

**Columns/Parameters Involved**: `BackOffice.MirrorComulative.*`, `History.Mirror.*`, `Customer.Customer.OriginalCID`, `Customer.Customer.OriginalProviderID`

**Rules**:
- Source: History.Mirror WHERE MirrorOperationID IN (1,3) in the window
  - MirrorOperationID 1 = copy start (DateOfLastCopy uses MAX of these Occurred values)
  - MirrorOperationID 3 = copy modification/re-invest
- DateOfFirstCopy = MIN(Occurred) in window
- DateOfLastCopy = MAX(Occurred WHERE MirrorOperationID=1) - last copy-start event
- TotalInvestedAmount = SUM(Amount) WHERE MirrorOperationID IN (1,3) AND Amount > 0
- NumOfCurrentCopies = 0 (hardcoded; updated in Step 4)
- NumOfUniqueCopiedTraders = 0 (hardcoded; updated in Step 4)
- CurrentInvestedAmount = 0 (hardcoded; updated in Step 4)
- OriginalCID, OriginalProviderID joined from Customer.Customer
- Only for new CIDs (WHERE Comul.CID IS NULL anti-join)

### 2.4 Mirror Cumulative Stats - Live Updates

**What**: Updates NumOfUniqueCopiedTraders, CurrentInvestedAmount, and NumOfCurrentCopies from live state.

**Columns/Parameters Involved**: `BackOffice.MirrorComulative.NumOfUniqueCopiedTraders`, `CurrentInvestedAmount`, `NumOfCurrentCopies`, `UpdateTime`

**Rules**:
- Update 1: NumOfUniqueCopiedTraders
  - From BackOffice.MirrorUniqueTraders, COUNT(DISTINCT ParentCID) per CID
  - Only for CIDs active in the window (JOIN Trade.Mirror WHERE window range)
  - Sets UpdateTime = @UpdateDate (marks rows for cursor selection in step 2.5)
- Update 2: CurrentInvestedAmount and NumOfCurrentCopies
  - From Trade.Mirror (current live positions, not history)
  - JOIN History.Mirror to limit to CIDs active in this window
  - CurrentInvestedAmount = SUM(ISNULL(Amount,0)) from current live mirrors
  - NumOfCurrentCopies = COUNT of current live mirror rows for the CID

### 2.5 Service Broker Cursor Dispatch to Dynamics

**What**: Sends updated customer mirror stats to svcDynamics via cursor loop.

**Rules**:
- DECLARE XMLCur CURSOR FOR SELECT FROM BackOffice.MirrorComulative WHERE UpdateTime = @UpdateDate
- For each row: BEGIN DIALOG CONVERSATION svcInitiator -> 'svcDynamics' ON CONTRACT ctrAnyXMLData
- SEND ON CONVERSATION MESSAGE TYPE mtAnyXMLData with XML body
- XML format: FOR XML RAW('Mirror'), TYPE, BINARY BASE64, ELEMENTS (columns: CID, DateOfFirstCopy, DateOfLastCopy, NumOfCurrentCopies, NumOfTotalCopies, NumOfUniqueCopiedTraders, CurrentInvestedAmount, TotalInvestedAmount, OriginalCID, OriginalProviderID)
- Cursor loop wrapped in BEGIN TRAN / COMMIT - all Service Broker enqueues are atomic
- Comment shows `--END CONVERSATION @Handle` is intentionally disabled (fire-and-forget, same as DynamicsInsert)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Occurred | DATETIME | NO | - | CODE-BACKED | Start of the processing window. Only History.Mirror rows WHERE Occurred >= @Occurred are processed. Caller should pass the previous run's @LastDate to advance the watermark forward without overlap or gap. |
| 2 | @LastDate | DATETIME | YES | NULL | CODE-BACKED | OUTPUT parameter. Set to MAX(Occurred) FROM Trade.Mirror at procedure start (the upper bound of this processing window). Returned to caller to use as @Occurred in the next run. Also written to Maintenance.Feature FeatureID=10001 as a durable watermark. |

**No result set. Side effects:**
- BackOffice.MirrorUniqueTraders: new (CID, ParentCID) pairs inserted
- BackOffice.MirrorComulative: new CID rows inserted, existing rows updated
- svcDynamics Service Broker queue: XML messages enqueued per updated customer
- Maintenance.Feature FeatureID=10001: Value updated to @LastDate

**XML message fields sent to Dynamics:**

| XML Field | Source | Business Meaning |
|-----------|--------|-----------------|
| CID | BackOffice.MirrorComulative | Customer whose mirror stats changed |
| DateOfFirstCopy | BackOffice.MirrorComulative | When the customer first started copying a trader |
| DateOfLastCopy | BackOffice.MirrorComulative | When the customer last initiated a new copy |
| NumOfCurrentCopies | BackOffice.MirrorComulative | How many traders the customer is currently copying |
| NumOfTotalCopies | BackOffice.MirrorComulative | Total distinct copy relationships ever opened |
| NumOfUniqueCopiedTraders | BackOffice.MirrorComulative | Number of distinct traders ever copied |
| CurrentInvestedAmount | BackOffice.MirrorComulative | Current total amount invested in copy trading |
| TotalInvestedAmount | BackOffice.MirrorComulative | Total amount ever invested in copy trading |
| OriginalCID | BackOffice.MirrorComulative | Original referring customer (affiliate/referral) |
| OriginalProviderID | BackOffice.MirrorComulative | Original referring provider |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Occurred, @LastDate | Trade.Mirror | Read | Resolves @LastDate from MAX(Occurred); used to bound live state queries |
| @Occurred, @LastDate | History.Mirror | Read | Source of copy activity events in the processing window |
| @CID | Customer.Customer | Read (JOIN) | Joins to get OriginalCID and OriginalProviderID for initial INSERT |
| @CID, @ParentCID | BackOffice.MirrorUniqueTraders | Read + INSERT | Maintains deduplicated unique trader-pair log |
| @CID | BackOffice.MirrorComulative | Read + INSERT + UPDATE | Cumulative mirror stats staging table for CRM |
| FeatureID=10001 | Maintenance.Feature | UPDATE | Stores @LastDate as durable processing watermark |
| svcDynamics | SQL Server Service Broker | Message target | CRM sync message destination (same as DynamicsInsert) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No callers found in SSDT repo. | - | Called from external scheduler/service. | |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GenerateMirrorDataForDynamics (procedure)
|- Trade.Mirror (table - cross-schema, current live copy state)
|- History.Mirror (table - cross-schema, copy activity history)
|- Customer.Customer (view - OriginalCID/ProviderID lookup)
|- BackOffice.MirrorUniqueTraders (table - cross-schema, unique trader tracking)
|- BackOffice.MirrorComulative (table - cross-schema, cumulative stats staging)
|- Maintenance.Feature FeatureID=10001 (table - cross-schema, watermark storage)
+-- svcDynamics (Service Broker service - async CRM dispatch)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Current live copy-trading state for CurrentInvestedAmount/NumOfCurrentCopies |
| History.Mirror | Table | Historical copy events for INSERT and cumulative calculations |
| Customer.Customer | View | OriginalCID and OriginalProviderID for initial MirrorComulative INSERT |
| BackOffice.MirrorUniqueTraders | Table | Unique (CID, ParentCID) deduplication; INSERT new pairs |
| BackOffice.MirrorComulative | Table | Cumulative copy stats; INSERT new CIDs and UPDATE existing |
| Maintenance.Feature (FeatureID=10001) | Table | Durable watermark: stores last processed @LastDate between runs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. | - | Called from external scheduler. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @LastDate = MAX(Trade.Mirror.Occurred) | Watermark resolution | Processing window upper bound; must be captured before any DML to avoid race conditions |
| BEGIN TRAN wraps cursor loop | Transaction scope | Only the Service Broker dispatch loop is transactional; the INSERT/UPDATE DML above is NOT in a transaction (auto-committed) |
| CATCH block ROLLBACK | Error handling | Rolls back only the Service Broker transaction if cursor fails; INSERT/UPDATE rows above remain committed |
| UpdateTime = @UpdateDate filter | Cursor selection | Only sends newly-updated rows to Service Broker, not the full MirrorComulative table |
| Maintenance.Feature FeatureID=10001 | Run state | Durable last-processed timestamp - next run reads this to determine @Occurred start |
| FOR XML RAW('Mirror') | XML format | Element-centric XML per row, same pattern as Customer.DynamicsInsert |
| Cursor used for Service Broker | Design | CURSOR required to call BEGIN DIALOG per row; no set-based Service Broker alternative for per-row dialogs |

---

## 8. Sample Queries

### 8.1 Run a processing cycle with explicit window

```sql
DECLARE @LastProcessed DATETIME
-- Get last processed watermark:
SELECT @LastProcessed = CAST(Value AS DATETIME)
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID = 10001

DECLARE @LastDate DATETIME
EXEC Customer.GenerateMirrorDataForDynamics
    @Occurred = @LastProcessed,
    @LastDate = @LastDate OUTPUT

SELECT @LastDate AS NewWatermark  -- will be written to Feature 10001
```

### 8.2 Check pending mirror stats updates

```sql
SELECT CID, NumOfCurrentCopies, NumOfTotalCopies, NumOfUniqueCopiedTraders,
       CurrentInvestedAmount, TotalInvestedAmount, UpdateTime
FROM BackOffice.MirrorComulative WITH (NOLOCK)
ORDER BY UpdateTime DESC
```

### 8.3 Check current watermark

```sql
SELECT FeatureID, Value AS LastProcessedDate
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID = 10001
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GenerateMirrorDataForDynamics | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GenerateMirrorDataForDynamics.sql*

# Monitoring.GetLastTransfersStatusesInPercentage

> Calculates the percentage distribution of transfer statuses within a configurable time window, providing an operational health snapshot of the money transfer pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Result set: Status (name), Count, Percentage |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetLastTransfersStatusesInPercentage is an operational health monitoring procedure that answers the question: "What percentage of recent transfers are in each status?" It produces a real-time breakdown showing how many transfers are New, Init, Pending, Sent, Received, Technical, Cancel, or Fail within a caller-specified time window.

Without this procedure, operations teams would have no quick way to detect pipeline health anomalies. A sudden spike in Technical(4) or Fail(8) percentages - or a drop in Received(10) - signals that the payment processing pipeline may be degraded. This is the kind of query that backs monitoring dashboards and alerting systems.

The procedure is called externally by the MoneyTransfer application (MoneyTransferUser has EXECUTE permission). It reads from two tables: `Billing.Transfers` (the core transactional table holding all money transfer records) and `Dictionary.TransferStatus` (the lookup table defining status names). It uses a LEFT JOIN to ensure all defined statuses appear in the output even when zero transfers are in that state - critical for alerting systems that need to detect "no transfers reaching Received" as a failure signal.

---

## 2. Business Logic

### 2.1 Adaptive TransferID Range Scanning

**What**: Instead of scanning by CreateDate (which would require a full table scan on a large table without a CreateDate index), the procedure uses a TransferID-based range approach that leverages the clustered/PK index for efficient access.

**Columns/Parameters Involved**: `@TimeFrameInMinutes`, `@LastTransferID`, `@MinTransferID`, `@AdjustmentValue`, `@TransferDateThreshold`

**Rules**:
- Gets the latest TransferID from Billing.Transfers (the most recent transfer)
- Sets an initial scan window of 100 TransferIDs back from the latest (`@AdjustmentValue = 100`)
- Iteratively expands the window by 100 IDs at a time, checking if the boundary row's CreateDate is still within the time threshold
- Stops expanding when it finds a TransferID whose CreateDate is older than `DATEADD(minute, -@TimeFrameInMinutes, GETUTCDATE())`
- The final query scans only the `@MinTransferID` to `@LastTransferID` range using a BETWEEN predicate

**Diagram**:
```
Input: @TimeFrameInMinutes (e.g., 60 = last hour)

Step 1: Find @LastTransferID (most recent transfer)
        |
Step 2: @MinTransferID = @LastTransferID - 100
        |
Step 3: WHILE CreateDate(@MinTransferID) > threshold
           @MinTransferID = @MinTransferID - 100
        |
Step 4: Query range [@MinTransferID .. @LastTransferID]
        LEFT JOIN Dictionary.TransferStatus
        GROUP BY Status -> Count + Percentage

Result: All statuses with counts and percentages
```

### 2.2 LEFT JOIN for Complete Status Coverage

**What**: Uses LEFT JOIN from Dictionary.TransferStatus to Billing.Transfers to ensure every defined status appears in the output, even with zero transfers.

**Columns/Parameters Involved**: `Dictionary.TransferStatus.ID`, `Billing.Transfers.TransferStatusID`

**Rules**:
- LEFT JOIN guarantees all 8 defined statuses (New, Init, Pending, Technical, Cancel, Fail, Sent, Received) appear in the result
- `COALESCE(Count, 0)` handles NULL counts for statuses with no matching transfers
- `NULLIF(SUM(Count) OVER (), 0)` prevents division by zero when no transfers exist in the range
- Output is ordered by Percentage DESC so the dominant status appears first
- This is critical for monitoring: the absence of a status row would make alerting logic ambiguous (is it zero or was it filtered out?)

---

## 3. Data Overview

N/A for Stored Procedure. The procedure returns a result set with the following structure:

| Status | Count | Percentage | Meaning |
|--------|-------|------------|---------|
| Received | 45 | 45.00 | 45% of recent transfers completed successfully - healthy indicator. A low Received percentage may signal pipeline issues. |
| Pending | 30 | 30.00 | 30% awaiting provider confirmation - normal for in-flight transfers. A high Pending percentage sustained over time may indicate provider delays. |
| Init | 10 | 10.00 | 10% initializing - early pipeline. Expected to be non-zero during normal operation. |
| New | 8 | 8.00 | 8% newly created - very early stage. A buildup here may indicate the pipeline is not progressing transfers. |
| Sent | 5 | 5.00 | 5% dispatched to provider, awaiting receipt confirmation. Similar to Pending but further in the pipeline. |
| Fail | 2 | 2.00 | 2% failed - business-level rejections (insufficient funds, invalid destination). Elevated Fail rates warrant investigation. |
| Technical | 0 | 0.00 | 0% technical errors - infrastructure/connectivity issues. Any non-zero Technical percentage is an immediate ops alert trigger. |
| Cancel | 0 | 0.00 | 0% cancelled - user or system-initiated cancellations. Normal to be low; spikes may indicate UX or compliance issues. |

*(Representative output - actual values depend on current transfer activity and the @TimeFrameInMinutes parameter.)*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeFrameInMinutes | int | NO (IN) | - | CODE-BACKED | Time window in minutes to analyze. The procedure calculates a threshold as `DATEADD(minute, -@TimeFrameInMinutes, GETUTCDATE())` and scans transfers created within that window. Typical monitoring values: 60 (last hour), 30 (last 30 minutes), 1440 (last 24 hours). Controls the adaptive TransferID range scan - larger windows cause the WHILE loop to expand further back through TransferID space. |
| 2 | @LastTransferID | int (local) | - | - | CODE-BACKED | Internal variable. Captures the most recent TransferID from `Billing.Transfers` via `SELECT TOP 1 ... ORDER BY TransferID DESC`. Serves as the upper bound of the scan range. |
| 3 | @MinTransferID | int (local) | - | - | CODE-BACKED | Internal variable. Dynamically computed lower bound of the TransferID scan range. Initialized to `@LastTransferID - 100` and decremented by 100 in a WHILE loop until the corresponding CreateDate falls outside the time window. |
| 4 | @TransferDateThreshold | datetime (local) | - | - | CODE-BACKED | Internal variable. Computed as `DATEADD(minute, -@TimeFrameInMinutes, GETUTCDATE())`. UTC timestamp marking the oldest transfer to include. Used in the WHILE loop condition to determine when to stop expanding the scan range. |
| 5 | @AdjustmentValue | int (local) | - | 100 | CODE-BACKED | Internal variable. Step size for the adaptive range expansion. Each WHILE iteration subtracts 100 from @MinTransferID. The value of 100 balances scan efficiency (not too many loop iterations) against precision (not scanning too many extra rows). |
| 6 | Status (output) | varchar (from ts.Name) | NO | - | VERIFIED | Transfer status name from Dictionary.TransferStatus.Name. Values: New, Init, Pending, Technical, Cancel, Fail, Sent, Received. See [Transfer Status](../../_glossary.md#transfer-status) for full business definitions of each status. Always returns all 8 statuses due to LEFT JOIN. |
| 7 | Count (output) | int | NO | - | CODE-BACKED | Number of transfers in this status within the scanned TransferID range. Zero-filled via `COALESCE(Count, 0)` for statuses with no matching transfers. Represents absolute count, not a rate. |
| 8 | Percentage (output) | decimal | NO | - | CODE-BACKED | Percentage of transfers in this status relative to all transfers in the scanned range. Formula: `(Count * 100.0) / SUM(Count) OVER ()`. Returns 0 when no transfers exist in the range (division-by-zero guarded via `NULLIF(..., 0)`). Result rows ordered by Percentage DESC. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransferStatusID JOIN | Dictionary.TransferStatus | Direct LEFT JOIN | Resolves status IDs to human-readable names. LEFT JOIN ensures all defined statuses appear in output even with zero transfers. |
| TransferID, CreateDate, TransferStatusID | Billing.Transfers | Direct READ (NOLOCK) | Scans recent transfers by TransferID range to count status distribution. Uses NOLOCK for non-blocking reads appropriate for monitoring queries. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (External callers) | - | Application EXECUTE | Called by the MoneyTransfer application layer (MoneyTransferUser has GRANT EXECUTE). No stored procedure callers found in the repo - invoked directly by application monitoring infrastructure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetLastTransfersStatusesInPercentage (procedure)
+-- Billing.Transfers (table)
+-- Dictionary.TransferStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | READ - scans TransferID range for status counts. Uses TransferID (ORDER BY DESC for latest), CreateDate (time window check), TransferStatusID (JOIN key). Reads with NOLOCK. |
| Dictionary.TransferStatus | Table | READ - LEFT JOIN on ID = TransferStatusID to resolve status Name for output. All rows included via LEFT JOIN. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none in repo) | - | No stored procedures in the repo call this SP. Called externally by the application layer. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

**Index usage notes**: The procedure benefits from:
- `PK_Transfers` (NC on TransferID) for the `SELECT TOP 1 ... ORDER BY TransferID DESC` and the `BETWEEN @MinTransferID AND @LastTransferID` range scan
- `IX_Billing_Transfers_CurrencyID_TransferStatusID_TransferID` (NC on CurrencyID, TransferStatusID, TransferID) may assist the status grouping

### 7.2 Constraints

N/A for Stored Procedure.

**Permissions**: `GRANT EXECUTE ON [Monitoring].[GetLastTransfersStatusesInPercentage] TO [MoneyTransferUser]`

---

## 8. Sample Queries

### 8.1 Get transfer status distribution for the last hour
```sql
EXEC [Monitoring].[GetLastTransfersStatusesInPercentage] @TimeFrameInMinutes = 60
```

### 8.2 Get transfer status distribution for the last 30 minutes
```sql
EXEC [Monitoring].[GetLastTransfersStatusesInPercentage] @TimeFrameInMinutes = 30
```

### 8.3 Manual equivalent query with status names and time-based filter
```sql
SELECT ts.[Name] AS [Status],
       COUNT(BT.TransferID) AS [Count],
       COALESCE((COUNT(BT.TransferID) * 100.0) / NULLIF(SUM(COUNT(BT.TransferID)) OVER (), 0), 0) AS Percentage
FROM Dictionary.TransferStatus ts WITH (NOLOCK)
LEFT JOIN [Billing].[Transfers] BT WITH (NOLOCK)
    ON ts.ID = BT.TransferStatusID
    AND BT.CreateDate >= DATEADD(HOUR, -1, GETUTCDATE())
GROUP BY ts.[Name]
ORDER BY Percentage DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Confluence search returned no pages referencing this procedure. Jira search was unavailable (410 Gone).

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetLastTransfersStatusesInPercentage | Type: Stored Procedure | Source: MoneyTransfer/Monitoring/Stored Procedures/Monitoring.GetLastTransfersStatusesInPercentage.sql*

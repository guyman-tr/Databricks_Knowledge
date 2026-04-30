# Trade.PositionAirdropLog

> Backward-compatible view that unifies old airdrop log data with new admin position log data for BI reporting on historical airdrop and compensation events.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | AirdropID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.PositionAirdropLog provides a unified history of position airdrop and admin compensation operations across two data sources: the legacy PositionAirdropLogOldD_DoNotdelete table and the current Trade.AdminPositionLog table. Each row represents a single airdrop or admin-position request with its execution result, timestamps, amounts, and user context. The view exists to maintain backward compatibility for BI reporting and analytics that need the complete history of airdrop and compensation events without querying two separate tables.

Without this view, consumers would need to UNION the old and new tables in every query, handle different column names (AdminPositionID vs AirdropID), and translate State codes to Result values. PositionAirdropLog centralizes this logic and exposes a single schema. BI reporting uses it to analyze historical airdrop volumes, success/failure rates, compensation patterns, and user activity.

The view performs a UNION ALL of both sources. For old records, CompensationReasonID is NULL and all other columns pass through. For new records, AdminPositionID maps to AirdropID, State maps to Result (3=success/1, 1 or 2=pending/NULL, else=failure/0), TerminalID is empty string, and CompensationReasonID is populated.

---

## 2. Business Logic

UNION ALL of two disjoint sources with column mapping. Old branch: direct select from PositionAirdropLogOldD_DoNotdelete with CompensationReasonID forced to NULL. New branch: select from AdminPositionLog with AdminPositionID aliased to AirdropID, State converted to Result (CASE: State=3 -> 1, State IN (1,2) -> NULL, else -> 0), TerminalID forced to empty string. Both branches expose identical column set for union compatibility.

---

## 3. Data Overview

N/A - output combines Trade.PositionAirdropLogOldD_DoNotdelete and Trade.AdminPositionLog. See base tables for column semantics and data patterns.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AirdropID | (varies) | NO | - | CODE-BACKED | Unique identifier. From AirdropID in old table or AdminPositionID in AdminPositionLog. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. User who received the airdrop or compensation. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. Instrument of the airdropped/compensated position. |
| 4 | Amount | decimal | YES | - | CODE-BACKED | Monetary amount of the airdrop or compensation. |
| 5 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server where the position was created or intended. |
| 6 | RequestOccurred | datetime | YES | - | CODE-BACKED | When the airdrop/compensation was requested. |
| 7 | UserName | varchar | YES | - | CODE-BACKED | Username or identifier of the operator who initiated the request. |
| 8 | ExecutionOccurred | datetime | YES | - | CODE-BACKED | When the position was actually created (or NULL if failed/pending). |
| 9 | PositionID | bigint | YES | - | CODE-BACKED | Created position ID. NULL if execution failed or pending. |
| 10 | Result | tinyint | YES | - | CODE-BACKED | 1=success, 0=failure, NULL=pending (State 1 or 2). Mapped from AdminPositionLog.State for new records. |
| 11 | FailReason | varchar | YES | - | CODE-BACKED | Error message or reason when Result=0. |
| 12 | AmountInUnits | decimal | YES | - | CODE-BACKED | Position size in units/shares. |
| 13 | Cusip | varchar | YES | - | CODE-BACKED | CUSIP identifier for the instrument when applicable. |
| 14 | ApexID | varchar | YES | - | CODE-BACKED | Apex account or reference ID. |
| 15 | Rate | decimal | YES | - | CODE-BACKED | Execution or reference rate used. |
| 16 | TerminalID | varchar | YES | - | CODE-BACKED | Terminal identifier. Empty string for AdminPositionLog records, populated for old records. |
| 17 | CompensationReasonID | int | YES | - | CODE-BACKED | FK to compensation reason lookup. NULL for old records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit FK | Instrument of the position |
| CID | (User/Customer) | Implicit FK | Customer who received airdrop |
| HedgeServerID | (HedgeServer) | Implicit FK | Target hedge server |
| PositionID | Trade.PositionTbl | Implicit FK | Created position when Result=1 |
| CompensationReasonID | (Dictionary) | Implicit FK | Compensation reason (new records only) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionAirdropLog (view)
    |
    +-- Trade.PositionAirdropLogOldD_DoNotdelete (table)
    |
    +-- Trade.AdminPositionLog (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionAirdropLogOldD_DoNotdelete | Table | FROM - legacy airdrop log, first branch of UNION ALL |
| Trade.AdminPositionLog | Table | FROM - current admin position log, second branch of UNION ALL |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Recent successful airdrops

```sql
SELECT AirdropID, CID, InstrumentID, Amount, RequestOccurred, ExecutionOccurred, PositionID
FROM Trade.PositionAirdropLog WITH (NOLOCK)
WHERE Result = 1 AND RequestOccurred >= DATEADD(day, -7, GETDATE())
ORDER BY RequestOccurred DESC;
```

### 8.2 Failed airdrops with reasons

```sql
SELECT AirdropID, CID, InstrumentID, FailReason, RequestOccurred, UserName
FROM Trade.PositionAirdropLog WITH (NOLOCK)
WHERE Result = 0
ORDER BY RequestOccurred DESC;
```

### 8.3 Compensation events by CompensationReasonID

```sql
SELECT CompensationReasonID, COUNT(*) AS Cnt
FROM Trade.PositionAirdropLog WITH (NOLOCK)
WHERE CompensationReasonID IS NOT NULL AND Result = 1
GROUP BY CompensationReasonID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 8.6/10, Relationships: 8.6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionAirdropLog | Type: View | Source: etoro/etoro/Trade/Views/Trade.PositionAirdropLog.sql*

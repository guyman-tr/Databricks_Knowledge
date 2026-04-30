# Monitoring.GetBounceBackRequestsByDaysBack

> Retrieves all bounceback requests within a specified day range, classifying each by its bounceback lifecycle status (Pending, Initiated, or Handled) based on the presence of specific request status IDs.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns classified bounceback requests with lifecycle status |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetBounceBackRequestsByDaysBack provides visibility into the bounceback request pipeline by classifying each request according to how far it has progressed through the bounceback lifecycle. A bounceback goes through three statuses: BounceBackPending (36), BounceBackInitiated (37), and BounceBackHandled (38). This procedure identifies which stage each request is in, enabling operations to spot stuck bouncebacks.

Without this procedure, the team would have no way to quickly identify bouncebacks that are stuck in the Pending or Initiated state without progressing to completion. Stuck bouncebacks represent customer funds that are being held without being returned.

The procedure uses a CTE with MAX(CASE) pivoting to detect which status flags are set per request, then classifies the combination into a human-readable BounceBackStatus string. Only requests with at least one bounceback status are returned.

---

## 2. Business Logic

### 2.1 Bounceback Lifecycle Classification

**What**: Classifies each request into one of three bounceback states based on which status IDs exist.

**Columns/Parameters Involved**: `RequestStatusId`, `BounceBackStatus`

**Rules**:
- RequestStatusId 36 = BounceBackPending (bounceback identified, not yet started)
- RequestStatusId 37 = BounceBackInitiated (bounceback send has been triggered)
- RequestStatusId 38 = BounceBackHandled (bounceback fully processed)
- Classification logic:
  - Has 36 only -> "BounceBackPending" (stuck - not progressing)
  - Has 36 + 37 but not 38 -> "BounceBackInitiated" (in progress)
  - Has 36 + 37 + 38 -> "BounceBackHandled" (complete)
- Requests without any of these statuses are excluded

**Diagram**:
```
BounceBackPending (36) --> BounceBackInitiated (37) --> BounceBackHandled (38)
         |                          |                          |
    "Stuck here?"            "In progress?"              "Complete"
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DaysBack | INT | NO | - | CODE-BACKED | Number of days to look back from current time. No default - caller must specify. Defines the window of RequestStatuses.Timestamp to scan. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RequestId | BIGINT | NO | - | CODE-BACKED | Unique request identifier from Wallet.Requests. |
| 2 | BounceBackPending | INT | NO | - | CODE-BACKED | Flag (0/1): whether this request has status 36 (BounceBackPending). |
| 3 | BounceBackInitiated | INT | NO | - | CODE-BACKED | Flag (0/1): whether this request has status 37 (BounceBackInitiated). |
| 4 | BounceBackHandled | INT | NO | - | CODE-BACKED | Flag (0/1): whether this request has status 38 (BounceBackHandled). |
| 5 | CorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Correlation ID linking this request to the broader transaction flow. |
| 6 | Gcid | INT | NO | - | CODE-BACKED | Global Customer ID of the request owner. |
| 7 | Cryptoid | INT | NO | - | CODE-BACKED | Cryptocurrency identifier for the bounceback. |
| 8 | RequestTypeId | TINYINT | NO | - | CODE-BACKED | Type of the original request (e.g., send, receive). |
| 9 | Timestamp | DATETIME2 | NO | - | CODE-BACKED | When the original request was created. |
| 10 | DetailsJson | NVARCHAR | YES | - | CODE-BACKED | JSON payload with request details including amounts and addresses. |
| 11 | DeviceId | INT | YES | - | CODE-BACKED | Device identifier of the originating client. |
| 12 | BounceBackStatus | VARCHAR | YES | - | CODE-BACKED | Human-readable classification: 'BounceBackPending', 'BounceBackInitiated', or 'BounceBackHandled'. NULL values are filtered out. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.Requests | FROM (read) | Source of request metadata (CorrelationId, Gcid, CryptoId, etc.) |
| Query body | Wallet.RequestStatuses | JOIN | Scanned for bounceback status IDs 36, 37, 38 |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetBounceBackRequestsByDaysBack (procedure)
  ├── Wallet.Requests (table)
  └── Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FROM - request metadata |
| Wallet.RequestStatuses | Table | INNER JOIN - status flag detection |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check bouncebacks from the last 7 days
```sql
EXEC Monitoring.GetBounceBackRequestsByDaysBack @DaysBack = 7;
```

### 8.2 Check only bouncebacks stuck in Pending status
```sql
EXEC Monitoring.GetBounceBackRequestsByDaysBack @DaysBack = 3;
-- Then filter results where BounceBackStatus = 'BounceBackPending'
```

### 8.3 Count bouncebacks by status for the last 30 days
```sql
;WITH BBResults AS (
    -- Inline the logic to count by status
    SELECT R.Id, 
        CASE WHEN MAX(CASE WHEN RS.RequestStatusId = 36 THEN 1 ELSE 0 END) = 1
              AND MAX(CASE WHEN RS.RequestStatusId = 37 THEN 1 ELSE 0 END) = 0 THEN 'Pending'
             WHEN MAX(CASE WHEN RS.RequestStatusId = 37 THEN 1 ELSE 0 END) = 1
              AND MAX(CASE WHEN RS.RequestStatusId = 38 THEN 1 ELSE 0 END) = 0 THEN 'Initiated'
             WHEN MAX(CASE WHEN RS.RequestStatusId = 38 THEN 1 ELSE 0 END) = 1 THEN 'Handled'
        END AS Status
    FROM Wallet.Requests R WITH (NOLOCK)
    INNER JOIN Wallet.RequestStatuses RS WITH (NOLOCK) ON R.Id = RS.RequestId
    WHERE RS.Timestamp >= DATEADD(DAY, -30, SYSDATETIME())
      AND RS.RequestStatusId IN (36, 37, 38)
    GROUP BY R.Id
)
SELECT Status, COUNT(*) AS Total FROM BBResults WHERE Status IS NOT NULL GROUP BY Status;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetBounceBackRequestsByDaysBack | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetBounceBackRequestsByDaysBack.sql*

# Dictionary.FailType

## 1. Business Meaning

### What It Is
A lookup table classifying the types of trading operation failures — what went wrong when a position open, close, edit, redeem, or mirror detach operation failed.

### Why It Exists
Trading operations can fail at various stages for different reasons. This table categorizes failures so they can be logged in `History.HedgeFail` and `History.MMLog`, tracked for operational monitoring, and analyzed for patterns. The categorization drives alerting, retry logic, and operational dashboards.

### How It's Used
Referenced by `History.HedgeFail.FailTypeID` and `History.MMLog` for failure classification. Set by trading procedures including `Trade.HedgeOpen`, `Trade.HedgeClose`, `Trade.PositionCloseRequestAdd`, `Trade.DetachPositionsFromMirror`, and several others during error handling paths.

---

## 2. Business Logic

### Failure Categories

**Trade Request Failures:**
| ID | Name | Description |
|----|------|-------------|
| 1 | Request To Open | Failed during the open request submission phase |
| 2 | Request To Close | Failed during the close request submission phase |

**Trade Execution Failures:**
| ID | Name | Description |
|----|------|-------------|
| 3 | Open | Position open execution failed |
| 4 | Close | Position close execution failed |
| 5 | Edit | Position modification (SL/TP edit) failed |

**System/Integration Failures:**
| ID | Name | Description |
|----|------|-------------|
| 6 | External Error | Error from external provider/system |
| 7 | Internal Error | Internal system error |

**Validation Failures (CopyTrading/Mirror):**
| ID | Name | Description |
|----|------|-------------|
| 8 | MM object disconnected from its parent | Mirror position lost connection to parent copier |
| 9 | MM Max StopLoss | Mirror position exceeded maximum stop-loss allowed |
| 10 | Min Position Amount | Position below minimum amount threshold |
| 11 | Mirror edit StopLoss insufficient funds | Not enough funds to apply the stop-loss change on mirrored position |
| 12 | Max position amount in units | Position exceeds maximum units allowed |
| 13 | Max Take Profit reached | Position reached maximum take-profit limit |

**Redeem Failures (CopyTrading):**
| ID | Name | Description |
|----|------|-------------|
| 14 | PositionRedeemCancelFail | Failed to cancel a redeem operation |
| 15 | PositionRedeemPendingFail | Failed while redeem was in pending state |
| 16 | PositionRedeemCloseFail | Failed to close position during redeem |

**CopyTrading Detach:**
| ID | Name | Description |
|----|------|-------------|
| 17 | Detach | Failed to detach position from mirror/copy relationship |

---

## 3. Data Overview

| FailTypeID | Name |
|-----------|------|
| 1 | Request To Open |
| 2 | Request To Close |
| 3 | Open |
| 4 | Close |
| 5 | Edit |
| 6 | External Error |
| 7 | Internal Error |
| 8 | MM object disconnected from its parent |
| 9 | MM Max StopLoss |
| 10 | Min Position Amount |
| 11 | Mirror edit StopLoss insufficient funds |
| 12 | Max position amount in units |
| 13 | Max Take Profit reached |
| 14 | PositionRedeemCancelFail |
| 15 | PositionRedeemPendingFail |
| 16 | PositionRedeemCloseFail |
| 17 | Detach |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **FailTypeID** | `int` | NO | Primary key. Failure category identifier (1-17). | `MCP` |
| **Name** | `varchar(50)` | NO | Failure description. Indexed (non-unique) for name-based lookups. | `MCP` |

---

## 5. Relationships

### Referenced By
| Table | Column | Relationship |
|-------|--------|-------------|
| History.HedgeFail | FailTypeID | Implicit FK — classifies hedge operation failures |
| History.MMLog | FailTypeID | Implicit FK — classifies mirror management failures |

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- `History.HedgeFail` — stores hedge failure records with fail type classification
- `History.MMLog` — stores mirror management failure logs
- `History.InsertFailPositionToAzure` — archives failed positions
- `History.LogMMNotification` — logs mirror management notifications
- `History.AdminPositionFailInfo` — admin failure information
- `Trade.HedgeOpen` / `Trade.HedgeClose` — write fail type during hedge errors
- `Trade.HedgeRemove` — writes fail type during hedge removal errors
- `Trade.HedgeCloseRequestAdd_Original` — legacy close request failure tracking
- `Trade.PositionCloseRequestAdd` — close request failure handling
- `Trade.DetachPositionsFromMirror` — detach failure tracking
- `Trade.GetRecoveryItemsDemo` view — reads fail types for recovery dashboard
- `Trade.SSRS_Market_Open_Data` — SSRS reporting with fail types
- `dbo.Splunkallinstruments` — Splunk monitoring integration

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `FailTypeID` (clustered, PK_DFLT) |
| **Indexes** | `DFLT_NAME` — nonclustered on Name (non-unique) |
| **Filegroup** | DICTIONARY |
| **Row Count** | 17 |
| **Identity** | No |
| **Temporal** | No |

---

## 8. Sample Queries

```sql
-- Get all failure types
SELECT  FailTypeID,
        Name
FROM    Dictionary.FailType WITH (NOLOCK)
ORDER BY FailTypeID;

-- Count hedge failures by type
SELECT  ft.Name             AS FailureType,
        COUNT(*)            AS FailureCount
FROM    History.HedgeFail hf WITH (NOLOCK)
JOIN    Dictionary.FailType ft WITH (NOLOCK)
        ON hf.FailTypeID = ft.FailTypeID
GROUP BY ft.Name
ORDER BY FailureCount DESC;

-- Get CopyTrading-related failure types
SELECT  FailTypeID,
        Name
FROM    Dictionary.FailType WITH (NOLOCK)
WHERE   Name LIKE '%Mirror%'
OR      Name LIKE '%MM%'
OR      Name LIKE '%Redeem%'
OR      Name LIKE '%Detach%'
ORDER BY FailTypeID;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*

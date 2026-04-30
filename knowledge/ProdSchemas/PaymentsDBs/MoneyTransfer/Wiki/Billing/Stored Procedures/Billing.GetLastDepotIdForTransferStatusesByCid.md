# Billing.GetLastDepotIdForTransferStatusesByCid

> Retrieves the depot ID from the most recent transfer matching any of the caller-specified statuses for a given customer, defaulting to depot 104 when NULL.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns DepotId (int) via SELECT TOP 1 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetLastDepotIdForTransferStatusesByCid is a more flexible variant of GetDepotIdOfLastSuccessfulTransferByCid. Instead of being hardcoded to TransferStatusID = 10 (Received), it accepts a comma-separated list of allowed status IDs, enabling the caller to define which transfer states are acceptable for depot resolution.

This flexibility is needed because different business scenarios may want to consider transfers in different states. For example, a routing decision might accept both Sent(9) and Received(10) transfers, or even Pending(2) transfers if no completed ones exist. The caller controls the criteria.

The procedure uses STRING_SPLIT to parse the comma-separated status list and filters Billing.Transfers by CID and the resulting status set, returning the DepotId from the most recent matching transfer (ordered by TransferID DESC). ISNULL defaults to depot 104.

---

## 2. Business Logic

### 2.1 Dynamic Status Filtering with String Split

**What**: Accepts a comma-separated list of status IDs and filters transfers matching any of those statuses.

**Columns/Parameters Involved**: `TransferStatusID`, `@allowedStatuses`, `DepotId`, `CID`

**Rules**:
- @allowedStatuses is parsed using STRING_SPLIT(@allowedStatuses, ',') to produce a set of values
- The IN clause matches TransferStatusID against all parsed values
- Same TOP 1 ORDER BY TransferID DESC pattern as GetDepotIdOfLastSuccessfulTransferByCid
- Same ISNULL(DepotId, 104) default fallback
- Caller is responsible for passing valid integer status IDs

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | VERIFIED | Customer identifier to look up. Maps to Billing.Transfers.CID. |
| 2 | @allowedStatuses | VARCHAR(100) | NO | - | VERIFIED | Comma-separated list of TransferStatusID values to accept (e.g., '9,10' for Sent and Received). Parsed via STRING_SPLIT. See [Transfer Status](../../_glossary.md#transfer-status) for valid values. |
| 3 | (RETURN) DepotId | INT | - | - | VERIFIED | Depot ID from the most recent transfer matching any allowed status, or 104 if DepotId was NULL. Returns no rows if no matching transfers exist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Billing.Transfers | Read (SELECT) | Reads DepotId filtered by CID and dynamic status list |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetLastDepotIdForTransferStatusesByCid (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | SELECT source - reads DepotId filtered by CID and allowed statuses |

### 6.2 Objects That Depend On This

No dependents found in the database.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get depot for successful transfers (Sent or Received)
```sql
EXEC Billing.GetLastDepotIdForTransferStatusesByCid @cid = 12345678, @allowedStatuses = '9,10'
```

### 8.2 Get depot for any non-failed transfer
```sql
EXEC Billing.GetLastDepotIdForTransferStatusesByCid @cid = 12345678, @allowedStatuses = '0,1,2,9,10'
```

### 8.3 Verify the logic manually
```sql
SELECT TOP 1 ISNULL(DepotId, 104) AS DepotId
FROM Billing.Transfers WITH (NOLOCK)
WHERE CID = 12345678
  AND TransferStatusID IN (SELECT value FROM STRING_SPLIT('9,10', ','))
ORDER BY TransferID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetLastDepotIdForTransferStatusesByCid | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.GetLastDepotIdForTransferStatusesByCid.sql*

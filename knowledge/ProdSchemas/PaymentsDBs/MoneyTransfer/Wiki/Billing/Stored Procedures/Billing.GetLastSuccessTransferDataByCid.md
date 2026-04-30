# Billing.GetLastSuccessTransferDataByCid

> Retrieves the CID, last successful transfer date, and depot ID from the most recent successful (Sent or Received) transfer for a customer.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CID, LastSuccessTransferDateTime, LastSuccessDepotId via SELECT TOP 1 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetLastSuccessTransferDataByCid provides summary information about a customer's most recent successful transfer. Unlike the DepotId-only procedures, this returns a richer dataset including the transfer date and depot, enabling the caller to understand both when and where the last success occurred.

This procedure serves customer support and routing decisions that need to know not just the depot but also the recency of the last successful transfer. A recent success suggests the routing is working; a stale success date may indicate issues.

The procedure considers both Sent(9) and Received(10) as success statuses (broader than GetDepotIdOfLastSuccessfulTransferByCid which only uses 10). It returns CID (echoed back), CreateDate as LastSuccessTransferDateTime, and DepotId as LastSuccessDepotId.

---

## 2. Business Logic

### 2.1 Broader Success Definition

**What**: Uses TransferStatusID IN (9,10) as the success criteria, treating Sent as a success alongside Received.

**Columns/Parameters Involved**: `TransferStatusID`, `CreateDate`, `DepotId`, `CID`

**Rules**:
- Status 9 (Sent) AND 10 (Received) both qualify as "successful" - more lenient than the strict "Received only" approach
- Returns CreateDate as LastSuccessTransferDateTime (creation time, not the time the transfer reached success status)
- DepotId is returned without ISNULL fallback (unlike the GetDepotId procedures)
- Returns no rows if no successful transfers exist for this CID

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | VERIFIED | Customer identifier. Maps to Billing.Transfers.CID. |
| 2 | (RETURN) CID | INT | - | - | CODE-BACKED | Echoed customer ID from the matching transfer row (aliased from Cid column). |
| 3 | (RETURN) LastSuccessTransferDateTime | DATETIME2 | - | - | VERIFIED | CreateDate of the most recent successful transfer. Represents when the transfer was initiated, not when it reached success status. |
| 4 | (RETURN) LastSuccessDepotId | INT | - | - | CODE-BACKED | DepotId from the most recent successful transfer. May be NULL if SaveRoutingInfo was never called for that transfer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Billing.Transfers | Read (SELECT) | Reads CID, CreateDate, DepotId filtered by success statuses |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetLastSuccessTransferDataByCid (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | SELECT source - filtered by CID and TransferStatusID IN (9,10) |

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

### 8.1 Get last success data for a customer
```sql
EXEC Billing.GetLastSuccessTransferDataByCid @cid = 12345678
```

### 8.2 Verify manually
```sql
SELECT TOP 1 Cid AS CID, CreateDate AS LastSuccessTransferDateTime, DepotId AS LastSuccessDepotId
FROM Billing.Transfers WITH (NOLOCK)
WHERE CID = 12345678 AND TransferStatusID IN (9, 10)
ORDER BY TransferID DESC
```

### 8.3 Compare Sent vs Received counts for customer
```sql
SELECT TransferStatusID, COUNT(*) AS Count
FROM Billing.Transfers WITH (NOLOCK)
WHERE CID = 12345678 AND TransferStatusID IN (9, 10)
GROUP BY TransferStatusID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetLastSuccessTransferDataByCid | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.GetLastSuccessTransferDataByCid.sql*

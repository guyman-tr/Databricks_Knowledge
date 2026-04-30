# Billing.GetDepotIdOfLastSuccessfulTransferByCid

> Retrieves the depot ID from the most recent successfully completed (Received) transfer for a given customer, defaulting to depot 104 when NULL.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns DepotId (int) via SELECT TOP 1 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetDepotIdOfLastSuccessfulTransferByCid determines which depot (processing infrastructure/data center) a customer's most recent successful transfer was routed through. This is used to maintain routing consistency - subsequent transfers for the same customer should typically be routed to the same depot.

Without this procedure, the system would need a separate routing service or would risk sending a customer's transfers to different depots, potentially causing inconsistent processing behavior. The depot ID is a key routing parameter in the MoneyBus pipeline.

The procedure queries Billing.Transfers for the most recent transfer with TransferStatusID = 10 (Received - the definitive success state) for the specified CID, ordered by TransferID descending. If DepotId is NULL, it defaults to 104 via ISNULL. This default value (104) represents the primary/default depot.

---

## 2. Business Logic

### 2.1 Depot Routing with Default Fallback

**What**: Determines the customer's most recent successful depot, with a hardcoded fallback to depot 104.

**Columns/Parameters Involved**: `DepotId`, `TransferStatusID`, `CID`, `TransferID`

**Rules**:
- Only considers transfers with TransferStatusID = 10 (Received) - not Sent(9), not any other status
- Uses TOP 1 ORDER BY TransferID DESC to get the most recent successful transfer
- ISNULL(DepotId, 104) provides a fallback: depot 104 is the default when DepotId was never set
- If the customer has no successful transfers, returns no rows (not 104)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | VERIFIED | Customer identifier to look up. Maps to Billing.Transfers.CID. |
| 2 | (RETURN) DepotId | INT | - | - | VERIFIED | Depot ID from the most recent Received transfer, or 104 if DepotId was NULL. Returns no rows if no successful transfers exist for this customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Billing.Transfers | Read (SELECT) | Reads DepotId from the most recent successful transfer |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepotIdOfLastSuccessfulTransferByCid (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | SELECT source - reads DepotId filtered by CID and TransferStatusID = 10 |

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

### 8.1 Get depot for a customer
```sql
EXEC Billing.GetDepotIdOfLastSuccessfulTransferByCid @cid = 12345678
```

### 8.2 Verify the result manually
```sql
SELECT TOP 1 ISNULL(DepotId, 104) AS DepotId
FROM Billing.Transfers WITH (NOLOCK)
WHERE CID = 12345678 AND TransferStatusID = 10
ORDER BY TransferID DESC
```

### 8.3 Check if customer has any successful transfers
```sql
SELECT COUNT(*) AS SuccessfulTransfers
FROM Billing.Transfers WITH (NOLOCK)
WHERE CID = 12345678 AND TransferStatusID = 10
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetDepotIdOfLastSuccessfulTransferByCid | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.GetDepotIdOfLastSuccessfulTransferByCid.sql*

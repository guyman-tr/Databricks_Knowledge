# Billing.SaveRoutingInfo

> Sets the depot and country routing information on a transfer record, determining which processing infrastructure and jurisdiction handles the transfer.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Void (no return value) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.SaveRoutingInfo assigns the geographic and infrastructure routing for a transfer by setting DepotId and CountryId. The depot determines which data center or processing region handles the transfer, while the country identifies the customer's or transfer's jurisdiction for compliance and regional processing rules.

This is a critical step in the transfer pipeline because routing decisions affect which payment providers are available, what compliance rules apply, and where the processing happens. Depot 104 is the default/primary depot (used as fallback by GetDepotIdOfLastSuccessfulTransferByCid when DepotId is NULL), and depot 166 is the secondary.

The procedure is called after the MoneyTransfer service determines the appropriate routing based on the customer's location and the transfer type, but before the transfer is submitted to the payment provider.

---

## 2. Business Logic

### 2.1 Dual-Column Routing Assignment

**What**: Sets both DepotId and CountryId in a single UPDATE - these are always determined together.

**Columns/Parameters Involved**: `DepotId`, `CountryId`, `ReferenceID`

**Rules**:
- Both values are set atomically in one UPDATE statement
- Common DepotId values: 104 (primary), 166 (secondary)
- CountryId values observed: 74, 112, 143, 191, 218 (references external country lookup)
- No validation against valid depot/country combinations
- Trigger auto-updates ModificationDate

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RefGuid | UNIQUEIDENTIFIER | NO | - | VERIFIED | Internal business key of the transfer. Maps to Billing.Transfers.ReferenceID. |
| 2 | @DepotId | INT | NO | - | VERIFIED | Processing depot/data center identifier. Determines which infrastructure handles the transfer. Common values: 104 (primary/default), 166 (secondary). Used by GetDepotIdOfLastSuccessfulTransferByCid and GetLastDepotIdForTransferStatusesByCid for routing consistency. |
| 3 | @CountryId | INT | NO | - | CODE-BACKED | Country/jurisdiction identifier for the transfer. References an external country lookup. Observed values include 74, 112, 143, 191, 218. Used for compliance and regional processing rules. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Billing.Transfers | Write (UPDATE) | Sets DepotId and CountryId on the matching transfer |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SaveRoutingInfo (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | UPDATE target - sets DepotId and CountryId WHERE ReferenceID = @RefGuid |

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

### 8.1 Set routing info
```sql
EXEC Billing.SaveRoutingInfo
    @RefGuid = '023BE1D7-45AF-4710-9369-323E647A4EE4',
    @DepotId = 104,
    @CountryId = 191
```

### 8.2 Check routing distribution for recent transfers
```sql
SELECT DepotId, CountryId, COUNT(*) AS Count
FROM Billing.Transfers WITH (NOLOCK)
WHERE TransferID > (SELECT MAX(TransferID) - 1000 FROM Billing.Transfers WITH (NOLOCK))
GROUP BY DepotId, CountryId
ORDER BY Count DESC
```

### 8.3 Find transfers with no routing set
```sql
SELECT TOP 10 TransferID, ReferenceID, TransferStatusID, CreateDate
FROM Billing.Transfers WITH (NOLOCK)
WHERE DepotId IS NULL
ORDER BY TransferID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.SaveRoutingInfo | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.SaveRoutingInfo.sql*

# AffiliateCommission.SetCustomerFinanceDetailsState

> Updates a trader's total revenue and minimum commission thresholds used for CPA finance-based commission eligibility evaluation.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates TotalRevenue and MinimumCommission on TraderFirstAssetPosition by CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure updates the financial state of a trader within the affiliate commission system. It records the total accumulated commission revenue and the minimum commission threshold for a specific customer, which are key inputs for determining whether CPA (Cost Per Acquisition) commission payouts should be triggered.

The procedure writes to the AffiliateConfiguration.TraderFirstAssetPosition table, which stores per-trader financial metrics. These values are used downstream by the commission engine to evaluate whether a trader has generated sufficient revenue to qualify their referring affiliate for commission payment.

The DateUpdated timestamp is set to the current UTC time on each call, providing an audit trail of when the trader's financial state was last recalculated. The procedure uses partition pruning via PartitionCol = @CID % 50 for efficient lookups.

---

## 2. Business Logic

### 2.1 Finance State Update

**What**: Updates the total revenue, minimum commission threshold, and last-updated timestamp for a trader's first asset position record.

**Columns/Parameters Involved**: @CID, @TotalCommission, @MinimumCommission, TotalRevenue, MinimumCommission, DateUpdated

**Rules**:
- Targets a single trader record using CID with partition pruning (PartitionCol = @CID % 50)
- TotalRevenue is set from the @TotalCommission parameter
- MinimumCommission is set from the @MinimumCommission parameter
- DateUpdated is always set to GETUTCDATE() to record the modification time
- The update is unconditional - overwrites existing values without comparison

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | BIGINT | No | - | CODE-BACKED | Customer ID identifying the trader |
| 2 | @TotalCommission | FLOAT | No | - | CODE-BACKED | Total accumulated commission revenue for this trader |
| 3 | @MinimumCommission | FLOAT | No | - | CODE-BACKED | Minimum commission threshold required for payout eligibility |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | AffiliateConfiguration.TraderFirstAssetPosition | UPDATE target | Updates TotalRevenue, MinimumCommission, DateUpdated by CID with partition pruning |

### 5.2 Referenced By (other objects point to this)

Called by the commission processing service after recalculating a trader's financial metrics, typically during CPA evaluation cycles.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.SetCustomerFinanceDetailsState
  --> AffiliateConfiguration.TraderFirstAssetPosition (UPDATE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateConfiguration.TraderFirstAssetPosition | Table | UPDATE target - sets TotalRevenue, MinimumCommission, DateUpdated |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Commission processing service | Application | Calls this SP to persist recalculated finance details |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Set finance details for a trader
```sql
EXEC AffiliateCommission.SetCustomerFinanceDetailsState
    @CID = 500001,
    @TotalCommission = 1250.75,
    @MinimumCommission = 100.00;
```

### 8.2 Verify the updated finance state
```sql
SELECT CID, TotalRevenue, MinimumCommission, DateUpdated
FROM AffiliateConfiguration.TraderFirstAssetPosition WITH (NOLOCK)
WHERE CID = 500001 AND PartitionCol = 500001 % 50;
```

### 8.3 Find traders with updated finance details in the last hour
```sql
SELECT CID, TotalRevenue, MinimumCommission, DateUpdated
FROM AffiliateConfiguration.TraderFirstAssetPosition WITH (NOLOCK)
WHERE DateUpdated >= DATEADD(HOUR, -1, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-2448: CPA New Compensation Design (17/12/23)
- 7/2/24 Noga: Fix WHERE clause of PartitionCol
- 16/7/24 Noga: Add update of new column DateUpdated

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.SetCustomerFinanceDetailsState | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.SetCustomerFinanceDetailsState.sql*

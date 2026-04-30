# Billing.WithdrawToFunding_GetItems

> Batch-fetches WithdrawData (provider response XML) for a set of WithdrawIDs filtered by a specific depot, enabling efficient multi-withdrawal data retrieval in a single database call.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Ids (batch of WithdrawIDs) + @DepotId (routing filter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawToFunding_GetItems` retrieves the core withdrawal execution data - specifically the provider response XML (`WithdrawData`) - for a batch of withdrawal IDs that were processed through a specific depot. This is a batch read procedure designed for efficiency: rather than making N individual database calls to fetch data for N withdrawals, the caller passes all withdrawal IDs at once via a table-valued parameter.

The procedure is scoped to a single `@DepotId` because withdrawal execution is depot-specific: the same WithdrawID may have payment legs through different depots (acquirers/gateways), and the caller needs to retrieve only the legs relevant to the depot it is processing. This makes the procedure safe for concurrent depot-specific batch jobs without returning cross-depot data.

The `WithdrawData` XML column is the key output - it contains the raw provider response data for each payment leg (auth codes, transaction references, rejection reasons), which the calling process uses for reconciliation, status updates, or downstream reporting.

---

## 2. Business Logic

### 2.1 Batch Fetch by TVP

**What**: Uses the `dbo.IdIntList` table-valued parameter type for efficient multi-ID batch retrieval.

**Columns/Parameters Involved**: `@Ids`, `WithdrawID`

**Rules**:
- `@Ids` is a `dbo.IdIntList` TVP (table type: single INT column named `ID`)
- INNER JOIN to `Billing.WithdrawToFunding` on `wtf.WithdrawID = i.ID` - only rows matching the provided IDs are returned
- If an ID in @Ids has no matching row in Billing.WithdrawToFunding for the given DepotID, that ID is silently excluded

### 2.2 Depot-Scoped Results

**What**: Restricts results to payment legs processed through a specific depot (acquirer/gateway).

**Columns/Parameters Involved**: `@DepotId`, `DepotID`

**Rules**:
- Only `Billing.WithdrawToFunding` rows where `DepotID = @DepotId` are returned
- One withdrawal can have multiple payment legs across different depots; this filter ensures depot-specific processing
- If no legs for the given WithdrawIDs exist at the specified depot, zero rows are returned

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Ids | dbo.IdIntList | NO | - | CODE-BACKED | Required. Table-valued parameter containing the set of WithdrawIDs to fetch. Each row has a single INT column (ID). Passed as ReadOnly - the procedure cannot modify this input. |
| 2 | @DepotId | int | NO | - | CODE-BACKED | Required. Depot (acquirer/gateway) ID to filter results. Only WithdrawToFunding rows where DepotID matches are returned. See Billing.WithdrawToFunding Section 2.4 for depot context. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | int | NO | - | CODE-BACKED | The withdrawal request ID. FK to Billing.Withdraw. Enables the caller to correlate output rows back to the input IDs. |
| 2 | WithdrawData | xml | YES | - | CODE-BACKED | Provider response XML for this payment execution leg. Contains auth codes, transaction references, rejection reasons, and other provider-specific response data. From `Billing.WithdrawToFunding.WithdrawData`. |
| 3 | WithdrawToFundingId | int | NO | - | CODE-BACKED | PK of `Billing.WithdrawToFunding.ID`, aliased as `WithdrawToFundingId`. Uniquely identifies this specific payment leg within the withdrawal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Ids | dbo.IdIntList | Type dependency | Uses this UDT as the TVP type for batch input |
| @Ids + @DepotId | Billing.WithdrawToFunding | Reader | Filtered by both WithdrawID (from TVP) and DepotID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PayoutService (application) | @Ids, @DepotId | Caller | Called during batch payout processing to retrieve provider response data for multiple withdrawals at once |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFunding_GetItems (procedure)
├── Billing.WithdrawToFunding (table)
└── dbo.IdIntList (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Source table - filtered by DepotID and the provided WithdrawID list |
| dbo.IdIntList | User Defined Type | TVP type for @Ids parameter - list of INT IDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PayoutService (application) | External application | Caller - batch retrieval of provider response data per depot |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| INNER JOIN to TVP | Design | Withdrawals not present in @Ids are not returned; withdrawals without matching DepotID are excluded. Silent exclusion, no error raised for missing IDs. |
| ReadOnly TVP | Design | @Ids cannot be modified within the procedure - standard SQL Server TVP contract |

---

## 8. Sample Queries

### 8.1 Fetch provider response data for a batch of withdrawals at a specific depot

```sql
DECLARE @Ids dbo.IdIntList;
INSERT @Ids VALUES (1001), (1002), (1003);

EXEC Billing.WithdrawToFunding_GetItems
    @Ids = @Ids,
    @DepotId = 5;
```

### 8.2 Direct equivalent query against the source table

```sql
SELECT
    wtf.WithdrawID,
    wtf.WithdrawData,
    wtf.ID AS WithdrawToFundingId
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.WithdrawID IN (1001, 1002, 1003)
  AND wtf.DepotID = 5;
```

### 8.3 Inspect provider XML response for a specific withdrawal leg

```sql
SELECT
    wtf.ID AS WithdrawToFundingId,
    wtf.WithdrawID,
    wtf.DepotID,
    wtf.CashoutStatusID,
    wtf.WithdrawData
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.WithdrawID = 1001
ORDER BY wtf.ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFunding_GetItems | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFunding_GetItems.sql*

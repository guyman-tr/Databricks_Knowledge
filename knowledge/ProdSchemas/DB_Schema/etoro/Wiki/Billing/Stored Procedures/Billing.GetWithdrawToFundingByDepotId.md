# Billing.GetWithdrawToFundingByDepotId

> Cross-validates a set of WithdrawToFunding IDs against a set of DepotIDs: returns only those WithdrawToFunding record IDs that exist in BOTH the provided ID list AND the provided Depot list, used by the payout service to confirm depot ownership before processing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawToFundingIds (TVP) + @DepotIds (TVP); returns matching WithdrawToFunding IDs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetWithdrawToFundingByDepotId validates that a given set of WithdrawToFunding records belong to a specific set of depots. The payout service uses this to confirm that the withdrawal records it intends to process are assigned to the depots it controls, preventing cross-depot processing errors.

The filter logic: "Give me the WithdrawToFunding IDs where the record's ID is in the ID list AND the record's DepotID is in the Depot list." Only records satisfying both conditions are returned.

Note: `dbo.IdList` is a user-defined table type whose column is named `CID` (not `ID`), which is why the WHERE clause reads `WHERE BWTF.ID = CID` and `WHERE BWTF.DepotID = CID` - the `CID` column in IdList serves as the generic integer value column regardless of what it actually represents.

Created per PAYUS-1560, referenced in "Payout Service Gen 2.0 - Changes" (Confluence MG).

---

## 2. Business Logic

### 2.1 Dual TVP Cross-Validation

**What**: Returns WithdrawToFunding IDs that appear in both the ID list and have a DepotID in the depot list.

**Columns/Parameters Involved**: `@WithdrawToFundingIds`, `@DepotIds`, `Billing.WithdrawToFunding.ID`, `Billing.WithdrawToFunding.DepotID`

**Rules**:
- `WHERE EXISTS (SELECT TOP 1 1 FROM @WithdrawToFundingIds WHERE BWTF.ID = CID)` - ID must be in the WithdrawToFunding ID set
- `AND EXISTS (SELECT TOP 1 1 FROM @DepotIds WHERE BWTF.DepotID = CID)` - DepotID must be in the depot set
- Both conditions must be satisfied; only the intersection is returned
- `dbo.IdList` column name is `CID` (generic integer type; used for both ID and DepotID lookups)
- Returns only `BWTF.ID` - not the full record; caller uses these IDs for further processing

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingIds | dbo.IdList | NO | - | CODE-BACKED | READONLY TVP of WithdrawToFunding IDs to validate. The IdList type has a single INT column named CID (generic integer container). |
| 2 | @DepotIds | dbo.IdList | NO | - | CODE-BACKED | READONLY TVP of permitted DepotIDs. Only records whose DepotID appears in this list are returned. |
| - | ID | INT | NO | - | CODE-BACKED | The WithdrawToFunding.ID of each record that passes both filters. Returned as a set - one row per matching record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ID, DepotID | Billing.WithdrawToFunding | SELECT (EXISTS filters) | Source of withdrawal funding records; both ID and DepotID filtered against TVP inputs |
| @WithdrawToFundingIds, @DepotIds | dbo.IdList | TVP type | User-defined table type for both input parameters |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payout Service Gen 2.0 | @WithdrawToFundingIds, @DepotIds | EXEC | Depot ownership validation before processing withdrawals (PAYUS-1560) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetWithdrawToFundingByDepotId (procedure)
+-- Billing.WithdrawToFunding (table) [ID + DepotID cross-validation]
+-- dbo.IdList (user defined type) [TVP type for both parameters]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Filtered by EXISTS against both TVP inputs; returns matching IDs |
| dbo.IdList | User Defined Type | Type of both @WithdrawToFundingIds and @DepotIds parameters; column named CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payout Service Gen 2.0 | External | Validates depot ownership of WithdrawToFunding records before payout processing (PAYUS-1560) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| dbo.IdList CID column name | Design | The generic integer column in dbo.IdList is named CID (not ID); used as both the WithdrawToFunding ID and DepotID lookup value |
| No NOLOCK | Concurrency | No WITH (NOLOCK) on Billing.WithdrawToFunding; reads committed data |
| Returns only IDs | Design | Only BWTF.ID is returned; caller must fetch full record data separately if needed |
| PAYUS-1560 | Change history | Initial version per PAYUS-1560; Payout Service Gen 2.0 context |

---

## 8. Sample Queries

### 8.1 Validate depot ownership for a batch

```sql
DECLARE @ids dbo.IdList
DECLARE @depots dbo.IdList

INSERT INTO @ids (CID) VALUES (101), (102), (103)
INSERT INTO @depots (CID) VALUES (5), (6)

EXEC [Billing].[GetWithdrawToFundingByDepotId]
    @WithdrawToFundingIds = @ids,
    @DepotIds = @depots
-- Returns IDs from @ids where the record's DepotID is in @depots
```

---

## 9. Atlassian Knowledge Sources

**Confluence**: "Payout Service Gen 2.0 - Changes" (/spaces/MG) - payout service generation 2.0 changes that introduced this procedure (PAYUS-1560).

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 1 Confluence (Payout Service Gen 2.0) + 1 Jira (PAYUS-1560) | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetWithdrawToFundingByDepotId | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetWithdrawToFundingByDepotId.sql*

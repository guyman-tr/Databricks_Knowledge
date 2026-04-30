# Trade.RemoveTradonomiContract

> Removes a Tradonomi contract and all its LP contract mappings in a single transaction, decommissioning the Tradonomi contract from the instrument-to-provider routing system.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ContractID (TradonomiContracts.ContractID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.RemoveTradonomiContract decommissions a Tradonomi internal contract by removing all its LP contract mappings (Trade.TradonomiToLiquidityProviderContracts) and then the contract itself (Trade.TradonomiContracts) in a single atomic transaction. This is the mirror operation to Trade.RemoveLiquidityProviderContract - while that procedure starts from the LP contract side, this one starts from the Tradonomi contract side.

This procedure exists to ensure clean removal of Tradonomi contracts without leaving orphaned LP-to-Tradonomi mapping rows. TradonomiContracts and TradonomiToLiquidityProviderContracts must stay in sync; deleting a contract without clearing its mappings would leave the hedge/price system with unresolvable references.

Data flow: Called by ops/admin tools when retiring a Tradonomi contract (e.g., a contract period ends, an instrument is rolled over to a new contract). The @ContractID is the PK of Trade.TradonomiContracts. Returns 0 on success, -1 with full rollback on error. Both tables are system-versioned, so deleted rows are captured in their respective History tables automatically.

---

## 2. Business Logic

### 2.1 Cascading Delete in a Single Transaction (Tradonomi-Side)

**What**: Two DELETE statements within BEGIN TRAN/COMMIT TRAN and TRY/CATCH remove the contract and its LP mappings atomically.

**Columns/Parameters Involved**: `@ContractID`

**Rules**:
- Step 1: DELETE Trade.TradonomiToLiquidityProviderContracts WHERE TradonomiContractID = @ContractID (remove all LP contract assignments for this Tradonomi contract).
- Step 2: DELETE Trade.TradonomiContracts WHERE ContractID = @ContractID (remove the Tradonomi contract itself).
- Order: mapping rows deleted first to respect any FK constraints.
- On error: ROLLBACK TRAN, RETURN -1.
- On success: COMMIT TRAN, RETURN 0.
- Comparison with Trade.RemoveLiquidityProviderContract: that procedure deletes by LiquidityProviderContractID (LP side); this procedure deletes by TradonomiContractID (Tradonomi side). Both share the same atomic pattern.

**Diagram**:
```
Trade.RemoveTradonomiContract(@ContractID)
    |
    v
BEGIN TRAN
    |
    +-- DELETE Trade.TradonomiToLiquidityProviderContracts WHERE TradonomiContractID = @ContractID
    |       +-- System versioning -> History.TradonomiToLiquidityProviderContracts
    |
    +-- DELETE Trade.TradonomiContracts WHERE ContractID = @ContractID
    |       +-- System versioning -> History.TradonomiContracts
    |
    v
COMMIT (RETURN 0) or ROLLBACK (RETURN -1) on error
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ContractID | INT | NO | - | CODE-BACKED | The unique identifier of the Tradonomi contract to remove. Maps to Trade.TradonomiContracts.ContractID (PK) and Trade.TradonomiToLiquidityProviderContracts.TradonomiContractID (FK). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ContractID | Trade.TradonomiToLiquidityProviderContracts | Deleter (DELETE) | Removes all LP contract mappings for this Tradonomi contract first. |
| @ContractID | Trade.TradonomiContracts | Deleter (DELETE) | Removes the Tradonomi contract itself after clearing mappings. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by ops/admin tools for Tradonomi contract decommissioning.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RemoveTradonomiContract (procedure)
├── Trade.TradonomiToLiquidityProviderContracts (table)
└── Trade.TradonomiContracts (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TradonomiToLiquidityProviderContracts | Table | DELETE - removes LP mappings for this TradonomiContractID first. |
| Trade.TradonomiContracts | Table | DELETE - removes the Tradonomi contract after clearing mappings. |

### 6.2 Objects That Depend On This

No stored procedure dependents found. Called directly by ops/admin tools.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Remove a Tradonomi contract

```sql
EXEC Trade.RemoveTradonomiContract @ContractID = 101;
-- Returns 0 on success, -1 on failure
```

### 8.2 Verify deletion

```sql
SELECT ContractID, InstrumentID, Description, FromDate, ToDate
FROM Trade.TradonomiContracts WITH (NOLOCK)
WHERE ContractID = 101;
-- Expected: 0 rows

SELECT TradonomiContractID, LiquidityProviderContractID
FROM Trade.TradonomiToLiquidityProviderContracts WITH (NOLOCK)
WHERE TradonomiContractID = 101;
-- Expected: 0 rows
```

### 8.3 Compare with LP-side removal

```sql
-- To remove from the LP contract side instead, use:
-- EXEC Trade.RemoveLiquidityProviderContract @ContractID = {LiquidityProviderContractID};
-- That procedure deletes TradonomiToLiquidityProviderContracts by LiquidityProviderContractID
-- and LiquidityProviderContracts by ContractID.
SELECT tc.ContractID AS TradonomiContractID, tc.InstrumentID, tc.Description,
       ttlp.LiquidityProviderContractID, lpc.LiquidityProviderID
FROM Trade.TradonomiContracts tc WITH (NOLOCK)
JOIN Trade.TradonomiToLiquidityProviderContracts ttlp WITH (NOLOCK) ON ttlp.TradonomiContractID = tc.ContractID
JOIN Trade.LiquidityProviderContracts lpc WITH (NOLOCK) ON lpc.ContractID = ttlp.LiquidityProviderContractID
WHERE tc.ContractID = 101;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RemoveTradonomiContract | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.RemoveTradonomiContract.sql*

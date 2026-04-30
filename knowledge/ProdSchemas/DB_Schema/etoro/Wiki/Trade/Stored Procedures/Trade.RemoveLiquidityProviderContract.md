# Trade.RemoveLiquidityProviderContract

> Removes a liquidity provider contract and all its Tradonomi mappings in a single transaction, decommissioning the LP contract from the price and hedge subsystems.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ContractID (LiquidityProviderContracts.ContractID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.RemoveLiquidityProviderContract decommissions a liquidity provider contract by removing it from both the mapping table (Trade.TradonomiToLiquidityProviderContracts) and the contract registry (Trade.LiquidityProviderContracts) in a single atomic transaction. This ensures that when an LP contract is removed, no orphaned Tradonomi-to-LP mappings remain.

This procedure exists to provide a safe, transactional delete path for LP contracts. Trade.LiquidityProviderContracts and Trade.TradonomiToLiquidityProviderContracts must remain in sync - if the LP contract row is deleted but its mappings remain, the hedge/price systems would have dangling references. The transaction guarantees both deletes succeed together or neither takes effect.

Data flow: Called by ops/admin tools when an LP contract is being retired (e.g., a provider terminates a contract, an instrument rolls over). The ContractID is the PK of Trade.LiquidityProviderContracts (unique, per UQ_ContractID index). Returns 0 on success, -1 on any error with full transaction rollback.

---

## 2. Business Logic

### 2.1 Cascading Delete in a Single Transaction

**What**: Two DELETE statements in a BEGIN TRAN/COMMIT TRAN block with TRY/CATCH ensure both related records are removed atomically.

**Columns/Parameters Involved**: `@ContractID`

**Rules**:
- Step 1: DELETE Trade.TradonomiToLiquidityProviderContracts WHERE LiquidityProviderContractID = @ContractID (removes all Tradonomi contract mappings for this LP contract).
- Step 2: DELETE Trade.LiquidityProviderContracts WHERE ContractID = @ContractID (removes the LP contract itself).
- Order matters: the mapping table is deleted first to avoid FK constraints (if any).
- If either DELETE fails: ROLLBACK TRAN, RETURN -1.
- If both succeed: COMMIT TRAN, RETURN 0.
- Both tables are system-versioned - History tables capture the end-dated rows automatically on delete.

**Diagram**:
```
Trade.RemoveLiquidityProviderContract(@ContractID)
    |
    v
BEGIN TRAN
    |
    +-- DELETE Trade.TradonomiToLiquidityProviderContracts WHERE LiquidityProviderContractID = @ContractID
    |       +-- System versioning -> History.TradonomiToLiquidityProviderContracts
    |
    +-- DELETE Trade.LiquidityProviderContracts WHERE ContractID = @ContractID
    |       +-- System versioning -> History.LiquidityProviderContracts
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
| 1 | @ContractID | INT | NO | - | CODE-BACKED | The unique identifier of the LP contract to remove. Maps to Trade.LiquidityProviderContracts.ContractID (unique per UQ_ContractID constraint) and Trade.TradonomiToLiquidityProviderContracts.LiquidityProviderContractID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ContractID | Trade.TradonomiToLiquidityProviderContracts | Deleter (DELETE) | Removes all Tradonomi-to-LP mappings for this contract first. |
| @ContractID | Trade.LiquidityProviderContracts | Deleter (DELETE) | Removes the LP contract registration after mappings are cleared. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by ops/admin tools for LP contract decommissioning.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RemoveLiquidityProviderContract (procedure)
├── Trade.TradonomiToLiquidityProviderContracts (table)
└── Trade.LiquidityProviderContracts (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TradonomiToLiquidityProviderContracts | Table | DELETE - removes Tradonomi-to-LP mappings for this ContractID first. |
| Trade.LiquidityProviderContracts | Table | DELETE - removes the LP contract itself after clearing mappings. |

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

### 8.1 Remove an LP contract (transactional)

```sql
EXEC Trade.RemoveLiquidityProviderContract @ContractID = 42;
-- Returns 0 on success, -1 on failure
```

### 8.2 Verify deletion

```sql
SELECT ContractID, InstrumentID, LiquidityProviderID, ExchangeID
FROM Trade.LiquidityProviderContracts WITH (NOLOCK)
WHERE ContractID = 42;
-- Expected: 0 rows

SELECT LiquidityProviderContractID, TradonomiContractID
FROM Trade.TradonomiToLiquidityProviderContracts WITH (NOLOCK)
WHERE LiquidityProviderContractID = 42;
-- Expected: 0 rows
```

### 8.3 Check history after deletion

```sql
SELECT ContractID, InstrumentID, LiquidityProviderID, SysStartTime, SysEndTime
FROM History.LiquidityProviderContracts WITH (NOLOCK)
WHERE ContractID = 42
ORDER BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RemoveLiquidityProviderContract | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.RemoveLiquidityProviderContract.sql*

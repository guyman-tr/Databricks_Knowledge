# Trade.SetTradonomiToLPContracts

> Populates the Tradonomi-to-LiquidityProvider contract mapping table by cross-joining Tradonomi contracts with LP contracts on shared InstrumentID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure builds the many-to-many mapping between Tradonomi contracts and Liquidity Provider (LP) contracts by matching them on the instrument they cover. Tradonomi is a trading counterparty/execution venue, and LiquidityProviderContracts define the contracts with hedge/execution providers. For each Tradonomi contract and each LP contract covering the same instrument, a link is created in `Trade.TradonomiToLiquidityProviderContracts`.

This mapping enables the routing engine to know which LP contracts are valid counterparties for each Tradonomi position. Without this procedure's output, the system would not know how to hedge positions placed through Tradonomi.

The procedure is a batch seed operation with no parameters - it reads all existing Tradonomi and LP contracts and creates all pairwise links. It is typically run once during onboarding of new instruments or after bulk contract insertions.

---

## 2. Business Logic

### 2.1 Instrument-Based Contract Cross-Linking

**What**: Links every Tradonomi contract to every LP contract that covers the same instrument.

**Columns/Parameters Involved**: `Trade.TradonomiContracts.ContractID`, `Trade.TradonomiContracts.InstrumentID`, `Trade.LiquidityProviderContracts.ContractID`, `Trade.LiquidityProviderContracts.InstrumentID`

**Rules**:
- JOIN condition: `LPC.InstrumentID = TC.InstrumentID`
- For each (TradonomiContractID, LiquidityProviderContractID) pair sharing an InstrumentID, inserts one row into TradonomiToLiquidityProviderContracts
- No WHERE filter - processes ALL existing contracts in both tables

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | - | This procedure takes no input parameters and produces no output parameters. It is a side-effect-only seed operation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ContractID | Trade.TradonomiContracts | Reader | Read to get all Tradonomi contracts and their InstrumentIDs |
| ContractID | Trade.LiquidityProviderContracts | Reader | Read to get all LP contracts and their InstrumentIDs |
| TradonomiContractID, LiquidityProviderContractID | Trade.TradonomiToLiquidityProviderContracts | Writer | Inserts all matched (Tradonomi, LP) pairs sharing an InstrumentID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetTradonomiToLPContracts (procedure)
├── Trade.TradonomiContracts (table) [read: ContractID + InstrumentID]
├── Trade.LiquidityProviderContracts (table) [read: ContractID + InstrumentID]
└── Trade.TradonomiToLiquidityProviderContracts (table) [inserted into]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TradonomiContracts | Table | Read for ContractID and InstrumentID of all Tradonomi contracts |
| Trade.LiquidityProviderContracts | Table | Read for ContractID and InstrumentID of all LP contracts |
| Trade.TradonomiToLiquidityProviderContracts | Table | Inserted into with (TradonomiContractID, LiquidityProviderContractID) pairs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No callers found in Trade SP folder | - | Likely run as a one-time seed script or during instrument onboarding |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No duplicate guard | Potential issue | No duplicate check - if run multiple times, will insert duplicate rows. Should only be run once or with prior truncation of the target table. |

---

## 8. Sample Queries

### 8.1 Execute the contract mapping seed

```sql
EXEC Trade.SetTradonomiToLPContracts;
```

### 8.2 Verify the resulting mappings

```sql
SELECT TOP 20
    ttlp.TradonomiContractID,
    tc.InstrumentID,
    ttlp.LiquidityProviderContractID,
    lpc.LiquidityProviderID
FROM Trade.TradonomiToLiquidityProviderContracts ttlp WITH (NOLOCK)
INNER JOIN Trade.TradonomiContracts tc WITH (NOLOCK) ON tc.ContractID = ttlp.TradonomiContractID
INNER JOIN Trade.LiquidityProviderContracts lpc WITH (NOLOCK) ON lpc.ContractID = ttlp.LiquidityProviderContractID;
```

### 8.3 Check how many mappings would be generated (dry run)

```sql
SELECT COUNT(*) AS ExpectedMappings
FROM Trade.TradonomiContracts TC WITH (NOLOCK)
JOIN Trade.LiquidityProviderContracts LPC WITH (NOLOCK)
    ON LPC.InstrumentID = TC.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetTradonomiToLPContracts | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetTradonomiToLPContracts.sql*

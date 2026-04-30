# Trade.GetLiguidityProviderContractData

> Returns LP contract data for a Tradonomi contract, either already-assigned contracts (FreeToUse=1) or available-for-assignment contracts (FreeToUse=0). Combines GetLiguidityProviderContractsForTradonomiContract and GetAvailableLiquidityProviderContracts based on the FreeToUse flag. (Note: Function name spelling "Liguidity" is as in DDL.)

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline TVF |
| **Key Identifier** | Returns TABLE: Abbreviation, LiquidityProviderName, FromDate, ToDate, Ticker, ContractID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetLiguidityProviderContractData returns liquidity provider contract details for a given Tradonomi contract. The caller controls whether to get contracts already assigned to that Tradonomi contract (FreeToUse=1) or contracts still available for assignment (FreeToUse=0). When FreeToUse=1, it calls Trade.GetLiguidityProviderContractsForTradonomiContract; when FreeToUse=0, it calls Trade.GetAvailableLiquidityProviderContracts. Both inner functions return the same column set, which this function passes through.

This function exists because instrument setup and LP contract assignment UIs need a single entry point to fetch either "assigned" or "available" LP contracts. The FreeToUse parameter acts as a mode switch. Assigned contracts come from Trade.TradonomiToLiquidityProviderContracts; available contracts are those in LiquidityProviderContracts that match the instrument and date overlap but are not yet in the mapping table.

Data flows: Called by procedures/views that manage Tradonomi-to-LP mappings. Depends on Trade.GetLiguidityProviderContractsForTradonomiContract and Trade.GetAvailableLiquidityProviderContracts.

---

## 2. Business Logic

### 2.1 FreeToUse Mode Switch

**What**: Routes to assigned vs available LP contracts based on @FreeToUse.

**Columns/Parameters Involved**: `@TradonomiContractID`, `@FreeToUse`

**Rules**:
- @FreeToUse = 1: Returns contracts from GetLiguidityProviderContractsForTradonomiContract (already mapped in TradonomiToLiquidityProviderContracts)
- @FreeToUse = 0: Returns contracts from GetAvailableLiquidityProviderContracts (LP contracts not yet assigned to this Tradonomi contract, with date overlap)
- UNION ALL combines both branches; WHERE @FreeToUse = 1 or @FreeToUse = 0 filters to exactly one branch per call

**Diagram**:
```
@FreeToUse = 1  -> GetLiguidityProviderContractsForTradonomiContract
@FreeToUse = 0  -> GetAvailableLiquidityProviderContracts
     |
     v
  Both return: Abbreviation, LiquidityProviderName, FromDate, ToDate, Ticker, ContractID
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TradonomiContractID | int | NO | - | CODE-BACKED | Trade.TradonomiContracts.ContractID. Identifies the Tradonomi contract. |
| 2 | @FreeToUse | int | NO | - | CODE-BACKED | Mode: 1 = return assigned LP contracts; 0 = return available (unassigned) LP contracts. |
| 3 | Abbreviation | varchar | YES | - | CODE-BACKED | Currency abbreviation from Dictionary.Currency (BuyCurrencyID of instrument). From base tables via inner functions. |
| 4 | LiquidityProviderName | varchar | YES | - | CODE-BACKED | Provider instance name from Trade.LiquidityProviders.LiquidityProviderName. |
| 5 | FromDate | datetime | NO | - | CODE-BACKED | Start of LP contract validity. From Trade.LiquidityProviderContracts. |
| 6 | ToDate | datetime | NO | - | CODE-BACKED | End of LP contract validity. From Trade.LiquidityProviderContracts. |
| 7 | Ticker | varchar(150) | YES | - | CODE-BACKED | Provider-specific ticker (e.g., EUR/USD). From Trade.LiquidityProviderContracts. |
| 8 | ContractID | int | NO | - | CODE-BACKED | Trade.LiquidityProviderContracts.ContractID (LP contract surrogate key). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TradonomiContractID | Trade.TradonomiContracts | Lookup | Via inner functions |
| @TradonomiContractID | Trade.GetLiguidityProviderContractsForTradonomiContract | Call | When FreeToUse=1 |
| @TradonomiContractID | Trade.GetAvailableLiquidityProviderContracts | Call | When FreeToUse=0 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetLiguidityProviderContractData (function)
├── Trade.GetLiguidityProviderContractsForTradonomiContract (function)
│     ├── Trade.TradonomiContracts (table)
│     ├── Trade.LiquidityProviderContracts (table)
│     ├── Trade.TradonomiToLiquidityProviderContracts (table)
│     ├── Trade.LiquidityProviders (table)
│     ├── Trade.Instrument (table)
│     └── Dictionary.Currency (table)
└── Trade.GetAvailableLiquidityProviderContracts (function)
      ├── Trade.TradonomiContracts (table)
      ├── Trade.LiquidityProviderContracts (table)
      ├── Trade.TradonomiToLiquidityProviderContracts (table)
      ├── Trade.LiquidityProviders (table)
      ├── Trade.Instrument (table)
      └── Dictionary.Currency (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetLiguidityProviderContractsForTradonomiContract | Function | Called when @FreeToUse=1 |
| Trade.GetAvailableLiquidityProviderContracts | Function | Called when @FreeToUse=0 |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Assigned LP contracts for Tradonomi contract 1
```sql
SELECT * FROM Trade.GetLiguidityProviderContractData(1, 1);
```

### 8.2 Available LP contracts for assignment
```sql
SELECT * FROM Trade.GetLiguidityProviderContractData(1, 0);
```

### 8.3 Both modes for comparison
```sql
SELECT 'Assigned' AS Mode, Abbreviation, LiquidityProviderName, Ticker, ContractID
FROM Trade.GetLiguidityProviderContractData(1, 1)
UNION ALL
SELECT 'Available', Abbreviation, LiquidityProviderName, Ticker, ContractID
FROM Trade.GetLiguidityProviderContractData(1, 0);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetLiguidityProviderContractData | Type: Inline TVF | Source: etoro/etoro/Trade/Functions/Trade.GetLiguidityProviderContractData.sql*

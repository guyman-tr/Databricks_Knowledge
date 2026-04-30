# Trade.TradonomiToLiquidityProviderContracts

> Junction table that maps Tradonomi internal contract IDs to LiquidityProviderContracts ContractIDs, enabling the hedge and price subsystems to resolve which external LP contracts are assigned to each Tradonomi contract for execution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | TradonomiContractID, LiquidityProviderContractID (composite PK) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK) |

---

## 1. Business Meaning

Trade.TradonomiToLiquidityProviderContracts is the many-to-many mapping between eToro's internal Tradonomi contract identifiers (from Trade.TradonomiContracts) and the external liquidity provider contract identifiers (from Trade.LiquidityProviderContracts). A Tradonomi contract represents a contract period for an instrument (e.g., EUR/USD March 2024); a LiquidityProviderContracts row holds the provider-specific ticker and validity for that instrument. This table links them so the system knows: "For Tradonomi contract X, use LP contract Y at FXCM and LP contract Z at FD." Without it, GetAvailableLiquidityProviderContracts could not exclude already-assigned LP contracts, and GetLiguidityProviderContractsForTradonomiContract could not resolve which LP contracts serve a given Tradonomi contract.

This table exists because the same instrument can have multiple Tradonomi contracts (e.g., monthly rollovers) and multiple LP contracts (different providers, different date ranges). The mapping is configurable: ops can assign/detach LP contracts via Trade.SetTradonomiToLPContracts and Trade.UpdateTradonomiToLiquidityProviderContracts. Trade.InsertInstrumentRealTable bulk-loads the mapping during instrument onboarding. Trade.RemoveTradonomiContract and Trade.RemoveLiquidityProviderContract cascade-delete mappings when contracts are removed. System versioning tracks all changes in History.TradonomiToLiquidityProviderContracts.

Data flows: Created by Trade.SetTradonomiToLPContracts, Trade.UpdateTradonomiToLiquidityProviderContracts, and Trade.InsertInstrumentRealTable. Read by Trade.GetAvailableLiquidityProviderContracts (EXCEPT to exclude already-mapped LP contracts) and Trade.GetLiguidityProviderContractsForTradonomiContract. Deleted by Trade.RemoveTradonomiContract (by TradonomiContractID) and Trade.RemoveLiquidityProviderContract (by LiquidityProviderContractID).

---

## 2. Business Logic

### 2.1 Many-to-Many Mapping

**What**: Each row links one TradonomiContractID to one LiquidityProviderContractID. A Tradonomi contract can map to multiple LP contracts (different providers); an LP contract can map to multiple Tradonomi contracts (same ticker, different validity periods).

**Columns/Parameters Involved**: `TradonomiContractID`, `LiquidityProviderContractID`

**Rules**:
- Composite PK (TradonomiContractID, LiquidityProviderContractID) - no duplicate pairs.
- TradonomiContractID references Trade.TradonomiContracts.ContractID (implicit; no declared FK in DDL).
- LiquidityProviderContractID FK to Trade.LiquidityProviderContracts.ContractID.
- Trade.GetAvailableLiquidityProviderContracts returns LP contracts NOT already in this table for the given TradonomiContractID (EXCEPT pattern). Trade.GetLiguidityProviderContractsForTradonomiContract returns LP contracts that ARE in this table.

**Diagram**:
```
TradonomiContractID=1 (EUR/USD active contract)
  |-- LiquidityProviderContractID=101 (FXCM ticker EUR/USD)
  |-- LiquidityProviderContractID=102 (FD ticker EUR/USD)
TradonomiContractID=2 (GBP/USD)
  |-- LiquidityProviderContractID=103
```

### 2.2 System Versioning and Audit

**What**: Temporal table with SysStartTime/SysEndTime and computed audit columns.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- SYSTEM_VERSIONING ON with History.TradonomiToLiquidityProviderContracts. All changes are retained.
- DbLoginName = suser_name(), AppLoginName = CONVERT(varchar(500), context_info()). INSERT trigger touches row to force versioning (no logical update).
- When a mapping is added or removed, history records the prior state.

---

## 3. Data Overview

| TradonomiContractID | LiquidityProviderContractID | SysStartTime | SysEndTime | Meaning |
|--------------------|----------------------------|--------------|------------|---------|
| (empty in sampled environment) | - | - | - | This environment shows 0 rows. In production, rows would link Tradonomi contracts to LP contracts. Example: TradonomiContractID=1 (EUR/USD) -> LiquidityProviderContractID=101 (FXCM), 102 (FD). |

**Selection criteria:** Table had 0 rows in the queried environment. Documented structure and usage from DDL and procedure/function code. In populated environments, typical rows show one Tradonomi contract mapped to 1+ LP contracts per provider.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TradonomiContractID | int | NO | - | CODE-BACKED | References Trade.TradonomiContracts.ContractID. The Tradonomi internal contract. Part of PK. No explicit FK in DDL - implicit relationship. |
| 2 | LiquidityProviderContractID | int | NO | - | CODE-BACKED | FK to Trade.LiquidityProviderContracts.ContractID. The external LP contract (ticker + provider + validity). Part of PK. |
| 3 | DbLoginName | varchar(128) | NO | AS (suser_name()) | CODE-BACKED | Computed: current SQL login. Audit trail. |
| 4 | AppLoginName | varchar(500) | NO | AS (CONVERT(varchar(500),context_info())) | CODE-BACKED | Computed: application context. Audit trail. |
| 5 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System versioning row start. GENERATED ALWAYS AS ROW START. |
| 6 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System versioning row end. GENERATED ALWAYS AS ROW END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TradonomiContractID | Trade.TradonomiContracts | Implicit | Internal Tradonomi contract. No declared FK - referenced by procedures. |
| LiquidityProviderContractID | Trade.LiquidityProviderContracts | FK | External LP contract. FK_TradonomiToLiquidityProviderContracts_LiquidityProviderContracts. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetAvailableLiquidityProviderContracts | TTLPC | JOIN | EXCEPT subquery - excludes already-mapped LP contracts. |
| Trade.GetLiguidityProviderContractsForTradonomiContract | TTLPC | JOIN | Returns LP contracts for given Tradonomi contract. |
| Trade.SetTradonomiToLPContracts | INSERT | Writer | Inserts mapping rows. |
| Trade.UpdateTradonomiToLiquidityProviderContracts | INSERT/DELETE | Modifier | Replaces mapping set. |
| Trade.InsertInstrumentRealTable | INSERT | Writer | Bulk insert during instrument load. |
| Trade.RemoveTradonomiContract | DELETE | Deleter | Removes mappings by TradonomiContractID. |
| Trade.RemoveLiquidityProviderContract | DELETE | Deleter | Removes mappings by LiquidityProviderContractID. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TradonomiToLiquidityProviderContracts (table)
└── Trade.LiquidityProviderContracts (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviderContracts | Table | FK LiquidityProviderContractID -> ContractID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetAvailableLiquidityProviderContracts | Function | JOIN (EXCEPT) |
| Trade.GetLiguidityProviderContractsForTradonomiContract | Function | JOIN |
| Trade.SetTradonomiToLPContracts | Procedure | INSERT |
| Trade.UpdateTradonomiToLiquidityProviderContracts | Procedure | INSERT/DELETE |
| Trade.InsertInstrumentRealTable | Procedure | INSERT |
| Trade.RemoveTradonomiContract | Procedure | DELETE |
| Trade.RemoveLiquidityProviderContract | Procedure | DELETE |
| History.TradonomiToLiquidityProviderContracts | Table | System versioning history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradonomiToLiquidityProviderContracts | CLUSTERED | TradonomiContractID, LiquidityProviderContractID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_TradonomiToLiquidityProviderContracts_LiquidityProviderContracts | FK | LiquidityProviderContractID -> Trade.LiquidityProviderContracts.ContractID |
| DF_TradonomiToLiquidityProviderContracts_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_TradonomiToLiquidityProviderContracts_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |

---

## 8. Sample Queries

### 8.1 Mappings for a Tradonomi contract with LP details
```sql
SELECT TTLPC.TradonomiContractID,
       TTLPC.LiquidityProviderContractID,
       LPC.InstrumentID,
       LPC.LiquidityProviderID,
       LPC.Ticker,
       LPC.FromDate,
       LPC.ToDate
  FROM Trade.TradonomiToLiquidityProviderContracts TTLPC WITH (NOLOCK)
 INNER JOIN Trade.LiquidityProviderContracts LPC WITH (NOLOCK)
         ON LPC.ContractID = TTLPC.LiquidityProviderContractID
 WHERE TTLPC.TradonomiContractID = 1
 ORDER BY TTLPC.LiquidityProviderContractID;
```

### 8.2 Tradonomi contracts with their LP contract count
```sql
SELECT TTLPC.TradonomiContractID,
       TC.InstrumentID,
       TC.Description AS TradonomiDesc,
       COUNT(TTLPC.LiquidityProviderContractID) AS LPContractCount
  FROM Trade.TradonomiToLiquidityProviderContracts TTLPC WITH (NOLOCK)
 INNER JOIN Trade.TradonomiContracts TC WITH (NOLOCK)
         ON TC.ContractID = TTLPC.TradonomiContractID
 GROUP BY TTLPC.TradonomiContractID, TC.InstrumentID, TC.Description
 ORDER BY TTLPC.TradonomiContractID;
```

### 8.3 LP contracts not yet assigned to a Tradonomi contract (available for assignment)
```sql
SELECT LPC.ContractID,
       LPC.InstrumentID,
       LPC.LiquidityProviderID,
       LPC.Ticker
  FROM Trade.LiquidityProviderContracts LPC WITH (NOLOCK)
 WHERE NOT EXISTS (
       SELECT 1
         FROM Trade.TradonomiToLiquidityProviderContracts TTLPC WITH (NOLOCK)
        WHERE TTLPC.LiquidityProviderContractID = LPC.ContractID
       )
   AND LPC.ToDate >= GETUTCDATE();
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.3/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TradonomiToLiquidityProviderContracts | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.TradonomiToLiquidityProviderContracts.sql*

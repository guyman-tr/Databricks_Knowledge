# History.TradonomiToLiquidityProviderContracts

> SQL Server system-versioned temporal history table for Trade.TradonomiToLiquidityProviderContracts - stores superseded mappings linking Tradonomi CFD contracts to specific liquidity provider contracts.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No - stored on [PRIMARY] with PAGE compression |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.TradonomiToLiquidityProviderContracts is the temporal history backing table for Trade.TradonomiToLiquidityProviderContracts, which is a mapping table linking Tradonomi CFD contracts (Trade.TradonomiContracts) to liquidity provider contracts. This establishes which external liquidity provider contract backs each Tradonomi instrument contract.

When a mapping is added, changed, or removed - for example when eToro switches liquidity providers for a Tradonomi contract, or adds an alternative LP - the old mapping is archived here. Combined with History.TradonomiContracts, this enables full reconstruction of the Tradonomi/LP contract relationship at any point in time.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Changes to the Tradonomi-to-LP contract mapping produce history rows with SysStartTime/SysEndTime boundaries.

**Columns/Parameters Involved**: `TradonomiContractID`, `LiquidityProviderContractID`, `SysStartTime`, `SysEndTime`

**Rules**:
- SysStartTime = when this mapping became active
- SysEndTime = when it was superseded
- A LP switch event would: delete old mapping (creating history row) and insert new mapping
- DbLoginName and AppLoginName capture who made the change

---

## 3. Data Overview

Table is typically empty in non-production environments. Production accumulates rows when LP contract mappings change.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TradonomiContractID | INT | NO | - | CODE-BACKED | Identifier of the Tradonomi CFD contract (references Trade.TradonomiContracts.ContractID in source). The Tradonomi contract being mapped to a liquidity provider. |
| 2 | LiquidityProviderContractID | INT | NO | - | CODE-BACKED | Identifier of the external liquidity provider contract that backs the Tradonomi contract. Application-managed reference. |
| 3 | DbLoginName | NVARCHAR(128) | YES | NULL | CODE-BACKED | SQL Server login that made the change (suser_name() at DML time). Preserved for change attribution. |
| 4 | AppLoginName | VARCHAR(500) | YES | NULL | CODE-BACKED | Application login from context_info() at DML time. Identifies the calling service or admin tool. |
| 5 | SysStartTime | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this mapping became active. SQL Server system-versioning managed. |
| 6 | SysEndTime | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this mapping was superseded. Clustered index leading column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TradonomiContractID | Trade.TradonomiContracts | Temporal (inherited) | Historical snapshot of which Tradonomi contract was mapped to an LP. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.TradonomiToLiquidityProviderContracts | SYSTEM_VERSIONING | Temporal parent | Writes superseded mappings here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.TradonomiToLiquidityProviderContracts (table)
  (leaf - temporal history table)
```

### 6.1 Objects This Depends On

No hard DDL dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.TradonomiToLiquidityProviderContracts | Table | Temporal parent - writes superseded mapping rows automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_TradonomiToLiquidityProviderContracts | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (PAGE compression) |

### 7.2 Constraints

None. Temporal history tables have no PK, FK, or CHECK constraints.

---

## 8. Sample Queries

### 8.1 View current LP contract mappings
```sql
SELECT tc.TradonomiContractID, tc.LiquidityProviderContractID, tc.SysStartTime
FROM Trade.TradonomiToLiquidityProviderContracts tc WITH (NOLOCK)
ORDER BY tc.TradonomiContractID;
```

### 8.2 Audit LP mapping history for a specific Tradonomi contract
```sql
SELECT h.TradonomiContractID, h.LiquidityProviderContractID,
       h.SysStartTime, h.SysEndTime, h.DbLoginName
FROM History.TradonomiToLiquidityProviderContracts h WITH (NOLOCK)
WHERE h.TradonomiContractID = 1
ORDER BY h.SysStartTime;
```

### 8.3 View mappings as of a specific date
```sql
SELECT tc.TradonomiContractID, tc.LiquidityProviderContractID
FROM Trade.TradonomiToLiquidityProviderContracts
FOR SYSTEM_TIME AS OF '2024-01-01T00:00:00'
ORDER BY tc.TradonomiContractID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 (temporal - SQL Server managed) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.TradonomiToLiquidityProviderContracts | Type: Table | Source: etoro/etoro/History/Tables/History.TradonomiToLiquidityProviderContracts.sql*

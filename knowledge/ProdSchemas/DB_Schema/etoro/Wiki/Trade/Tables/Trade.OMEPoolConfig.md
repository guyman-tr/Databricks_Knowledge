# Trade.OMEPoolConfig

> ACTIVE CONFIGURATION TABLE. OME = Order Matching Engine. Configures how OME instances are pooled by asset class/region. Each pool has StartID, PoolSize, ExchangeIDs. Three triggers enforce: no duplicate exchange assignments, no overlapping instance ranges, exactly one default pool.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | PoolName (varchar(50), CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | PK only |

---

## 1. Business Meaning

Trade.OMEPoolConfig is an **active configuration table** (not a backup). OME = Order Matching Engine. It configures how OME instances are pooled by asset class or region. Each pool has a PoolName (e.g., FX, EU, NA, AS, CRPT, INDX, CMDTY), a StartID (first OME instance ID in the pool), PoolSize (number of instances), IsDefault (exactly one pool must be default), and ExchangeIDs (comma-separated list of exchange IDs the pool handles). The live database has 7 rows. FX is the default pool (IsDefault=true). Three triggers enforce data integrity: no same ExchangeID in multiple pools, no overlapping StartID+PoolSize ranges, exactly one default pool at all times.

This table drives routing of orders to OME instances based on exchange and asset class. See InstrumentExludedFromOME for instruments excluded from OME.

---

## 2. Business Logic

### 2.1 Pool Configuration

**What**: Each row defines an OME pool (asset class/region) with instance range and exchange assignments.

**Columns/Parameters Involved**: `PoolName`, `StartID`, `PoolSize`, `IsDefault`, `ExchangeIDs`

**Rules**:
- PoolName is the primary key
- StartID = first OME instance ID; PoolSize = number of instances (range StartID to StartID+PoolSize-1)
- ExchangeIDs: comma-separated list; used with STRING_SPLIT in triggers
- IsDefault: exactly one row must have IsDefault=1 (enforced by TRG_OMEPoolConfig_IsDefault)

### 2.2 Trigger Enforcement

**TRG_OMEPoolConfig_ExchangeIDs**: Prevents same ExchangeID in multiple pools (uses STRING_SPLIT).

**TRG_OMEPoolConfig_Instances**: Prevents overlapping StartID+PoolSize ranges across pools.

**TRG_OMEPoolConfig_IsDefault**: Ensures exactly 1 default pool exists at all times.

---

## 3. Data Overview

| PoolName | StartID | PoolSize | IsDefault | ExchangeIDs | Meaning |
|----------|---------|----------|-----------|-------------|---------|
| AS | 41 | 1 | false | 13,21,31 | Asian exchanges |
| CMDTY | 4 | 1 | false | 2 | Commodities |
| CRPT | 11 | 4 | false | 8 | Crypto |
| EU | 31 | 2 | false | 6,7,9,10,11,12,14,15,16,17,22,23,24,30,32,34,35,36,37 | European exchanges |
| FX | 1 | 1 | true | 1 | Forex - DEFAULT pool |
| INDX | 7 | 1 | false | 3 | Indices |
| NA | 21 | 4 | false | 4,5,18,19,20,33 | North America |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Description |
|---|---------|------|----------|---------|-------------|
| 1 | PoolName | varchar(50) | NO | - | Pool identifier (PK): FX, EU, NA, AS, CRPT, INDX, CMDTY |
| 2 | StartID | int | NO | - | First OME instance ID in pool |
| 3 | PoolSize | int | NO | - | Number of OME instances (range length) |
| 4 | IsDefault | bit | NO | - | 1 = default pool; exactly one must exist |
| 5 | ExchangeIDs | varchar(400) | YES | - | Comma-separated list of ExchangeIDs handled by this pool |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExchangeIDs | Dictionary.Exchange (or similar) | Implicit | Exchange IDs in the list |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetExchangeIDsByTime | - | Procedure | Reads pool config for exchange routing |
| Trade.GetExchangeIDsByTimeUTC | - | Procedure | Reads pool config |
| (Other OME routing logic) | - | - | Pool config drives OME instance selection |

---

## 6. Dependencies

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Exchange (or similar) | Table | ExchangeIDs values reference exchanges |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetExchangeIDsByTime | Procedure | OME pool routing |
| Trade.GetExchangeIDsByTimeUTC | Procedure | OME pool routing |
| TRG_OMEPoolConfig_* | Triggers | Data integrity |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_OMEPoolConfig | CLUSTERED | PoolName | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|----------------------|
| PK_OMEPoolConfig | PRIMARY KEY | PoolName |

### 7.3 Triggers

| Trigger | Purpose |
|---------|---------|
| TRG_OMEPoolConfig_ExchangeIDs | Prevents same ExchangeID in multiple pools (STRING_SPLIT) |
| TRG_OMEPoolConfig_Instances | Prevents overlapping StartID+PoolSize ranges |
| TRG_OMEPoolConfig_IsDefault | Ensures exactly 1 default pool |

---

*Generated: 2026-03-14 | Quality: 8.5/10*
*Object: Trade.OMEPoolConfig | Type: Table | Active configuration (7 rows)*

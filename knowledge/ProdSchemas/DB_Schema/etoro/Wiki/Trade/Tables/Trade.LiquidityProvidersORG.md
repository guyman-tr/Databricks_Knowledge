# Trade.LiquidityProvidersORG

> Snapshot/backup of the original Trade.LiquidityProviders table before modification. ORG suffix = "original". Three columns vs current table; preserved for reference/rollback. Contains 6 rows with XML settings.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | LiquidityProviderID (implicit; no PK in DDL) |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

Trade.LiquidityProvidersORG is a snapshot/backup of the original Trade.LiquidityProviders table before it was modified. The "ORG" suffix means "original". The current Trade.LiquidityProviders has LiquidityProviderTypeID, DbLoginName, AppLoginName, SysStartTime, SysEndTime, and system versioning. This backup has only three columns: LiquidityProviderID, LiquidityProviderName, and LiquidityProviderSettingsXML. It lacks the PK constraint and FK to LiquidityProviderType. The live database reports EXISTS with 6 rows; the LiquidityProviderSettingsXML column stores provider-specific connection and routing configuration.

This table exists for reference and rollback purposes when the LiquidityProviders schema was expanded. See Trade.LiquidityProviders for the current registry of concrete LP instances.

---

## 2. Business Logic

### 2.1 Original Schema Preserved

**What**: Pre-migration structure of liquidity provider instances with name and XML settings only.

**Columns/Parameters Involved**: `LiquidityProviderID`, `LiquidityProviderName`, `LiquidityProviderSettingsXML`

**Rules**:
- No LiquidityProviderTypeID - provider type was added later
- No system versioning or audit columns
- LiquidityProviderSettingsXML holds provider-specific connection/routing config

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Live DB | EXISTS |
| Row count | 6 |
| Purpose | Reference snapshot |

**Sample data**: Contains XML settings for 6 liquidity providers. The LiquidityProviderSettingsXML column stores provider-specific connection/routing config.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Description |
|---|---------|------|----------|---------|-------------|
| 1 | LiquidityProviderID | int | NO | - | Provider instance ID (implicit key) |
| 2 | LiquidityProviderName | varchar(50) | YES | - | Human-readable instance name |
| 3 | LiquidityProviderSettingsXML | xml | YES | - | Provider-specific connection/routing config |

---

## 5. Relationships

### 5.1 References To

None (no FKs in DDL).

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.LiquidityProviders | - | Parent | Current table; this is the pre-modification backup |

---

## 6. Dependencies

### 6.1 Objects This Depends On

None declared.

### 6.2 Objects That Depend On This

None. Reference table only.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| (None) | - | - | No indexes in DDL |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|----------------------|
| (None) | - | No PK, FK, or unique constraints |

**Filegroup**: ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

---

*Generated: 2026-03-14 | Quality: 7.0/10*
*Object: Trade.LiquidityProvidersORG | Type: Table | Backup snapshot (6 rows)*

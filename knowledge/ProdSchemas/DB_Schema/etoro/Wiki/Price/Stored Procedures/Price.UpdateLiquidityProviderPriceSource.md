# Price.UpdateLiquidityProviderPriceSource

> Updates the price source mapping for an existing liquidity provider in Price.LiquidityProviderPriceSource after validating both the mapping and the new price source exist, with optional application-level audit attribution.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates Price.LiquidityProviderPriceSource WHERE LiquidityProviderID; returns enriched record |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.UpdateLiquidityProviderPriceSource changes which exchange or data venue is declared as the price source for a specific liquidity provider. A "liquidity provider" (LP) is a broker or trading entity whose prices eToro accepts; the "price source" (Dictionary.PriceSourceName) is the exchange or data venue from which those prices originate - for example, NASDAQ (ID=3), LSE (ID=5), or eToro's internal pricing (ID=0).

This procedure updates the `PriceSourceID` in `Price.LiquidityProviderPriceSource` for a given LP, allowing administrators to correct or change the attributed exchange without deleting and re-inserting the mapping. Two validations run before the update: the LP must already have a mapping row, and the new PriceSourceID must exist in the dictionary. An optional `@AppLoginName` parameter enables audit attribution by setting SQL Server's CONTEXT_INFO before the DML, which is then captured by the `AppLoginName` computed column.

After the update, the procedure returns the updated record enriched with human-readable names from Trade.LiquidityProviders and Dictionary.PriceSourceName, giving the caller confirmation of what was changed and what it now reads as.

---

## 2. Business Logic

### 2.1 Two-Guard Validation Before Update

**What**: Checks that (1) the LP already has a mapping row and (2) the requested PriceSourceID is valid.

**Columns/Parameters Involved**: `@LiquidityProviderID`, `@PriceSourceID`

**Rules**:
- Guard 1: IF NOT EXISTS (Price.LiquidityProviderPriceSource WHERE LiquidityProviderID=@LiquidityProviderID) -> RAISERROR('Mapping for LiquidityProviderID %d does not exist', 16, 1)
- Guard 2: IF NOT EXISTS (Dictionary.PriceSourceName WHERE PriceSourceID=@PriceSourceID) -> RAISERROR('PriceSourceID %d does not exist in Dictionary.PriceSourceName', 16, 1)
- Both guards use parameterized RAISERROR (includes the offending ID value in the error message)
- If either guard fails: RETURN immediately, no DML executed

### 2.2 Optional Application Audit Identity

**What**: When @AppLoginName is provided, sets SQL Server CONTEXT_INFO to enable application-level audit tracking.

**Columns/Parameters Involved**: `@AppLoginName`

**Rules**:
- IF @AppLoginName != '': DECLARE @OpsUserInfo VARBINARY(128) = CAST(@AppLoginName AS VARBINARY(128)); SET CONTEXT_INFO @OpsUserInfo
- The Price.LiquidityProviderPriceSource table has a computed column `AppLoginName = CAST(context_info() AS VARCHAR(500))` which captures this value on DML
- The temporal versioning row in History.LiquidityProviderPriceSource will store this AppLoginName value
- If @AppLoginName is '' (default), CONTEXT_INFO is not set and AppLoginName computed column will be NULL or retain previous value

### 2.3 Enriched Return Record

**What**: After the update, returns the mapping row joined with provider and source name tables for human-readable confirmation.

**Columns/Parameters Involved**: `LiquidityProviderID`, `PriceSourceID`, `LiquidityProviderName`, `PriceSourceName`

**Rules**:
- SELECT lp.LiquidityProviderID, lp.PriceSourceID, lprov.LiquidityProviderName, psn.Name AS PriceSourceName
- FROM LiquidityProviderPriceSource JOIN Trade.LiquidityProviders JOIN Dictionary.PriceSourceName
- Returns exactly 1 row (PK on LiquidityProviderID guarantees uniqueness)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityProviderID | INT | NOT NULL | - | CODE-BACKED | The liquidity provider whose price source attribution is being changed. Must already have a row in Price.LiquidityProviderPriceSource; raises error if mapping does not exist. FK maps to Trade.LiquidityProviders.LiquidityProviderID. |
| 2 | @PriceSourceID | INT | NOT NULL | - | CODE-BACKED | The new price source to assign to this LP. Validated against Dictionary.PriceSourceName. Values include: 0=eToro, 1=Xignite, 2=CME, 3=NASDAQ, 4=Chi-Ex, 5=LSE PLC, 6=Xetra, 7=Euronext, and others up to 30=Blue Ocean. See Dictionary.PriceSourceName for full list. |
| 3 | @AppLoginName | VARCHAR(50) | YES | '' | CODE-BACKED | Optional application user identity for audit. If non-empty, sets SQL Server CONTEXT_INFO before the UPDATE, which is then captured by Price.LiquidityProviderPriceSource.AppLoginName computed column and persisted in the temporal history row. Typically the authenticated user's login from the calling service. |

**Return columns:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| R1 | LiquidityProviderID | INT | CODE-BACKED | The LP ID that was updated. |
| R2 | PriceSourceID | INT | CODE-BACKED | The new PriceSourceID now assigned to this LP. |
| R3 | LiquidityProviderName | VARCHAR | CODE-BACKED | Human-readable LP name from Trade.LiquidityProviders. |
| R4 | PriceSourceName | VARCHAR | CODE-BACKED | Human-readable price source name from Dictionary.PriceSourceName. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LiquidityProviderID | Price.LiquidityProviderPriceSource | MODIFIER | Updates PriceSourceID for matching LP row; also used in guard 1 existence check |
| @PriceSourceID | Dictionary.PriceSourceName | Lookup (validation) | Guard 2: new price source must exist in dictionary |
| @LiquidityProviderID (return) | Trade.LiquidityProviders | READER | JOIN in return query to get LiquidityProviderName |

### 5.2 Referenced By (other objects point to this)

No SQL callers found in the etoro SSDT repo. Called externally by the pricing administration API.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.UpdateLiquidityProviderPriceSource (procedure)
├── Price.LiquidityProviderPriceSource (table - guard check + UPDATE target + return source)
├── Dictionary.PriceSourceName (table - validation + return JOIN)
└── Trade.LiquidityProviders (table - return JOIN for LiquidityProviderName)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.LiquidityProviderPriceSource | Table | Guard 1 existence check; UPDATE PriceSourceID; SELECT for return |
| Dictionary.PriceSourceName | Table | Guard 2 validation; JOIN for PriceSourceName in return |
| Trade.LiquidityProviders | Table | JOIN in return query for LiquidityProviderName |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| LP mapping guard | Validation | LP must already have a mapping; procedure does not INSERT, only UPDATE |
| Price source guard | Validation | New PriceSourceID must be in Dictionary.PriceSourceName; prevents invalid source assignments |
| Audit via CONTEXT_INFO | Audit | Optional @AppLoginName sets CONTEXT_INFO captured by AppLoginName computed column on LiquidityProviderPriceSource |
| Temporal versioning | Side effect | UPDATE triggers temporal versioning on LiquidityProviderPriceSource - old row archived to History.LiquidityProviderPriceSource |
| SET NOCOUNT ON | Performance | Suppresses "rows affected" messages |

---

## 8. Sample Queries

### 8.1 Update LP 5 to use NASDAQ as its price source

```sql
EXEC Price.UpdateLiquidityProviderPriceSource
    @LiquidityProviderID = 5,
    @PriceSourceID = 3,         -- 3 = NASDAQ
    @AppLoginName = 'admin@etoro.com';
-- Returns: LiquidityProviderID=5, PriceSourceID=3, LiquidityProviderName=..., PriceSourceName='NASDAQ'
```

### 8.2 Update LP 5 to eToro internal pricing (no audit user)

```sql
EXEC Price.UpdateLiquidityProviderPriceSource
    @LiquidityProviderID = 5,
    @PriceSourceID = 0;         -- 0 = eToro (default, no @AppLoginName needed)
```

### 8.3 View all LP-to-price-source mappings after the update

```sql
SELECT
    lp.LiquidityProviderID,
    lprov.LiquidityProviderName,
    lp.PriceSourceID,
    psn.Name AS PriceSourceName,
    lp.AppLoginName AS LastUpdatedBy,
    lp.SysStartTime AS UpdatedAt
FROM Price.LiquidityProviderPriceSource lp WITH (NOLOCK)
JOIN Trade.LiquidityProviders lprov WITH (NOLOCK)
    ON lprov.LiquidityProviderID = lp.LiquidityProviderID
JOIN Dictionary.PriceSourceName psn WITH (NOLOCK)
    ON psn.PriceSourceID = lp.PriceSourceID
ORDER BY lp.LiquidityProviderID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Price.UpdateLiquidityProviderPriceSource | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.UpdateLiquidityProviderPriceSource.sql*

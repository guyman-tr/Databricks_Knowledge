# Hedge.ProviderExternalTags

> Static and dynamic FIX protocol custom tag configuration table, defining per-provider (and optionally per-account) custom field values that the hedge engine appends to FIX order messages sent to liquidity providers.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (ProviderTypeID, TagID, LiquidityAccountID, Mode) - 4-column composite PK CLUSTERED |
| **Partition** | No (on [DICTIONARY] filegroup) |
| **Indexes** | 1 (PK only) |
| **Versioning** | SYSTEM_VERSIONING -> History.ProviderExternalTags |

---

## 1. Business Meaning

`Hedge.ProviderExternalTags` defines custom FIX message fields (tags) that the hedge engine includes when submitting orders to each liquidity provider. FIX protocol supports custom/non-standard tags (numbers above 5000 or in custom ranges) that providers use for routing, account identification, algorithm selection, and other provider-specific metadata.

The 4-column PK enables two dimensions of per-tag configuration:
- **Per account**: `LiquidityAccountID` = 0 means the tag applies to all accounts for that provider; a specific ID targets one account.
- **Per mode**: `Mode` distinguishes between `Static` (fixed literal value sent as-is) and `Dynamic` (template value with runtime substitution, e.g., `{CID}` = resolved to client ID at order time).

This means the same tag (e.g., TagID=59) can exist twice for the same provider/account: once with `Mode=Static` (default fallback value) and once with `Mode=Dynamic` (runtime-resolved value). Both rows are loaded; the engine applies the appropriate mode based on context.

**Current data** (11 rows, 4 providers):
- **FD/ProviderTypeID=3** (5 rows, LiquidityAccountID=354541): TagID=59 in both Static("1") and Dynamic("{CID}") modes + custom tags 9002("1"), 9003("2"), 9004("TWAP")
- **APEX/ProviderTypeID=40** (1 row, LiquidityAccountID=14): TagID=100 = "MNGDFTE" (managed futures tag)
- **Talos Hidden Road/ProviderTypeID=333** (1 row, LiquidityAccountID=0): TagID=100 = "route28"
- **OMS/ProviderTypeID=10002** (4 rows, LiquidityAccountID=2152 and 2150): TagID=10001 and 10115 each in Static + Dynamic modes

**Reader**: `GetProviderExternalTags(@ProviderTypeID)` - returns ProviderTypeID, TagID, TagValue, LiquidityAccountID for a specific provider. Note: the `Mode` column is NOT returned by the reader procedure.

---

## 2. Business Logic

### 2.1 Static vs Dynamic Tag Values

**What**: `Mode` controls how `TagValue` is interpreted when building FIX messages.

**Columns/Parameters Involved**: `Mode`, `TagValue`

**Rules**:
- DEFAULT 'Static': TagValue is sent literally in the FIX message (e.g., "MNGDFTE", "TWAP", "1")
- 'Dynamic': TagValue is a template placeholder resolved at order time (e.g., `{CID}` = resolved to the eToro client ID for the order being hedged)
- A tag can have both a Static row (fallback) and a Dynamic row (preferred) for the same provider/account/tagID
- The CK_ProviderExternalTags_Mode constraint is named as a check constraint but is implemented as a DEFAULT - it enforces 'Static' as the default when Mode is not specified

### 2.2 Account-Scoped vs Provider-Wide Tags

**What**: `LiquidityAccountID` scopes a tag to either all accounts or a specific account for a provider.

**Columns/Parameters Involved**: `LiquidityAccountID`

**Rules**:
- DEFAULT 0: Tag applies to ALL accounts for this provider (global scope)
- Non-zero: Tag applies only to the specified liquidity account (account-specific scope)
- Example: Talos Hidden Road (333) has LiquidityAccountID=0 (global), OMS (10002) has account-specific tags (2150 for DMA Virtu, 2152 for DMA JPM)

### 2.3 Custom FIX Tags by Provider

**What**: Different providers require different custom FIX fields for proper order routing and identification.

**Rules**:
- Standard FIX tags (below 5000) are handled by the standard FIX engine; tags in this table are the non-standard/custom additions
- FD provider: TagID=9002-9004 are FD-specific custom tags for order routing (values: "1", "2", "TWAP")
- APEX provider: TagID=100 = "MNGDFTE" (managed futures execution routing code)
- Talos Hidden Road: TagID=100 = "route28" (routing destination tag)
- OMS provider: TagID=10001 (ClientID injection), 10115 (another client identifier field)
- `{CID}` placeholder = the eToro client/customer ID injected at order submission time

---

## 3. Data Overview

| ProviderTypeID | Provider Name | LiquidityAccountID | TagID | TagValue | Mode | Meaning |
|---|---|---|---|---|---|---|
| 3 | FD | 354541 | 59 | {CID} | Dynamic | Client ID tag - resolved at runtime |
| 3 | FD | 354541 | 59 | 1 | Static | Client ID tag - static fallback |
| 3 | FD | 354541 | 9002 | 1 | Static | Custom routing tag |
| 3 | FD | 354541 | 9003 | 2 | Static | Custom routing tag |
| 3 | FD | 354541 | 9004 | TWAP | Static | Algorithm type (Time-Weighted Average Price) |
| 40 | APEX | 14 | 100 | MNGDFTE | Static | Managed futures execution route |
| 333 | Talos Hidden Road | 0 | 100 | route28 | Static | Routing destination identifier |
| 10002 | OMS | 2152 | 10001 | {CID} | Dynamic | Client ID for JPM DMA account |
| 10002 | OMS | 2152 | 10001 | ETORO | Static | Client ID static fallback (JPM) |
| 10002 | OMS | 2150 | 10115 | {CID} | Dynamic | Client ID for Virtu DMA account |
| 10002 | OMS | 2150 | 10115 | ranlev | Static | Client ID static fallback (Virtu) |

Total: 11 rows. History tracked via SYSTEM_VERSIONING.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderTypeID | int | NO | - | CODE-BACKED | The liquidity provider type this tag applies to. Part of 4-column PK. Implicit reference to Trade.LiquidityProviderType (no FK constraint). 4 providers in use: FD(3), APEX(40), Talos Hidden Road(333), OMS(10002). |
| 2 | TagID | int | NO | - | CODE-BACKED | FIX protocol tag number for the custom field. Part of 4-column PK. Standard FIX tags and custom/proprietary tag numbers (e.g., 59=TimeInForce-area custom, 100=routing, 9002-9004=FD custom, 10001/10115=OMS). |
| 3 | TagValue | varchar(500) | NO | - (required) | VERIFIED | Value to set for the FIX tag. Static mode: literal value (e.g., "TWAP", "route28"). Dynamic mode: template with placeholders (e.g., "{CID}" = resolved to eToro client ID at order submission time). |
| 4 | LiquidityAccountID | int | NO | 0 | VERIFIED | Account scope for this tag. DEFAULT 0 = applies to all accounts for this provider. Non-zero = applies to one specific liquidity account. Part of 4-column PK enabling per-account tag overrides. |
| 5 | Mode | varchar(10) | NO | 'Static' | VERIFIED | Tag resolution mode. 'Static' = TagValue sent as-is. 'Dynamic' = TagValue is a template resolved at runtime. DEFAULT 'Static'. Part of 4-column PK - same provider/account/tagID can have both Static and Dynamic rows simultaneously. |
| 6 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 7 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |
| 8 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 9 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.ProviderExternalTags. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints. ProviderTypeID and LiquidityAccountID are application-managed without explicit FK enforcement.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetProviderExternalTags | ProviderTypeID | READER | Returns tags for a specific provider; does NOT return Mode column |
| History.ProviderExternalTags | (temporal) | Temporal History | Stores historical row versions via SYSTEM_VERSIONING |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ProviderExternalTags (table)
  (no FK dependencies - leaf table)
```

---

### 6.1 Objects This Depends On

No FK dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetProviderExternalTags | Stored Procedure | READER - loads custom FIX tags per provider on hedge engine startup |
| History.ProviderExternalTags | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_providerExternalTags | CLUSTERED PK | ProviderTypeID ASC, TagID ASC, LiquidityAccountID ASC, Mode ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_providerExternalTags | PRIMARY KEY | (ProviderTypeID, TagID, LiquidityAccountID, Mode) - one value per tag per mode per account per provider |
| DF_LiquidityAccountID | DEFAULT | LiquidityAccountID = 0 (global scope) |
| CK_ProviderExternalTags_Mode | DEFAULT | Mode = 'Static' (named as CHECK but implemented as DEFAULT) |
| DF_ProviderExternalTags_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_ProviderExternalTags_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.ProviderExternalTags |

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| Tr_T_ProviderExternalTags_INSERT | INSERT | No-op self-UPDATE (joins on ProviderTypeID+TagID only - not full 4-column PK) to force temporal history capture on INSERT. Note: JOIN condition uses only 2 of 4 PK columns; may touch sibling rows with same ProviderTypeID/TagID but different LiquidityAccountID/Mode. |

---

## 8. Sample Queries

### 8.1 View all custom FIX tags for a provider

```sql
-- Matches Hedge.GetProviderExternalTags(@ProviderTypeID=10002)
SELECT
    pet.ProviderTypeID,
    pet.TagID,
    pet.TagValue,
    pet.LiquidityAccountID,
    pet.Mode  -- Note: NOT returned by the stored proc
FROM Hedge.ProviderExternalTags pet WITH (NOLOCK)
WHERE pet.ProviderTypeID = 10002  -- OMS
ORDER BY pet.LiquidityAccountID, pet.TagID, pet.Mode
```

### 8.2 Find all Dynamic (runtime-resolved) tags

```sql
SELECT
    pet.ProviderTypeID,
    pet.TagID,
    pet.TagValue AS Template,
    pet.LiquidityAccountID
FROM Hedge.ProviderExternalTags pet WITH (NOLOCK)
WHERE pet.Mode = 'Dynamic'
ORDER BY pet.ProviderTypeID, pet.TagID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.ProviderExternalTags | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ProviderExternalTags.sql*

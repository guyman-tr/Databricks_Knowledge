# Trade.GetProvider

> Read-only view of active trading execution providers, excluding ProviderID 0 and inactive providers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | ProviderID (from Trade.Provider) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetProvider exposes the subset of Trade.Provider representing active execution venues (e.g., Tradonomi, Interactive Brokers) that route customer CFD positions to backend liquidity. The view filters out ProviderID 0 (system placeholder) and inactive providers (IsActive = 0), so callers receive only providers that are currently in use for trading.

The view exists so procedures and APIs can query "which providers are live?" without duplicating the exclusion logic. Used by systems that need to list or resolve active execution providers.

---

## 2. Business Logic

### 2.1 Active Providers Only

**What**: Only providers with IsActive = 1 are exposed.

**Columns/Parameters Involved**: `IsActive`

**Rules**:
- WHERE TPRV.IsActive = 1
- Inactive providers are excluded from the view

### 2.2 Exclusion of System Placeholder

**What**: ProviderID 0 is a system placeholder and is filtered out.

**Columns/Parameters Involved**: `ProviderID`

**Rules**:
- WHERE TPRV.ProviderID != 0
- Ensures only real execution providers appear

---

## 3. Data Overview

| ProviderID | ProviderName | Commission | IsIB | IsActive | Meaning |
|------------|--------------|------------|------|----------|---------|
| 1 | TRADONOMI | 0 | 0 | 1 | Primary CFD execution provider. Standard flow, zero commission. Configuration holds LotSize, DefaultLeverage, WebLink, and connection settings. |

**Selection criteria**: Live MCP sample. Single active provider (Tradonomi) in staging; production may have additional providers (e.g., IB).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | CODE-BACKED | Primary key from Trade.Provider. Identifies the execution provider. |
| 2 | ProviderName | varchar(20) | NO | - | CODE-BACKED | Display name (e.g., TRADONOMI). Alias for Name. |
| 3 | Commission | dbo.dtPercentage | NO | - | CODE-BACKED | Commission percentage. 0 = no commission. |
| 4 | Configuration | xml | YES | - | CODE-BACKED | Provider-specific XML (LotSize, DefaultLeverage, AvailableBet, UserName, WebLink, etc.). |
| 5 | IsIB | bit | NO | - | CODE-BACKED | 1 = Introducing Broker - special withdrawal/cashout handling; 0 = standard provider. |
| 6 | IsActive | bit | NO | - | CODE-BACKED | Always 1 in view output (filtered). Indicates provider is active. |
| 7 | Description | varchar(100) | YES | - | NAME-INFERRED | Optional description of the provider. |
| 8 | Passport | timestamp | NO | - | CODE-BACKED | Row version for optimistic concurrency. From Trade.Provider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|----------------|-------------------|-------------|
| All columns | Trade.Provider | Base table | Single-table view; direct column mapping |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No direct procedure/view references in etoro/etoro/**/*.sql; may be used by external consumers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetProvider (view)
└── Trade.Provider (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Provider | Table | FROM - single source; WHERE ProviderID != 0 AND IsActive = 1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None) | - | No references found; view may be used by APIs or external systems |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all active providers
```sql
SELECT ProviderID, ProviderName, Commission, IsIB, IsActive
  FROM Trade.GetProvider WITH (NOLOCK)
 ORDER BY ProviderID;
```

### 8.2 Get provider configuration for Tradonomi
```sql
SELECT ProviderID, ProviderName, Configuration, Commission
  FROM Trade.GetProvider WITH (NOLOCK)
 WHERE ProviderName = 'TRADONOMI';
```

### 8.3 List IB providers (special withdrawal routing)
```sql
SELECT ProviderID, ProviderName, Commission
  FROM Trade.GetProvider WITH (NOLOCK)
 WHERE IsIB = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 6/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetProvider | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetProvider.sql*

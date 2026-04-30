# Trade.GetLiquidityProviders

> Joins liquidity provider instances with their type definitions to expose provider names, settings XML, and pluggable configurations for hedging and price feeds.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | LiquidityProviderID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetLiquidityProviders is the primary view for resolving liquidity provider instances to their type configurations. It joins Trade.LiquidityProviders (concrete instances such as "FXCM Real", "FD Production") with Trade.LiquidityProviderType (type definitions with assembly and class configuration). The result exposes both instance-level settings (LiquidityProviderSettingsXML) and type-level settings (TypeSettingsXML, Name) in a single row per provider.

This view exists so hedge subsystems, NBBO (National Best Bid Offer) services, and configuration resolvers can get a complete provider picture without repeating the JOIN. Without it, callers would need to replicate the LiquidityProviders + LiquidityProviderType join. NBBOUser has explicit GRANT SELECT on this view for price feed resolution.

Data flows: The view reads Trade.LiquidityProviders and Trade.LiquidityProviderType with NOLOCK. All provider instances with a valid LiquidityProviderTypeID appear; orphaned instances (NULL type) are excluded by the INNER JOIN.

---

## 2. Business Logic

### 2.1 Instance-to-Type Resolution

**What**: Each liquidity provider instance belongs to exactly one provider type. The view resolves the type name and type-level XML.

**Columns/Parameters Involved**: `LiquidityProviderID`, `LiquidityProviderTypeID`, `Name`, `TypeSettingsXML`

**Rules**:
- INNER JOIN on TLP.LiquidityProviderTypeID = TLPT.LiquidityProviderTypeID
- TLPT.Name: Human-readable type (e.g., eToro, FXCM, BMFN, FD)
- TLPT.TypeSettingsXML: Assembly and class references for price provider, PCS, execution client, hedging provider
- TLP.LiquidityProviderSettingsXML: Instance-specific overrides (can extend or override type settings)

**Diagram**:
```
Trade.LiquidityProviders (instance) --> Trade.LiquidityProviderType (type)
  FXCM Real (LiquidityProviderID=2) --> FXCM (Name, TypeSettingsXML)
  FD Production (4) --> FD (Name, TypeSettingsXML)
```

### 2.2 No Filter on Provider State

**What**: The view returns all provider instances that have a valid type. There is no WHERE clause - no filtering by enabled/disabled.

**Columns/Parameters Involved**: N/A

**Rules**:
- All rows from Trade.LiquidityProviders that match a row in Trade.LiquidityProviderType are returned
- Legacy "Obsolete! Use Hedge Account" placeholder rows may appear if they have a valid type

---

## 3. Data Overview

| LiquidityProviderID | LiquidityProviderName | LiquidityProviderTypeID | Name | Meaning |
|--------------------|----------------------|-------------------------|------|---------|
| 0 | ACT | 1 | BMFN | BMFN-type provider. ACT used for forex hedging. |
| 1 | Log files | 0 | eToro | eToro internal. Log files indicate internal/logging use. |
| 2 | FXCM Real | 2 | FXCM | FXCM production for real forex hedging. |
| 3 | FXCM Demo | 2 | FXCM | FXCM demo - same type as FXCM Real. |
| 4 | FD RealStream Production REAL 208.100.16.161 | 3 | FD | First Derivatives production instance. |

**Selection criteria**: Representative of external providers (BMFN, FXCM, FD) and internal (eToro). Live sample shows variety of LiquidityProviderSettingsXML (XML) and TypeSettingsXML.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderID | int | NO | - | CODE-BACKED | PK from Trade.LiquidityProviders. Unique identifier for provider instance. |
| 2 | LiquidityProviderName | varchar(250) | YES | - | CODE-BACKED | Instance name (e.g., FXCM Real, FD RealStream Production REAL 208.100.16.161). From TLP. |
| 3 | LiquidityProviderSettingsXML | xml | YES | - | CODE-BACKED | Instance-specific XML settings. Can override type-level TypeSettingsXML. From TLP. |
| 4 | LiquidityProviderTypeID | int | YES | - | CODE-BACKED | FK to Trade.LiquidityProviderType. Provider type: 0=eToro, 1=BMFN, 2=FXCM, 3=FD. From TLP. |
| 5 | Name | varchar(50) | NO | - | CODE-BACKED | Provider type name (e.g., FXCM, BMFN) from Trade.LiquidityProviderType. From TLPT. |
| 6 | TypeSettingsXML | xml | YES | - | CODE-BACKED | Type-level pluggable configuration: assembly/class for price, PCS, execution, hedging. From TLPT. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderTypeID | Trade.LiquidityProviderType | FK/INNER JOIN | Each instance references its type for Name and TypeSettingsXML |
| (base) | Trade.LiquidityProviders | FROM | Primary source of provider instance data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| NBBOUser | GRANT SELECT | Permission | NBBOUser has SELECT on this view for price/quote resolution |
| Trade.GetLiquidityAccountsDetails | - | JOIN | Resolves provider details in account listings |
| Trade.GetInstrumentRateSources | - | JOIN | Resolves provider name for rate source display |
| Trade.GetLiquidityProviderContracts | - | JOIN | Returns contracts with provider name |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetLiquidityProviders (view)
├── Trade.LiquidityProviders (table)
└── Trade.LiquidityProviderType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviders | Table | FROM - base provider instance data |
| Trade.LiquidityProviderType | Table | INNER JOIN - type name and TypeSettingsXML |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| NBBOUser | Permission | GRANT SELECT |
| Trade.GetLiquidityAccountsDetails | View | JOIN for provider resolution |
| Trade.GetInstrumentRateSources | View | JOIN for rate source display |
| Trade.GetLiquidityProviderContracts | View | JOIN for contract listings |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

### 7.3 JOIN Conditions

- TLP.LiquidityProviderTypeID = TLPT.LiquidityProviderTypeID (INNER)

---

## 8. Sample Queries

### 8.1 List all liquidity providers with type names
```sql
SELECT LiquidityProviderID,
       LiquidityProviderName,
       Name AS ProviderTypeName,
       LiquidityProviderTypeID
  FROM Trade.GetLiquidityProviders WITH (NOLOCK)
 ORDER BY LiquidityProviderTypeID, LiquidityProviderID;
```

### 8.2 Resolve provider by ID for NBBO/hedge use
```sql
SELECT LiquidityProviderID,
       LiquidityProviderName,
       Name AS ProviderTypeName,
       LiquidityProviderSettingsXML,
       TypeSettingsXML
  FROM Trade.GetLiquidityProviders WITH (NOLOCK)
 WHERE LiquidityProviderID = 2;
```

### 8.3 All FXCM instances
```sql
SELECT LiquidityProviderID,
       LiquidityProviderName,
       LiquidityProviderSettingsXML
  FROM Trade.GetLiquidityProviders WITH (NOLOCK)
 WHERE Name = 'FXCM';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 6/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetLiquidityProviders | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetLiquidityProviders.sql*

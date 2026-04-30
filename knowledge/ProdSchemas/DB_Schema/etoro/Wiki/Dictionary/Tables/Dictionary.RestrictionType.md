# Dictionary.RestrictionType

> Lookup table defining 4 CopyTrading settlement restriction levels — AllowedAll, RestrictedReal, RestrictedCfd, and RestrictedAll — controlling which asset types a copier can trade.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RestrictionTypeID (TINYINT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.RestrictionType defines the levels of trading restrictions applied to CopyTrading settlement configurations. When a copy relationship is set up, the system may restrict which types of assets (real stocks vs CFDs) can be copied based on regulatory requirements, customer classification, or instrument availability.

This table is consumed by Trade.CopyTradeSettlementRestrictions (stores restrictions per copy relationship), managed by Trade.InsertCopyTradeSettlementRestrictions/Trade.AddCopyTradeSettlementRestriction/Trade.DeleteCopyTradeSettlementRestrictions*, and read by Trade.GetSmartCopyRestrictions for real-time copy execution decisions. Also referenced by Dictionary.SettlementRestrictions and reporting (dbo.SSRS_SmartCopyRestrictions).

---

## 2. Business Logic

### 2.1 Restriction Levels

**What**: Each level defines which settlement types are restricted in a copy relationship.

**Columns/Parameters Involved**: `RestrictionTypeID`, `RestrictionTypeName`

**Rules**:
- **0 = AllowedAll** — No restrictions. The copier can trade both real stocks and CFDs, mirroring the copied trader exactly.
- **1 = RestrictedReal** — Real stock trading is restricted. The copier can only execute CFD copies, even if the copied trader opens real stock positions.
- **2 = RestrictedCfd** — CFD trading is restricted. The copier can only execute real stock copies.
- **3 = RestrictedAll** — All trading restricted. The copy relationship is effectively paused.
- Restrictions are applied per copy relationship through Trade.CopyTradeSettlementRestrictions.

**Diagram**:
```
CopyTrading Restriction Types
├── 0 = AllowedAll      → Real ✓  CFD ✓
├── 1 = RestrictedReal   → Real ✗  CFD ✓
├── 2 = RestrictedCfd    → Real ✓  CFD ✗
└── 3 = RestrictedAll    → Real ✗  CFD ✗
```

---

## 3. Data Overview

| RestrictionTypeID | RestrictionTypeName | Meaning |
|---|---|---|
| 0 | AllowedAll | No restrictions — both real stocks and CFDs can be copied. |
| 1 | RestrictedReal | Real stock trading restricted — only CFD positions are copied. |
| 2 | RestrictedCfd | CFD trading restricted — only real stock positions are copied. |
| 3 | RestrictedAll | All trading restricted — copy relationship effectively paused. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RestrictionTypeID | tinyint | NO | - | VERIFIED | Primary key. 0=AllowedAll, 1=RestrictedReal, 2=RestrictedCfd, 3=RestrictedAll. Referenced by Trade.CopyTradeSettlementRestrictions. |
| 2 | RestrictionTypeName | varchar(50) | NO | - | VERIFIED | Human-readable restriction level name. Used in BackOffice and reporting UI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CopyTradeSettlementRestrictions | RestrictionTypeID | Implicit | Active copy relationship restrictions |
| History.CopyTradeSettlementRestrictions | RestrictionTypeID | Implicit | Historical restriction audit trail |
| Dictionary.SettlementRestrictions | RestrictionTypeID | Implicit | Settlement restriction definitions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CopyTradeSettlementRestrictions | Table | Stores restriction per copy relationship |
| History.CopyTradeSettlementRestrictions | Table | Historical audit |
| Trade.InsertCopyTradeSettlementRestrictions | Stored Procedure | Writer — creates restrictions |
| Trade.AddCopyTradeSettlementRestriction | Stored Procedure | Writer — adds restriction |
| Trade.DeleteCopyTradeSettlementRestrictions* | Stored Procedure | Deleter — removes restrictions |
| Trade.GetSmartCopyRestrictions | Stored Procedure | Reader — real-time restriction check |
| dbo.SSRS_SmartCopyRestrictions | Stored Procedure | Reader — SSRS reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RestrictionType | CLUSTERED PK | RestrictionTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RestrictionType | PRIMARY KEY | Unique restriction level identifier |

---

## 8. Sample Queries

### 8.1 List all restriction types
```sql
SELECT  RestrictionTypeID,
        RestrictionTypeName
FROM    [Dictionary].[RestrictionType] WITH (NOLOCK)
ORDER BY RestrictionTypeID;
```

### 8.2 Find copy relationships with restrictions
```sql
SELECT  csr.*,
        rt.RestrictionTypeName
FROM    [Trade].[CopyTradeSettlementRestrictions] csr WITH (NOLOCK)
JOIN    [Dictionary].[RestrictionType] rt WITH (NOLOCK) ON csr.RestrictionTypeID = rt.RestrictionTypeID
WHERE   rt.RestrictionTypeID > 0;
```

### 8.3 Count restrictions by type
```sql
SELECT  rt.RestrictionTypeName,
        COUNT(*) AS RestrictionCount
FROM    [Trade].[CopyTradeSettlementRestrictions] csr WITH (NOLOCK)
JOIN    [Dictionary].[RestrictionType] rt WITH (NOLOCK) ON csr.RestrictionTypeID = rt.RestrictionTypeID
GROUP BY rt.RestrictionTypeName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RestrictionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RestrictionType.sql*

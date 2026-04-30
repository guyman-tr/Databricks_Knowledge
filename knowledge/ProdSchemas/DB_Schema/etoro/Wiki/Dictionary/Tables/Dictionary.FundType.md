# Dictionary.FundType

> Lookup table defining the three CopyFunds/SmartPortfolio fund categories — TopTraders (copy-based), Partners (external), and Market (thematic index-based).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | FundTypeID (INT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.FundType classifies eToro's CopyFunds (later rebranded as SmartPortfolios) into three strategy categories based on how the fund's holdings are determined. Each fund type represents a fundamentally different investment approach — copying top traders, partnering with external strategists, or tracking a market theme.

This table exists because the fund management system needs to differentiate between fund types that have different rebalancing logic, fee structures, and regulatory treatment. A TopTraders fund copies the portfolios of selected Popular Investors, a Partners fund follows an external strategist's allocation, and a Market fund tracks a thematic index (e.g., "Big Tech", "Crypto"). The fund type determines how the system sources allocation decisions and calculates performance.

FundTypeID is consumed by Trade.Fund (which stores each fund's definition) and is replicated to SettingsDB for configuration management. The SettingsDB.Trading.FundTypeResolver procedure resolves fund type names to IDs.

---

## 2. Business Logic

### 2.1 Fund Strategy Categories

**What**: Each fund type represents a different investment strategy model.

**Columns/Parameters Involved**: `FundTypeID`, `Description`

**Rules**:
- **TopTraders (1)**: Fund that copies positions from selected eToro Popular Investors. Allocation is based on trader selection and their portfolio weights. Rebalances when copied traders change their positions or during scheduled intervals.
- **Partners (2)**: Fund managed by an external partner or strategist. Allocation decisions come from outside eToro's platform — the partner provides target weights and the system executes rebalancing.
- **Market (3)**: Thematic index fund that tracks a market theme (e.g., "Big Tech", "Renewable Energy", "CryptoPortfolio"). Allocation is based on a predefined set of instruments with target weights. Rebalances on a schedule or when instruments enter/exit the theme.

---

## 3. Data Overview

| FundTypeID | Description | Meaning |
|---|---|---|
| 1 | TopTraders | Copy-based fund that mirrors the portfolios of selected eToro Popular Investors. Investors in this fund automatically receive the same positions as the selected traders. The fund's performance is driven by the collective trading decisions of its constituent traders. |
| 2 | Partners | Externally managed fund where an outside strategist provides allocation targets. eToro's system executes the rebalancing, but the investment decisions originate from the partner. May have different fee structures reflecting the external management. |
| 3 | Market | Thematic market-tracking fund built around an investment theme rather than individual traders. Holds a diversified set of instruments matching the theme with predefined target weights. Provides broad thematic exposure without copying any individual trader. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundTypeID | int | NO | - | VERIFIED | Primary key identifying the fund category. 1=TopTraders (copy-based), 2=Partners (external strategist), 3=Market (thematic index). Referenced by Trade.Fund to classify each CopyFund/SmartPortfolio. Replicated to SettingsDB for configuration management. |
| 2 | Description | varchar(50) | NO | - | VERIFIED | Human-readable label for the fund type. Used in the platform UI, fund details pages, and management reporting. Describes the fundamental strategy approach of the fund category. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.Fund | FundTypeID | Implicit Lookup | Each fund is classified by its strategy type |
| SettingsDB.Trading.FundTypeResolver | FundTypeID | Read | Resolves fund type names to IDs for configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.Fund | Table | References FundTypeID to classify each fund's strategy category |
| SettingsDB.Trading.FundTypeResolver | Stored Procedure | Resolves fund type names to IDs |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryFundType | CLUSTERED PK | FundTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryFundType | PRIMARY KEY | Unique fund type identifier |

---

## 8. Sample Queries

### 8.1 List all fund types
```sql
SELECT  FundTypeID,
        Description
FROM    [Dictionary].[FundType] WITH (NOLOCK)
ORDER BY FundTypeID;
```

### 8.2 Count active funds by type
```sql
SELECT  ft.Description  AS FundType,
        COUNT(*)        AS FundCount
FROM    [Trade].[Fund] f WITH (NOLOCK)
JOIN    [Dictionary].[FundType] ft WITH (NOLOCK)
        ON f.FundTypeID = ft.FundTypeID
GROUP BY ft.Description
ORDER BY FundCount DESC;
```

### 8.3 Find all TopTraders funds
```sql
SELECT  f.*,
        ft.Description  AS FundTypeName
FROM    [Trade].[Fund] f WITH (NOLOCK)
JOIN    [Dictionary].[FundType] ft WITH (NOLOCK)
        ON f.FundTypeID = ft.FundTypeID
WHERE   ft.FundTypeID = 1
ORDER BY f.FundID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.FundType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.FundType.sql*

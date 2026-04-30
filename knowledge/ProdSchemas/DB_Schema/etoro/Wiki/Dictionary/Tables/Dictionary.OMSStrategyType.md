# Dictionary.OMSStrategyType

> Defines the Order Management System (OMS) execution strategy types that control how hedge orders are routed and executed by liquidity providers.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.OMSStrategyType classifies the execution strategies used by the Order Management System (OMS) for routing hedge orders to liquidity providers. Each strategy determines how orders are matched, split, and executed — directly through an internal matching engine (IM) or via Direct Market Access (DMA) to external liquidity.

Without this table, the hedge server could not configure which execution strategy to use for each OMS portfolio, making it impossible to distinguish between internally matched orders and those sent directly to market.

Referenced by Hedge.HedgeServerIDToOMSPortfolio (OMSStrategyTypeID column) and read by Hedge.GetHedgeServerIDToOMSPortfolio procedure for OMS configuration.

---

## 2. Business Logic

### 2.1 Execution Strategy Options

**What**: Two hedge order execution strategies controlling market access.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- IM (1): Internal Matching — orders are matched internally within the platform's order book before going to external liquidity
- DMA (2): Direct Market Access — orders are sent directly to external liquidity providers/exchanges without internal matching
- The strategy is configured per hedge server + OMS portfolio combination
- DMA provides better price transparency but higher execution costs; IM reduces market impact

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 1 | IM | Internal Matching — hedge orders are first matched against other internal orders before any remainder is sent to external liquidity providers |
| 2 | DMA | Direct Market Access — hedge orders bypass internal matching and are sent directly to liquidity providers/exchanges for immediate execution |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Unique identifier for the OMS execution strategy: 1=IM (Internal Matching), 2=DMA (Direct Market Access). Referenced by Hedge.HedgeServerIDToOMSPortfolio. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Short strategy name: "IM" or "DMA". Used in hedge server configuration and dealing reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.HedgeServerIDToOMSPortfolio | OMSStrategyTypeID | Implicit | Maps hedge server portfolios to their execution strategy |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeServerIDToOMSPortfolio | Table | OMSStrategyTypeID column |
| Hedge.GetHedgeServerIDToOMSPortfolio | Stored Procedure | Reads strategy type for OMS configuration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_[OMSStrategyType | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None beyond PK. Note: PK constraint name has a bracket artifact in the DDL.

---

## 8. Sample Queries

### 8.1 List all OMS strategy types
```sql
SELECT  ID,
        Name
FROM    [Dictionary].[OMSStrategyType] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find hedge servers using DMA
```sql
SELECT  hs.*,
        ost.Name AS StrategyType
FROM    [Hedge].[HedgeServerIDToOMSPortfolio] hs WITH (NOLOCK)
JOIN    [Dictionary].[OMSStrategyType] ost WITH (NOLOCK)
        ON hs.OMSStrategyTypeID = ost.ID
WHERE   ost.Name = 'DMA';
```

### 8.3 Strategy distribution across OMS portfolios
```sql
SELECT  ost.Name AS Strategy,
        COUNT(*) AS PortfolioCount
FROM    [Hedge].[HedgeServerIDToOMSPortfolio] hs WITH (NOLOCK)
JOIN    [Dictionary].[OMSStrategyType] ost WITH (NOLOCK)
        ON hs.OMSStrategyTypeID = ost.ID
GROUP BY ost.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OMSStrategyType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OMSStrategyType.sql*

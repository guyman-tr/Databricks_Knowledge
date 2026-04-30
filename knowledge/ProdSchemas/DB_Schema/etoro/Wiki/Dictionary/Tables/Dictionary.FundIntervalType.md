# Dictionary.FundIntervalType

> Lookup table defining the two fund interval modes — BackTesting and Real — used to distinguish simulated vs live fund allocation intervals in the CopyFunds/SmartPortfolio system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | FundIntervalType (TINYINT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.FundIntervalType classifies fund allocation intervals as either backtesting simulations or live (real) operations. This supports eToro's CopyFunds/SmartPortfolio system, where funds periodically rebalance their holdings. Before applying a rebalancing strategy to real customer money, the system can run backtesting intervals using historical data to evaluate strategy performance.

This table exists because the Trade.FundInterval table tracks both simulated and real rebalancing events. The FundIntervalType column distinguishes between backtesting intervals (used for strategy evaluation and optimization) and real intervals (which trigger actual trades and fund movements). This classification determines whether trades are actually executed or merely simulated.

FundIntervalType is referenced by Trade.FundInterval, which stores the interval records for CopyFunds/SmartPortfolio rebalancing operations.

---

## 2. Business Logic

### 2.1 Simulation vs Live Intervals

**What**: Fund intervals are classified as backtesting (simulated) or real (live execution).

**Columns/Parameters Involved**: `FundIntervalType`, `FundIntervalTypeDesc`

**Rules**:
- **BackTesting (1)**: Simulated rebalancing intervals using historical data. No real trades are executed. Used to evaluate and optimize fund allocation strategies before going live. Results are compared against benchmarks to validate strategy performance.
- **Real (2)**: Live rebalancing intervals where actual trades are executed. Customer funds are rebalanced according to the strategy, positions are opened/closed, and the fund's NAV is updated.

---

## 3. Data Overview

| FundIntervalType | FundIntervalTypeDesc | Meaning |
|---|---|---|
| 1 | BackTesting | Simulated fund interval for strategy evaluation. Historical price data is used to model what would have happened if the rebalancing strategy had been active. No real money moves, no actual trades. Used by fund managers and the platform to validate strategies before deployment. |
| 2 | Real | Live fund interval where the rebalancing strategy is executed with real customer money. Triggers actual trade orders, updates fund holdings, and recalculates the fund's Net Asset Value. This is the production state for active CopyFunds/SmartPortfolios. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundIntervalType | tinyint | NO | - | VERIFIED | Primary key identifying the interval mode. 1=BackTesting (simulated), 2=Real (live execution). Referenced by Trade.FundInterval to classify each rebalancing interval as simulated or live. |
| 2 | FundIntervalTypeDesc | varchar(50) | YES | - | VERIFIED | Human-readable label for the interval type (BackTesting/Real). Used in reporting and fund management UI to distinguish simulated from live intervals. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FundInterval | FundIntervalType | Implicit Lookup | Each fund interval record is classified as backtesting or real |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FundInterval | Table | References FundIntervalType to classify intervals as simulated or live |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_FundIntervalType | CLUSTERED PK | FundIntervalType ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_FundIntervalType | PRIMARY KEY | Unique interval type identifier |

---

## 8. Sample Queries

### 8.1 List all fund interval types
```sql
SELECT  FundIntervalType,
        FundIntervalTypeDesc
FROM    [Dictionary].[FundIntervalType] WITH (NOLOCK)
ORDER BY FundIntervalType;
```

### 8.2 Count fund intervals by type
```sql
SELECT  fit.FundIntervalTypeDesc,
        COUNT(*) AS IntervalCount
FROM    [Trade].[FundInterval] fi WITH (NOLOCK)
JOIN    [Dictionary].[FundIntervalType] fit WITH (NOLOCK)
        ON fi.FundIntervalType = fit.FundIntervalType
GROUP BY fit.FundIntervalTypeDesc;
```

### 8.3 Find active real fund intervals
```sql
SELECT  fi.*,
        fit.FundIntervalTypeDesc
FROM    [Trade].[FundInterval] fi WITH (NOLOCK)
JOIN    [Dictionary].[FundIntervalType] fit WITH (NOLOCK)
        ON fi.FundIntervalType = fit.FundIntervalType
WHERE   fit.FundIntervalType = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.FundIntervalType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.FundIntervalType.sql*

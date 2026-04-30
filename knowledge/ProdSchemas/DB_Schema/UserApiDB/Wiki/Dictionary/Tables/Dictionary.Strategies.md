# Dictionary.Strategies

> Lookup table defining investment strategy classifications for Popular Investor profiles in the copy-trading ecosystem.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | StrategyID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.Strategies defines the investment strategies that Popular Investors (PIs) declare on their profiles. Copiers use these strategy labels to find PIs whose approach matches their investment goals. The strategies range from traditional (value, growth, income) to specialized (macro, quant, eventDriven).

This classification helps copiers make informed decisions about which PIs to copy. It also supports platform search and filtering features where users can browse PIs by strategy type.

Strategy is self-declared by the PI during profile setup. 0=none indicates the PI has not selected a strategy.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| StrategyID | StrategyValue | Meaning |
|---|---|---|
| 0 | none | PI has not declared a strategy |
| 1 | value | Value investing - buying undervalued assets and holding for price correction |
| 2 | growth | Growth investing - targeting companies with above-average earnings growth |
| 6 | momentum | Momentum trading - following established price trends |
| 11 | quant | Quantitative strategies - algorithm and data-driven trading decisions |

*5 of 12 rows shown.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StrategyID | int | NO | - | CODE-BACKED | Primary key. Strategy identifier: 0=none through 11=quant. See [Strategies](_glossary.md#strategies). |
| 2 | StrategyValue | varchar(255) | NO | - | CODE-BACKED | camelCase strategy identifier used in PI profiles and API responses. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer PI profile tables | StrategyID | Lookup | Stores the PI's declared investment strategy |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Strategies | CLUSTERED PK | StrategyID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all strategies
```sql
SELECT StrategyID, StrategyValue FROM Dictionary.Strategies WITH (NOLOCK) ORDER BY StrategyID
```

### 8.2 Find PIs by strategy
```sql
SELECT p.CustomerID, s.StrategyValue FROM Customer.PiProfiles p WITH (NOLOCK)
JOIN Dictionary.Strategies s WITH (NOLOCK) ON p.StrategyID = s.StrategyID WHERE s.StrategyValue = 'value'
```

### 8.3 Strategy distribution among PIs
```sql
SELECT s.StrategyValue, COUNT(*) AS PiCount FROM Customer.PiProfiles p WITH (NOLOCK)
JOIN Dictionary.Strategies s WITH (NOLOCK) ON p.StrategyID = s.StrategyID
GROUP BY s.StrategyValue ORDER BY PiCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.Strategies | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.Strategies.sql*

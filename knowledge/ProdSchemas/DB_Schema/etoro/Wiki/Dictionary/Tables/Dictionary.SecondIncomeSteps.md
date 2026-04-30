# Dictionary.SecondIncomeSteps

## 1. Business Meaning

**What it is**: A configuration table that defines the Popular Investor (PI) "Second Income" compensation tiers based on the number of copiers. Each row specifies a copier-count range and the monthly income payment for standard and top-level Popular Investors.

**Why it exists**: eToro's Popular Investor program pays users who are copied by others. The compensation scales with the number of active copiers — the more copiers a PI has, the higher their monthly payment. This table provides the tiered payment schedule used to calculate PI compensation. There are two income tracks: standard income and "TopLevel" income (for the highest-tier PIs).

**How it works**: The procedure `dbo.GetSecondIncomeSteps` reads all rows from this table and returns them to the application layer. The application matches each PI's current copier count against the `FromNumberOfCopiers`/`ToNumberOfCopiers` range to determine their payment tier and applicable income amount.

---

## 2. Business Logic

### Compensation Tiers
| Copiers Range | Standard Income ($) | Top-Level Income ($) |
|---------------|--------------------|--------------------|
| 10 – 49 | 50 | 100 |
| 50 – 249 | 150 | 300 |
| 250 – 499 | 300 | 600 |
| 500 – 749 | 500 | 1,000 |
| 750 – 999 | 650 | 1,300 |
| 1,000 – 1,499 | 750 | 1,500 |
| 1,500 – 3,999 | 1,000 | 2,000 |
| 4,000 – 7,999 | 2,000 | 4,000 |
| 8,000 – 9,999 | 2,500 | 5,000 |
| 10,000+ | 5,000 | 10,000 |

### Key Business Rules
- Minimum threshold: 10 copiers required to start earning
- Top-Level income is always exactly 2× the standard income
- Maximum payout: $5,000/month standard, $10,000/month top-level
- The upper bound of the last tier (1,000,000) acts as a practical infinity ceiling

---

## 3. Data Overview

| FromNumberOfCopiers | ToNumberOfCopiers | Income | TopLevelIncome | Business Meaning |
|--------------------|--------------------|--------|---------------|------------------|
| 10 | 49 | 50 | 100 | Entry-level PI compensation |
| 250 | 499 | 300 | 600 | Mid-tier PI compensation |
| 1000 | 1499 | 750 | 1500 | High-volume PI compensation |
| 10000 | 1000000 | 5000 | 10000 | Maximum PI compensation tier |

*10 rows — complete PI compensation schedule*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **FromNumberOfCopiers** | int | NOT NULL | — | Composite PK part 1. Lower bound (inclusive) of the copier count range for this tier. Minimum is 10 (entry threshold). | `MCP` |
| **ToNumberOfCopiers** | int | NOT NULL | — | Composite PK part 2. Upper bound (inclusive) of the copier count range. Last tier uses 1,000,000 as a practical ceiling. | `MCP` |
| **Income** | money | NOT NULL | — | Monthly compensation amount in USD for standard Popular Investors in this copier range. Range: $50–$5,000. | `MCP` |
| **TopLevelIncome** | money | NOT NULL | — | Monthly compensation amount in USD for top-level Popular Investors (highest PI tier). Always 2× the standard Income. Range: $100–$10,000. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — standalone configuration table.*

### Referenced By (other objects point to this table)
| Referencing Object | Relationship | Business Meaning |
|-------------------|--------------|------------------|
| dbo.GetSecondIncomeSteps | Full table read | Returns all tiers to the application for PI compensation calculation |

---

## 6. Dependencies

### Depends On
*None — standalone configuration table.*

### Depended On By
- `dbo.GetSecondIncomeSteps` — PI compensation tier retrieval

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `(FromNumberOfCopiers, ToNumberOfCopiers)` (clustered, composite) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | PRIMARY |
| Row Count | 10 |

---

## 8. Sample Queries

```sql
-- Get all PI compensation tiers
SELECT  FromNumberOfCopiers, ToNumberOfCopiers, Income, TopLevelIncome
FROM    Dictionary.SecondIncomeSteps WITH (NOLOCK)
ORDER BY FromNumberOfCopiers;

-- Find the compensation tier for a PI with 500 copiers
SELECT  Income, TopLevelIncome
FROM    Dictionary.SecondIncomeSteps WITH (NOLOCK)
WHERE   500 BETWEEN FromNumberOfCopiers AND ToNumberOfCopiers;

-- Verify TopLevel is always 2x standard
SELECT  FromNumberOfCopiers, Income, TopLevelIncome,
        CASE WHEN TopLevelIncome = Income * 2 THEN 'OK' ELSE 'MISMATCH' END AS Check2x
FROM    Dictionary.SecondIncomeSteps WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. The Popular Investor compensation schedule is a product/commercial configuration.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (10 rows), codebase traced (1 procedure consumer), business rules extracted*

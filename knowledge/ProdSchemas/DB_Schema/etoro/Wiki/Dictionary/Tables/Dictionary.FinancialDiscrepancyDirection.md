# Dictionary.FinancialDiscrepancyDirection

> Lookup table defining the direction of a financial discrepancy — whether funds are missing from or surplus in a customer's trading account balance.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.FinancialDiscrepancyDirection classifies the direction of financial discrepancies detected by eToro's billing reconciliation processes. A discrepancy occurs when the expected balance (based on deposits, withdrawals, and trade outcomes) does not match the actual account balance. The direction indicates whether money is missing from (underpayment) or surplus in (overpayment) the customer's account.

This table supports eToro's financial integrity monitoring. Automated reconciliation jobs compare expected vs actual balances and log discrepancies into Billing.FinancialDiscrepancy with a direction classification. The direction determines which investigation workflow applies — missing funds typically require urgent resolution (customer impact), while surplus funds indicate a potential duplicate credit.

Discrepancy records in Billing.FinancialDiscrepancy reference this table via an explicit FK on FinancialDiscrepancyDirectionID. Currently only one direction is defined (missing funds), suggesting surplus fund detection may use a different mechanism or is planned for future implementation.

---

## 2. Business Logic

### 2.1 Discrepancy Direction Classification

**What**: Each financial discrepancy is classified by whether the customer's account has less or more money than expected.

**Columns/Parameters Involved**: `ID`, `Name`, `Meaning`

**Rules**:
- ID 1 ("Missing funds on eToro Account Balance"): The customer's trading account balance is lower than expected based on transaction history — funds are missing
- Additional directions (e.g., surplus funds, zero-impact discrepancies) may be added as reconciliation processes evolve
- Direction is stored alongside FinancialDiscrepancyType to fully classify each discrepancy (type + direction)

---

## 3. Data Overview

| ID | Name | Meaning | Business Context |
|---|---|---|---|
| 1 | Missing funds on eToro Account Balance | Trading Account Balance missing funds | Indicates a reconciliation mismatch where the customer's balance is lower than the sum of their deposits, withdrawals, and trade outcomes would predict. Triggers investigation by the billing operations team to identify the root cause (duplicate deduction, failed credit, system error). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying the discrepancy direction. Currently only 1=Missing funds. Referenced by Billing.FinancialDiscrepancy via explicit FK (FK_FinancialDiscrepancy_FinancialDiscrepancyDirectionID). |
| 2 | Name | varchar(100) | NO | - | VERIFIED | Short label for the discrepancy direction, used in reports and the BackOffice UI. Describes the nature of the balance mismatch in business terms. |
| 3 | Meaning | varchar(max) | NO | - | VERIFIED | Extended description explaining the discrepancy direction in detail. Provides context for operations staff investigating the discrepancy — clarifies what "missing funds" means in technical terms (Trading Account Balance missing funds). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.FinancialDiscrepancy | FinancialDiscrepancyDirectionID | FK | Each discrepancy record references the direction (missing/surplus) |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.FinancialDiscrepancy | Table | FK to ID — classifies each discrepancy by direction |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FinancialDiscrepancyDirection | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FinancialDiscrepancyDirection | PRIMARY KEY | Unique discrepancy direction identifier |

---

## 8. Sample Queries

### 8.1 List all discrepancy directions
```sql
SELECT  ID,
        Name,
        Meaning
FROM    [Dictionary].[FinancialDiscrepancyDirection] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Count discrepancies by direction
```sql
SELECT  d.Name          AS Direction,
        COUNT(*)        AS DiscrepancyCount
FROM    [Billing].[FinancialDiscrepancy] fd WITH (NOLOCK)
JOIN    [Dictionary].[FinancialDiscrepancyDirection] d WITH (NOLOCK)
        ON fd.FinancialDiscrepancyDirectionID = d.ID
GROUP BY d.Name
ORDER BY DiscrepancyCount DESC;
```

### 8.3 Find recent discrepancies with direction and type labels
```sql
SELECT  fd.FinancialDiscrepancyID,
        dd.Name         AS Direction,
        dt.Name         AS DiscrepancyType,
        fd.Amount,
        fd.CreatedDate
FROM    [Billing].[FinancialDiscrepancy] fd WITH (NOLOCK)
JOIN    [Dictionary].[FinancialDiscrepancyDirection] dd WITH (NOLOCK)
        ON fd.FinancialDiscrepancyDirectionID = dd.ID
JOIN    [Dictionary].[FinancialDiscrepancyType] dt WITH (NOLOCK)
        ON fd.FinancialDiscrepancyTypeID = dt.ID
ORDER BY fd.CreatedDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.FinancialDiscrepancyDirection | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.FinancialDiscrepancyDirection.sql*

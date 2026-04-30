# Dictionary.BankClassification

> Lookup table defining the 3 bank classification tiers — Basic, Evaluation, and Optimised — used to categorize payment processing banks by their integration maturity and transaction handling capabilities.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ClassificationID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.BankClassification categorizes payment processing banks into quality/maturity tiers. Each classification reflects how well a bank's payment processing infrastructure has been evaluated and optimized for eToro's deposit and withdrawal operations.

This table supports the payment routing optimization system. Banks progress through tiers as their integration quality improves: new bank integrations start as "Basic," move to "Evaluation" during testing/monitoring, and reach "Optimised" once their transaction success rates, processing times, and reliability meet the platform's standards. The classification may influence routing decisions (preferring optimised banks for high-value transactions).

Referenced by Billing.InsertBankClassification (writes classifications), Billing.GetBankClassifications and Billing.GetAllBankClassifications (reads for routing decisions), and a companion Billing.BankClassification table that likely stores bank-to-classification mappings.

---

## 2. Business Logic

### 2.1 Bank Integration Maturity Tiers

**What**: Classification of payment processing banks by integration quality.

**Columns/Parameters Involved**: `ClassificationID`, `ClassificationName`

**Rules**:
- **Basic (1)**: New or unoptimized bank integration. Standard processing with default routing priority. Bank has not been specifically tuned for eToro's transaction patterns.
- **Evaluation (2)**: Bank integration is under active review. Transaction success rates, processing times, and reliability are being monitored. May be a newly added bank or one being reassessed after issues.
- **Optimised (3)**: Bank integration has been tuned and verified for optimal performance. Highest confidence in transaction success rates. May receive preferential routing for deposits and withdrawals.

---

## 3. Data Overview

| ClassificationID | ClassificationName | Meaning |
|---|---|---|
| 1 | Basic | Default tier for bank integrations without specific optimization. Standard processing parameters and routing priority. New banks start here. |
| 2 | Evaluation | Bank under active assessment. Transaction patterns, success rates, and processing times are being monitored. May receive limited transaction volume while being evaluated. |
| 3 | Optimised | Bank integration fully optimized for eToro's transaction patterns. Highest reliability tier — may receive preferential routing for deposit and withdrawal processing. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClassificationID | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key. 1=Basic, 2=Evaluation, 3=Optimised. Referenced by Billing.BankClassification table for bank-to-tier mappings. Used by routing procedures to determine processing priority. |
| 2 | ClassificationName | nvarchar(100) | YES | - | VERIFIED | Human-readable tier name. Nullable but all current rows have values. Displayed in billing management interfaces and returned by Billing.GetBankClassifications/Billing.GetAllBankClassifications. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| [Billing.BankClassification](../../Billing/Tables/Billing.BankClassification.md) | ClassificationID, EtoroClassificationID | FK (explicit x2) | Stores per-bank tier mappings for Trustly routing; both ClassificationID and EtoroClassificationID reference this table |
| Billing.InsertBankClassification | @ClassificationID | Parameter INSERT | Creates new bank classification entries |
| Billing.GetBankClassifications | ClassificationID | SELECT | Returns classifications for routing decisions |
| Billing.GetAllBankClassifications | ClassificationID | SELECT | Returns all bank classifications |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.BankClassification | Table | Stores bank-to-tier mappings |
| Billing.InsertBankClassification | Stored Procedure | Writer — creates classification entries |
| Billing.GetBankClassifications | Stored Procedure | Reader — routing decisions |
| Billing.GetAllBankClassifications | Stored Procedure | Reader — full list |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | ClassificationID ASC | - | - | Active (FILLFACTOR 95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK (unnamed) | PRIMARY KEY | Unique classification tier identifier on PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all bank classifications
```sql
SELECT  ClassificationID,
        ClassificationName
FROM    Dictionary.BankClassification WITH (NOLOCK)
ORDER BY ClassificationID;
```

### 8.2 Count banks per classification tier
```sql
SELECT  dbc.ClassificationName  AS Tier,
        COUNT(*)                AS BankCount
FROM    Billing.BankClassification bbc WITH (NOLOCK)
JOIN    Dictionary.BankClassification dbc WITH (NOLOCK)
        ON bbc.ClassificationID = dbc.ClassificationID
GROUP BY dbc.ClassificationName
ORDER BY BankCount DESC;
```

### 8.3 Find optimised banks
```sql
SELECT  bbc.*,
        dbc.ClassificationName
FROM    Billing.BankClassification bbc WITH (NOLOCK)
JOIN    Dictionary.BankClassification dbc WITH (NOLOCK)
        ON bbc.ClassificationID = dbc.ClassificationID
WHERE   dbc.ClassificationID = 3;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.BankClassification | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.BankClassification.sql*

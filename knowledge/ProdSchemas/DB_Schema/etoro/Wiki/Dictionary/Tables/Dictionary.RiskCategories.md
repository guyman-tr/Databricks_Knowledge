# Dictionary.RiskCategories

> Lookup table defining the 3 risk classification levels (Low, Medium, High) for trading instruments and accounts.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RiskCategoryID (INT, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 2 active (PK clustered + unique on Name) |

---

## 1. Business Meaning

Dictionary.RiskCategories assigns risk classifications to trading instruments and possibly user accounts. The three-tier model (Low, Medium, High) aligns with standard financial risk classification frameworks and drives regulatory disclosures, margin requirements, and suitability assessments.

Risk category affects what instruments are shown to users based on their experience level and regulatory jurisdiction. Under MiFID II, brokers must assess client suitability for different risk levels, and this table provides the classification framework.

RiskCategoryID is referenced by instrument configuration and potentially by client suitability assessment procedures.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| RiskCategoryID | Name | Meaning |
|---|---|---|
| 1 | Low | Low-risk instruments — typically major forex pairs, large-cap stocks, government bonds. Lower margin requirements. Available to all experience levels. |
| 2 | Medium | Medium-risk instruments — minor forex pairs, mid-cap stocks, commodities. Standard margin requirements. May require basic trading knowledge assessment. |
| 3 | High | High-risk instruments — crypto, exotic forex, leveraged products. Higher margin requirements. May require advanced suitability assessment under MiFID II. Risk warnings more prominent. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RiskCategoryID | int | NO | - | CODE-BACKED | Primary key. 1=Low, 2=Medium, 3=High. See [Risk Categories](_glossary.md#risk-categories). (Dictionary.RiskCategories) |
| 2 | Name | varchar(40) | YES | - | CODE-BACKED | Risk level name. UNIQUE constraint. NULL allowed (unusual for a name column — may indicate a placeholder row). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Instrument configuration tables | RiskCategoryID | Implicit Lookup | Classifies instruments by risk level |

---

## 6. Dependencies

This object has no dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryRiskCategory | CLUSTERED PK | RiskCategoryID ASC | - | - | Active |
| UNQ_DictionaryRiskCategories_Name | NC UNIQUE | Name ASC | - | - | Active |

---

## 8. Sample Queries

### 8.1 List all risk categories
```sql
SELECT RiskCategoryID, Name FROM [Dictionary].[RiskCategories] WITH (NOLOCK) ORDER BY RiskCategoryID;
```

---

*Generated: 2026-03-13 | Quality: 7.0/10*
*Object: Dictionary.RiskCategories | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RiskCategories.sql*

# Trade.GetUserInfoForFee

> Minimal customer lookup for fee calculation - returns CID, GCID, CountryID, and WeekendFeePrecentage for a single customer. Used by the fee processing pipeline to determine the applicable weekend fee rate.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer for fee calculation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUserInfoForFee` is a focused, minimal-overhead lookup used by the fee calculation subsystem. When computing weekend fees (charges applied for holding positions over weekends), the fee engine needs only four fields: the customer identifiers and the customer's weekend fee percentage. This procedure provides exactly those four columns with no joins to unneeded tables.

The `WeekendFeePrecentage` column (note: the name contains a typo - "Precentage" not "Percentage") comes from `Customer.CustomerStatic` and represents a customer-specific weekend fee multiplier or rate. Country-specific fee rates may apply based on CountryID.

The use of `Customer.CustomerStatic` (rather than `Customer.Customer`) aligns this with TRADEA-387 patterns - CustomerStatic is the post-detachment customer view.

---

## 2. Business Logic

### 2.1 Single Row Weekend Fee Context

**What**: Returns one row with fee-relevant fields only.

**Rules**:
- No joins required - all four columns are in Customer.CustomerStatic
- Filtered by CID
- WeekendFeePrecentage: customer-specific weekend holding fee rate; used by the fee engine to compute the charge on open positions over weekends

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID for fee calculation context. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | CID | INT | NO | - | CODE-BACKED | Database-local Customer ID. |
| 3 | GCID | INT | NO | - | CODE-BACKED | Global Customer ID. |
| 4 | CountryID | INT | NO | - | CODE-BACKED | Customer's country. FK to Dictionary.Country. May drive country-specific fee rates. |
| 5 | WeekendFeePrecentage | DECIMAL/FLOAT | YES | - | CODE-BACKED | Customer-specific weekend holding fee percentage rate. Name contains typo ("Precentage" not "Percentage"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Customer.CustomerStatic | FROM | Single source for all four output columns |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (fee calculation engine) | @CID | EXEC caller | Weekend fee computation pipeline |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUserInfoForFee (procedure)
+-- Customer.CustomerStatic (view/table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | View/Table | Only source - CID, GCID, CountryID, WeekendFeePrecentage |

### 6.2 Objects That Depend On This

No documented dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH (NOLOCK) | Isolation | Dirty reads acceptable for fee rate lookup |

---

## 8. Sample Queries

### 8.1 Get weekend fee context for a customer
```sql
EXEC Trade.GetUserInfoForFee @CID = 123456
```

### 8.2 Directly query the weekend fee percentage
```sql
SELECT CID, GCID, CountryID, WeekendFeePrecentage
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE CID = 123456
```

### 8.3 N/A - third query not applicable for this minimal procedure

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Minimal fee-context procedure not separately documented.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUserInfoForFee | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUserInfoForFee.sql*

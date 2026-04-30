# Trade.GetBacktraderIsUserUS

> Determines whether a customer is a US user by checking for the presence of an ApexID in their customer static record.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns IsUSCustomer flag (1/0) for a given CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a companion to `Trade.GetBacktraderCustomerData`, determining whether a customer is a US-based user. US users have special regulatory treatment on the platform - their positions are settled through Apex Clearing (a US clearing broker), and they have an ApexID assigned. This flag is used by the Back Trader feature to apply US-specific portfolio display rules.

The procedure exists because US and non-US users have different trading conditions (real stock ownership vs CFDs), different fee structures, and different regulatory displays. The Back Trader UI needs to know the user's jurisdiction to render the appropriate portfolio view.

Data flows from `Customer.CustomerStatic` - if the customer has an ApexID (not NULL), they are a US customer. The presence of an ApexID indicates they have been onboarded with the US clearing broker.

---

## 2. Business Logic

### 2.1 US Customer Detection via ApexID

**What**: Determines US status by checking ApexID presence in CustomerStatic.

**Columns/Parameters Involved**: `ApexID`, `IsUSCustomer`

**Rules**:
- `CASE WHEN ApexID IS NULL THEN 0 ELSE 1 END AS IsUSCustomer`
- ApexID NOT NULL -> customer has a US clearing account -> IsUSCustomer = 1
- ApexID IS NULL -> customer does not have US clearing -> IsUSCustomer = 0
- Cross-schema read: accesses Customer.CustomerStatic from the Trade schema

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to check US status for. |
| 2 | IsUSCustomer | INT | NO | - | CODE-BACKED | US customer flag: 1 = US customer (has ApexID/US clearing account), 0 = non-US customer. Derived from ApexID presence in Customer.CustomerStatic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Customer.CustomerStatic | SELECT FROM | Source table - checks ApexID for US determination |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetBacktraderIsUserUS (procedure)
+-- Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | SELECT FROM - reads ApexID for US customer detection |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Check if a customer is US-based
```sql
EXEC Trade.GetBacktraderIsUserUS @CID = 12345;
```

### 8.2 Direct query for US customers
```sql
SELECT  CID, ApexID, CASE WHEN ApexID IS NULL THEN 0 ELSE 1 END AS IsUSCustomer
FROM    Customer.CustomerStatic WITH (NOLOCK)
WHERE   CID = 12345;
```

### 8.3 Count US vs non-US customers
```sql
SELECT  CASE WHEN ApexID IS NULL THEN 'Non-US' ELSE 'US' END AS CustomerType, COUNT(*) AS CustomerCount
FROM    Customer.CustomerStatic WITH (NOLOCK)
GROUP BY CASE WHEN ApexID IS NULL THEN 'Non-US' ELSE 'US' END;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetBacktraderIsUserUS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetBacktraderIsUserUS.sql*

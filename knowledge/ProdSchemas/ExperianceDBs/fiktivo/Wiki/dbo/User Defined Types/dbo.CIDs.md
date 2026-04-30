# dbo.CIDs

> Table-valued parameter type for passing a list of Customer IDs (CIDs) to stored procedures as a single parameter.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | CID (INT, CLUSTERED PK with IGNORE_DUP_KEY=OFF) |
| **Partition** | N/A |
| **Indexes** | 1 (PK) |

---

## 1. Business Meaning

This table type enables stored procedures to accept a batch of customer identifiers in a single parameter instead of requiring comma-separated strings or multiple calls. Customer IDs (CIDs) are the primary identifiers for customers tracked through the affiliate system.

The type is defined with a clustered primary key on CID, ensuring uniqueness and efficient lookups when JOINed inside procedures. IGNORE_DUP_KEY=OFF means duplicate CIDs will cause an error rather than being silently ignored.

No active stored procedure consumers were found in the current dbo schema, suggesting this type may be used by application code or cross-schema procedures, or reserved for future use.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID. The unique platform-wide identifier for a customer/trader whose activity is tracked for affiliate commission attribution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in dbo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK (unnamed) | PRIMARY KEY CLUSTERED | Ensures CID uniqueness within the parameter set. IGNORE_DUP_KEY=OFF enforces strict no-duplicates. |

---

## 8. Sample Queries

### 8.1 Declare and populate the type
```sql
DECLARE @cids dbo.CIDs
INSERT INTO @cids (CID) VALUES (12345), (67890), (11111)
```

### 8.2 Use in a JOIN to filter affiliates by customer
```sql
DECLARE @cids dbo.CIDs
INSERT INTO @cids (CID) VALUES (12345)
SELECT a.AffiliateID, a.LoginName
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN dbo.CidToAffiliateID c WITH (NOLOCK) ON a.AffiliateID = c.MobileAffiliateID
JOIN @cids p ON p.CID = c.CID
```

### 8.3 Count matching records
```sql
DECLARE @cids dbo.CIDs
INSERT INTO @cids (CID) VALUES (12345), (67890)
SELECT COUNT(*) FROM @cids
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.CIDs | Type: User Defined Type | Source: fiktivo/dbo/User Defined Types/dbo.CIDs.sql*

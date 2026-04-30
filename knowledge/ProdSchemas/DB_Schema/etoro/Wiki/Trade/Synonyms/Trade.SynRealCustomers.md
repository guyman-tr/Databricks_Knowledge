# Trade.SynRealCustomers

> Synonym pointing to the Customer.Customer table in the same etoro database, enabling the Trade schema to access customer master data for real (non-demo) accounts without cross-schema dependencies in procedure signatures.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [etoro].[Customer].[Customer] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.SynRealCustomers is a synonym that provides the Trade schema with access to the Customer.Customer table - the master customer record table that holds all registered customer accounts. The "Real" in the name distinguishes this from demo/virtual customer data, indicating this synonym targets the production customer table with actual funded accounts.

The synonym exists to decouple the Trade schema from a direct dependency on the Customer schema at the database project level. By referencing customer data through a synonym, the Trade database project can compile independently without requiring the Customer project as a reference, simplifying the SSDT build process while still allowing runtime cross-schema access.

The primary consumer is Trade.GetTreeNodesByParentCID_Inner, which reads customer data through this synonym when resolving copy-trade tree hierarchies. The procedure needs customer information to build the tree structure showing which customers are copying which leaders.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Customer data logic resides in the Customer schema.

---

## 3. Data Overview

N/A for synonym.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Three-part name | - | - | CODE-BACKED | Points to [etoro].[Customer].[Customer]. The master customer table containing all registered customer accounts (CID, name, registration data, account status). Referenced for real/production accounts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | Customer.Customer | Synonym target | Same-database cross-schema reference to the master customer table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetTreeNodesByParentCID_Inner | JOIN | Reader | Reads customer data when resolving copy-trade tree hierarchies by parent CID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SynRealCustomers (synonym)
  +-- Customer.Customer (table, Customer schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table (Customer schema) | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetTreeNodesByParentCID_Inner | Stored Procedure | Reads customer data for tree hierarchy resolution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

N/A for synonym.

---

## 8. Sample Queries

### 8.1 Verify synonym target
```sql
SELECT name, base_object_name
FROM   sys.synonyms WITH (NOLOCK)
WHERE  name = 'SynRealCustomers'
       AND schema_id = SCHEMA_ID('Trade')
```

### 8.2 Check if synonym resolves
```sql
SELECT OBJECT_ID('Trade.SynRealCustomers') AS ObjectID
```

### 8.3 Preview customer data through synonym
```sql
SELECT TOP 10 *
FROM   Trade.SynRealCustomers WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SynRealCustomers | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.SynRealCustomers.sql*

# BackOffice.GetCustomerComments

> Returns the third-party manager comment for a customer from BackOffice.Customer.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Cid - single customer lookup |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This minimal procedure retrieves the free-text comment that a third-party manager has recorded against a customer account. The comment is stored in `BackOffice.Customer.ThirdPartyManagerComment` and is used to capture notes from external relationship managers or white-label partners who manage subsets of eToro customers.

The procedure is a thin accessor for a single column, providing a named entry point rather than requiring callers to query BackOffice.Customer directly.

---

## 2. Business Logic

No complex logic. Returns the single column `ThirdPartyManagerComment` from `BackOffice.Customer WHERE CID = @Cid`. Returns zero rows if the CID does not exist; returns one row with a NULL comment if the CID exists but no comment has been set.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @Cid | INTEGER | NO | - | CODE-BACKED | Customer ID to look up. Matched against BackOffice.Customer.CID. |
| **Output Columns** | | | | | | |
| 2 | ThirdPartyManagerComment | NVARCHAR | YES | NULL | CODE-BACKED | Free-text comment recorded by a third-party or white-label manager for this customer. From BackOffice.Customer.ThirdPartyManagerComment. NULL if no comment has been set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Cid | BackOffice.Customer | Direct READ | Only source - reads ThirdPartyManagerComment for the given CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Called to display the third-party manager comment in the customer profile |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerComments (procedure)
+-- BackOffice.Customer (ThirdPartyManagerComment)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | Only source - reads ThirdPartyManagerComment WHERE CID=@Cid |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Reads third-party manager comment in customer profile |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get comment for a customer

```sql
EXEC BackOffice.GetCustomerComments @Cid = 12345678;
```

### 8.2 Direct base-table query

```sql
SELECT ThirdPartyManagerComment
FROM BackOffice.Customer WITH(NOLOCK)
WHERE CID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira records found for this procedure.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerComments | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerComments.sql*

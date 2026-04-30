# Customer.GetUsersPrivacyPoliciesByCIDs

> Accepts a table-valued parameter of CIDs and returns the CID, PrivacyPolicyID, and UserName for each matching customer - a batch privacy policy lookup by internal customer IDs.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CIDs (TVP of CIDs) -> CID, PrivacyPolicyID, UserName from Customer.Customer |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUsersPrivacyPoliciesByCIDs retrieves the privacy policy version accepted by a batch of customers, identified by their internal CIDs. The procedure accepts a table-valued parameter of type dbo.Typ_CID (a TVP containing a list of CID integers) and returns the PrivacyPolicyID and UserName for each matching customer from the Customer.Customer view.

This procedure is used by BI administrators for compliance and data governance workflows - specifically to verify which version of the privacy policy each customer has accepted. The PrivacyPolicyID links to a versioned privacy policy document; when the policy is updated (e.g., GDPR revision), compliance teams can use this procedure to identify customers who have not yet accepted the new version.

Data flows: PrivacyPolicyID is stored on Customer.CustomerStatic and surfaced via Customer.Customer. The procedure is a read-only batch retrieval; no writes occur. CIDs not found in Customer.Customer are silently excluded (IN subquery behavior for non-matching values).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CIDs | dbo.Typ_CID (TVP) | NO | - | CODE-BACKED | Table-Valued Parameter containing the list of CIDs to look up. dbo.Typ_CID is a user-defined table type in the dbo schema containing a single CID (int) column. READONLY means the procedure cannot modify the TVP contents. The IN subquery on @CIDs allows efficient batch filtering. |

**Output columns** (SELECT result set):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Internal eToro Customer ID. Identifies which customer each row belongs to. Matches the input CID values. |
| 2 | PrivacyPolicyID | int | YES | - | VERIFIED | The ID of the privacy policy version this customer has accepted. Updated by Customer.SetPrivacyPolicyID when the customer accepts a new policy version. NULL means the customer has not explicitly accepted any versioned policy (pre-policy-versioning accounts). See Customer.GetPrivacyPolicyID for single-customer lookup. |
| 3 | UserName | varchar | NO | - | VERIFIED | Customer's public platform username. Returned alongside PrivacyPolicyID to allow compliance teams to identify customers by name without needing a secondary lookup. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CIDs (IN subquery) | Customer.Customer | Reader (SELECT) | Batch lookup of PrivacyPolicyID and UserName for all supplied CIDs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE permission | Caller | BI administrators use for compliance checks on privacy policy acceptance |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUsersPrivacyPoliciesByCIDs (procedure)
└── Customer.Customer (view)
      ├── Customer.CustomerStatic (table)
      └── Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | SELECT source - filtered by CID IN (@CIDs), returns CID, PrivacyPolicyID, UserName |
| dbo.Typ_CID | User Defined Type | TVP parameter type - table of CID INT values |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | Service account | Privacy policy compliance batch checks |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Look up privacy policy for a batch of customers using TVP
```sql
-- Create a temp table to hold the CIDs
DECLARE @cids dbo.Typ_CID;
INSERT @cids VALUES (12345678), (23456789), (34567890);
EXEC Customer.GetUsersPrivacyPoliciesByCIDs @CIDs = @cids;
```

### 8.2 Direct equivalent query for debugging
```sql
SELECT CID, PrivacyPolicyID, UserName
FROM Customer.Customer WITH (NOLOCK)
WHERE CID IN (12345678, 23456789, 34567890);
```

### 8.3 Find customers who have not accepted the latest privacy policy version
```sql
-- First get the latest policy version ID, then find non-compliant customers
DECLARE @latestPolicyID INT = 5; -- example current version
DECLARE @cids dbo.Typ_CID;
-- populate @cids with your target customer list
EXEC Customer.GetUsersPrivacyPoliciesByCIDs @CIDs = @cids;
-- Then filter results in application code where PrivacyPolicyID < @latestPolicyID or IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 9/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetUsersPrivacyPoliciesByCIDs | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetUsersPrivacyPoliciesByCIDs.sql*

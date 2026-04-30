# Customer.GetUserDetails

> Returns the CountryID and UserName for a single customer by CID, providing a lightweight identity lookup from the customer master record.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID -> CountryID, UserName from Customer.CustomerStatic |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUserDetails is a minimal point-lookup procedure that retrieves exactly two fields - CountryID and UserName - from Customer.CustomerStatic by CID. It exists to give lightweight services a focused, permission-safe API to obtain these two frequently needed identity fields without exposing the full 84-column CustomerStatic record.

This procedure is used by the Recom_user service (the recommendation engine or a related personalization service), which needs to know a customer's country and username as inputs for recommendation logic (e.g., country-specific content, personalization by username). Fetching only these two columns keeps the query efficient and limits PII exposure in service contexts that do not need full customer data.

Data flows: Customer.CustomerStatic is the single master record source. The clustered PK on CID makes this a direct single-row seek with minimal overhead.

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
| 1 | @CID | int | NO | - | VERIFIED | Internal eToro Customer ID. Applied as WHERE CID = @CID against the clustered PK of Customer.CustomerStatic - a single-row seek. |

**Output columns** (SELECT result set):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | VERIFIED | Customer's registered country. FK to Dictionary.Country. Used by the recommendation service to apply country-specific logic (e.g., region-based recommendations, regulatory-aware filtering). See Customer.CustomerStatic.CountryID and Dictionary.Country for the full country ID map. |
| 2 | UserName | varchar | NO | - | VERIFIED | Customer's public platform username from Customer.CustomerStatic. Used by the recommendation service to reference or personalize content. This is the username visible on the eToro social feed and Popular Investor profiles. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | Reader (SELECT) | Point lookup by CID to retrieve CountryID and UserName |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Recom_user | EXECUTE permission | Caller | Recommendation/personalization service uses CountryID and UserName for recommendation logic |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUserDetails (procedure)
└── Customer.CustomerStatic (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | SELECT source - filtered by CID PK, returns CountryID and UserName |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recom_user | Service account | Calls this procedure for lightweight customer identity lookup |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get country and username for a customer
```sql
EXEC Customer.GetUserDetails @CID = 12345678;
```

### 8.2 Direct equivalent query for debugging
```sql
SELECT CountryID, UserName
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE CID = 12345678;
```

### 8.3 Join with Dictionary.Country to resolve the country name
```sql
SELECT cs.CID, cs.UserName, c.Name AS CountryName
FROM Customer.CustomerStatic cs WITH (NOLOCK)
INNER JOIN Dictionary.Country c WITH (NOLOCK) ON c.CountryID = cs.CountryID
WHERE cs.CID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetUserDetails | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetUserDetails.sql*

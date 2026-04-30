# Customer.GetVerificationTitle

> Returns the VerificationTitle and VerificationTitleVersion for a single customer by CID, providing the customer's current display title used in verification flows.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID -> VerificationTitle, VerificationTitleVersion from Customer.CustomerStatic |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetVerificationTitle retrieves the VerificationTitle and VerificationTitleVersion fields from Customer.CustomerStatic for a given customer CID. VerificationTitle is a 4-digit string (e.g., "0742") that serves as the customer's unique display identifier in verification flows - assigned either as a random default via Customer.VerificationTitle_Default() at registration, or updated later via Customer.UpdateVerificationTitle. VerificationTitleVersion tracks the version number of this title assignment.

This procedure is used by BI administrators to check what verification title a customer currently holds - for example, in support investigations, duplicate account detection, or verification flow debugging. The VerificationTitle is displayed to the customer during identity or account verification steps as a personalized code they can recognize.

Data flows: VerificationTitle is set at customer registration via Customer.InsertRealCustomer (using VerificationTitle_Default()) and can be updated via Customer.UpdateVerificationTitle. VerificationTitleVersion is incremented each time the title is updated, enabling detection of title changes.

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
| 1 | @CID | int | NO | - | VERIFIED | Internal eToro Customer ID. Applied as WHERE CID = @CID against the clustered PK of Customer.CustomerStatic. |

**Output columns** (SELECT result set):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | VerificationTitle | varchar(4) | YES | - | CODE-BACKED | The customer's 4-digit verification display title (e.g., "0742"). Assigned at registration via Customer.VerificationTitle_Default() as a pseudo-random 4-digit zero-padded string. Displayed to customers during verification steps as a personal identifier they can recognize. Updated by Customer.UpdateVerificationTitle. NULL for customers where this field has not been populated. |
| 2 | VerificationTitleVersion | int | YES | - | CODE-BACKED | Version counter for the VerificationTitle field. Incremented by Customer.UpdateVerificationTitle each time the title changes. Enables detection of title rotation and provides ordering context when auditing title change history. NULL for customers where this field has not been set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | Reader (SELECT) | Point lookup by CID to retrieve VerificationTitle and VerificationTitleVersion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE permission | Caller | BI administrators use for verification title lookups in support and audit workflows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetVerificationTitle (procedure)
└── Customer.CustomerStatic (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | SELECT source - filtered by CID PK, returns VerificationTitle and VerificationTitleVersion |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | Service account | Verification title lookups for support and audit |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get verification title for a customer
```sql
EXEC Customer.GetVerificationTitle @CID = 12345678;
```

### 8.2 Direct equivalent query for debugging
```sql
SELECT VerificationTitle, VerificationTitleVersion
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE CID = 12345678;
```

### 8.3 Find all customers with a specific verification title (duplicates check)
```sql
SELECT CID, UserName, VerificationTitle, VerificationTitleVersion
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE VerificationTitle = '0742';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 5/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetVerificationTitle | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetVerificationTitle.sql*

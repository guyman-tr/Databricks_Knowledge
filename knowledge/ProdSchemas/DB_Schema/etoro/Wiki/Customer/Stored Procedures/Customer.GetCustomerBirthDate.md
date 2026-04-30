# Customer.GetCustomerBirthDate

> Returns the birth date of a single customer by CID; used for age verification, KYC, and regulatory compliance checks.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer to query) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomerBirthDate is a minimal accessor procedure that retrieves a customer's date of birth from Customer.Customer. Created 2020-09-29 by Elrom Behar (PAYIL-1371), it was introduced as part of the payment/identity layer (PAYIL = Payments IL) to provide a single, auditable entry point for BirthDate retrieval.

The procedure exists because BirthDate is a sensitive PII field protected by SQL Server Dynamic Data Masking in the underlying Customer.CustomerStatic table. By routing BirthDate access through a dedicated procedure, it enables caller-specific access control: only roles/users with EXECUTE permission on this procedure can retrieve the actual unmasked birth date value, rather than directly querying the view.

It is called by payment and payout services (PayoutUser, DepositUser, WithdrawalServiceUser) for age verification and by BackOffice services for KYC compliance.

---

## 2. Business Logic

### 2.1 PII Access Control via Procedure Encapsulation

**What**: BirthDate is a PII field with Dynamic Data Masking; this procedure is the controlled access point.

**Columns/Parameters Involved**: `@CID`, `BirthDate`

**Rules**:
- The procedure grants execute permission to specific service accounts (PayoutUser, DepositUser, etc.) without needing direct table/view SELECT grants
- No NULL guard on @CID: if @CID does not exist in Customer.Customer, returns empty result set (0 rows)
- Returns at most 1 row (Customer.Customer is a view with unique CID)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID to look up. The procedure has no NULL guard; a non-existent CID returns an empty result set. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| BirthDate | Customer.Customer.BirthDate | Customer's date of birth. PII field protected by Dynamic Data Masking in the underlying Customer.CustomerStatic table. Used for age verification (18+ requirement), KYC, and regulatory compliance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Read | Retrieves BirthDate from the customer view |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PayoutUser (SQL login) | EXECUTE | Permission | Payout service reads birth date for age/KYC verification |
| DepositUser (SQL login) | EXECUTE | Permission | Deposit service reads birth date for age verification |
| WithdrawalServiceUser (SQL login) | EXECUTE | Permission | Withdrawal service reads birth date for compliance |
| PROD_BIadmins (SQL role) | EXECUTE | Permission | BI admin role has execute permission |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomerBirthDate (procedure)
└── Customer.Customer (view)
      └── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | Reads BirthDate column filtered by CID |

### 6.2 Objects That Depend On This

No stored procedure dependents found (called directly by external service accounts).

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No NULL guard, no error handling - returns empty result set for non-existent CID.

---

## 8. Sample Queries

### 8.1 Get birth date for a specific customer

```sql
EXEC Customer.GetCustomerBirthDate @CID = 12345678
```

### 8.2 Check birth date via direct view query (requires view SELECT permission)

```sql
SELECT BirthDate
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345678
```

### 8.3 Age verification check

```sql
DECLARE @BirthDate DATE
CREATE TABLE #BD (BirthDate DATE)
INSERT INTO #BD EXEC Customer.GetCustomerBirthDate @CID = 12345678
SELECT BirthDate, DATEDIFF(YEAR, BirthDate, GETDATE()) AS AgeYears FROM #BD WITH (NOLOCK)
DROP TABLE #BD
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 6/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomerBirthDate | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetCustomerBirthDate.sql*

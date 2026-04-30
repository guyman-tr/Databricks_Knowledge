# Billing.PayoutProcess_GetShopperData

> Fetches customer identity (shopper) data for a single payout record, providing the KYC attributes required by payment providers to process a withdrawal.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID (Billing.WithdrawToFunding.ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayoutProcess_GetShopperData` retrieves the customer identity attributes needed by a payment provider to process a withdrawal. Payment providers (e.g., Adyen) require "shopper data" - the customer's legal name, date of birth, gender, email, and nationality - for KYC (Know Your Customer) compliance before disbursing funds.

The procedure accepts a `WithdrawToFunding.ID` and returns a single row with the customer's personal details sourced from `Customer.Customer`, enriched with nationality (country abbreviation) from `Dictionary.Country`. The join chain traces from the WTF record back through the withdrawal request to the customer.

Read-only, no DML. Used by `SQL_SecurePay` (payment gateway integration service with EXECUTE grant). Created by Ran Ovadia, 15/05/2018 (ticket 51527).

---

## 2. Business Logic

### 2.1 Shopper Identity Data Retrieval

**What**: Fetches the customer identity fields required by payment providers for payout KYC.

**Parameters Involved**: `@ID`

**Rules**:
- Join chain: `Billing.WithdrawToFunding (WHERE ID=@ID) -> Billing.Withdraw (ON WithdrawID) -> Customer.Customer (ON CID) -> Dictionary.Country (ON CountryID)`
- Returns: CID, FirstName, LastName, Gender, BirthDate, Email, Nationality (country abbreviation)
- NOLOCK on Customer.Customer and Billing.Withdraw (read-only query, dirty reads acceptable)
- If @ID not found: empty result set (0 rows, no error)

### 2.2 Nationality via Country Abbreviation

**What**: Returns the 2-letter country abbreviation as the nationality field.

**Rules**:
- `Dictionary.Country.Abbreviation AS Nationality` - standard ISO country abbreviation (e.g., 'US', 'GB', 'DE')
- Based on `Customer.Customer.CountryID` -> `Dictionary.Country`
- This is the customer's registered country, used as their nationality indicator for the payment provider

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | INT | NO | - | CODE-BACKED | WithdrawToFunding.ID (the payout record). Used to trace back through Withdraw to the customer. Returns empty if not found. |
| 2 | CID | INT | - | - | CODE-BACKED | Customer ID. Identifies the customer receiving the payout. |
| 3 | FirstName | VARCHAR | - | - | CODE-BACKED | Customer's legal first name (from Customer.Customer). Sent to payment provider for KYC. |
| 4 | LastName | VARCHAR | - | - | CODE-BACKED | Customer's legal last name (from Customer.Customer). Sent to payment provider for KYC. |
| 5 | Gender | CHAR/VARCHAR | - | - | CODE-BACKED | Customer's gender (from Customer.Customer). Required by some payment providers. |
| 6 | BirthDate | DATE/DATETIME | - | - | CODE-BACKED | Customer's date of birth (from Customer.Customer). Required by payment providers for age verification. |
| 7 | Email | VARCHAR | - | - | CODE-BACKED | Customer's registered email address (from Customer.Customer). Contact point for payout notifications. |
| 8 | Nationality | VARCHAR | - | - | CODE-BACKED | Country abbreviation (e.g., 'US', 'GB') from Dictionary.Country.Abbreviation via Customer.Customer.CountryID. Used as nationality field for payment provider KYC. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN (via Withdraw) | Billing.WithdrawToFunding | READ | Filter by ID; traces to withdrawal request |
| JOIN | Billing.Withdraw | READ | Links WTF to CID |
| JOIN | Customer.Customer | READ | Source of all customer identity/KYC fields |
| JOIN | Dictionary.Country | Lookup | Country abbreviation used as Nationality |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_SecurePay (payment gateway service) | @ID | EXEC caller | Fetches shopper KYC data before submitting withdrawal to payment provider |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutProcess_GetShopperData (procedure)
├── Billing.WithdrawToFunding (table)
├── Billing.Withdraw (table)
├── Customer.Customer (table)
└── Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | WHERE ID=@ID - filter by payout record |
| Billing.Withdraw | Table | INNER JOIN - link to CID |
| Customer.Customer | Table | INNER JOIN - KYC identity fields |
| Dictionary.Country | Table | INNER JOIN - country abbreviation (Nationality) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_SecurePay (payment gateway service) | Application | Retrieves shopper KYC data for payment provider submission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Read-only - no DML. NOLOCK on Billing.Withdraw and Customer.Customer. Single-row lookup by WithdrawToFunding.ID. No error handling - exceptions surface as unhandled. Empty result set if @ID not found.

---

## 8. Sample Queries

### 8.1 Fetch shopper data for a payout record

```sql
EXEC Billing.PayoutProcess_GetShopperData @ID = 1234567;
```

### 8.2 Preview shopper data directly

```sql
SELECT
    cc.CID,
    cc.FirstName,
    cc.LastName,
    cc.Gender,
    cc.BirthDate,
    cc.Email,
    c.Abbreviation AS Nationality
FROM Customer.Customer cc WITH (NOLOCK)
INNER JOIN Dictionary.Country c ON c.CountryID = cc.CountryID
INNER JOIN Billing.Withdraw w WITH (NOLOCK) ON w.CID = cc.CID
INNER JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK) ON wtf.WithdrawID = w.WithdrawID
WHERE wtf.ID = 1234567;
```

### 8.3 Find payouts where gender or birthdate is missing (KYC completeness check)

```sql
SELECT
    wtf.ID AS WithdrawToFundingID,
    bw.CID,
    cc.Gender,
    cc.BirthDate,
    cc.Email
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
INNER JOIN Billing.Withdraw bw WITH (NOLOCK) ON bw.WithdrawID = wtf.WithdrawID
INNER JOIN Customer.Customer cc WITH (NOLOCK) ON cc.CID = bw.CID
WHERE (cc.Gender IS NULL OR cc.BirthDate IS NULL)
  AND wtf.CashoutStatusID NOT IN (3, 4)  -- exclude finalized
ORDER BY wtf.ID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: SQL_SecurePay EXECUTE grant confirmed | Corrections: 0 applied*
*Object: Billing.PayoutProcess_GetShopperData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayoutProcess_GetShopperData.sql*

# Billing.SearchSecuredCardData

> Compliance/fraud investigation tool that finds all customers associated with a specific secured card data value (credit card token), searching across both deposits and withdrawals.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns customer list associated with the card token |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a compliance or fraud investigation involves a specific credit card (identified by its `SecuredCardData` token), investigators need to find all eToro customers who have used that card - whether for deposits or withdrawals. `Billing.SearchSecuredCardData` performs this cross-customer search.

It first finds all funding records (FundingTypeID=1 = credit card) with the matching SecuredCardData, then traces those FundingIDs to customers via both the deposit and withdrawal paths. The result is a deduplicated list of customers with their usernames and contact details.

Performance improvement note (Geri Reshef, 26/12/2017): the original version extracted SecuredCardData from the FundingData XML (`FundingData.value('(Funding/SecuredCardDataAsString)[1]','VarChar(100)')`), but was replaced with a direct column lookup on `Billing.Funding.SecuredCardData` for better index utilization.

---

## 2. Business Logic

### 2.1 Multi-Path Customer Discovery

**What**: Finds customers via deposit AND withdrawal paths for the same card.

**Columns/Parameters Involved**: `@SecuredCardData`, `FundingTypeID=1`

**Rules**:
- Step 1: Find all FundingIDs in Billing.Funding WHERE SecuredCardData = @SecuredCardData AND FundingTypeID = 1 (credit card only).
- Step 2a: Join FundingIDs to Billing.Deposit to find CIDs who deposited with this card.
- Step 2b: Join FundingIDs to Billing.WithdrawToFunding -> Billing.Withdraw to find CIDs who withdrew with this card.
- UNION (deduplication) of the two paths.
- Join result to Customer.CustomerStatic for name/email output.
- Results ordered by CID.

**Diagram**:
```
Billing.Funding WHERE SecuredCardData = @SecuredCardData AND FundingTypeID=1
  --> FundingIDs
       |
       +-- Billing.Deposit (Deposit path)   --> CID
       +-- Billing.WithdrawToFunding + Billing.Withdraw (Withdrawal path) --> CID
       |
       UNION
       |
       --> Customer.CustomerStatic (for name/email)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SecuredCardData | VARCHAR(100) | NO | - | CODE-BACKED | The encrypted/tokenized credit card identifier to search for. Matches Billing.Funding.SecuredCardData directly (not XML path, per 2017 optimization). FundingTypeID=1 (credit card) filter applies. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | FundingID | INT | NO | - | CODE-BACKED | Billing.Funding record associated with the card token. May appear once per CID. |
| 3 | CID | INT | NO | - | CODE-BACKED | Customer ID who used this card. |
| 4 | UserName | VARCHAR | NO | - | CODE-BACKED | Customer's eToro username from Customer.CustomerStatic. |
| 5 | FirstName | VARCHAR | YES | - | CODE-BACKED | Customer first name. |
| 6 | LastName | VARCHAR | YES | - | CODE-BACKED | Customer last name. |
| 7 | Email | VARCHAR | NO | - | CODE-BACKED | Customer email address. Used by compliance to contact or further investigate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SecuredCardData | Billing.Funding | READ | Finds matching funding records (FundingTypeID=1) |
| Deposit path | Billing.Deposit | READ | Links FundingIDs to depositing customers |
| Withdrawal path | Billing.WithdrawToFunding, Billing.Withdraw | READ | Links FundingIDs to withdrawing customers |
| Customer data | Customer.CustomerStatic | READ | Returns name and email for found customers |

### 5.2 Referenced By (other objects point to this)

No SQL callers found. Called by compliance/fraud investigation tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SearchSecuredCardData (procedure)
├── Billing.Funding (table)
├── Billing.Deposit (table)
├── Billing.WithdrawToFunding (table)
├── Billing.Withdraw (table)
└── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | Source of SecuredCardData match; FundingTypeID=1 filter |
| Billing.Deposit | Table | Deposit-path customer discovery |
| Billing.WithdrawToFunding | Table | Withdrawal-path funding link |
| Billing.Withdraw | Table | Withdrawal-path CID resolution |
| Customer.CustomerStatic | Table | Customer name and email output |

### 6.2 Objects That Depend On This

No SQL dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FundingTypeID=1 filter | Business filter | Credit cards only. Excludes other funding types (PayPal, wire, etc.) from the search. |
| UNION (not UNION ALL) | Deduplication | Removes duplicate (FundingID, CID) pairs that appear in both deposit and withdrawal paths. |

---

## 8. Sample Queries

### 8.1 Search for customers using a specific card token

```sql
EXEC Billing.SearchSecuredCardData
    @SecuredCardData = 'TOKEN123ENCRYPTED'
```

### 8.2 Find a card's SecuredCardData value for a known FundingID

```sql
SELECT FundingID, SecuredCardData
FROM Billing.Funding WITH (NOLOCK)
WHERE FundingID = 99999
AND FundingTypeID = 1
```

### 8.3 Direct query for customers sharing a card (bypasses SP)

```sql
SELECT DISTINCT f.FundingID, d.CID, cs.UserName, cs.Email
FROM Billing.Funding f WITH (NOLOCK)
JOIN Billing.Deposit d WITH (NOLOCK) ON d.FundingID = f.FundingID
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = d.CID
WHERE f.SecuredCardData = 'TOKEN123ENCRYPTED'
AND f.FundingTypeID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: skipped | Corrections: 0 applied*
*Object: Billing.SearchSecuredCardData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.SearchSecuredCardData.sql*

# Billing.GetSavedCreditCards

> Returns all non-expired, active (CustomerFundingStatusID=1, IsBlocked=0) credit card records for a customer including SchemeID from Billing.CreditCardSchemeID; used to populate the "saved cards" list in the payment UI.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (all credit cards for a customer); optional @count (unused in current query) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetSavedCreditCards` is the saved-cards list loader for the eToro payment UI. When a customer navigates to the deposit page or payment screen, the application calls this procedure to retrieve all of their eligible credit cards - non-expired, active, and not blocked - that can be offered as payment options.

Unlike the singular `Billing.GetSavedCreditCard` (which retrieves one specific card by FundingID), this procedure returns the full set of eligible cards for a customer. It includes the real SchemeID from `Billing.CreditCardSchemeID` (added Jun 2021, Elad F., PAYUS-3126), which identifies the card network scheme (e.g., Visa/Mastercard sub-types).

Performance improvements were made Oct 2023 (Dor I., PAYUSOLA-7154). An additional fix in Jan 2024 (Dor I.) corrected the expiry comparison format string using `FORMAT(GetUTCDate(),'MM')` to ensure the month is always zero-padded (e.g., "03" not "3") for correct string comparison.

The @count parameter (default 100) is declared but NOT applied as a TOP clause in the current query - all eligible cards are returned regardless. This may be a deprecated feature or an oversight.

---

## 2. Business Logic

### 2.1 Active Card Filters

**What**: Four conditions determine which cards are returned.

**Columns/Parameters Involved**: `ctf.CID`, `FundingTypeID`, `ctf.IsBlocked`, `ctf.CustomerFundingStatusID`, expiry from `FundingData`

**Rules**:
- `ctf.CID = @CID` - cards belonging to this customer
- `FundingTypeID = 1` - credit cards only
- `ctf.IsBlocked = 0` - card not blocked (fraud, expiry, customer request)
- `ctf.CustomerFundingStatusID = 1` - card is in Active status (1=Active; other values indicate inactive/deleted states)
- Note: `GetSavedCreditCard` (singular) does NOT check CustomerFundingStatusID - this is an additional eligibility gate in the multi-card version

### 2.2 Expiry Comparison (YYMM String Sort)

**What**: Cards are filtered to only include non-expired ones using a string-based YYMM comparison.

**Columns/Parameters Involved**: `FundingData.value(...ExpirationDateAsString...)`, expiry string concat

**Rules**:
- `FundingData.value('Funding[1]/ExpirationDateAsString[1]','VARCHAR(4)')` returns "MMYY" (e.g., "1226" for Dec 2026)
- Inner query extracts this as `Expiration` column
- Outer WHERE: `RIGHT(Expiration,2) + LEFT(Expiration,2) >= CONVERT(VARCHAR(2), RIGHT(YEAR(GetUTCDate()),2)) + FORMAT(GetUTCDate(),'MM')`
  - `RIGHT(Expiration,2)` = YY (year portion)
  - `LEFT(Expiration,2)` = MM (month portion)
  - Concatenated as "YYMM" string (e.g., "2612")
  - Compared against current "YYMM" string (e.g., "2603" for Mar 2026)
  - String comparison works correctly because "2612" >= "2603" (lexicographic YYMM ordering)
  - Jan 2024 fix: `FORMAT(GetUTCDate(),'MM')` ensures zero-padded month ("03" not "3") - previously `CONVERT(VARCHAR(2), Month(GetUTCDate()))` returned "3" for March, breaking the comparison

### 2.3 SchemeID Lookup

**What**: Returns the card's payment scheme identifier from `Billing.CreditCardSchemeID`.

**Columns/Parameters Involved**: `ccsid.SchemeID`, `Billing.CreditCardSchemeID`

**Rules**:
- `LEFT OUTER JOIN Billing.CreditCardSchemeID ccsid ON f.FundingID = ccsid.FundingID AND @CID = ccsid.CID`
- Both FundingID and CID are used in the JOIN condition (CreditCardSchemeID stores scheme per customer-card pair)
- LEFT JOIN - SchemeID is NULL if no scheme mapping exists for this card
- Contrast with `GetSavedCreditCard` (singular) which hardcodes SchemeID='0'

### 2.4 Unused @count Parameter

**What**: The @count parameter is declared with a default of 100 but is not applied to the query.

**Rules**:
- No `TOP @count` appears in the current SELECT
- All non-expired, active credit cards are returned
- Historical context: this parameter may have been used with a TOP clause that was removed during the Oct 2023 performance tuning (PAYUSOLA-7154)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Returns all active, non-expired credit cards for this customer. |
| 2 | @count | INT | YES | 100 | CODE-BACKED | Declared maximum result count, but NOT applied as a TOP clause in the current query. All eligible cards are returned. May be a deprecated or unused parameter. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | FundingID | INT | NO | - | CODE-BACKED | PK of the funding record (`Billing.Funding.FundingID`). |
| 4 | FundingData | XML | YES | - | CODE-BACKED | Native XML card data from `Billing.Funding.FundingData`. Contains ExpirationDateAsString (MMYY), card number mask, cardholder name, BIN, etc. Returned as XML (unlike the singular version which casts to NVARCHAR). |
| 5 | DepositCreditCardTypeID | INT | YES | - | CODE-BACKED | `Billing.CustomerToFunding.DepositTypeID` aliased as DepositCreditCardTypeID. Credit card type used during deposit processing. |
| 6 | SchemeID | INT/NVARCHAR | YES | NULL | CODE-BACKED | `Billing.CreditCardSchemeID.SchemeID` - the card network scheme identifier (added PAYUS-3126, Jun 2021). NULL if no scheme mapping exists. Contrast with `GetSavedCreditCard` which returns hardcoded '0'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Funding | SELECT (primary, via CustomerToFunding) | Card details and FundingData XML |
| @CID + FundingID | Billing.CustomerToFunding | INNER JOIN | Customer card relationship, IsBlocked, CustomerFundingStatusID, DepositTypeID |
| FundingID + @CID | Billing.CreditCardSchemeID | LEFT OUTER JOIN | Card network scheme identifier |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application payment UI | @CID | EXEC | Loads saved cards list for deposit/payment screens |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetSavedCreditCards (procedure)
+-- Billing.Funding (table)
+-- Billing.CustomerToFunding (table)
+-- Billing.CreditCardSchemeID (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | Primary source of FundingData XML and FundingTypeID |
| Billing.CustomerToFunding | Table | INNER JOIN for CID, IsBlocked, CustomerFundingStatusID, DepositTypeID, LastUsedDate |
| Billing.CreditCardSchemeID | Table | LEFT OUTER JOIN for SchemeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application payment UI | External | Populates the saved credit card selection list |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CustomerFundingStatusID=1 | Filter | Additional active-status check not present in GetSavedCreditCard singular |
| @count unused | DDL gap | Parameter declared but not applied; all eligible cards returned |
| Expiry as YYMM string sort | Design | String comparison works due to zero-padded month (fixed Jan 2024 via FORMAT) |
| SchemeID LEFT JOIN on CID | Design | JOIN condition includes both FundingID and @CID because CreditCardSchemeID stores scheme per customer-card pair |
| FundingData returned as XML | Type | Unlike singular version (NVARCHAR), this returns native XML type |

---

## 8. Sample Queries

### 8.1 Get all saved credit cards for a customer
```sql
EXEC Billing.GetSavedCreditCards @CID = 12345678;
```

### 8.2 Get saved credit cards with @count (has no effect currently)
```sql
EXEC Billing.GetSavedCreditCards @CID = 12345678, @count = 5;
-- Note: @count is ignored; all non-expired active cards are returned
```

### 8.3 Manual equivalent with expiry context
```sql
SELECT
    f.FundingID,
    f.FundingData.value('Funding[1]/ExpirationDateAsString[1]','VARCHAR(4)') AS ExpiryMMYY,
    ctf.CustomerFundingStatusID,
    ctf.IsBlocked,
    ccsid.SchemeID
FROM Billing.Funding f WITH (NOLOCK)
INNER JOIN Billing.CustomerToFunding ctf WITH (NOLOCK) ON ctf.FundingID = f.FundingID
LEFT OUTER JOIN Billing.CreditCardSchemeID ccsid WITH (NOLOCK) ON ccsid.FundingID = f.FundingID AND ccsid.CID = 12345678
WHERE ctf.CID = 12345678
  AND f.FundingTypeID = 1
  AND ctf.IsBlocked = 0
  AND ctf.CustomerFundingStatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUS-3126 (referenced in DDL comment, Elad F., 02/06/2021) | Jira | Added SchemeID JOIN from Billing.CreditCardSchemeID to the result set (Jira unavailable for full details) |
| PAYUSOLA-7154 (referenced in DDL comment, Dor I., 23/10/2023) | Jira | Performance tuning pass (Jira unavailable for full details) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetSavedCreditCards | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetSavedCreditCards.sql*

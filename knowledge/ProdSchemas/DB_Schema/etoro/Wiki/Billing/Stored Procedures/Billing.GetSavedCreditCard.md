# Billing.GetSavedCreditCard

> Returns the most recently used non-expired, non-blocked credit card funding record for a specific customer and FundingID; used to load a single saved card for payment processing with SchemeID hardcoded to '0'.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingID + @CID; returns TOP 1 by LastUsedDate DESC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetSavedCreditCard` retrieves a single saved credit card for a customer, scoped to a specific FundingID. It is called when the billing system needs to load a specific card's details (FundingData XML, deposit type) before initiating a payment. The lookup verifies the card is still usable: not blocked by the customer relationship record (`IsBlocked=0`) and not expired based on the card's expiry date embedded in the FundingData XML.

Created 03 Aug 2021 (Elrom B.). A notable design decision was made 21 Aug 2021: the SchemeID lookup from `Billing.CreditCardSchemeID` was commented out and replaced with a hardcoded `N'0'` default. The sibling procedure `Billing.GetSavedCreditCards` (plural) still retrieves the real SchemeID; this procedure returns '0' regardless of the actual scheme.

The `TOP (1)` with `ORDER BY ctf.LastUsedDate DESC` means that if somehow multiple records match (same FundingID, same CID, credit card, non-blocked, non-expired), the most recently used one is returned.

---

## 2. Business Logic

### 2.1 Card Eligibility Checks

**What**: The WHERE clause applies three validity filters before returning the card.

**Columns/Parameters Involved**: `f.FundingID`, `ctf.CID`, `FundingTypeID`, `ctf.IsBlocked`, `ExpirationDateAsString` (from FundingData XML)

**Rules**:
- `f.FundingID = @FundingID AND ctf.CID = @CID` - exact match on the requested card and customer
- `FundingTypeID = 1` - credit cards only (FundingTypeID=1)
- `ctf.IsBlocked = 0` - card must not be blocked in the customer-to-funding relationship
- Expiry check (not expired): `(expiryYear > currentYear) OR (expiryYear = currentYear AND expiryMonth >= currentMonth)`
  - ExpirationDateAsString format: "MMYY" (4 chars, e.g., "1226" = December 2026)
  - `expiryYear = CAST(RIGHT(ExpirationDateAsString, 2) AS INT)` (last 2 chars = YY)
  - `expiryMonth = CAST(LEFT(ExpirationDateAsString, 2) AS INT)` (first 2 chars = MM)
  - `currentYear = RIGHT(YEAR(GETUTCDATE()), 2)` (2-digit UTC year)
  - `currentMonth = MONTH(GETUTCDATE())`
- Note: AND takes precedence over OR, so the condition correctly evaluates as `(YY > currentYY) OR (YY = currentYY AND MM >= currentMM)`

### 2.2 SchemeID Hardcoded to '0'

**What**: The SchemeID column returns a hardcoded string '0' rather than the actual payment scheme ID.

**Rules**:
- Original DDL (commented out): `ccsid.SchemeID as SchemeID FROM ... LEFT JOIN Billing.CreditCardSchemeID ccsid ON f.FundingID = ccsid.FundingID`
- Current DDL: `N'0' as SchemeID` - hardcoded default
- Use `Billing.GetSavedCreditCards` if the actual SchemeID is needed
- The reason for this removal is not documented in the DDL comments

### 2.3 FundingData Cast to NVARCHAR

**What**: FundingData is returned as cast NVARCHAR rather than the native XML type.

**Rules**:
- `CAST(FundingData AS NVARCHAR(MAX)) AS FundingData` - converts from XML to string
- The sibling `GetSavedCreditCards` returns FundingData as native XML
- Callers of this procedure receive the FundingData as a string they can parse as needed

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INT | NO | - | CODE-BACKED | PK of the specific funding record (`Billing.Funding.FundingID`) to retrieve. Must be a credit card (FundingTypeID=1). |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Used to verify the card belongs to this customer via `Billing.CustomerToFunding.CID = @CID`. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | FundingID | INT | NO | - | CODE-BACKED | PK of the funding record (`Billing.Funding.FundingID`). Echoes @FundingID if found. |
| 4 | FundingData | NVARCHAR(MAX) | YES | - | CODE-BACKED | Card details as XML string, cast from `Billing.Funding.FundingData`. Contains ExpirationDateAsString (MMYY format), card number mask, cardholder name, etc. |
| 5 | DepositCreditCardTypeID | INT | YES | - | CODE-BACKED | `Billing.CustomerToFunding.DepositTypeID` - the credit card type ID used during deposit processing. Determines card-specific deposit handling rules. |
| 6 | SchemeID | NVARCHAR(1) | NO | '0' | CODE-BACKED | Hardcoded to '0'. Originally from `Billing.CreditCardSchemeID.SchemeID` but that JOIN was commented out (Aug 2021). Use `Billing.GetSavedCreditCards` for actual scheme data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID | Billing.Funding | SELECT (primary) | Card details and FundingData XML |
| @FundingID + @CID | Billing.CustomerToFunding | INNER JOIN | Customer card relationship, IsBlocked, DepositTypeID, LastUsedDate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application payment processing | @FundingID, @CID | EXEC | Single card lookup before initiating a credit card payment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetSavedCreditCard (procedure)
+-- Billing.Funding (table)
+-- Billing.CustomerToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | Primary source of FundingData XML and FundingTypeID |
| Billing.CustomerToFunding | Table | INNER JOIN for CID verification, IsBlocked, DepositTypeID, LastUsedDate |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application payment processing | External | Loads specific credit card before initiating payment |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TOP (1) | Safety | Returns at most one card; ORDER BY LastUsedDate DESC picks most recently used if duplicates exist |
| SchemeID hardcoded | Design | CreditCardSchemeID JOIN removed Aug 2021; always returns '0' |
| FundingTypeID=1 | Filter | Only credit cards (type 1); other funding types excluded |
| Expiry check | Business rule | Complex XML-derived expiry check; MMYY format from ExpirationDateAsString |
| No NOLOCK on CustomerToFunding | Consistency | Billing.CustomerToFunding is INNER JOINed without NOLOCK (Billing.Funding has NOLOCK) |

---

## 8. Sample Queries

### 8.1 Get a specific saved credit card
```sql
EXEC Billing.GetSavedCreditCard
    @FundingID = 987654,
    @CID       = 12345678;
-- Returns 0 rows if: card expired, blocked, wrong CID, or not FundingTypeID=1
-- Returns 1 row if valid and non-expired
```

### 8.2 Check card validity manually
```sql
SELECT
    f.FundingID,
    f.FundingData.value('Funding[1]/ExpirationDateAsString[1]','VARCHAR(4)') AS ExpiryMMYY,
    ctf.IsBlocked,
    ctf.LastUsedDate
FROM Billing.Funding f WITH (NOLOCK)
JOIN Billing.CustomerToFunding ctf WITH (NOLOCK) ON ctf.FundingID = f.FundingID
WHERE f.FundingID = 987654
  AND ctf.CID = 12345678
  AND f.FundingTypeID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetSavedCreditCard | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetSavedCreditCard.sql*

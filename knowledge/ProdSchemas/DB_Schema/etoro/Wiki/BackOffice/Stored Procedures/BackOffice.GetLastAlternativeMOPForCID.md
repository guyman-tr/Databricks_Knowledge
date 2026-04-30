# BackOffice.GetLastAlternativeMOPForCID

> Returns the Alternative Method of Payment (AMOP) from the customer's most recent withdrawal request, including the payment method type and parsed payment details extracted from the XML FundingData blob.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer whose last withdrawal's AMOP is retrieved |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the Alternative Method of Payment (AMOP) for a given customer. The AMOP is the non-card payment method used on the customer's most recent withdrawal request. It answers: "What alternative payment method does this customer use, and what are its payment details?" - for example, their bank account number and IBAN for a wire transfer, or their email for a PayPal withdrawal.

The AMOP concept exists in eToro's withdrawal logic because the default cashout (CO) flow prioritizes returning funds to the Original Method of Payment (OMOP - typically the deposit method). When the OMOP cannot cover the full withdrawal amount or is otherwise invalid, the system routes funds to the AMOP. BackOffice agents use this procedure to identify where funds will be sent as an alternative route, and to verify that the AMOP details are valid before processing a manual withdrawal.

The procedure uses a CTE to efficiently identify the most recent withdrawal request (TOP 1 from `Billing.Withdraw` by `WithdrawID DESC`), then joins to `Billing.Funding` to read the associated payment instrument record, whose `FundingData` XML column contains all payment-method-specific fields. A large CASE statement parses this XML differently for each `FundingTypeID`, producing a single human-readable `PaymentDetails` string formatted to show the relevant fields for each payment method.

---

## 2. Business Logic

### 2.1 OMOP vs AMOP Payment Routing

**What**: eToro's withdrawal system routes funds based on a priority hierarchy: Original Method of Payment (OMOP) first, then Alternative Method of Payment (AMOP).

**Columns/Parameters Involved**: `@CID`, `FundingTypeID`, `FundingID`, `PaymentDetails`

**Rules**:
- The OMOP receives priority: if the original deposit method (typically a credit/debit card) can cover the withdrawal, funds go there first.
- The AMOP is used when: the deposit balance on the OMOP is insufficient, the OMOP is no longer valid, or the customer requests an alternative destination.
- This procedure fetches the AMOP details (not OMOP) - the non-card payment instrument associated with the most recent withdrawal.
- Per Confluence (OTS/Methods Of Payment): 3rd party MOPs are NOT acceptable as cashout destinations, except for specific compliance-approved scenarios (3rd party refunds, risk refunds).

**Diagram**:
```
Withdrawal Request Processing:
  1. Check OMOP (original deposit MOP - usually CC)
     -> If sufficient deposit balance -> route to OMOP
  2. If OMOP insufficient or invalid:
     -> Route to AMOP (Alternative MOP - wire, PayPal, etc.)
     -> BackOffice.GetLastAlternativeMOPForCID provides the AMOP details

GetLastAlternativeMOPForCID Logic:
  Billing.Withdraw (TOP 1 by WithdrawID DESC, WHERE CID = @CID)
    -> FundingID, FundingTypeID, ManagerID
  Billing.Funding (JOIN on FundingID)
    -> FundingData (XML)
  Dictionary.FundingType (JOIN on FundingTypeID)
    -> Name (e.g., "Wire Transfer", "PayPal")
  CASE on FundingTypeID -> parse XML -> formatted PaymentDetails string
```

### 2.2 Payment Method-Specific XML Parsing

**What**: The `FundingData` column in `Billing.Funding` stores payment details as an XML blob with a schema that varies by `FundingTypeID`. This procedure decodes the relevant fields for each known payment type.

**Columns/Parameters Involved**: `FundingTypeID`, `FundingData` (XML), `PaymentDetails`

**Rules**:
- FundingTypeID = 2 (Wire Transfer): Parses PayeeName, BankName, ClientBankName, AccountID, IBANCode, SwiftCode, Country (resolved via Dictionary.Country), SortCode, RoutingNumber, BSBNumber - per regulation requirements (e.g., SortCode for GBP UK domestic, BSBNumber for AUD ASIC, RoutingNumber for FinCEN/FINRA).
- FundingTypeID IN (3, 8, 30) (PayPal and similar email-based): Returns Email only.
- FundingTypeID = 6 (Skrill/Moneybookers): Returns AccountID + Email.
- FundingTypeID = 10 (WebMoney or similar): Returns AccountID + Purse.
- FundingTypeID = 14 (Neteller): Returns AccountID only.
- FundingTypeID = 20 (Western Union): Returns CustomerName, CustomerAddress, BankName, BankAddress, SwiftCode, IbanCode, AccountID, CountryID.
- FundingTypeID = 21: Returns AccountID + PayerID (nullable).
- FundingTypeID = 22 (UnionPay): Returns AccountID, CustomerName, BankID, BankName, BankCode, BankAddress, BankAccount.
- FundingTypeID = 28 (Chinese bank transfer): Returns CID label, CustomerName, BankAccountNumber, BranchNameAndAddress, BankName.
- FundingTypeID IN (29, 31) (ACH-style bank debit): Returns BankName, Last4Digits of Account, AccountType.
- All other FundingTypeIDs: Returns NULL for PaymentDetails.
- XML fields that are empty or missing return the literal string 'none'.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Input parameter. The internal customer identifier. The procedure finds the most recent withdrawal record for this CID in `Billing.Withdraw` and returns the associated funding/payment details. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingType | NVARCHAR | YES | - | CODE-BACKED | Human-readable name of the payment method type (e.g., "Wire Transfer", "PayPal", "Skrill"). Resolved from `Dictionary.FundingType` via FundingTypeID. |
| 2 | PaymentDetails | NVARCHAR | YES | - | CODE-BACKED | Formatted string of payment-method-specific details, extracted from the XML `FundingData` column in `Billing.Funding`. Format varies by FundingTypeID (see Business Logic Section 2.2). For unrecognized FundingTypeIDs, returns NULL. |
| 3 | FundingID | INT | YES | - | CODE-BACKED | The ID of the `Billing.Funding` record representing the customer's payment instrument for the most recent withdrawal. References `Billing.Funding.FundingID`. |
| 4 | ManagerID | INT | YES | - | CODE-BACKED | The BackOffice manager ID associated with the most recent withdrawal request. From `Billing.Withdraw.ManagerID` - identifies which manager processed or is assigned to this withdrawal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (internal) | Billing.Withdraw | Lookup (READ) | Source of the most recent withdrawal record; filtered by CID, ordered by WithdrawID DESC |
| FundingID | Billing.Funding | Lookup (READ) | Source of payment instrument details including the XML FundingData blob |
| FundingTypeID | Dictionary.FundingType | Lookup | Resolves FundingTypeID to a human-readable payment method name |
| CountryID (in XML) | Dictionary.Country | Lookup | Used inside the Wire Transfer CASE branch to resolve country ID from XML to country name |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No SQL callers found; invoked directly from the BackOffice application layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetLastAlternativeMOPForCID (procedure)
├── Billing.Withdraw (table) [CTE: TOP 1 by WithdrawID DESC]
├── Billing.Funding (table) [INNER JOIN on FundingID]
├── Dictionary.FundingType (table) [INNER JOIN on FundingTypeID]
└── Dictionary.Country (table) [correlated subquery inside Wire Transfer CASE branch]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | CTE `GetFundingID`: selects TOP 1 most recent withdrawal for the CID (ORDER BY WithdrawID DESC) |
| Billing.Funding | Table | INNER JOIN on FundingID; source of FundingTypeID and FundingData XML |
| Dictionary.FundingType | Table | INNER JOIN to resolve FundingTypeID to payment method name |
| Dictionary.Country | Table | Correlated subquery inside Wire Transfer CASE: resolves CountryIDAsInteger from XML to country name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Called to display the customer's AMOP details during manual withdrawal processing in the BackOffice portal |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CTE TOP 1 ORDER BY WithdrawID DESC | Query logic | Ensures exactly one row is returned - the most recent withdrawal for the customer |
| WITH (NOLOCK) on Billing.Withdraw and Billing.Funding | Query hint | Avoids blocking on payment tables under high-load scenarios |
| XML .value() calls with VARCHAR(MAX) | Data access | FundingData is accessed as XML; fields that don't exist in the XML structure for a given type return empty string or are guarded with .exist() checks |

---

## 8. Sample Queries

### 8.1 Get the last alternative payment method for a customer

```sql
EXEC BackOffice.GetLastAlternativeMOPForCID @CID = 12345
```

### 8.2 Directly query the most recent withdrawal and its funding type

```sql
SELECT TOP 1
    w.WithdrawID,
    w.FundingID,
    w.FundingTypeID,
    ft.Name AS FundingType,
    w.ManagerID
FROM Billing.Withdraw w WITH (NOLOCK)
INNER JOIN Dictionary.FundingType ft WITH (NOLOCK)
    ON ft.FundingTypeID = w.FundingTypeID
WHERE w.CID = 12345
ORDER BY w.WithdrawID DESC;
```

### 8.3 Find all customers who used Wire Transfer (FundingTypeID=2) as their last withdrawal method

```sql
SELECT w.CID,
       ft.Name AS FundingType,
       w.WithdrawID
FROM Billing.Withdraw w WITH (NOLOCK)
INNER JOIN Dictionary.FundingType ft WITH (NOLOCK)
    ON ft.FundingTypeID = w.FundingTypeID
WHERE w.FundingTypeID = 2
  AND w.WithdrawID = (
      SELECT MAX(w2.WithdrawID)
      FROM Billing.Withdraw w2 WITH (NOLOCK)
      WHERE w2.CID = w.CID
  )
ORDER BY w.CID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Methods Of Payment (MOPs) for processing](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/973832296/Methods+Of+Payment+MOPs+for+processing) | Confluence | Defines OMOP vs AMOP routing priority, per-payment-method rules (wire transfer fields, PayPal AMOP restrictions, Neteller/Skrill as AMOP exception), and regulatory requirements per FundingType |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 9.0/10, Logic: 10.0/10, Relationships: 8.5/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetLastAlternativeMOPForCID | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetLastAlternativeMOPForCID.sql*

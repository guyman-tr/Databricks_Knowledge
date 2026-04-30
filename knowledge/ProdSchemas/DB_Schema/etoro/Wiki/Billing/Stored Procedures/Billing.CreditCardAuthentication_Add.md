# Billing.CreditCardAuthentication_Add

> Creates a new card authentication session in `Billing.CreditCardAuthentication` for Zero Auth and 3DS verification in recurring investment plan setup; returns the new session ID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns ID (SCOPE_IDENTITY()) via result set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CreditCardAuthentication_Add` is the WRITER for `Billing.CreditCardAuthentication`. It is called when the CreditCardAuthentication microservice initiates a card authentication session - the first step of the Zero Auth + 3DS flow used to set up recurring investment plans on eToro.

A Zero Auth is a card verification technique where a zero-value (or very small) charge is made to checkout.com to: (1) confirm the card is valid, (2) perform 3DS authentication, and (3) obtain a SchemeID that enables future Merchant Initiated Transactions (MIT) - recurring charges without requiring the customer to re-authenticate. This procedure creates the session record at initiation with `StatusID=1` (New) and returns the new session ID for the calling service to track.

The procedure is part of the Recurring Investment Phase 1.2 feature (live November 2025). `Created` and `Modified` timestamps are always set to `GETUTCDATE()` regardless of caller input. The table is SYSTEM_VERSIONED, so all subsequent status changes via `CreditCardAuthentication_Update` are automatically archived to `History.BillingCreditCardAuthenticationHistory`.

---

## 2. Business Logic

### 2.1 Session Initiation for Zero Auth

**What**: Creates the initial session record with all plan context needed for the Zero Auth call to checkout.com.

**Parameters Involved**: `@CID`, `@StatusID`, `@FundingID`, `@Amount`, `@SchemeID`, `@RecurringFrequency`, `@RecurringStartDate`, `@RecurringEndDate`

**Rules**:
- `@StatusID` is typically 1 (New) at creation - the session is awaiting authentication
- `@Amount` is typically 0.00 for Zero Auth (no real charge); may be a small test amount for some flows
- `@RecurringFrequency`, `@RecurringStartDate`, `@RecurringEndDate` bind the SchemeID to the specific recurring plan at checkout.com
- `@SchemeID` is typically NULL at creation; populated after checkout.com responds (via `CreditCardAuthentication_Update`)
- `@ThreeDsData` is typically NULL at creation; populated after 3DS response
- `Created` and `Modified` are always forced to `GETUTCDATE()` by the INSERT VALUES clause, regardless of any caller expectation
- Returns `SCOPE_IDENTITY() AS ID` in a result set (not via OUTPUT parameter)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Customer ID whose card is being authenticated. Written to `Billing.CreditCardAuthentication.CID`. Implicit FK to Customer.CustomerStatic. |
| 2 | @StatusID | int | NO | - | VERIFIED | Initial authentication session state. Typically 1 (New) at creation. FK to `Dictionary.CreditCardAuthenticationStatus`: 1=New, 2=Approved, 3=Decline, 4=Technical, 35=DeclineByRRE. |
| 3 | @StatusReasonID | int | NO | - | CODE-BACKED | Reason code for the initial status. Observed dominant value: 3. Set by the calling service based on the authentication flow being initiated. |
| 4 | @CurrencyID | int | NO | - | CODE-BACKED | Currency for the authentication amount. References `Dictionary.Currency`. Common values: 0=no-currency zero auth, 1=USD, 2=EUR. |
| 5 | @Amount | money | NO | - | VERIFIED | Amount for the authentication. Typically 0.00 for Zero Auth. Passed to checkout.com as part of the plan context that determines the returned SchemeID. |
| 6 | @FundingID | int | NO | - | VERIFIED | The customer's registered card (Billing.Funding record) being authenticated. The central link between this authentication session and the payment instrument. |
| 7 | @RecurringFrequency | int | YES | NULL | ATLASSIAN-ONLY | Recurring plan charge frequency (e.g., 1=monthly). Passed to checkout.com to bind the returned SchemeID to this specific plan schedule. NULL for one-time authentications. |
| 8 | @RecurringStartDate | datetime | YES | NULL | ATLASSIAN-ONLY | Start date of the recurring investment plan being set up. Included in the Zero Auth context. NULL for non-recurring authentications. |
| 9 | @RecurringEndDate | datetime | YES | NULL | ATLASSIAN-ONLY | End date of the recurring plan. NULL for open-ended plans or one-time authentications. |
| 10 | @ProcessRegulationID | int | YES | NULL | CODE-BACKED | Regulatory context: 1=standard, 4=enhanced regulation. Influences 3DS and risk management rules applied. NULL if not specified. |
| 11 | @DepotID | int | YES | NULL | CODE-BACKED | Payment depot/terminal for the authentication. Implicit FK to Billing.Depot. Often NULL at creation; updated by `CreditCardAuthentication_Update` after routing decisions. |
| 12 | @MerchantAccountID | int | YES | NULL | CODE-BACKED | Merchant account at checkout.com. Often NULL at creation; updated by `CreditCardAuthentication_Update` after routing. |
| 13 | @SchemeID | nvarchar(100) | YES | NULL | VERIFIED | checkout.com scheme ID from a successful Zero Auth. Typically NULL at creation; populated in subsequent update after checkout.com responds. Enables future MIT charges. |
| 14 | @ThreeDsData | nvarchar(max) | YES | NULL | VERIFIED | Raw 3DS response payload (JSON/XML from Cardinal SDK). NULL at creation; populated by `CreditCardAuthentication_Update` after 3DS authentication step completes. |
| 15 | @FirstName | nvarchar(100) | YES | NULL | CODE-BACKED | Cardholder first name. DDM-masked in the table (`default()` function - non-privileged users see NULL). Optional cardholder identity context. |
| 16 | @MiddleName | nvarchar(100) | YES | NULL | CODE-BACKED | Cardholder middle name. DDM-masked in the table. |
| 17 | @LastName | nvarchar(100) | YES | NULL | CODE-BACKED | Cardholder last name. DDM-masked in the table. |
| 18 | @ReferenceID | nvarchar(100) | YES | NULL | NAME-INFERRED | External reference for this authentication session (e.g., checkout.com payment ID, Cardinal transaction ID). Used for correlation with provider systems. |

**Result set**: Returns `SCOPE_IDENTITY() AS ID` - the new `Billing.CreditCardAuthentication.ID`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (INSERT target) | Billing.CreditCardAuthentication | Write | Creates new authentication session record |
| @CID | Customer.CustomerStatic | Implicit | Customer whose card is being authenticated |
| @FundingID | Billing.Funding | Implicit | The payment instrument (registered card) |
| @StatusID | Dictionary.CreditCardAuthenticationStatus | Lookup | Initial session status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CreditCardAuthentication microservice | All params | Caller | Called to initiate card authentication for recurring plan setup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CreditCardAuthentication_Add (procedure)
+-- Billing.CreditCardAuthentication (table) [INSERT target; system-versioned]
      History.BillingCreditCardAuthenticationHistory (auto-archived by SQL Server)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCardAuthentication | Table | INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CreditCardAuthentication microservice | External | Calls to create authentication sessions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Notable behavior**: `Created` and `Modified` are hardcoded to `GETUTCDATE()` in the INSERT, not taken from parameters. The new row's ID is returned via `SELECT SCOPE_IDENTITY() AS ID` result set (not via OUTPUT parameter - callers must read the result set).

---

## 8. Sample Queries

### 8.1 Create a new Zero Auth session (caller pattern)

```sql
EXEC Billing.CreditCardAuthentication_Add
    @CID = 24186018,
    @StatusID = 1,          -- New
    @StatusReasonID = 3,
    @CurrencyID = 1,        -- USD
    @Amount = 0.00,         -- Zero auth
    @FundingID = 12345,
    @RecurringFrequency = 1,
    @RecurringStartDate = '2026-04-01',
    @RecurringEndDate = NULL,
    @ProcessRegulationID = 1
-- Result set: ID = new session ID
```

### 8.2 View recent Zero Auth sessions

```sql
SELECT TOP 20
    cca.ID, cca.CID, cca.StatusID, cca.StatusReasonID,
    cca.FundingID, cca.Amount, cca.CurrencyID,
    cca.SchemeID, cca.Created, cca.Modified
FROM Billing.CreditCardAuthentication cca WITH (NOLOCK)
ORDER BY cca.Created DESC
```

### 8.3 Find sessions awaiting checkout.com response

```sql
SELECT cca.ID, cca.CID, cca.FundingID, cca.Created
FROM Billing.CreditCardAuthentication cca WITH (NOLOCK)
WHERE cca.StatusID = 1  -- New - still in progress
ORDER BY cca.Created ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HLD Recurring Payments Zero Auth](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13281656921) | Confluence | Zero Auth flow architecture: SchemeID binding to recurring plans, MIT enablement, CIT vs MIT distinction, 3DS response types |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 11 CODE-BACKED, 4 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CreditCardAuthentication_Add | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CreditCardAuthentication_Add.sql*

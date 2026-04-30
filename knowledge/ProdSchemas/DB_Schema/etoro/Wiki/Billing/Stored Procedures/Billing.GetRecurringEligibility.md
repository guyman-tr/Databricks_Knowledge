# Billing.GetRecurringEligibility

> Returns each non-blocked payment method for a customer with three readiness flags - whether a card-on-file token exists, whether 3DS authentication is available, and whether the method is currently visible/active - enabling the application to determine which instruments are eligible for recurring (merchant-initiated) charges.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer scope); returns one row per eligible FundingID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRecurringEligibility` answers the question: "Which of this customer's saved payment methods can be used for an automatic, merchant-initiated charge right now?" It is the gateway check before the system attempts a recurring deposit - the caller receives a result set listing each qualifying funding instrument along with the flags needed to choose the best charging strategy.

The procedure exists to support recurring deposit features (automatic top-ups, subscription charges) where the customer is not present at time of payment. For such Merchant-Initiated Transactions (MIT) to succeed, the payment instrument must (a) not be blocked at the customer or funding level, (b) not be expired (for credit cards), and (c) have a valid card-on-file SchemeID registered with the payment processor. The `WithSchemeId` and `With3Ds` flags directly encode these MIT requirements.

Data flow: the application calls this procedure with a customer ID and an optional JSON list of FundingTypeIDs (defaulting to credit cards only). The procedure queries `Billing.CustomerToFunding` + `Billing.Funding` to gather the customer's non-blocked instruments, strips out expired credit cards by parsing the XML `FundingData` expiry field, then LEFT JOINs `Billing.CreditCardSchemeID` to determine card-on-file token availability. The result set is consumed by the application's recurring eligibility service to decide whether to proceed with an automatic charge and which charging path to use (standard vs 3DS).

---

## 2. Business Logic

### 2.1 Eligibility Filter Pipeline

**What**: A three-stage filter reduces the full set of a customer's registered payment methods to those safe for automatic charging.

**Columns/Parameters Involved**: `@CID`, `@FundingTypesConfig`, `ctf.IsBlocked`, `f.IsBlocked`, `FundingTypeID`

**Rules**:
- Stage 1 - Type filter: only FundingTypeIDs present in the `@FundingTypesConfig` JSON array are loaded into the temp table. Default `[1]` = credit cards only. Pass `[1,3,6]` to include PayPal and Neteller alongside cards.
- Stage 2 - Block filter: both `CustomerToFunding.IsBlocked = 0` AND `Funding.IsBlocked = 0` must be true. A funding blocked at either level is excluded entirely, regardless of type or expiry.
- Stage 3 - Expiry filter (credit cards only): for FundingTypeID=1, the XML expiry is parsed and cards where `ExpirationYear < thisYear` OR `(ExpirationYear = thisYear AND ExpirationMonth <= thisMonth)` are deleted. The `<= thisMonth` boundary means a card expiring during the current calendar month is treated as expired (conservative).

**Diagram**:
```
CustomerToFunding (all for @CID)
  |-- FundingTypeID IN @FundingTypesConfig?  NO -> excluded
  |-- IsBlocked = 0 (ctf)?                  NO -> excluded
  |-- f.IsBlocked = 0 (Funding)?            NO -> excluded
  |-- FundingTypeID=1 AND card expired?     YES -> DELETE from temp
  v
Eligible set -> LEFT JOIN CreditCardSchemeID -> return with flags
```

### 2.2 Card-on-File Token Flags (MIT Readiness)

**What**: Two BIT flags indicate the availability and quality of the card-on-file token needed for merchant-initiated transactions.

**Columns/Parameters Involved**: `WithSchemeId`, `With3Ds`, `Billing.CreditCardSchemeID`

**Rules**:
- `WithSchemeId = 1` when at least one `CreditCardSchemeID` row exists for (FundingID, CID). Without a SchemeID, the payment processor cannot charge the card without the customer's live involvement. This is the minimum requirement for recurring payments.
- `With3Ds = 1` when any matched SchemeID row has `IsThreeDs = 1` (computed via `MAX(CONVERT(INT, IsThreeDs)) > 0`). A 3DS-authenticated token provides stronger SCA (Strong Customer Authentication) compliance and higher approval rates for recurring charges in regulated markets (EU/UK).
- Both flags are CAST to BIT, producing clean 0/1 values. A funding record with no CreditCardSchemeID rows has both flags = 0.

### 2.3 Visibility vs Block Distinction

**What**: The procedure separates "blocked" (excluded entirely) from "deactivated" (returned with IsVisible=0), giving the caller full information.

**Columns/Parameters Involved**: `IsVisible`, `CustomerFundingStatusID`

**Rules**:
- Blocked funding methods (IsBlocked=1) are never returned - the WHERE clause removes them before the temp table is built.
- Non-blocked but deactivated methods (CustomerFundingStatusID != 1) ARE returned, but `IsVisible = IIF(CustomerFundingStatusID = 1, 1, 0)` = 0. The caller can use this to present the method differently or skip it.
- `IsVisible = 1` only when `CustomerFundingStatusID = 1` (Active). All other statuses (0=Deactivated, 2, 3=RemovedFromDeposit, 4=Extended-Active) yield IsVisible=0.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Scopes all queries to one customer's payment methods. Maps to `Billing.CustomerToFunding.CID`. |
| 2 | @FundingTypesConfig | NVARCHAR(50) | YES | `'[1]'` | CODE-BACKED | JSON array of FundingTypeID integers to include in the eligibility check. Default `[1]` = credit cards only (Billing.Funding FundingTypeID=1). Pass additional IDs (e.g., `[1,3,6]`) to check PayPal or Neteller. Parsed via `OPENJSON()`. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method category for this row. Sourced from `Billing.Funding.FundingTypeID`. Used by the caller to apply type-specific charging logic (e.g., credit card flow vs e-wallet flow). |
| 4 | FundingID | INT | NO | - | CODE-BACKED | Specific funding instrument identifier. FK to `Billing.Funding.FundingID`. The caller passes this ID to deposit/charge procedures to identify which payment method to use. |
| 5 | WithSchemeId | BIT | NO | - | CODE-BACKED | 1 = a card-on-file token (SchemeID) exists in `Billing.CreditCardSchemeID` for this (CID, FundingID). This is the minimum requirement for merchant-initiated (recurring) charges - without a SchemeID the payment processor cannot charge without customer presence. 0 = no token registered. |
| 6 | With3Ds | BIT | NO | - | CODE-BACKED | 1 = at least one SchemeID row for this (CID, FundingID) has `IsThreeDs = 1` (3DS-authenticated card-on-file token). 3DS tokens provide SCA compliance for EU/UK regulated markets and generally achieve higher authorization rates. Derived via `MAX(CONVERT(INT, IsThreeDs)) > 0`. 0 = only non-3DS tokens exist, or no token at all. |
| 7 | IsVisible | BIT | NO | - | CODE-BACKED | 1 = the customer's link to this funding is Active (`CustomerToFunding.CustomerFundingStatusID = 1`). 0 = the link exists but is Deactivated, RemovedFromDeposit, or in another non-active state. The caller uses this to decide whether to surface the method in the UI or in automatic-charge selection. Per `Billing.CustomerToFunding` Section 2.2: only status=1 yields IsVisible=1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.CustomerToFunding | JOIN | Filters customer's registered payment instruments by CID |
| FundingID (via ctf) | Billing.Funding | JOIN | Retrieves payment method type, block status, and XML data |
| FundingID / @CID | Billing.CreditCardSchemeID | LEFT JOIN | Retrieves card-on-file tokens for MIT readiness flags |
| @FundingTypesConfig values | Billing.Funding.FundingTypeID | Lookup | JSON-parsed type filter; default [1] = credit cards |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application (billing service) | @CID, @FundingTypesConfig | EXEC | Called by the application's recurring deposit eligibility service before initiating an MIT charge. Not called by any other stored procedure in the Billing schema. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRecurringEligibility (procedure)
├── Billing.CustomerToFunding (table)
├── Billing.Funding (table)
└── Billing.CreditCardSchemeID (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | INNER JOIN on CID + FundingID; filters by IsBlocked=0 and FundingTypeID list |
| Billing.Funding | Table | INNER JOIN on FundingID; reads FundingTypeID, IsBlocked, FundingData XML for expiry parsing |
| Billing.CreditCardSchemeID | Table | LEFT JOIN on (FundingID, CID); reads SchemeID (existence) and IsThreeDs for MIT readiness flags |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application recurring deposit service | External | Calls this procedure to determine which payment instruments are eligible for automatic MIT charges |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Expiry DELETE logic | Business rule | Only FundingTypeID=1 rows are expiry-checked; other payment types (bank accounts, e-wallets) are not expired by date |
| Conservative expiry boundary | Business rule | `ExperationMonth <= thisMonth` - a card expiring in the current month is treated as expired. Protects against charges on a card about to expire mid-month. |
| XML parsing path | Technical | `FundingData.value('Funding[1]/ExpirationDateAsString[1]','VARCHAR(Max)')` - expected format "MM/YY"; Left 2 chars = month, Right 2 chars = 2-digit year |
| `WITH (NOLOCK)` | Concurrency | Both base table reads use NOLOCK - read consistency is sacrificed for throughput; acceptable for eligibility pre-check |

---

## 8. Sample Queries

### 8.1 Check recurring eligibility for a customer (default: credit cards)
```sql
EXEC Billing.GetRecurringEligibility @CID = 12345678;
```

### 8.2 Check eligibility across multiple payment types
```sql
EXEC Billing.GetRecurringEligibility
    @CID = 12345678,
    @FundingTypesConfig = N'[1,3,6]';
-- Returns credit cards (1), PayPal (3), and Neteller (6) for this customer
-- WithSchemeId=1 required for MIT; With3Ds=1 preferred for SCA markets
```

### 8.3 Inspect raw eligibility data for a customer's cards
```sql
SELECT
    ctf.CID,
    ctf.FundingID,
    f.FundingTypeID,
    ctf.CustomerFundingStatusID,
    ctf.IsBlocked AS CtfBlocked,
    f.IsBlocked AS FundingBlocked,
    ccsi.SchemeID,
    ccsi.IsThreeDs
FROM Billing.CustomerToFunding ctf WITH (NOLOCK)
INNER JOIN Billing.Funding f WITH (NOLOCK) ON ctf.FundingID = f.FundingID
LEFT JOIN Billing.CreditCardSchemeID ccsi WITH (NOLOCK)
    ON ctf.FundingID = ccsi.FundingID AND ccsi.CID = ctf.CID
WHERE ctf.CID = 12345678
  AND f.FundingTypeID = 1;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUS-2979 (referenced in DDL comment, 2021-05-20) | Jira | Initial version of the procedure - Inna A. created it for recurring deposit eligibility (Jira unavailable for full details) |
| PAYUSOLA-5090 / PAUYSOLA-5385 (referenced in DDL comment, 2022-08-21) | Jira | Enhancement to exclude expired credit cards from eligibility results (Jira unavailable for full details) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira MCP unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetRecurringEligibility | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRecurringEligibility.sql*

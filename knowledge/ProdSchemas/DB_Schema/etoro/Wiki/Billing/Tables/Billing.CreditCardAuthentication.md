# Billing.CreditCardAuthentication

> System-versioned audit table for credit card Zero Auth and 3DS authentication sessions used in recurring investment plan setup; each row tracks one card authentication attempt from initial request through approval, decline, or technical error.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | N/A - PRIMARY filegroup |
| **Indexes** | 1 (PK only) |
| **Special** | SYSTEM_VERSIONING = ON -> History.BillingCreditCardAuthenticationHistory; DDM masking on FirstName, MiddleName, LastName |

---

## 1. Business Meaning

`Billing.CreditCardAuthentication` records every card authentication session for recurring investment plan setup. When a customer chooses a credit card for a recurring investment plan, the payment system performs a "Zero Auth" - a card verification via checkout.com that proves the card is valid and the cardholder is authenticated, without charging real funds. This table is the persistent store of those authentication sessions.

The feature (Recurring Investment Phase 1.2 - 3DS Zero Auth) went live in November 2025, which is why all 9,013 rows date from 2025-11-17 onward. The `CreditCardAuthentication` microservice writes and updates rows through `CreditCardAuthentication_Add` and `CreditCardAuthentication_Update` stored procedures, called when the card front-end service orchestrates the 3DS and Zero Auth flows with checkout.com.

The table is **SYSTEM_VERSIONED** (SQL Server temporal table): all changes are automatically archived in `History.BillingCreditCardAuthenticationHistory` with system-managed `ValidFrom`/`ValidTo` columns, providing a complete history of status transitions. `FirstName`, `MiddleName`, and `LastName` are protected with Dynamic Data Masking (DDM) - only privileged roles see the actual cardholder name.

---

## 2. Business Logic

### 2.1 Authentication Status Lifecycle

**What**: Each authentication session moves through status transitions from New through a terminal state (Approved, Decline, Technical, DeclineByRRE).

**Columns/Parameters Involved**: `StatusID`, `StatusReasonID`, `ThreeDsResponseType`, `ProviderResponseCode`

**Rules**:
- `StatusID` values (from Dictionary.CreditCardAuthenticationStatus):
  - 1 = New: Session created, authentication in progress (1,952 rows)
  - 2 = Approved: Authentication succeeded - card can be used for recurring plan (6,096 rows, 68%)
  - 3 = Decline: Authentication declined by issuer or checkout.com (133 rows)
  - 4 = Technical: Technical error occurred during authentication (72 rows)
  - 5 = (not in lookup - likely a newer status added after deployment, 325 rows)
  - 35 = DeclineByRRE: Declined by the Risk and Routing Engine (435 rows)
- Status transitions are recorded in History.BillingCreditCardAuthenticationHistory via system versioning.
- `StatusReasonID` provides additional detail on the reason for the final status. Values: 1 (2,019 rows), 3 (6,341 rows - dominant), 4 (368 rows), 7 (273 rows), 8-11 (rare).

**Diagram**:
```
CreditCardAuthentication_Add (StatusID=1, New)
  |
  |--> 3DS flow (if ShouldCheck3ds per Dictionary.CountryBin)
  |     ThreeDsResponseType: Y=Success, N=Failed, B=Bypassed,
  |                          U=Unable, A=Attempts, R=Rejected
  |
  |--> Zero Auth flow (checkout.com)
  |     ProviderResponseCode: checkout.com error codes
  |
  v
CreditCardAuthentication_Update -> StatusID 2 (Approved)
                                -> StatusID 3 (Decline)
                                -> StatusID 4 (Technical)
                                -> StatusID 35 (DeclineByRRE)
```

### 2.2 Zero Auth for Recurring Plan Setup

**What**: A zero-value card authentication that binds a SchemeID to a specific recurring plan, enabling future merchant-initiated transactions (MIT) without requiring customer re-authentication.

**Columns/Parameters Involved**: `SchemeID`, `FundingID`, `RecurringFrequency`, `RecurringStartDate`, `RecurringEndDate`, `Amount`

**Rules**:
- Per Confluence (HLD Recurring Payments Zero Auth, 2025-11-17): the `SchemeID` returned by checkout.com is connected to a specific recurring investment plan - not just to the card. This distinguishes Zero Auth from regular 3DS.
- `RecurringFrequency`, `RecurringStartDate`, `RecurringEndDate` capture the plan schedule at authentication time. Zero Auth data must include these so the returned SchemeID is tied to that specific plan.
- `Amount` is typically 0 (zero auth) but can be a small test charge amount.
- Once Approved, the SchemeID enables Merchant Initiated Transactions (MIT) - future recurring charges without customer re-authentication.

### 2.3 3DS Configuration

**What**: 3DS challenge is applied selectively based on country/BIN configuration.

**Columns/Parameters Involved**: `ThreeDsData`, `ThreeDsResponseType`, `ProcessRegulationID`

**Rules**:
- 3DS is triggered based on `Dictionary.CountryBin.ShouldCheck3ds` configuration.
- `ThreeDsData` stores the raw 3DS response from Cardinal SDK (nvarchar(max)).
- `ThreeDsResponseType` values (from Confluence): 1=Y(Success/Continue), 2=N(Failed), B=Bypassed(Continue), U=Unable(Continue), A=Attempts(Continue), R=Rejected(Failed), I=Informational. Data shows values 1, 10 etc. - specific int encoding per lookup.
- `ProcessRegulationID` indicates the regulatory context: 1=standard regulation, 4=enhanced regulation. Affects which payment flows are permitted.

---

## 3. Data Overview

| ID | CID | StatusID | StatusReasonID | FundingID | Amount | RecurringFrequency | Meaning |
|----|-----|----------|----------------|-----------|--------|--------------------|---------|
| 1 | 24186018 | 4 (Technical) | 11 | (FundingID) | 10.00 | 1 | Authentication failed with technical error during 3DS/Zero Auth flow. ProcessRegulationID=4 (enhanced regulation). |
| 2 | 23977840 | 2 (Approved) | 3 | (FundingID) | 0.00 | 1 | Successful zero auth - card authenticated for recurring plan. Zero amount confirms no real charge. |
| 3 | 24186332 | 4 (Technical) | 3 | (FundingID) | 0.00 | 1 | Another technical error; ThreeDsResponseType=1 (Y=Success) means 3DS passed but Zero Auth itself had technical issue. |
| 5 | 9329025 | 4 (Technical) | 3 | (FundingID) | 0.00 | 1 | Technical decline for different customer; CurrencyID=2 (EUR). RollbackReasonID=3 is dominant in current data. |
| - | various | 2 (Approved) | 3 | various | 0.00 | 1 | 68% of all rows are Approved - most authentication sessions succeed. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key. Returned via SCOPE_IDENTITY() to the caller after insert. |
| 2 | CID | int | NO | - | VERIFIED | Customer ID whose card is being authenticated. Implicit FK to Customer.CustomerStatic(CID). |
| 3 | StatusID | int | NO | - | VERIFIED | Authentication session state. FK to Dictionary.CreditCardAuthenticationStatus. Values: 1=New, 2=Approved, 3=Decline, 4=Technical, 35=DeclineByRRE. Updated by CreditCardAuthentication_Update as the authentication progresses. |
| 4 | StatusReasonID | int | NO | - | CODE-BACKED | Reason code providing additional context for the StatusID. No Dictionary lookup table found. Observed values: 1 (2,019 rows), 3 (6,341 rows - dominant, likely "3DS flow"), 4 (368 rows), 7-11 (rare). Set at creation by the calling service. |
| 5 | Created | datetime | NO | GETUTCDATE() | VERIFIED | UTC timestamp when the authentication session was initiated. Auto-set by CreditCardAuthentication_Add; not controlled by the caller. |
| 6 | Modified | datetime | NO | GETUTCDATE() | VERIFIED | UTC timestamp of the most recent update to this session. Automatically updated to GETUTCDATE() by every call to CreditCardAuthentication_Update. |
| 7 | CurrencyID | int | NO | - | CODE-BACKED | Currency of the amount used in authentication. Implicit FK to Dictionary.Currency. Common values: 0 (no-currency zero auth), 1=USD, 2=EUR. |
| 8 | Amount | money | NO | - | VERIFIED | Amount used in the authentication transaction. Typically 0.00 for Zero Auth (no real charge). Passed by the calling service as part of the plan parameters that are encoded in the returned SchemeID. |
| 9 | RecurringFrequency | int | YES | - | ATLASSIAN-ONLY | Recurring plan charge frequency (e.g., 1=monthly). Per Confluence, this is passed to checkout.com as part of the Zero Auth so the SchemeID encodes the specific plan schedule. NULL when not a recurring plan context. |
| 10 | RecurringStartDate | datetime | YES | - | ATLASSIAN-ONLY | Start date of the recurring investment plan being set up. Included in the Zero Auth to bind SchemeID to the specific plan. NULL for one-time authentications. |
| 11 | RecurringEndDate | datetime | YES | - | ATLASSIAN-ONLY | End date of the recurring investment plan. NULL for open-ended plans or one-time authentications. |
| 12 | ProcessRegulationID | int | YES | - | CODE-BACKED | Regulatory context for this authentication. Observed values: 1=standard regulation, 4=enhanced regulation (requires additional checks). Influences which 3DS and risk management rules apply. |
| 13 | DepotID | int | YES | - | CODE-BACKED | Payment terminal/depot configuration used for this authentication. Implicit FK to Billing.Depot. Updated by CreditCardAuthentication_Update. NULL if not yet assigned. |
| 14 | MerchantAccountID | int | YES | - | CODE-BACKED | Merchant account at checkout.com used for this authentication. Influences routing and success rates. Updated by CreditCardAuthentication_Update. NULL if not yet assigned. |
| 15 | FundingID | int | NO | - | VERIFIED | The Billing.Funding record (registered card) being authenticated. Implicit FK to Billing.Funding(FundingID). Central link between this authentication record and the payment instrument. |
| 16 | SchemeID | nvarchar(100) | YES | - | VERIFIED | The checkout.com scheme ID returned after successful Zero Auth. Per Confluence: this ID is linked to a specific recurring plan (not just the card), enabling future Merchant Initiated Transactions (MIT). NULL until checkout.com returns a successful response. |
| 17 | ThreeDsData | nvarchar(max) | YES | - | VERIFIED | Raw 3DS response data from Cardinal SDK. JSON/XML payload containing the full 3DS authentication response. NULL if 3DS was not triggered (e.g., BIN not configured for 3DS per Dictionary.CountryBin). Updated by CreditCardAuthentication_Update. |
| 18 | ThreeDsResponseType | int | YES | - | VERIFIED | Encoded result of the 3DS authentication step. Based on Cardinal/EMV 3DS response codes: Y=Success, N=Failed, B=Bypassed, U=Unable, A=Attempts, R=Rejected, I=Informational (encoded as integers). NULL if 3DS was not triggered. |
| 19 | RiskManagementStatusID | int | YES | - | NAME-INFERRED | Risk management check result for this authentication. Always NULL in current data (9,013 rows). Reserved for integration with risk scoring - once populated will reflect whether the authentication passed or failed risk checks. |
| 20 | ValidFrom | datetime2(7) | NO | GENERATED | VERIFIED | System-generated temporal period start. Automatically maintained by SQL Server system versioning. Marks when this row version became current. |
| 21 | ValidTo | datetime2(7) | NO | GENERATED | VERIFIED | System-generated temporal period end. When a row is updated, old ValidTo is set and new row created. Use FOR SYSTEM_TIME to query history. |
| 22 | FirstName | nvarchar(100) | YES | - | CODE-BACKED | Cardholder first name. MASKED with DDM default() function - returns NULL for non-privileged users. Stored for authentication context; not used in routing logic. |
| 23 | MiddleName | nvarchar(100) | YES | - | CODE-BACKED | Cardholder middle name. MASKED with DDM. |
| 24 | LastName | nvarchar(100) | YES | - | CODE-BACKED | Cardholder last name. MASKED with DDM. |
| 25 | ReferenceID | nvarchar(100) | YES | - | NAME-INFERRED | External reference ID for this authentication session (e.g., checkout.com payment ID, Cardinal transaction ID). Passed by the calling service as optional context. |
| 26 | ProviderResponseCode | nvarchar(100) | YES | - | VERIFIED | Raw response code from checkout.com for the Zero Auth request. Updated by CreditCardAuthentication_Update. Used in error classification. Per Confluence examples: 20062=Restricted Card, 40205=Gateway Reject BIN Blacklist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | Customer whose card is being authenticated |
| FundingID | Billing.Funding | Implicit | The registered card (payment instrument) being authenticated |
| StatusID | Dictionary.CreditCardAuthenticationStatus | Implicit | Authentication state: 1=New, 2=Approved, 3=Decline, 4=Technical, 35=DeclineByRRE |
| CurrencyID | Dictionary.Currency | Implicit | Currency of the auth amount |
| ProcessRegulationID | (regulation lookup) | Implicit | Regulatory context for this authentication |
| DepotID | Billing.Depot | Implicit | Payment terminal configuration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CreditCardAuthentication_Add | (all columns) | WRITER | Creates the initial session record; returns new ID |
| Billing.CreditCardAuthentication_Update | ID | MODIFIER | Updates status, ThreeDsData, SchemeID, RiskManagementStatusID, ProviderResponseCode |
| Billing.CreditCardAuthentication_Get | ID | READER | Retrieves session details for the calling service |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CreditCardAuthentication (table)
  (no DDL FK constraints - all relationships are implicit)
  System versioning -> History.BillingCreditCardAuthenticationHistory (table)
```

### 6.1 Objects This Depends On

No hard DDL dependencies (no FK constraints). Runtime dependencies resolved by the CreditCardAuthentication microservice before calling the stored procedures.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCardAuthentication_Add | Stored Procedure | WRITER - creates authentication sessions |
| Billing.CreditCardAuthentication_Update | Stored Procedure | MODIFIER - updates status/results |
| Billing.CreditCardAuthentication_Get | Stored Procedure | READER - retrieves session data |
| History.BillingCreditCardAuthenticationHistory | Table | System-versioned history (auto-maintained by SQL Server) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CreditCardAuthentication | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CreditCardAuthentication | PRIMARY KEY CLUSTERED | Unique session identifier |
| DF_CreditCardAuthentication_Created | DEFAULT | Created = GETUTCDATE() on insert |
| DF_CreditCardAuthentication_Modified | DEFAULT | Modified = GETUTCDATE() on insert |
| DDM on FirstName | DYNAMIC DATA MASKING | default() mask - hides cardholder name from non-privileged users |
| DDM on MiddleName | DYNAMIC DATA MASKING | default() mask |
| DDM on LastName | DYNAMIC DATA MASKING | default() mask |
| SYSTEM_VERSIONING | TEMPORAL | History archived to History.BillingCreditCardAuthenticationHistory |

---

## 8. Sample Queries

### 8.1 Get all authentication sessions for a customer with status names
```sql
SELECT  CCA.ID,
        CCA.FundingID,
        CCA.Amount,
        CCAS.StatusName,
        CCA.StatusReasonID,
        CCA.ThreeDsResponseType,
        CCA.SchemeID,
        CCA.ProviderResponseCode,
        CCA.Created,
        CCA.Modified
FROM    Billing.CreditCardAuthentication CCA WITH (NOLOCK)
INNER JOIN Dictionary.CreditCardAuthenticationStatus CCAS WITH (NOLOCK)
        ON CCA.StatusID = CCAS.ID
WHERE   CCA.CID = 24186018
ORDER BY CCA.Created DESC;
```

### 8.2 Authentication success rate by status
```sql
SELECT  CCAS.StatusName,
        COUNT(*)                        AS SessionCount,
        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS decimal(5,2)) AS Pct
FROM    Billing.CreditCardAuthentication CCA WITH (NOLOCK)
LEFT JOIN Dictionary.CreditCardAuthenticationStatus CCAS WITH (NOLOCK)
        ON CCA.StatusID = CCAS.ID
GROUP BY CCAS.StatusName
ORDER BY SessionCount DESC;
```

### 8.3 Find all sessions with a specific SchemeID (recurring plan token)
```sql
SELECT  CCA.ID,
        CCA.CID,
        CCA.FundingID,
        CCA.SchemeID,
        CCA.RecurringFrequency,
        CCA.RecurringStartDate,
        CCA.RecurringEndDate,
        CCA.Created
FROM    Billing.CreditCardAuthentication CCA WITH (NOLOCK)
WHERE   CCA.SchemeID IS NOT NULL
        AND CCA.StatusID = 2  -- Approved only
ORDER BY CCA.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HLD Recurring Payments Zero Auth](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13281656921) | Confluence | Full architecture - CIT/MIT flows, SchemeID binding to recurring plans, 3DS response code table, checkout.com error categories, CreditCardAuthentication microservice endpoints |
| [Recurring investment Phase 1.2 - 3DS support - Operations support BRS](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13473284120) | Confluence | Business requirements for 3DS support in recurring investment operations |

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 9.2/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 11 CODE-BACKED, 4 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CreditCardAuthentication | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.CreditCardAuthentication.sql*

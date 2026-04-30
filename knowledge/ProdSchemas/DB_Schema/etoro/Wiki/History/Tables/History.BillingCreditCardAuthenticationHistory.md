# History.BillingCreditCardAuthenticationHistory

> Temporal history table capturing every past state of credit card 3DS authentication records in Billing.CreditCardAuthentication, with dynamic data masking protecting cardholder PII.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID + ValidFrom + ValidTo (temporal period) |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo/ValidFrom) |

---

## 1. Business Meaning

History.BillingCreditCardAuthenticationHistory is the SQL Server system-versioned temporal history table for Billing.CreditCardAuthentication. It automatically records every past state of credit card 3D-Secure (3DS) authentication sessions - the process by which eToro verifies cardholder identity before processing a payment.

Each authentication session progresses through multiple status states (New -> Approved/Decline/Technical) and the history table captures the state at each transition point. This enables full audit trails for payment disputes, 3DS compliance checks, and fraud investigations: "what was the exact status of this authentication at time T?" can be answered by querying this table.

Personal data (cardholder name fields) uses SQL Server Dynamic Data Masking to protect PII - users without the UNMASK permission see NULL values in FirstName, MiddleName, and LastName even in this history table.

Data flows here exclusively via SQL Server's temporal mechanism: when Billing.CreditCardAuthentication is updated (e.g., by Billing.CreditCardAuthentication_Update), the engine automatically writes the old row here with the appropriate ValidTo timestamp.

---

## 2. Business Logic

### 2.1 3DS Authentication State Transitions

**What**: Each row represents one completed state for an authentication session - captured when the session moved to the next state.

**Columns/Parameters Involved**: `ID`, `StatusID`, `StatusReasonID`, `ValidFrom`, `ValidTo`

**Rules**:
- StatusID defines the authentication outcome: 1=New (in-progress), 2=Approved, 3=Decline, 4=Technical (error), 35=DeclineByRRE (declined by Risk Review Engine)
- A typical successful flow creates two history rows per session:
  1. Initial creation: StatusID=1 (New), ValidFrom=creation, ValidTo=status-update-time
  2. Result captured: StatusID=2 (Approved), ValidFrom=approval, ValidTo=next-change-time
- Failed or declined authentications end with StatusID=3 (Decline) or 35 (DeclineByRRE)
- ThreeDsResponseType = 0 indicates a non-3DS or frictionless flow; NULL means no 3DS was attempted

**Diagram**:
```
3DS Authentication Lifecycle (History rows for one ID):
  [Row 1] StatusID=1 (New),       StatusReasonID=1, ValidFrom=T0, ValidTo=T1  (initial - waiting for 3DS challenge)
  [Row 2] StatusID=1 (New),       StatusReasonID=2, ValidFrom=T1, ValidTo=T2  (3DS challenge response received)
  [Row 3] StatusID=2 (Approved),  StatusReasonID=2, ValidFrom=T2, ValidTo=Max (current - in Billing.CreditCardAuthentication)
```

### 2.2 PII Masking

**What**: Cardholder name fields are masked to protect personal data, even in historical records.

**Columns/Parameters Involved**: `FirstName`, `MiddleName`, `LastName`

**Rules**:
- All three name columns use MASKED WITH (FUNCTION = 'default()') - SQL Server Dynamic Data Masking
- Users without the UNMASK privilege see NULL for these fields regardless of actual values
- This masking persists in the history table - PII is protected across both current and historical records
- Applies to all query contexts unless the caller has explicit UNMASK permission

---

## 3. Data Overview

| ID | CID | StatusID | StatusReasonID | CurrencyID | Amount | FundingID | ValidFrom | ValidTo | Meaning |
|----|-----|---------|---------------|-----------|--------|----------|-----------|---------|---------|
| 9090 | 25480004 | 1 (New) | 1 | 1 (USD) | 0 | 3549787 | 2026-03-19 01:14:21 | 2026-03-19 01:14:26 | Initial creation of authentication session for CID 25480004 - card verification with $0 amount (pure 3DS verification, not a payment). Duration: ~5 seconds. |
| 9090 | 25480004 | 1 (New) | 2 | 1 (USD) | 0 | 3549787 | 2026-03-19 01:14:26 | 2026-03-19 01:14:28 | Intermediate state - StatusReasonID advanced to 2 within 2 seconds of the previous. Authentication progressing. |
| 9089 | 25480000 | 1 (New) | 1 | 1 (USD) | 0 | 2898233 | 2026-03-19 01:14:08 | 2026-03-19 01:14:10 | Another $0 card verification. Multiple sessions across different customers processed in rapid sequence. |
| 9083 | 25479910 | 1 (New) | 2 | 1 (USD) | 100 | 1157510 | 2026-03-19 01:11:07 | 2026-03-19 01:11:08 | A $100 authentication (actual payment attempt). ThreeDsResponseType=0 indicates frictionless 3DS flow. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Authentication session ID (PK in Billing.CreditCardAuthentication). Multiple history rows with the same ID represent successive states of one authentication session. IDENTITY in the live table, plain int here (temporal history tables do not carry IDENTITY). |
| 2 | CID | int | NO | - | VERIFIED | Customer ID initiating the authentication. Links this auth session to the eToro account. |
| 3 | StatusID | int | NO | - | VERIFIED | Authentication outcome status. FK to Dictionary.CreditCardAuthenticationStatus: 1=New (in-progress), 2=Approved, 3=Decline, 4=Technical (provider error), 35=DeclineByRRE (declined by Risk Review Engine). Each state transition writes a history row. |
| 4 | StatusReasonID | int | NO | - | NAME-INFERRED | Sub-reason for the current status. Observed values: 1, 2, 3, 8, 9, 10, 11. No standalone Dictionary table found. Likely classifies the reason within a status (e.g., reason for decline, phase of the authentication flow). |
| 5 | Created | datetime | NO | - | VERIFIED | UTC timestamp when the authentication session was originally created. Set once (GETUTCDATE() at INSERT) and never changed - same value across all history rows for the same session. |
| 6 | Modified | datetime | NO | - | VERIFIED | UTC timestamp of the last modification to the authentication record in the live table. Each UPDATE advances this value, and the old Modified value is captured in history. |
| 7 | CurrencyID | int | NO | - | CODE-BACKED | Currency of the authentication amount. Typically 1 (USD) for eToro's standard flow. No FK constraint on history table - enforced on Billing.CreditCardAuthentication. |
| 8 | Amount | money | NO | - | CODE-BACKED | Amount being authenticated. Can be 0 for pure card verification flows (3DS verification without an actual charge). Positive values indicate a payment amount being authorized. |
| 9 | RecurringFrequency | int | YES | - | CODE-BACKED | Frequency in days for recurring payment setups. NULL for one-time authentications. Used when setting up recurring investment or subscription payments (DepositType=Recurring or RecurringInvestment). |
| 10 | RecurringStartDate | datetime | YES | - | CODE-BACKED | Start date of the recurring payment schedule. NULL for one-time authentications. |
| 11 | RecurringEndDate | datetime | YES | - | CODE-BACKED | End date of the recurring payment schedule. NULL for one-time authentications or open-ended recurring setups. |
| 12 | ProcessRegulationID | int | YES | - | NAME-INFERRED | Regulatory process classification governing this authentication. NULL in most observed records. Likely identifies which regulatory regime applies (PSD2, SCA, etc.). |
| 13 | DepotID | int | YES | - | NAME-INFERRED | Depot or sub-account identifier for this authentication. NULL in most cases. May reference a specific trading account or sub-portfolio. |
| 14 | MerchantAccountID | int | YES | - | CODE-BACKED | The merchant account used to process this authentication with the payment provider. Identifies which eToro merchant configuration was active at this point. NULL if using default merchant. |
| 15 | FundingID | int | NO | - | VERIFIED | The specific payment method (card) being authenticated. Links to Billing.Funding.FundingID. The FundingID uniquely identifies the customer's payment instrument being 3DS-verified. |
| 16 | SchemeID | nvarchar(100) | YES | - | CODE-BACKED | Payment scheme reference identifier from the card network (Visa, Mastercard, etc.). Used in 3DS protocol flows to reference the specific payment scheme. NULL for non-card payments or older records. |
| 17 | ThreeDsData | nvarchar(max) | YES | - | CODE-BACKED | Raw 3DS challenge response data (typically JSON) from the card scheme or issuing bank. Contains the full 3DS authentication payload. NULL if 3DS was not triggered or for frictionless flows. PII may be embedded - access should be controlled. |
| 18 | ThreeDsResponseType | int | YES | - | CODE-BACKED | Type of 3DS response received: 0=frictionless/non-3DS flow (no challenge presented to customer), other values indicate specific 3DS response classifications. NULL if 3DS was not attempted. |
| 19 | RiskManagementStatusID | int | YES | - | NAME-INFERRED | Risk assessment status from eToro's internal Risk Review Engine (RRE). NULL in most observed records. Related to StatusID=35 (DeclineByRRE) - the risk engine can override authentication approval. |
| 20 | ValidFrom | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version of the authentication record became active in Billing.CreditCardAuthentication. Set automatically by SQL Server temporal versioning. |
| 21 | ValidTo | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version was superseded. The clustered index leads with ValidTo to optimise FOR SYSTEM_TIME range queries. Short ValidTo-ValidFrom intervals (seconds) are normal for rapid 3DS state transitions. |
| 22 | FirstName | nvarchar(100) MASKED | YES | - | VERIFIED | Cardholder first name. MASKED WITH (FUNCTION = 'default()') - returns NULL to users without UNMASK permission. PII field, stored for 3DS compliance and dispute resolution. |
| 23 | MiddleName | nvarchar(100) MASKED | YES | - | VERIFIED | Cardholder middle name. Same masking as FirstName. NULL when not provided. |
| 24 | LastName | nvarchar(100) MASKED | YES | - | VERIFIED | Cardholder last name. Same masking as FirstName. Required for 3DS identity verification. |
| 25 | ReferenceID | nvarchar(100) | YES | - | CODE-BACKED | External payment provider reference ID for this authentication session. Used to correlate eToro's internal record with the payment gateway's transaction reference. |
| 26 | ProviderResponseCode | nvarchar(100) | YES | - | CODE-BACKED | Raw response code from the payment provider (e.g., Adyen, Stripe) following the authentication attempt. Useful for debugging declined or failed authentications. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ID | Billing.CreditCardAuthentication | Temporal relationship | Each history row is a past state of the current authentication record. |
| StatusID | Dictionary.CreditCardAuthenticationStatus | Implicit | Authentication outcome: 1=New, 2=Approved, 3=Decline, 4=Technical, 35=DeclineByRRE. |
| FundingID | Billing.Funding | Implicit | The card/payment method being authenticated. |
| CID | Billing.Customer / History.Customer | Implicit | The eToro customer initiating the authentication. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CreditCardAuthentication | SYSTEM_VERSIONING | Temporal (auto) | SQL Server writes to this history table automatically when the live table is updated. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BillingCreditCardAuthenticationHistory (table)
  - leaf node: temporal history table, no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies. Temporal history tables carry no FK constraints or computed columns.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCardAuthentication | Table | Live table whose history is stored here via SYSTEM_VERSIONING |
| Billing.CreditCardAuthentication_Add | Stored Procedure | Creates new sessions in the live table (indirectly triggers history) |
| Billing.CreditCardAuthentication_Update | Stored Procedure | Updates sessions in the live table - triggers history writes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_BillingCreditCardAuthenticationHistory | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page compression on table and clustered index |
| FirstName MASKED | Dynamic Data Masking | default() masking - returns NULL to users without UNMASK permission |
| MiddleName MASKED | Dynamic Data Masking | Same as FirstName |
| LastName MASKED | Dynamic Data Masking | Same as FirstName |

---

## 8. Sample Queries

### 8.1 Get full authentication history for a specific session
```sql
SELECT
    h.ID,
    cs.StatusName       AS Status,
    h.StatusReasonID,
    h.Amount,
    h.ThreeDsResponseType,
    h.ProviderResponseCode,
    h.ValidFrom,
    h.ValidTo,
    DATEDIFF(MILLISECOND, h.ValidFrom, h.ValidTo) AS DurationMs
FROM History.BillingCreditCardAuthenticationHistory h WITH (NOLOCK)
LEFT JOIN Dictionary.CreditCardAuthenticationStatus cs WITH (NOLOCK)
    ON h.StatusID = cs.ID
WHERE h.ID = 9090
ORDER BY h.ValidFrom ASC;
```

### 8.2 Find the state of an authentication at a specific point in time
```sql
-- Use live table with FOR SYSTEM_TIME - transparently reads History table
SELECT
    ca.ID,
    ca.CID,
    ca.StatusID,
    ca.Amount,
    ca.FundingID,
    ca.ValidFrom,
    ca.ValidTo
FROM Billing.CreditCardAuthentication FOR SYSTEM_TIME AS OF '2026-03-01T00:00:00'
    WITH (NOLOCK) AS ca
WHERE ca.CID = 12345678;
```

### 8.3 Investigate declined authentications over the past 7 days
```sql
SELECT
    h.ID,
    h.CID,
    h.StatusID,
    cs.StatusName       AS Status,
    h.StatusReasonID,
    h.Amount,
    h.FundingID,
    h.ProviderResponseCode,
    h.ThreeDsData,
    h.ValidFrom
FROM History.BillingCreditCardAuthenticationHistory h WITH (NOLOCK)
LEFT JOIN Dictionary.CreditCardAuthenticationStatus cs WITH (NOLOCK)
    ON h.StatusID = cs.ID
WHERE h.StatusID IN (3, 35)  -- Decline, DeclineByRRE
  AND h.ValidFrom >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY h.ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 8.8/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 5 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BillingCreditCardAuthenticationHistory | Type: Table | Source: etoro/etoro/History/Tables/History.BillingCreditCardAuthenticationHistory.sql*

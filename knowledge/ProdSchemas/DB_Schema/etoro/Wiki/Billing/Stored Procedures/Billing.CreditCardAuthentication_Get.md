# Billing.CreditCardAuthentication_Get

> Retrieves a single credit card authentication session record by ID from `Billing.CreditCardAuthentication`; used by the CreditCardAuthentication microservice to read session state after initiation.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID (Billing.CreditCardAuthentication.ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CreditCardAuthentication_Get` is the primary READER for `Billing.CreditCardAuthentication`. It retrieves the complete state of a single card authentication session by its ID. The CreditCardAuthentication microservice calls this after the 3DS / Zero Auth flow to confirm the outcome, retrieve the SchemeID returned by checkout.com, check the authentication status, and obtain all session context needed for subsequent recurring plan setup.

The procedure returns all significant columns including the full `ThreeDsData` payload, `ProviderResponseCode`, `RiskManagementStatusID`, and the DDM-masked cardholder name fields. It uses `NOLOCK` for non-blocking reads as authentication state polling is time-sensitive.

---

## 2. Business Logic

### 2.1 Single-Row Session Retrieval

**What**: Exact PK lookup (`WHERE ID = @ID`) returning all session columns.

**Rules**:
- Uses the clustered PK on `ID` - O(1) retrieval
- `WITH (NOLOCK)` - non-blocking; acceptable since this is a polling read and minor inconsistency during status update is tolerated
- Returns 0 or 1 rows (0 if ID does not exist)
- Result set includes ValidFrom/ValidTo system columns are NOT in the SELECT list (temporal columns are excluded for API compatibility)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int | NO | - | VERIFIED | Primary key of the authentication session to retrieve. References `Billing.CreditCardAuthentication.ID`. |

**Result set columns** (from `Billing.CreditCardAuthentication`):

| # | Column | Description |
|---|--------|-------------|
| 1 | ID | Session primary key. |
| 2 | CID | Customer ID. |
| 3 | StatusID | Authentication state: 1=New, 2=Approved, 3=Decline, 4=Technical, 35=DeclineByRRE. |
| 4 | StatusReasonID | Detailed reason code for the status. |
| 5 | Created | UTC timestamp when session was created. |
| 6 | Modified | UTC timestamp of most recent update. |
| 7 | CurrencyID | Currency of the authentication amount. |
| 8 | Amount | Amount used in authentication (typically 0.00 for Zero Auth). |
| 9 | RecurringFrequency | Recurring plan frequency (e.g., 1=monthly). NULL for one-time auth. |
| 10 | RecurringStartDate | Recurring plan start date. NULL for one-time auth. |
| 11 | RecurringEndDate | Recurring plan end date. NULL for open-ended plans. |
| 12 | ProcessRegulationID | Regulatory context: 1=standard, 4=enhanced. |
| 13 | DepotID | Payment depot/terminal used. NULL if not yet assigned. |
| 14 | MerchantAccountID | checkout.com merchant account used. NULL if not yet assigned. |
| 15 | FundingID | Billing.Funding ID of the card being authenticated. |
| 16 | SchemeID | checkout.com scheme ID from successful Zero Auth. NULL until populated. |
| 17 | ThreeDsData | Raw 3DS response payload from Cardinal SDK. NULL if 3DS not triggered. |
| 18 | ThreeDsResponseType | Encoded 3DS result: Y=Success/1, N=Failed/2, B=Bypassed/3, U=Unable, A=Attempts, R=Rejected. NULL if not triggered. |
| 19 | RiskManagementStatusID | Risk check result. NULL in current data (reserved for future). |
| 20 | FirstName | Cardholder first name. DDM-masked (shows NULL for non-privileged users). |
| 21 | MiddleName | Cardholder middle name. DDM-masked. |
| 22 | LastName | Cardholder last name. DDM-masked. |
| 23 | ReferenceID | External reference ID (e.g., checkout.com payment ID). |
| 24 | ProviderResponseCode | Raw checkout.com response code (e.g., 20062=Restricted Card, 40205=BIN Blacklisted). NULL until populated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ID | Billing.CreditCardAuthentication | Read | PK lookup to retrieve authentication session |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CreditCardAuthentication microservice | @ID | Caller | Polls authentication state after 3DS/Zero Auth completion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CreditCardAuthentication_Get (procedure)
+-- Billing.CreditCardAuthentication (table) [SELECT source]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCardAuthentication | Table | SELECT source - PK lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CreditCardAuthentication microservice | External | Reads session state after authentication |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Retrieve a specific authentication session

```sql
EXEC Billing.CreditCardAuthentication_Get @ID = 12345
-- Returns all 24 columns for session ID 12345
```

### 8.2 Equivalent direct query with status name

```sql
SELECT
    cca.ID, cca.CID, cca.StatusID,
    cca.SchemeID, cca.ProviderResponseCode,
    cca.ThreeDsResponseType, cca.Amount,
    cca.Created, cca.Modified
FROM Billing.CreditCardAuthentication cca WITH (NOLOCK)
WHERE cca.ID = 12345
```

### 8.3 Check if authentication completed successfully

```sql
SELECT
    CASE
        WHEN StatusID = 2 THEN 'Approved'
        WHEN StatusID = 3 THEN 'Declined'
        WHEN StatusID = 4 THEN 'Technical Error'
        WHEN StatusID = 35 THEN 'Declined by RRE'
        ELSE 'Pending/Unknown'
    END AS AuthResult,
    SchemeID,
    ProviderResponseCode
FROM Billing.CreditCardAuthentication WITH (NOLOCK)
WHERE ID = 12345
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HLD Recurring Payments Zero Auth](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13281656921) | Confluence | Authentication flow context: what each column contains after checkout.com responds, SchemeID usage for MIT, provider response code meanings |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 17 CODE-BACKED, 4 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CreditCardAuthentication_Get | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CreditCardAuthentication_Get.sql*

# BackOffice.IsFirstLogin

> Detects whether a customer is experiencing their first-ever login session by checking if they have an active login record but no archived login history.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns BIT - 1=first login, 0=returning user |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.IsFirstLogin answers the question "is this customer logging in for the very first time?" by checking two login tables simultaneously. The eToro platform splits login records between an active session store (Customer.Login) and an archived history store (History.Login). When a customer logs in, a record appears in Customer.Login. When they log out or their session expires, that record is moved (or copied) to History.Login. A customer with no record in History.Login but a record in Customer.Login has never completed a login session before - this is their first login.

This function is a component of the customer lifecycle status classification system. It feeds directly into BackOffice.GetCustomerStatus, which combines first-login status with registration-age flags to produce a bitmask describing where a customer is in their onboarding journey. First-login detection is valuable for triggering welcome workflows, first-login bonuses, onboarding campaigns, or BackOffice alerts for newly activated accounts.

The function is called by BackOffice.GetCustomerStatus as one of three binary inputs to the customer status bitmask.

---

## 2. Business Logic

### 2.1 First Login Detection Logic

**What**: Uses the absence of historical login records combined with the presence of an active login record to identify first-time logins.

**Parameters Involved**: `@CID`

**Rules**:
- Returns 1 (true) if BOTH conditions hold: (a) customer does NOT appear in History.Login (no completed past sessions), AND (b) customer DOES appear in Customer.Login (currently has an active or recent session).
- Returns 0 (false) if the customer has any history in History.Login (they have logged in before and completed at least one session).
- Returns 0 if the customer has no record in either table (not currently logged in at all).
- History.Login stores past/completed sessions. Customer.Login stores active/recent sessions. This two-table architecture separates live from historical data.

**Diagram**:
```
EXISTS in History.Login?    NOT EXISTS in Customer.Login?
       YES                          YES
        |                            |
   Return 0 (returning user)    Return 0 (not logged in at all)

       NO (no history)
        |
EXISTS in Customer.Login?
       YES
        |
   Return 1 (FIRST LOGIN!)
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID whose first-login status is being checked. Looked up in both History.Login and Customer.Login tables. FK to Customer.CustomerStatic.CID (cross-schema). |
| 2 | Return value | BIT | NO | - | CODE-BACKED | 1 = This is the customer's first login (active session exists but no historical sessions). 0 = Customer has logged in before (has History.Login records), or is not currently logged in. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | History.Login | Table access (cross-schema) | Checked for absence - no historical login records means no prior completed sessions |
| @CID | Customer.Login | Table access (cross-schema) | Checked for presence - active session record confirms customer is currently logging in |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetCustomerStatus | Bit 2 (2^2 = 4) | Function call | First-login flag contributes the third bit (value 4) to the customer status bitmask |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.IsFirstLogin (scalar function)
├── History.Login (table) [cross-schema]
└── Customer.Login (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Login | Table (cross-schema) | NOT EXISTS check - CID absence = no completed prior sessions |
| Customer.Login | Table (cross-schema) | EXISTS check - CID presence = active current session |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCustomerStatus | Scalar Function | Multiplied by POWER(2,2) = 4 and OR'd into the customer status bitmask |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Check if a specific customer is logging in for the first time
```sql
SELECT BackOffice.IsFirstLogin(12345) AS IsFirstLogin
-- 1 = first login
-- 0 = returning user or not logged in
```

### 8.2 Find all customers currently experiencing their first login
```sql
SELECT
    cl.CID,
    BackOffice.IsFirstLogin(cl.CID) AS IsFirstLogin
FROM Customer.Login cl WITH (NOLOCK)
WHERE BackOffice.IsFirstLogin(cl.CID) = 1
```

### 8.3 Get full customer status for a customer including first-login flag
```sql
SELECT
    BackOffice.IsFirstLogin(@CID) AS IsFirstLogin,
    BackOffice.IsRegisteredBefore24Hrs(@CID) AS IsNewWithin24Hrs,
    BackOffice.IsRegisteredBeforeMonth(@CID) AS IsNewWithinMonth,
    BackOffice.GetCustomerStatus(@CID) AS StatusBitmask
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 external callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.IsFirstLogin | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.IsFirstLogin.sql*

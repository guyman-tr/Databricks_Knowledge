# Billing.PhoneVerificationWhiteList

> Security whitelist table for phone numbers that bypass the standard phone verification flow during payment operations, with dynamic data masking applied to protect the phone number values.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | PhoneNumber (VARCHAR(30), PK CLUSTERED - natural key) |
| **Partition** | PRIMARY filegroup (PAGE compressed) |
| **Indexes** | 1 active (PK clustered on PhoneNumber, FILLFACTOR=95) |

---

## 1. Business Meaning

Billing.PhoneVerificationWhiteList stores phone numbers that are granted a bypass from the standard SMS verification step in the billing/payment flow. This is a security exception list: certain phone numbers (typically test accounts, internal eToro numbers, or partner numbers) are pre-authorized so that the verification process skips the normal SMS OTP challenge for them.

The table has only 1 row in the staging environment, suggesting it is either lightly used or populated specifically in production. The PhoneNumber column has SQL Server Dynamic Data Masking applied (`MASKED WITH (FUNCTION = 'default()')`), which means users without UNMASK permission see a masked value (XXXX or similar) instead of the real phone number - protecting PII from unauthorized database access.

No stored procedures within the Billing schema reference this table directly - it is queried by application code via direct SQL or via a non-Billing SP.

---

## 2. Business Logic

### 2.1 Whitelist Lookup

**What**: During phone verification, the system checks if the phone number is in this whitelist to skip OTP.

**Columns/Parameters Involved**: `PhoneNumber`, `VerificationListTypeID`

**Rules**:
- PhoneNumber is the PK - each number appears at most once.
- VerificationListTypeID: Nullable. Allows categorization of whitelist entries by type (e.g., test numbers vs. internal numbers). Only 1 distinct value in staging.
- Application queries this table by PhoneNumber to determine whether to skip verification.
- Dynamic data masking (`default()` function): Users without UNMASK permission see masked data. eToro's DepositUser role likely has UNMASK for operational purposes.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 1 (staging environment) |
| VerificationListTypeID values | 1 distinct value |
| PII protection | Dynamic data masking on PhoneNumber |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PhoneNumber | varchar(30) | NO | - | CODE-BACKED | International phone number string (E.164 or similar format). PK - unique per number. **MASKED** with `default()` function for users without UNMASK permission - they see "xxxx" instead of the actual number. Up to 30 characters supports international format with country code. |
| 2 | VerificationListTypeID | int | YES | - | CODE-BACKED | Category of the whitelist entry. NULL allowed. Enables filtering by whitelist type (e.g., 1=TestNumbers, 2=InternalNumbers) if multiple types are managed. Only 1 distinct value observed in staging. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints declared.

### 5.2 Referenced By (other objects point to this)

No stored procedures in the Billing schema directly reference this table. Consumed by application code or non-Billing SPs for phone verification bypass logic.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PhoneVerificationWhiteList (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No stored procedures found in Billing schema. Application-level direct queries.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PhoneVerificationWhiteList_PhoneNumber | CLUSTERED PK | PhoneNumber ASC | - | - | Active (PAGE compressed, FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PhoneVerificationWhiteList_PhoneNumber | PRIMARY KEY | PhoneNumber clustered |
| MASKED WITH (FUNCTION = 'default()') | Dynamic Data Masking | PhoneNumber masked for unauthorized users |

---

## 8. Sample Queries

### 8.1 Check if a phone number is whitelisted

```sql
SELECT PhoneNumber, VerificationListTypeID
FROM Billing.PhoneVerificationWhiteList WITH (NOLOCK)
WHERE PhoneNumber = @PhoneNumber
-- Returns 1 row if whitelisted, 0 rows if not
```

### 8.2 List all whitelisted numbers (requires UNMASK permission)

```sql
SELECT PhoneNumber, VerificationListTypeID
FROM Billing.PhoneVerificationWhiteList WITH (NOLOCK)
ORDER BY PhoneNumber
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8.0/10, Logic: 7.5/10, Relationships: 6.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Note: Only 1 row in staging; production table likely has more entries. No SP references found - application queries directly.*
*Object: Billing.PhoneVerificationWhiteList | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.PhoneVerificationWhiteList.sql*

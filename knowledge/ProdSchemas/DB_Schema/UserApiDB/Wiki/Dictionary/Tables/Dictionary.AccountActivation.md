# Dictionary.AccountActivation

> Lookup table defining the activation pathways available for user accounts on the eToro platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AccountActivationID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.AccountActivation defines the available account activation methods for the eToro platform. Each row represents a distinct onboarding flow that a new user can go through when activating their account. This is a system-level configuration table that controls which activation pathways are presented to users.

This table exists to decouple activation flow logic from application code. Without it, activation pathways would be hardcoded, making it impossible to add new flows (e.g., for new regulations or brands) without code changes.

Currently contains a single activation pathway (Activate_eToro). Referenced by Customer.InsertRealCustomer and Customer.InsertNewCustomer when setting up new accounts. The value is stored on the user record to track which activation flow was used during onboarding.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single-column lookup with one value. See individual element descriptions in Section 4.

---

## 3. Data Overview

| AccountActivationID | Name | Meaning |
|---|---|---|
| 1 | Activate_eToro | Standard eToro platform activation - the default onboarding flow for all new eToro accounts across all regulations |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountActivationID | int | NO | - | CODE-BACKED | Primary key identifying the activation pathway. Currently only value 1 exists. Referenced by Customer schema procedures during account creation. |
| 2 | Name | varchar(50) | YES | - | CODE-BACKED | Human-readable name of the activation pathway. Used for display and logging purposes. Currently: "Activate_eToro". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.InsertRealCustomer | AccountActivationID | Lookup | Sets activation type during real account creation |
| Customer.InsertNewCustomer | AccountActivationID | Lookup | Sets activation type during new account creation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.InsertRealCustomer | Stored Procedure | Reads activation type |
| Customer.InsertNewCustomer | Stored Procedure | Reads activation type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryAccountActivation | CLUSTERED PK | AccountActivationID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all activation pathways
```sql
SELECT AccountActivationID, Name
FROM Dictionary.AccountActivation WITH (NOLOCK)
ORDER BY AccountActivationID
```

### 8.2 Find users by activation type
```sql
SELECT u.CustomerID, u.UserName, aa.Name AS ActivationType
FROM Customer.Users u WITH (NOLOCK)
JOIN Dictionary.AccountActivation aa WITH (NOLOCK) ON u.AccountActivationID = aa.AccountActivationID
```

### 8.3 Verify activation type exists before insert
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Dictionary.AccountActivation WITH (NOLOCK)
    WHERE AccountActivationID = @ActivationID
) THEN 1 ELSE 0 END AS IsValid
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AccountActivation | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.AccountActivation.sql*

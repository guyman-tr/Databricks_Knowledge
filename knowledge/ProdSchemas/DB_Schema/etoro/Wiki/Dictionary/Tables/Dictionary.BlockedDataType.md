# Dictionary.BlockedDataType

> Lookup table defining the 5 types of customer data that can be blacklisted — User Name, Email, OriginalCID, Credit Card, and PayPal Email — used by the fraud prevention and risk management blacklist system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | BlockedDataTypeID (int, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (clustered PK + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.BlockedDataType classifies the categories of personal or financial data that can be placed on a blacklist to prevent fraudulent or banned users from re-registering or transacting. When the compliance or risk team identifies a bad actor, they blacklist specific data points (username, email, credit card number, etc.) so that any future registration or deposit attempt using those same values is automatically blocked.

This table is critical to the platform's fraud prevention infrastructure. Without it, banned users could simply create new accounts using the same email, card number, or PayPal address. The blacklist system cross-references incoming registration and deposit data against entries in `BackOffice.CustomerBlackList`, where each entry has a `BlockedDataTypeID` from this table to specify what kind of data is being blocked.

The table is referenced by two consumers: `BackOffice.CustomerBlackList` (the active blacklist with explicit FK) and `History.RiskNotification` (risk event logging with explicit FK). The `BackOffice.CustomerBlackListAdd` procedure inserts new blacklist entries using this type classification.

---

## 2. Business Logic

### 2.1 Blacklist Data Categories

**What**: Five categories of customer data that can be independently blacklisted.

**Columns/Parameters Involved**: `BlockedDataTypeID`, `Name`

**Rules**:
- **User Name (1)**: Blocks a specific username from being reused in registration. Prevents banned users from reclaiming their identity on the platform.
- **Email (2)**: Blocks an email address from being used for new account registration or recovery. Most common blacklist type for banned accounts.
- **OriginalCID (3)**: Blocks a specific Customer ID (CID). Prevents a previously banned customer account from being reinstated or linked to new accounts.
- **Credit Card (4)**: Blocks a credit card number from being used for deposits. Prevents fraudulent cards or cards associated with chargebacks from being reused.
- **Pay Pal Email (5)**: Blocks a PayPal email address from being used as a payment method. Prevents banned PayPal accounts from being relinked.

**Diagram**:
```
BlockedDataType → BackOffice.CustomerBlackList
                   (BlockedDataTypeID + Data value)
                   
Registration/Deposit attempt
    → Check Data against CustomerBlackList
    → Match found? → BLOCK operation
    → No match → ALLOW operation

Types:
  1: User Name     → blocks re-registration
  2: Email         → blocks re-registration
  3: OriginalCID   → blocks account reinstatement
  4: Credit Card   → blocks fraudulent deposits
  5: Pay Pal Email → blocks PayPal payment method
```

---

## 3. Data Overview

| BlockedDataTypeID | Name | Meaning |
|---|---|---|
| 1 | User Name | When compliance bans a user, their username is blacklisted here to prevent re-registration under the same name. Most common in fraud and AML cases. |
| 2 | Email | Email addresses of banned or fraudulent accounts are blocked to prevent creation of new accounts using the same email. Core anti-fraud measure. |
| 3 | OriginalCID | The original Customer ID of a banned account is recorded to prevent account reinstatement attempts or cross-linking to new accounts. |
| 4 | Credit Card | Card numbers associated with confirmed fraud, chargebacks, or stolen cards are blocked from all future deposit attempts across the platform. |
| 5 | Pay Pal Email | PayPal email addresses linked to fraudulent activity or banned accounts are blocked from being used as a deposit method. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BlockedDataTypeID | int | NO | - | VERIFIED | Primary key identifying the blocked data category. Values 1-5. Referenced by `BackOffice.CustomerBlackList.BlockedDataTypeID` (FK) and `History.RiskNotification.BlockedDataTypeID` (FK) to classify what type of data is on the blacklist. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable name of the blocked data category (e.g., 'User Name', 'Email', 'Credit Card'). Enforced unique via the `DBDT_NAME` index. Used in BackOffice UIs for blacklist management and in risk notification reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerBlackList | BlockedDataTypeID | FK (FK_DBDT_BCBL) | Each blacklist entry specifies which data type is being blocked — the blacklist stores the actual data value alongside this type classifier |
| History.RiskNotification | BlockedDataTypeID | FK (FK_DBDT_HRNT) | Risk notification events reference which type of data triggered the notification — used for audit trails and risk reporting |
| BackOffice.CustomerBlackListAdd | @BlockedDataTypeID | Procedure parameter | Stored procedure that inserts new entries into CustomerBlackList — accepts the type ID as a parameter along with the data value to block |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerBlackList | Table | FK reference — each blacklist entry has a BlockedDataTypeID |
| History.RiskNotification | Table | FK reference — each risk notification has a BlockedDataTypeID |
| BackOffice.CustomerBlackListAdd | Procedure | Inserts rows into CustomerBlackList with a BlockedDataTypeID parameter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DBDT | CLUSTERED PK | BlockedDataTypeID ASC | - | - | Active |
| DBDT_NAME | UNIQUE NC | Name ASC | - | - | Active |

### 7.2 Constraints

None beyond PK and unique index.

---

## 8. Sample Queries

### 8.1 List all blocked data types
```sql
SELECT  BlockedDataTypeID,
        Name
FROM    Dictionary.BlockedDataType WITH (NOLOCK)
ORDER BY BlockedDataTypeID;
```

### 8.2 Count blacklisted entries per data type
```sql
SELECT  BDT.BlockedDataTypeID,
        BDT.Name,
        COUNT(CBL.BlackListID) AS BlacklistEntries
FROM    Dictionary.BlockedDataType BDT WITH (NOLOCK)
LEFT JOIN BackOffice.CustomerBlackList CBL WITH (NOLOCK)
        ON CBL.BlockedDataTypeID = BDT.BlockedDataTypeID
GROUP BY BDT.BlockedDataTypeID, BDT.Name
ORDER BY BDT.BlockedDataTypeID;
```

### 8.3 View recent risk notifications by blocked data type
```sql
SELECT  BDT.Name AS BlockedDataType,
        RN.RiskNotificationID,
        RN.Occurred
FROM    History.RiskNotification RN WITH (NOLOCK)
INNER JOIN Dictionary.BlockedDataType BDT WITH (NOLOCK)
        ON BDT.BlockedDataTypeID = RN.BlockedDataTypeID
ORDER BY RN.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.BlockedDataType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.BlockedDataType.sql*

# Dictionary.AccountType

> Lookup table defining the types of brokerage accounts available at Apex Clearing: CASH, MARGIN, and OPTION.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AccuntTypeID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.AccountType defines the three types of brokerage accounts supported at Apex Clearing. Each account type determines the trading capabilities, margin requirements, and regulatory forms required during onboarding. This is a core lookup table referenced by the customer profile (Apex.UserData.AccountTypeID).

This table is essential because the account type drives which Apex API forms and agreements must be submitted, what trading features are available, and what regulatory requirements apply. A CASH account has no borrowing capability, a MARGIN account allows leverage, and an OPTION account enables options trading.

---

## 2. Business Logic

No complex multi-column business logic. Simple 3-value lookup. Note: PK column has a typo - `AccuntTypeID` (missing 'o').

---

## 3. Data Overview

| AccuntTypeID | Name | Meaning |
|-------------|------|---------|
| 1 | CASH | Standard brokerage account. Securities purchased with settled funds only - no borrowing or leverage. Simplest account type with fewest regulatory requirements. |
| 2 | MARGIN | Margin-enabled account allowing borrowing against securities for increased purchasing power. Subject to Regulation T margin requirements and maintenance calls. Most common account type for active traders. |
| 3 | OPTION | Account enabled for options trading. Requires additional suitability assessment and approval from Apex Clearing before options contracts can be traded. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccuntTypeID | int | NO | - | VERIFIED | Primary key. Typo in column name (missing 'o' - should be AccountTypeID). Values: 1=CASH, 2=MARGIN, 3=OPTION. Referenced by Apex.UserData.AccountTypeID. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Display name for the account type. UPPERCASE format matching Apex Clearing's API conventions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.UserData | AccountTypeID | FK | Customer's brokerage account type classification |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.UserData | Table | FK reference for AccountTypeID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AccountType | CLUSTERED PK | AccuntTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_AccountType | PRIMARY KEY | Clustered on AccuntTypeID |

---

## 8. Sample Queries

### 8.1 Get all account types

```sql
SELECT AccuntTypeID, Name FROM Dictionary.AccountType WITH (NOLOCK) ORDER BY AccuntTypeID;
```

### 8.2 Resolve a customer's account type

```sql
SELECT ud.GCID, at.Name AS AccountType
FROM Apex.UserData ud WITH (NOLOCK)
INNER JOIN Dictionary.AccountType at WITH (NOLOCK) ON at.AccuntTypeID = ud.AccountTypeID
WHERE ud.GCID = 19533157;
```

### 8.3 Count customers by account type

```sql
SELECT at.Name AS AccountType, COUNT(*) AS CustomerCount
FROM Apex.UserData ud WITH (NOLOCK)
INNER JOIN Dictionary.AccountType at WITH (NOLOCK) ON at.AccuntTypeID = ud.AccountTypeID
GROUP BY at.Name ORDER BY CustomerCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AccountType | Type: Table | Source: USABroker/Dictionary/Tables/Dictionary.AccountType.sql*

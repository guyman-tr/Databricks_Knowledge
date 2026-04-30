# Apex.UserDataTrustedContact

> Stores the FINRA-required trusted contact person information for each customer, used by the broker to reach a designated person in cases of suspected exploitation or diminished capacity.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Apex.UserDataTrustedContact stores the trusted contact person designated by each customer, as required by FINRA Rule 4512. The trusted contact is a person the broker-dealer can reach out to if there are concerns about the customer's account activity, potential financial exploitation, or diminished mental capacity. This is a regulatory requirement for all brokerage accounts.

Data is written by Apex.SaveTrustedContact and read by Apex.GetTrustedContact. System versioning (History.UserDataTrustedContact) provides change history. Not all customers have a trusted contact record yet.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple PII storage for regulatory compliance.

---

## 3. Data Overview

N/A - PII data, representative structure described in elements.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Primary key. One trusted contact per customer. |
| 2 | FirstName | nvarchar(50) | NO | - | CODE-BACKED | Trusted contact's first name. |
| 3 | LastName | nvarchar(50) | NO | - | CODE-BACKED | Trusted contact's last name. |
| 4 | PhoneNumber | varchar(30) | YES | - | CODE-BACKED | Trusted contact's phone number. Optional - contact may provide only email. |
| 5 | PhoneNumberTypeID | int | YES | - | VERIFIED | Type of phone number. FK to Dictionary.PhoneType: 1=Home, 2=Work, 3=Mobile, 4=Fax, 5=Other. See [Phone Type](_glossary.md#phone-type). NULL when no phone provided. (Dictionary.PhoneType) |
| 6 | Email | varchar(50) | YES | - | CODE-BACKED | Trusted contact's email address. Optional alternative to phone. |
| 7 | BeginTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System versioning row start time. Part of SYSTEM_TIME period for History.UserDataTrustedContact. |
| 8 | EndTime | datetime2(7) | NO | '9999-12-31 23:59:59.9999999' | CODE-BACKED | System versioning row end time. Part of SYSTEM_TIME period. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PhoneNumberTypeID | Dictionary.PhoneType | FK | Phone type classification for trusted contact |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.SaveTrustedContact | @GCID | Writer | Creates/updates trusted contact |
| Apex.GetTrustedContact | @GCID | Reader | Retrieves trusted contact |
| Apex.DeleteTrustedContact | @GCID | Deleter | Removes trusted contact |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.UserDataTrustedContact (table)
└── Dictionary.PhoneType (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PhoneType | Table | FK for PhoneNumberTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.SaveTrustedContact | Stored Procedure | Writer |
| Apex.GetTrustedContact | Stored Procedure | Reader |
| Apex.DeleteTrustedContact | Stored Procedure | Deleter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Apex_UserDataTrustedContact | CLUSTERED PK | GCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Apex_UserDataTrustedContact | PRIMARY KEY | Clustered on GCID |
| FK_PhoneType_UserDataTrustedContact | FOREIGN KEY | PhoneNumberTypeID -> Dictionary.PhoneType(PhoneTypeID) |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.UserDataTrustedContact |

---

## 8. Sample Queries

### 8.1 Get trusted contact for a customer

```sql
SELECT GCID, FirstName, LastName, PhoneNumber, pt.Name AS PhoneType, Email
FROM Apex.UserDataTrustedContact tc WITH (NOLOCK)
LEFT JOIN Dictionary.PhoneType pt WITH (NOLOCK) ON pt.PhoneTypeID = tc.PhoneNumberTypeID
WHERE tc.GCID = 1626844;
```

### 8.2 Find customers without a trusted contact

```sql
SELECT s.GCID FROM Apex.State s WITH (NOLOCK)
LEFT JOIN Apex.UserDataTrustedContact tc WITH (NOLOCK) ON tc.GCID = s.GCID
WHERE tc.GCID IS NULL;
```

### 8.3 Trusted contact change history

```sql
SELECT GCID, FirstName, LastName, BeginTime, EndTime
FROM Apex.UserDataTrustedContact WITH (NOLOCK) WHERE GCID = 1626844
UNION ALL
SELECT GCID, FirstName, LastName, BeginTime, EndTime
FROM History.UserDataTrustedContact WITH (NOLOCK) WHERE GCID = 1626844
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.UserDataTrustedContact | Type: Table | Source: USABroker/Apex/Tables/Apex.UserDataTrustedContact.sql*

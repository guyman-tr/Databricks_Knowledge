# Apex.GetUserData

> Retrieves the complete customer personal data profile from UserData by GCID, returning all fields needed for account management, regulatory compliance, and Apex API operations.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns full UserData row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex.GetUserData retrieves the complete customer profile from the UserData table. Returns all personal data fields (name, DOB, SSN, address, phone, email), account classification (AccountTypeID, CustomerTypeID), regulatory disclosure flags (control person, FINRA affiliated, PEP), visa information, approval info, and the CID mapping. This is the primary read operation for customer data in the Apex integration.

---

## 2. Business Logic

No complex business logic. Returns all columns from UserData for the specified GCID. Note: does NOT use NOLOCK hint, which means it acquires shared locks. This is intentional for data consistency when reading customer data that may be actively updated.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID to retrieve data for. |

**Returns**: 33 columns from Apex.UserData including GCID, CID, AccountTypeID, CustomerTypeID, FirstName, LastName, MiddleName, DateOfBirth, NationalPin, CitizenshipCountryID, PermanentResident, PhoneNumber, PhoneNumberTypeID, Email, Address, BuildingNumber, City, ProvinceID, Zip, CountryID, POBCountryID, IsControlPerson, DisclosureCompanySymbols, IsAffiliatedExchangeOrFINRA, DisclosureFirmName, IsPoliticallyExposed, PepAdditionalData, ApproverName, ApprovedByDate, Created, VisaType, VisaExpirationDate, UsVisaHolder.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Apex.UserData | Read | Full row retrieval by GCID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.GetUserData (procedure)
└── Apex.UserData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Apex.UserData | Table | Full read by GCID (PK) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get customer profile

```sql
EXEC Apex.GetUserData @GCID = 19533157;
```

### 8.2 Get customer for Apex API update

```sql
EXEC Apex.GetUserData @GCID = 22055177;
-- Returns all fields needed to populate Apex update API call
```

### 8.3 Verify customer data exists

```sql
EXEC Apex.GetUserData @GCID = 999999;
-- Empty result if not found
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.GetUserData | Type: Stored Procedure | Source: USABroker/Apex/Stored Procedures/Apex.GetUserData.sql*

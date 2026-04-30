# Customer.UpdateBasicUserInfoRemote

> Updates a customer's basic personal data fields on CustomerStatic via GCID, using a preserve-existing ISNULL pattern - the "Remote" variant that skips the downstream action queue used by UpdateBasicUserInfo.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid - GCID lookup for CustomerStatic |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateBasicUserInfoRemote updates the same personal data fields on Customer.CustomerStatic as Customer.UpdateBasicUserInfo, but omits the Internal.ActionsToExecute_Registration queue entry. The "Remote" suffix indicates this is the entry point for external systems (e.g., back-office portals, KYC systems) that manage customer data independently and do not need downstream propagation triggered - they assume downstream systems are already informed through their own channels.

The procedure uses ISNULL(@param, ExistingColumn) for all fields, so callers can update a subset of fields by passing only the changed ones and NULLing the rest.

History: Varchar to NVarchar conversion (Case 28292, 2015-07-27), middle name added (Case 50094, 2018-01-11), migrated to CustomerStatic (2019-06-17), names fix for BO (COAIL-2453, 2021-03-03).

---

## 2. Business Logic

### 2.1 Preserve-Existing ISNULL Pattern (No Queue)

**What**: All fields updated with ISNULL to allow partial updates; no downstream action queue is written.

**Rules**:
- FirstName/LastName/MiddleName/Gender/LanguageID/BirthDate/PlayerLevelID all use ISNULL(@param, Column)
- NULL passed for any field -> that field is not changed in CustomerStatic
- No Internal.ActionsToExecute_Registration INSERT (key difference from UpdateBasicUserInfo)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. Lookup key for CustomerStatic WHERE GCID=@gcid. |
| 2 | @fName | nvarchar(50) | YES | NULL | CODE-BACKED | First name. Maps to CustomerStatic.FirstName. ISNULL: NULL preserves existing. |
| 3 | @lName | nvarchar(50) | YES | NULL | CODE-BACKED | Last name. Maps to CustomerStatic.LastName. ISNULL: NULL preserves existing. |
| 4 | @languageId | int | YES | NULL | CODE-BACKED | Language preference. Maps to CustomerStatic.LanguageID. ISNULL: NULL preserves existing. |
| 5 | @dob | datetime | YES | NULL | CODE-BACKED | Date of birth. Maps to CustomerStatic.BirthDate. ISNULL: NULL preserves existing. |
| 6 | @gender | char(1) | YES | NULL | CODE-BACKED | Gender code ('M'/'F'). Maps to CustomerStatic.Gender. ISNULL: NULL preserves existing. |
| 7 | @level | int | YES | NULL | CODE-BACKED | Player level ID. Maps to CustomerStatic.PlayerLevelID. ISNULL: NULL preserves existing. |
| 8 | @mName | nvarchar(50) | YES | NULL | CODE-BACKED | Middle name. Maps to CustomerStatic.MiddleName. Added 2018-01-11. ISNULL: NULL preserves existing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.CustomerStatic | Modifier | Updates personal data fields via ISNULL-preserving SET |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external system) | - | - | No intra-DB callers found; called from back-office/KYC remote systems |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateBasicUserInfoRemote (procedure)
└── Customer.CustomerStatic (table - UPDATE)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | UPDATE target for personal data fields via GCID lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No intra-DB callers found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ISNULL pattern | Partial update | All fields preserved if NULL passed |
| No action queue | Design | Unlike UpdateBasicUserInfo, does NOT insert into Internal.ActionsToExecute_Registration |

---

## 8. Sample Queries

### 8.1 Update customer name from a remote system
```sql
EXEC Customer.UpdateBasicUserInfoRemote
    @gcid = 67890, @fName = N'John', @lName = N'Smith';
```

### 8.2 Update only date of birth
```sql
EXEC Customer.UpdateBasicUserInfoRemote @gcid = 67890, @dob = '1985-06-15';
```

### 8.3 Verify the updated fields
```sql
SELECT GCID, FirstName, LastName, MiddleName, Gender, LanguageID, BirthDate, PlayerLevelID
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE GCID = 67890;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.UpdateBasicUserInfoRemote | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateBasicUserInfoRemote.sql*

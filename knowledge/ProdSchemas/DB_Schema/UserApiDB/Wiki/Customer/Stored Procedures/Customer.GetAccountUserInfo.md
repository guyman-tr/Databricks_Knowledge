# Customer.GetAccountUserInfo

> Returns account-level user information by reading from legacy Real_Customer and Real_BackOfficeCustomer dbo views/synonyms.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetAccountUserInfo is the legacy-path equivalent of GetAccountInfo. Instead of reading from the Customer schema tables directly, it reads from Real_Customer and Real_BackOfficeCustomer (dbo synonyms/views that map to legacy table structures). Returns similar account data plus additional fields like DownloadID and ReferralID from the legacy structure. Uses NOLOCK hints.

---

## 2. Business Logic

No complex business logic. SELECT with JOIN between Real_Customer and Real_BackOfficeCustomer on CID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | Global Customer ID. |

Output columns: GCID, OriginalCID, AffiliateID, WhiteLabelID, AccountTypeID, CreatedOn, TradeLevelID, CurrencyID, PendingClosureStatusID, AccountStatusID, MasterAccountCID, ManagerID, SubSerialID, GuruStatusID, KycState, FunnelFromID, DownloadID, ReferralID.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Real_Customer (dbo) | SELECT FROM | Legacy customer view |
| - | Real_BackOfficeCustomer (dbo) | JOIN | Legacy back-office data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetAccountUserInfo (procedure)
  +-- Real_Customer (dbo synonym/view)
  +-- Real_BackOfficeCustomer (dbo synonym/view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Real_Customer | dbo synonym/view | SELECT FROM |
| Real_BackOfficeCustomer | dbo synonym/view | JOIN |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get account user info
```sql
EXEC Customer.GetAccountUserInfo @gcid = 12345
```

### 8.2 Compare legacy vs modern
```sql
-- Legacy path:
EXEC Customer.GetAccountUserInfo @gcid = 12345
-- Modern path:
EXEC Customer.GetAccountInfo @gcid = 12345
```

### 8.3 Direct query on legacy views
```sql
SELECT c.GCID, c.CID, bc.AccountTypeID, bc.GuruStatusID
FROM Real_Customer c WITH (NOLOCK)
JOIN Real_BackOfficeCustomer bc WITH (NOLOCK) ON c.CID = bc.CID
WHERE c.GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetAccountUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetAccountUserInfo.sql*

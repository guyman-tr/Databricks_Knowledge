# Customer.GetManyAccountUserInfo

> Retrieves account information for multiple customers from legacy dbo tables (Real_Customer + Real_BackOfficeCustomer) by GCID list.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns account info rows from legacy dbo tables |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetManyAccountUserInfo is a batch reader that retrieves account-level information for multiple customers from the legacy dbo schema tables (Real_Customer and Real_BackOfficeCustomer). Unlike GetManyAccountInfo (which reads from the Customer schema), this procedure uses the original denormalized tables.

This procedure serves callers that still depend on the legacy table structure. It returns a subset of account fields including affiliate, label, account type, registration date, trade level, currency, closure status, master account, manager, sub-serial, and guru status.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Batch read by GCID list.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of GCIDs to retrieve account info for. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | OriginalCID (output) | int | YES | - | CODE-BACKED | Original CID before any migration. |
| 4 | AffiliateID (output) | int | YES | - | CODE-BACKED | Affiliate serial ID. Aliased from SerialID. |
| 5 | WhiteLabelID (output) | int | YES | - | CODE-BACKED | White label/brand. Aliased from LabelID. |
| 6 | AccountTypeID (output) | int | YES | - | CODE-BACKED | Account type from Real_BackOfficeCustomer. |
| 7 | CreatedOn (output) | datetime | YES | - | CODE-BACKED | Registration date. Aliased from Registered. |
| 8 | TradeLevelID (output) | int | YES | - | CODE-BACKED | Trading authorization level. |
| 9 | CurrencyID (output) | int | YES | - | CODE-BACKED | Account base currency. |
| 10 | PendingClosureStatusID (output) | int | YES | - | CODE-BACKED | Pending closure status if applicable. |
| 11 | AccountStatusID (output) | int | YES | - | CODE-BACKED | Current account status. |
| 12 | MasterAccountCID (output) | int | YES | - | CODE-BACKED | Master account CID for sub-accounts. |
| 13 | ManagerID (output) | int | YES | - | CODE-BACKED | Assigned account manager CID. |
| 14 | SubSerialID (output) | int | YES | - | CODE-BACKED | Sub-affiliate identifier. |
| 15 | GuruStatusID (output) | int | YES | - | CODE-BACKED | Popular Investor status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | dbo.Real_Customer | JOIN | Legacy customer record |
| CID | dbo.Real_BackOfficeCustomer | JOIN | Back-office data (account type, guru status) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Legacy batch account info retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetManyAccountUserInfo (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.Real_BackOfficeCustomer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | FROM - customer data |
| dbo.Real_BackOfficeCustomer | Table | JOIN on CID - back-office data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get account user info for multiple customers
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (1001), (1002)
EXEC Customer.GetManyAccountUserInfo @ids = @ids
```

### 8.2 Direct query equivalent
```sql
SELECT c.GCID, c.OriginalCID, c.SerialID AS AffiliateID, c.LabelID AS WhiteLabelID,
       bc.AccountTypeID, c.Registered AS CreatedOn, c.TradeLevelID, c.CurrencyID,
       c.PendingClosureStatusID, c.AccountStatusID, bc.MasterAccountCID,
       bc.ManagerID, c.SubSerialID, bc.GuruStatusID
FROM dbo.Real_Customer c WITH (NOLOCK)
JOIN @ids ids ON ids.Id = c.GCID
JOIN dbo.Real_BackOfficeCustomer bc WITH (NOLOCK) ON c.CID = bc.CID
```

### 8.3 Compare with Customer schema version
```sql
-- This SP reads from dbo.Real_Customer + Real_BackOfficeCustomer (legacy)
-- Customer.GetManyAccountInfo reads from Customer.AccountUserInfo + BasicUserInfo (new)
-- Both return similar data; prefer GetManyAccountInfo for new development
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetManyAccountUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetManyAccountUserInfo.sql*

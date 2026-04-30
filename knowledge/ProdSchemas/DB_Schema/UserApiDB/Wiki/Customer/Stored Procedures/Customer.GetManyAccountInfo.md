# Customer.GetManyAccountInfo

> Retrieves account information for multiple customers by GCID list - returns registration, affiliation, account type, trade level, currency, and closure status from Customer schema tables.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns account info rows for a GCID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetManyAccountInfo is a batch reader that retrieves account-level information for multiple customers in a single call. It reads from Customer.AccountUserInfo and Customer.BasicUserInfo (the normalized Customer schema tables) rather than the legacy dbo.Real_Customer view. This is the "new-style" account info getter that leverages the Customer schema migration.

This procedure is used when the application needs account details (affiliates, labels, trade levels, currencies, closure status) for multiple users at once - for example, in batch operations, admin dashboards, or bulk compliance reviews.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Batch read by GCID list from two Customer schema tables.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of GCIDs to retrieve account info for. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID from AccountUserInfo. |
| 3 | OriginalCID (output) | int | YES | - | CODE-BACKED | Original CID before any account migration. From AccountUserInfo. |
| 4 | AffiliateID (output) | int | YES | - | CODE-BACKED | Affiliate/serial ID that referred this customer. Aliased from SerialID. |
| 5 | WhiteLabelID (output) | int | YES | - | CODE-BACKED | White label/brand identifier. Aliased from LabelID. FK to Dictionary.Label. |
| 6 | AccountTypeID (output) | int | YES | - | CODE-BACKED | Account type classification. From AccountUserInfo. |
| 7 | CreatedOn (output) | datetime | YES | - | CODE-BACKED | Account registration date. Aliased from Registered in BasicUserInfo. |
| 8 | TradeLevelID (output) | int | YES | - | CODE-BACKED | Trading authorization level. FK to Dictionary.TradeLevel. |
| 9 | CurrencyID (output) | int | YES | - | CODE-BACKED | Account base currency. FK to Dictionary.Currency. |
| 10 | PendingClosureStatusID (output) | int | YES | - | CODE-BACKED | If account is pending closure, indicates the closure status. |
| 11 | AccountStatusID (output) | int | YES | - | CODE-BACKED | Current account status (active, suspended, etc.). |
| 12 | MasterAccountCID (output) | int | YES | - | CODE-BACKED | CID of the master account if this is a sub-account. |
| 13 | ManagerID (output) | int | YES | - | CODE-BACKED | Account manager CID assigned to this customer. |
| 14 | SubSerialID (output) | int | YES | - | CODE-BACKED | Sub-affiliate identifier. |
| 15 | GuruStatusID (output) | int | YES | - | CODE-BACKED | Popular Investor program status. FK to Dictionary.GuruStatus. |
| 16 | KycState (output) | int | YES | - | CODE-BACKED | KYC verification state. |
| 17 | FunnelFromID (output) | int | YES | - | CODE-BACKED | Identifies the registration funnel source. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | Customer.AccountUserInfo | JOIN | Account-level data (label, affiliate, trade level, etc.) |
| GCID | Customer.BasicUserInfo | JOIN | Registration date |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Batch account info retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetManyAccountInfo (procedure)
+-- Customer.AccountUserInfo (table)
+-- Customer.BasicUserInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.AccountUserInfo | Table | FROM - account data |
| Customer.BasicUserInfo | Table | JOIN on GCID - registration date |

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

### 8.1 Get account info for multiple customers
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (1001), (1002), (1003)
EXEC Customer.GetManyAccountInfo @ids = @ids
```

### 8.2 Direct query equivalent
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (1001), (1002)
SELECT a.GCID, OriginalCID, SerialID AS AffiliateID, LabelID AS WhiteLabelID,
       AccountTypeID, b.Registered AS CreatedOn, TradeLevelID, CurrencyID,
       PendingClosureStatusID, AccountStatusID, MasterAccountCID, ManagerID,
       SubSerialID, GuruStatusID, KycState, FunnelFromID
FROM Customer.AccountUserInfo a WITH (NOLOCK)
JOIN @ids ids ON ids.Id = a.GCID
JOIN Customer.BasicUserInfo b WITH (NOLOCK) ON a.GCID = b.GCID
```

### 8.3 Get account info with label name
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (1001)
SELECT a.GCID, l.Name AS LabelName, a.AccountTypeID, b.Registered AS CreatedOn
FROM Customer.AccountUserInfo a WITH (NOLOCK)
JOIN @ids ids ON ids.Id = a.GCID
JOIN Customer.BasicUserInfo b WITH (NOLOCK) ON a.GCID = b.GCID
LEFT JOIN Dictionary.Label l WITH (NOLOCK) ON a.LabelID = l.LabelID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetManyAccountInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetManyAccountInfo.sql*

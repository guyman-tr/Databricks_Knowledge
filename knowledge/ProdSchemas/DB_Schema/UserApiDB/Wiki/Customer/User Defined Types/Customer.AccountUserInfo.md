# Customer.AccountUserInfo (UDT)

> Table-valued parameter type for bulk updating account-level user information including label, trade level, guru status, and KYC state.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | GCID (user identifier column) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.AccountUserInfo is a table-valued parameter (TVP) type used to pass batches of account-level user data to stored procedures. It enables bulk operations on user account settings such as white label assignment, trade level, account type, guru (Popular Investor) status, and KYC state.

This type exists to support efficient bulk update operations. Rather than calling an update procedure once per user, callers can populate this TVP with multiple rows and pass it to Customer.Bulk_UpdateAccountUserInfo for batch processing.

Used by application services when syncing account configuration changes across multiple users simultaneously, such as during regulatory migration, bulk status updates, or PI tier recalculations.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a data transport type.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | CODE-BACKED | Global Customer ID - the unique user identifier across the platform. |
| 2 | AffiliateId | int | YES | - | CODE-BACKED | Marketing affiliate/partner ID that referred this user. |
| 3 | WhiteLabelId | int | YES | - | CODE-BACKED | White-label brand identifier. Maps to Dictionary.Label.LabelID. |
| 4 | AccountTypeId | int | YES | - | CODE-BACKED | Account type classification (e.g., real, demo, internal). |
| 5 | TradeLevelId | int | YES | - | CODE-BACKED | Trading platform UI access level. Maps to Dictionary.TradeLevel. 0=Normal, 1=Pro, 2=Visual. |
| 6 | PendingClosureStatusId | int | YES | - | CODE-BACKED | Status of pending account closure process. |
| 7 | AccountStatusId | int | YES | - | CODE-BACKED | Account operational status. |
| 8 | MasterAccountCId | int | YES | - | CODE-BACKED | For sub-accounts: the parent/master account's CID. NULL for standalone accounts. |
| 9 | ManagerId | int | YES | - | CODE-BACKED | Account manager or relationship manager CID. |
| 10 | GuruStatusId | int | YES | - | CODE-BACKED | Popular Investor tier. Maps to Dictionary.GuruStatus. 0=No, 2=Cadet through 6=Elite Pro. |
| 11 | KYCState | int | YES | - | CODE-BACKED | Current KYC (Know Your Customer) workflow state. |
| 12 | SubSerialID | varchar(1024) | YES | - | CODE-BACKED | Sub-serial identifier for tracking within partner/affiliate systems. |
| 13 | DownloadID | int | YES | - | CODE-BACKED | Download/installation tracking identifier for mobile app attribution. |
| 14 | ReferralID | int | YES | - | CODE-BACKED | Referral program identifier - tracks which referral campaign brought this user. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (UDT - no FK constraints).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.Bulk_UpdateAccountUserInfo | @BulkUpdateTable parameter | Parameter Type | TVP used to pass bulk account updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.Bulk_UpdateAccountUserInfo | Stored Procedure | Uses as READONLY parameter type |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate the type
```sql
DECLARE @Updates Customer.AccountUserInfo
INSERT INTO @Updates (GCID, GuruStatusId, TradeLevelId)
VALUES (12345, 2, 1), (67890, 3, 0)
```

### 8.2 Use in bulk update procedure
```sql
DECLARE @Updates Customer.AccountUserInfo
INSERT INTO @Updates (GCID, WhiteLabelId) VALUES (12345, 1)
EXEC Customer.Bulk_UpdateAccountUserInfo @BulkUpdateTable = @Updates
```

### 8.3 Select from the type variable
```sql
DECLARE @Data Customer.AccountUserInfo
INSERT INTO @Data (GCID, AccountTypeId) SELECT GCID, 1 FROM Customer.AccountUserInfo WITH (NOLOCK) WHERE AccountTypeID = 2
SELECT * FROM @Data
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.AccountUserInfo | Type: User Defined Type | Source: UserApiDB/UserApiDB/Customer/User Defined Types/Customer.AccountUserInfo.sql*

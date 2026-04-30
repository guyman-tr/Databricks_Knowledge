# Customer.UpdateAccountUserInfo

> Legacy account update - delegates to dbo.Real_UpdateAccountUserInfoRemote to update account fields in the dbo schema tables.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | EXEC dbo.Real_UpdateAccountUserInfoRemote |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateAccountUserInfo is the legacy version of UpdateAccountInfo. Instead of directly updating Customer.AccountUserInfo, it delegates to dbo.Real_UpdateAccountUserInfoRemote which updates the legacy dbo tables. Includes additional fields not in UpdateAccountInfo: SubSerialID, DownloadID, ReferralID. Returns SELECT 1 on success.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Pass-through to legacy remote procedure.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @affiliateId | int | YES | NULL | CODE-BACKED | Affiliate ID. |
| 3 | @originalCid | int | YES | NULL | CODE-BACKED | Original CID. |
| 4 | @whiteLabelId | int | YES | NULL | CODE-BACKED | White label. |
| 5 | @accountTypeId | int | YES | NULL | CODE-BACKED | Account type. |
| 6 | @tradeLevelId | int | YES | NULL | CODE-BACKED | Trade level. |
| 7 | @currencyId | int | YES | NULL | CODE-BACKED | Currency. |
| 8 | @createdOn | datetime | YES | NULL | CODE-BACKED | Registration date. |
| 9 | @pendingClosureStatusID | int | YES | NULL | CODE-BACKED | Pending closure. |
| 10 | @accountStatusID | int | YES | NULL | CODE-BACKED | Account status. |
| 11 | @masterAccountCID | int | YES | NULL | CODE-BACKED | Master account. |
| 12 | @managerID | int | YES | NULL | CODE-BACKED | Account manager. |
| 13 | @guruStatusID | int | YES | NULL | CODE-BACKED | Popular Investor status. |
| 14 | @KycState | int | YES | NULL | CODE-BACKED | KYC state. |
| 15 | @SubSerialID | varchar(1024) | YES | NULL | CODE-BACKED | Sub-affiliate ID (legacy-only field). |
| 16 | @DownloadID | int | YES | NULL | CODE-BACKED | Download tracking (legacy-only). |
| 17 | @ReferralID | int | YES | NULL | CODE-BACKED | Referral tracking (legacy-only). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | dbo.Real_UpdateAccountUserInfoRemote | EXEC | Legacy remote update |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Legacy account updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateAccountUserInfo (procedure)
+-- dbo.Real_UpdateAccountUserInfoRemote (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_UpdateAccountUserInfoRemote | Procedure | EXEC |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Legacy callers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update account (legacy)
```sql
EXEC Customer.UpdateAccountUserInfo @gcid=12345, @guruStatusID=2, @SubSerialID='sub-001'
```

### 8.2 Prefer new version
```sql
-- Use Customer.UpdateAccountInfo for new development (direct Customer schema update)
-- Use Customer.UpdateAccountUserInfo for legacy compatibility only
```

### 8.3 Verify update
```sql
EXEC Customer.GetAccountInfo @gcid=12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateAccountUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateAccountUserInfo.sql*

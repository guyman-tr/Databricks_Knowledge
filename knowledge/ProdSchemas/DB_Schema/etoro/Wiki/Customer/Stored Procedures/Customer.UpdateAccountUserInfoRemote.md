# Customer.UpdateAccountUserInfoRemote

> Updates account-level fields on both Customer.CustomerStatic and BackOffice.Customer for a given GCID, acting as a remote synchronization write-path for account metadata from external management systems.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid - GCID lookup for CustomerStatic; resolves to CID for BackOffice.Customer |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateAccountUserInfoRemote is a cross-schema account metadata synchronizer that updates account configuration fields on two tables - Customer.CustomerStatic (registration and identity fields) and BackOffice.Customer (account classification and CRM fields) - in a single call via GCID lookup. The "Remote" suffix indicates this procedure is the write-path for synchronization from external management systems (e.g., back-office portals, account migration tools) rather than a customer-facing UI action.

The procedure exists to provide a single atomic entry point for account-level data that spans two schemas. Account management operations (e.g., changing a customer's white-label assignment, KYC state, or account type) need to update both the Customer and BackOffice schemas consistently. This procedure handles both in one call, resolves GCID to CID internally, and outputs the affected row count.

Data flow: called from account management services or migration tools when account-level fields need synchronization. Resolves @gcid to @cid via CustomerStatic, then updates both schemas. Uses ISNULL() for SubSerialID, DownloadID, and ReferralID (preserve existing if NULL passed). No action queue is written (unlike the non-Remote UpdateBasicUserInfo). Returns @@RowCount from the BackOffice.Customer UPDATE via @RowCount OUTPUT; if @RowCount > 0, returns SELECT 1.

---

## 2. Business Logic

### 2.1 Dual-Schema Update via GCID Resolution

**What**: A single call updates both Customer.CustomerStatic and BackOffice.Customer, with GCID used to look up the customer's CID for the BackOffice update.

**Columns/Parameters Involved**: `@gcid`, Customer.CustomerStatic.GCID, BackOffice.Customer.CID

**Rules**:
- Step 1: UPDATE Customer.CustomerStatic WHERE GCID=@gcid (all account fields)
- Step 2: SELECT @cid = CID FROM CustomerStatic WITH(NoLock) WHERE GCID=@gcid
- Step 3: UPDATE BackOffice.Customer WHERE CID=@cid (account type/manager/KYC fields)
- @RowCount OUTPUT captures @@RowCount from the BackOffice.Customer UPDATE (not CustomerStatic)
- If @RowCount > 0: SELECT 1 (signals success to callers that check result sets)

### 2.2 Preserve-Existing Pattern for Optional Fields

**What**: SubSerialID, DownloadID, and ReferralID use ISNULL(@param, ExistingColumn) to avoid clearing values when the caller passes NULL.

**Columns/Parameters Involved**: `@SubSerialID`, `@DownloadID`, `@ReferralID`

**Rules**:
- SubSerialID = ISNULL(@SubSerialID, SubSerialID) - caller can pass NULL to leave unchanged
- DownloadID = ISNULL(@DownloadID, DownloadID) - same
- ReferralID = ISNULL(@ReferralID, ReferralID) - same
- All other CustomerStatic fields are SET unconditionally (NULL clears the column)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. Used to find the customer in CustomerStatic. Resolved to CID for the BackOffice.Customer UPDATE. |
| 2 | @affiliateId | int | YES | NULL | CODE-BACKED | Affiliate/partner identifier. Maps to CustomerStatic.SerialID (the affiliate serial tracking code). NULL leaves the column unchanged? No - only 3 fields use ISNULL; SerialID is SET directly, so NULL clears it. |
| 3 | @originalCid | int | YES | NULL | CODE-BACKED | Original customer CID before any account migration. Maps to CustomerStatic.OriginalCID. Set directly (NULL clears). |
| 4 | @whiteLabelId | int | YES | NULL | CODE-BACKED | White-label brand identifier. Maps to CustomerStatic.LabelID. Controls partner branding for the customer. Set directly (NULL clears). |
| 5 | @accountTypeId | int | YES | NULL | CODE-BACKED | Account type classification. Maps to BackOffice.Customer.AccountTypeID. Controls account behavior in the back-office system. Set directly (NULL clears). |
| 6 | @tradeLevelId | int | YES | NULL | CODE-BACKED | Trade level permission tier. Maps to CustomerStatic.TradeLevelID. Controls trading product access. Set directly (NULL clears). |
| 7 | @currencyId | int | YES | NULL | CODE-BACKED | Account base currency. Maps to CustomerStatic.CurrencyID. Denomination for balance and P&L. Set directly (NULL clears). |
| 8 | @createdOn | datetime | YES | NULL | CODE-BACKED | Account creation timestamp. Parameter is declared but NOT used in any UPDATE statement (unused parameter - likely a legacy artifact). |
| 9 | @pendingClosureStatusID | int | YES | NULL | CODE-BACKED | Pending account closure state. Maps to CustomerStatic.PendingClosureStatusID. Set directly (NULL clears). |
| 10 | @accountStatusID | int | YES | NULL | CODE-BACKED | Current account status. Maps to CustomerStatic.AccountStatusID. Controls account active/inactive/suspended state. Set directly (NULL clears). |
| 11 | @masterAccountCID | int | YES | NULL | CODE-BACKED | CID of the master account in a multi-account hierarchy. Maps to BackOffice.Customer.MasterAccountCID. Set directly (NULL clears). |
| 12 | @managerID | int | YES | NULL | CODE-BACKED | Assigned account manager CID. Maps to BackOffice.Customer.ManagerID. Set directly (NULL clears). |
| 13 | @guruStatusID | int | YES | NULL | CODE-BACKED | Guru/popular investor status. Maps to BackOffice.Customer.GuruStatusID. Set directly (NULL clears). |
| 14 | @KycState | int | YES | NULL | CODE-BACKED | Know-Your-Customer verification state. Maps to BackOffice.Customer.KycState. Set directly (NULL clears). |
| 15 | @SubSerialID | varchar(1024) | YES | NULL | CODE-BACKED | Sub-affiliate tracking identifier. Maps to CustomerStatic.SubSerialID. Uses ISNULL - NULL preserves existing value. |
| 16 | @DownloadID | int | YES | NULL | CODE-BACKED | Download/acquisition tracking ID. Maps to CustomerStatic.DownloadID. Uses ISNULL - NULL preserves existing value. |
| 17 | @ReferralID | int | YES | NULL | CODE-BACKED | Referring customer CID. Maps to CustomerStatic.ReferralID. Used in RAF validation. Uses ISNULL - NULL preserves existing value. |
| 18 | @RowCount | int | YES (OUTPUT) | NULL | CODE-BACKED | Output: @@RowCount from the BackOffice.Customer UPDATE step. Non-zero means BackOffice.Customer was found and updated. If @RowCount > 0, procedure also returns SELECT 1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.CustomerStatic | Reader + Modifier | Resolves GCID to CID; updates multiple account fields |
| @gcid (resolved to @cid) | BackOffice.Customer | Modifier | Updates account type, manager, guru status, KYC state |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external account management system) | - | - | No intra-DB callers found; called from account synchronization or migration services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateAccountUserInfoRemote (procedure)
├── Customer.CustomerStatic (table - GCID lookup + UPDATE)
└── BackOffice.Customer (table - UPDATE)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | GCID -> CID resolution (SELECT); target of account field UPDATE |
| BackOffice.Customer | Table | Target of account type/KYC UPDATE by resolved CID |

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
| TRY/CATCH | Error handling | Errors are caught and printed (server name, DB, procedure, line, message) but NOT re-raised - silent failure |
| @createdOn unused | Code note | Parameter declared but never used in any UPDATE statement |

---

## 8. Sample Queries

### 8.1 Update KYC state and account type for a customer
```sql
DECLARE @Rows INT;
EXEC Customer.UpdateAccountUserInfoRemote
    @gcid = 67890,
    @accountTypeId = 2,
    @KycState = 3,
    @RowCount = @Rows OUTPUT;
SELECT @Rows AS BackOfficeRowsUpdated;
```

### 8.2 Update white-label and trade level
```sql
EXEC Customer.UpdateAccountUserInfoRemote
    @gcid = 67890,
    @whiteLabelId = 11,    -- ICMarkets
    @tradeLevelId = 3;
```

### 8.3 Verify the update across both schemas
```sql
SELECT cs.GCID, cs.CID, cs.LabelID, cs.TradeLevelID, cs.AccountStatusID,
       bc.AccountTypeID, bc.KycState, bc.GuruStatusID
FROM Customer.CustomerStatic cs WITH (NOLOCK)
JOIN BackOffice.Customer bc WITH (NOLOCK) ON cs.CID = bc.CID
WHERE cs.GCID = 67890;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.UpdateAccountUserInfoRemote | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateAccountUserInfoRemote.sql*

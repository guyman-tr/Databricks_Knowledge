# BackOffice.AccountUserInfo

> Table-valued parameter type that defines the schema for bulk account-level attribute updates across Customer.CustomerStatic and BackOffice.Customer tables.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | User Defined Type |
| **Key Identifier** | GCID (Group Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.AccountUserInfo` is a Table-Valued Type (TVT) that defines the schema contract for passing a batch of account-level user updates from an external caller into the BackOffice layer. It captures the full set of account classification and control fields that describe a customer's account state - affiliate assignment, white-label branding, trade level, account type, manager, guru status, and KYC state.

This type exists to define a precise, type-safe schema for bulk update operations. Without it, the column contract between caller and stored procedure would be implicit and fragile. The type documents exactly which fields can be modified in a single bulk operation and their expected data types.

Data flows into this type from the remote caller (e.g., a sync service or back-office application). The caller populates a table variable or temp table matching this structure, then executes `BackOffice.Bulk_UpdateAccountUserInfoRemote`. The SP applies ISNULL-guarded updates - only non-NULL fields in the row overwrite the existing values, meaning partial updates are supported. Fields left as NULL are skipped.

---

## 2. Business Logic

### 2.1 NULL-as-No-Op Partial Update Pattern

**What**: All 11 columns in this type are nullable, enabling callers to update only the fields they care about in a single pass.

**Columns/Parameters Involved**: All columns (GCID through KYCState)

**Rules**:
- GCID is the row key - it identifies which customer to update. It should never be NULL in practice even though the DDL allows it.
- For all other columns: NULL = "do not update this field". Non-NULL = "set this field to the given value."
- The consuming SP uses `ISNULL(BulkTable.Column, ExistingValue)` to implement this logic, so no explicit NULL check is needed in the caller.
- This allows a single batch to mix records with different subsets of fields updated.

**Diagram**:
```
Incoming row (GCID=12345, AccountTypeId=2, others NULL)
        |
        v
Bulk_UpdateAccountUserInfoRemote
        |
        +-- UPDATE Customer.CustomerStatic
        |   SET LabelID       = ISNULL(NULL, existing)   -> unchanged
        |       SerialID      = ISNULL(NULL, existing)   -> unchanged
        |       AccountStatusID = ISNULL(NULL, existing) -> unchanged
        |       ...
        |
        +-- UPDATE BackOffice.Customer
            SET AccountTypeID = ISNULL(2, existing)      -> SET to 2
            SET ManagerID     = ISNULL(NULL, existing)   -> unchanged
            ...
```

---

## 3. Data Overview

N/A for User Defined Type. This is a type definition, not a persistent table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | CODE-BACKED | Group Customer ID - the logical key for a customer group. Joins to Customer.CustomerStatic.GCID to identify which customer record to update. Should be non-NULL in all valid usage even though DDL allows NULL. |
| 2 | AffiliateId | int | YES | - | CODE-BACKED | Affiliate identifier. Maps to Customer.CustomerStatic.SerialID (the affiliate/serial assignment). NULL = do not update this field. |
| 3 | WhiteLabelId | int | YES | - | CODE-BACKED | White-label brand identifier. Maps to Customer.CustomerStatic.LabelID. Determines which branded platform the customer belongs to. NULL = do not update. |
| 4 | AccountTypeId | int | YES | - | CODE-BACKED | Account type classification. Maps to BackOffice.Customer.AccountTypeID. Distinguishes regular, professional, and other account categories. NULL = do not update. |
| 5 | TradeLevelId | int | YES | - | CODE-BACKED | Trading level tier. Maps to Customer.CustomerStatic.TradeLevelID. Controls trading capabilities and leverage limits for the customer. NULL = do not update. |
| 6 | PendingClosureStatusId | int | YES | - | CODE-BACKED | Pending account closure state. Maps to Customer.CustomerStatic.PendingClosureStatusID. Indicates whether the account is queued for closure and at what stage. NULL = do not update. |
| 7 | AccountStatusId | int | YES | - | CODE-BACKED | Current account status. Maps to Customer.CustomerStatic.AccountStatusID. Controls whether the account is active, suspended, closed, etc. NULL = do not update. |
| 8 | MasterAccountCId | int | YES | - | CODE-BACKED | CID of the master account in a linked-account group. Maps to BackOffice.Customer.MasterAccountCID. Used for corporate or family accounts where one account is the primary. NULL = do not update. |
| 9 | ManagerId | int | YES | - | CODE-BACKED | BackOffice manager assigned to this customer. Maps to BackOffice.Customer.ManagerID and references BackOffice.Manager.ManagerID. Determines which sales/support manager owns this account. NULL = do not update. |
| 10 | GuruStatusId | int | YES | - | CODE-BACKED | Popular Investor (guru) status identifier. Maps to BackOffice.Customer.GuruStatusID. Indicates the customer's level in the Popular Investor programme. NULL = do not update. |
| 11 | KYCState | int | YES | - | CODE-BACKED | Know Your Customer verification state. Maps to BackOffice.Customer.KycState. Tracks the customer's identity verification progress. NULL = do not update. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID | Customer.CustomerStatic.GCID | Implicit | Row key for identifying which customer to update |
| AffiliateId | Customer.CustomerStatic.SerialID | Implicit | Affiliate assignment field mapping |
| WhiteLabelId | Customer.CustomerStatic.LabelID | Implicit | White-label brand field mapping |
| AccountTypeId | BackOffice.Customer.AccountTypeID | Implicit | Account type classification mapping |
| TradeLevelId | Customer.CustomerStatic.TradeLevelID | Implicit | Trade level mapping |
| PendingClosureStatusId | Customer.CustomerStatic.PendingClosureStatusID | Implicit | Closure status mapping |
| AccountStatusId | Customer.CustomerStatic.AccountStatusID | Implicit | Account status mapping |
| MasterAccountCId | BackOffice.Customer.MasterAccountCID | Implicit | Master account linkage mapping |
| ManagerId | BackOffice.Customer.ManagerID | Implicit | Manager assignment mapping |
| GuruStatusId | BackOffice.Customer.GuruStatusID | Implicit | Guru/Popular Investor status mapping |
| KYCState | BackOffice.Customer.KycState | Implicit | KYC state mapping |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Bulk_UpdateAccountUserInfoRemote | (temp table schema) | Schema contract | SP uses a temp table #BulkUpdateAccountUserInfo matching this type's structure. The TVT defines the intended schema contract even though the current SP uses a temp table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Bulk_UpdateAccountUserInfoRemote | Stored Procedure | Consumes rows matching this type's schema via #BulkUpdateAccountUserInfo temp table. Updates Customer.CustomerStatic and BackOffice.Customer. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None. All columns are INT NULL with no constraints.

---

## 8. Sample Queries

### 8.1 Declare and populate to update a customer's account status and manager

```sql
DECLARE @Updates BackOffice.AccountUserInfo;

INSERT INTO @Updates (GCID, AccountStatusId, ManagerId)
VALUES (12345, 2, 99);

-- Then execute consuming SP (which uses temp table in current impl)
-- SELECT * FROM @Updates WITH (NOLOCK)  -- for inspection
```

### 8.2 Partial update - only set KYC state for multiple customers

```sql
DECLARE @Updates BackOffice.AccountUserInfo;

INSERT INTO @Updates (GCID, KYCState)
SELECT GCID, 3  -- 3 = Verified
FROM SomeSourceTable WITH (NOLOCK)
WHERE NeedsKycUpdate = 1;

SELECT * FROM @Updates WITH (NOLOCK);
```

### 8.3 Inspect which customers have a specific account status pending update

```sql
-- Simulate what the SP would update for AccountStatusId changes
SELECT u.GCID, u.AccountStatusId, cs.AccountStatusID AS CurrentStatus
FROM @Updates u
JOIN Customer.CustomerStatic cs WITH (NOLOCK)
    ON cs.GCID = u.GCID
WHERE u.AccountStatusId IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AccountUserInfo | Type: User Defined Type | Source: etoro/etoro/BackOffice/User Defined Types/BackOffice.AccountUserInfo.sql*

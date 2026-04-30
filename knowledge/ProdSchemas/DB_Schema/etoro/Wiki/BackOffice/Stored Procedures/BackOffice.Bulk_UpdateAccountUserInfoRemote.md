# BackOffice.Bulk_UpdateAccountUserInfoRemote

> Applies a batch of account-level field updates to Customer.CustomerStatic and BackOffice.Customer from a pre-populated temp table (#BulkUpdateAccountUserInfo), using GCID-based matching and NULL-preserving updates.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | #BulkUpdateAccountUserInfo.GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is part of a three-procedure bulk update suite (Bulk_UpdateAccountUserInfoRemote, Bulk_UpdateBasicUserInfoRemote, Bulk_UpdateRiskUserInfoRemote) designed for high-volume batch customer data updates. The `_Remote` suffix indicates this procedure is called remotely - typically from a centralized service or orchestration layer that populates a temp table on the connection, then calls the procedure to apply the updates.

Bulk_UpdateAccountUserInfoRemote handles account classification fields: whitelabel assignment (LabelID), affiliate tracking (SerialID), trading access tier (TradeLevelID), account status (AccountStatusID), closure status (PendingClosureStatusID), and BackOffice-managed fields like account type, manager assignment, guru status, and KYC state. All updates use ISNULL logic: if the bulk table has NULL for a field, the existing customer value is preserved - enabling partial updates where only explicitly provided fields are changed.

Typical use case: a batch migration or sync operation needs to update hundreds or thousands of customers' account classifications in one operation, reading from a staging dataset.

---

## 2. Business Logic

### 2.1 Dual-Table Update via GCID Matching

**What**: Updates both Customer.CustomerStatic and BackOffice.Customer using GCID as the join key.

**Tables Involved**: `#BulkUpdateAccountUserInfo`, `Customer.CustomerStatic`, `BackOffice.Customer`

**Rules**:
- Reads from temp table `#BulkUpdateAccountUserInfo` (must exist on calling connection before EXEC)
- No parameters accepted - caller is responsible for creating and populating the temp table
- **Update 1**: Customer.CustomerStatic SET LabelID, SerialID, TradeLevelID, PendingClosureStatusID, AccountStatusID, SubSerialID, DownloadID, ReferralID WHERE GCID matches
- **Update 2**: BackOffice.Customer SET AccountTypeID, MasterAccountCID, ManagerID, GuruStatusID, KycState WHERE CID from CustomerStatic WHERE GCID matches (two-hop join)
- ISNULL(BulkTable.Value, CurrentValue) - NULL in the bulk table = preserve existing value
- No transaction - two sequential UPDATEs; if second fails, first's changes persist
- Returns no result set; return value is not explicitly set (defaults to 0)

### 2.2 GCID-to-CID Resolution for BackOffice.Customer

**What**: BackOffice.Customer is keyed by CID, not GCID. The second UPDATE joins through CustomerStatic to resolve GCID to CID.

**Rules**:
- `FROM Customer.CustomerStatic as CC INNER JOIN #BulkUpdateAccountUserInfo as BulkTable ON CC.GCID = BulkTable.GCID WHERE BackOffice.Customer.CID = CC.CID`
- GCID is the global customer identifier; CID is the eToro-specific identifier. GCID:CID is typically 1:1.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Temp Table Input (no parameters - reads from #BulkUpdateAccountUserInfo):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | (caller-defined) | NO | - | CODE-BACKED | Global Customer ID used to match rows in Customer.CustomerStatic. Join key for all updates. |
| 2 | WhiteLabelId | (caller-defined) | YES | - | CODE-BACKED | Maps to Customer.CustomerStatic.LabelID. NULL = preserve existing. Whitelabel partner assignment. |
| 3 | AffiliateId | (caller-defined) | YES | - | CODE-BACKED | Maps to Customer.CustomerStatic.SerialID. NULL = preserve existing. Affiliate who referred this customer. |
| 4 | TradeLevelId | (caller-defined) | YES | - | CODE-BACKED | Maps to Customer.CustomerStatic.TradeLevelID. NULL = preserve existing. Customer's trading access tier. |
| 5 | PendingClosureStatusId | (caller-defined) | YES | - | CODE-BACKED | Maps to Customer.CustomerStatic.PendingClosureStatusID. NULL = preserve existing. 1=No, 2=Suggested, 3=Approved for Closure. |
| 6 | AccountStatusId | (caller-defined) | YES | - | CODE-BACKED | Maps to Customer.CustomerStatic.AccountStatusID. NULL = preserve existing. 1=Active, 2=Closed, etc. |
| 7 | SubSerialID | (caller-defined) | YES | - | CODE-BACKED | Maps to Customer.CustomerStatic.SubSerialID. NULL = preserve existing. Sub-affiliate tracking. |
| 8 | DownloadID | (caller-defined) | YES | - | CODE-BACKED | Maps to Customer.CustomerStatic.DownloadID. NULL = preserve existing. Campaign download tracking. |
| 9 | ReferralID | (caller-defined) | YES | - | CODE-BACKED | Maps to Customer.CustomerStatic.ReferralID. NULL = preserve existing. Referral source tracking. |
| 10 | AccountTypeId | (caller-defined) | YES | - | CODE-BACKED | Maps to BackOffice.Customer.AccountTypeID. NULL = preserve existing. Customer account type classification. |
| 11 | MasterAccountCId | (caller-defined) | YES | - | CODE-BACKED | Maps to BackOffice.Customer.MasterAccountCID. NULL = preserve existing. For sub-accounts, the CID of the master account. |
| 12 | ManagerId | (caller-defined) | YES | - | CODE-BACKED | Maps to BackOffice.Customer.ManagerID. NULL = preserve existing. Assigned BackOffice manager. |
| 13 | GuruStatusId | (caller-defined) | YES | - | CODE-BACKED | Maps to BackOffice.Customer.GuruStatusID. NULL = preserve existing. Popular Investor / Guru status classification. |
| 14 | KYCState | (caller-defined) | YES | - | CODE-BACKED | Maps to BackOffice.Customer.KycState. NULL = preserve existing. KYC verification state. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| #BulkUpdateAccountUserInfo.GCID | Customer.CustomerStatic | MODIFIER | Bulk-updates account classification fields matched by GCID |
| #BulkUpdateAccountUserInfo.GCID | BackOffice.Customer | MODIFIER | Bulk-updates BackOffice account fields via GCID->CID resolution through CustomerStatic |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestration / sync service | #BulkUpdateAccountUserInfo temp table | Caller | Centralized bulk update service creates temp table, populates it, then calls this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.Bulk_UpdateAccountUserInfoRemote (procedure)
|- #BulkUpdateAccountUserInfo (temp table) [caller must create and populate before EXEC]
|- Customer.CustomerStatic (table) [UPDATE target - account classification fields]
+-- BackOffice.Customer (table) [UPDATE target - BackOffice account fields]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| #BulkUpdateAccountUserInfo | Temp Table | Source data for bulk UPDATE - must exist on calling connection |
| Customer.CustomerStatic | Table (cross-schema) | UPDATE target for account-level fields (LabelID, SerialID, TradeLevelID, etc.); also used for GCID-to-CID resolution |
| BackOffice.Customer | Table | UPDATE target for BackOffice classification fields (AccountTypeID, GuruStatusID, KycState, etc.) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External bulk update service | External | Calls after populating #BulkUpdateAccountUserInfo |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No parameters | Design | Reads exclusively from temp table - calling context owns data preparation |
| ISNULL preserving pattern | Design | NULL in bulk table = keep existing value. Only non-NULL values in the temp table trigger field updates. |
| No transaction | Design | Two sequential UPDATEs without explicit transaction - partial update possible if second UPDATE fails |
| GCID join | Design | Matching done on GCID (global ID), with GCID->CID resolution needed for BackOffice.Customer |
| No result set | Design | Procedure has no SELECT or RETURN; result is communicated by absence of error |

---

## 8. Sample Queries

### 8.1 Bulk update account fields for a set of customers

```sql
-- Step 1: Create and populate the temp table
CREATE TABLE #BulkUpdateAccountUserInfo (
    GCID        INT,
    WhiteLabelId    INT,
    AffiliateId     INT,
    TradeLevelId    INT,
    PendingClosureStatusId TINYINT,
    AccountStatusId TINYINT,
    SubSerialID     INT,
    DownloadID      INT,
    ReferralID      INT,
    AccountTypeId   INT,
    MasterAccountCId INT,
    ManagerId       INT,
    GuruStatusId    INT,
    KYCState        INT
)

INSERT INTO #BulkUpdateAccountUserInfo (GCID, AccountStatusId)
VALUES (100001, 2), (100002, 2)  -- close two accounts (only AccountStatusId set, all others NULL)

-- Step 2: Call the procedure
EXEC BackOffice.Bulk_UpdateAccountUserInfoRemote

DROP TABLE #BulkUpdateAccountUserInfo
```

### 8.2 Verify updates were applied

```sql
SELECT cs.GCID, cs.AccountStatusID, cs.LabelID, bc.GuruStatusID, bc.KycState
FROM Customer.CustomerStatic cs WITH (NOLOCK)
JOIN BackOffice.Customer bc WITH (NOLOCK) ON bc.CID = cs.CID
WHERE cs.GCID IN (100001, 100002)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Bulk_UpdateAccountUserInfoRemote | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.Bulk_UpdateAccountUserInfoRemote.sql*

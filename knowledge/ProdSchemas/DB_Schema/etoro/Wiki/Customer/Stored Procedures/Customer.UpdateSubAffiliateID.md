# Customer.UpdateSubAffiliateID

> Updates affiliate tracking fields (SubSerialID, SerialID, ReferralID, DownloadID) on Customer.Customer for a given CID; auto-creates the affiliate record via BackOffice.AffiliateEdit if @AffiliateID is provided but not yet registered; ISNULL-preserve for ReferralID and DownloadID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - CID-based lookup for Customer.Customer |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateSubAffiliateID handles late-binding affiliate attribution: it is called when the sub-affiliate ID (and optionally the parent affiliate ID, referral, and download tracking IDs) is not known at registration time - a common scenario for mobile registrations where the attribution chain is resolved asynchronously.

The procedure has two execution paths based on whether @AffiliateID is provided:
- **With @AffiliateID**: Also updates SerialID (the parent affiliate) and ensures the affiliate record exists in BackOffice.Affiliate (auto-creating via BackOffice.AffiliateEdit if missing).
- **Without @AffiliateID**: Updates SubSerialID only, leaving SerialID unchanged.

In both paths, @ReferralID and @DownloadID use ISNULL-preserve semantics - passing NULL leaves the existing value intact, allowing callers to update only the fields they know.

Error handling uses a TRY/CATCH that captures the error message into a temp table #T and returns it as a result set - errors are surfaced to the caller via SELECT rather than RAISERROR or re-throw.

**Change log** (from DDL comments):
- 2014-06-08 Yitzchak Wahnon: Added BackOffice.AffiliateEdit call
- 2014-10-26 Dror Meiri: Added @ReferralID parameter
- 2015-08-09 Dror Meiri: Added @DownloadID parameter

---

## 2. Business Logic

### 2.1 Affiliate-ID-Conditional Branching

**What**: Two paths - with @AffiliateID (affiliate known) and without (sub-affiliate only).

**Rules**:
- IF @AffiliateID IS NOT NULL:
  1. IF NOT EXISTS (SELECT 1 FROM BackOffice.Affiliate WHERE AffiliateID = @AffiliateID):
     EXEC BackOffice.AffiliateEdit @AffiliateID, 1, 0  -- auto-create the affiliate
  2. UPDATE Customer.Customer SET
       SubSerialID = @SubAffiliateID,
       SerialID = @AffiliateID,
       ReferralID = ISNULL(@ReferralID, ReferralID),
       DownloadID = ISNULL(@DownloadID, DownloadID)
     WHERE CID = @CID
- ELSE (@AffiliateID IS NULL):
  UPDATE Customer.Customer SET
    SubSerialID = @SubAffiliateID,
    ReferralID = ISNULL(@ReferralID, ReferralID),
    DownloadID = ISNULL(@DownloadID, DownloadID)
  WHERE CID = @CID
  (SerialID is NOT updated in this path)

**Diagram**:
```
@AffiliateID IS NOT NULL?
  YES -> BackOffice.Affiliate exists?
           NO  -> EXEC BackOffice.AffiliateEdit (@AffiliateID, 1, 0)
           YES -> (skip)
         UPDATE Customer.Customer
           SET SubSerialID=@SubAffiliateID, SerialID=@AffiliateID,
               ReferralID=ISNULL(@ReferralID,cur), DownloadID=ISNULL(@DownloadID,cur)
           WHERE CID=@CID
  NO  -> UPDATE Customer.Customer
           SET SubSerialID=@SubAffiliateID,
               ReferralID=ISNULL(@ReferralID,cur), DownloadID=ISNULL(@DownloadID,cur)
           WHERE CID=@CID
```

### 2.2 Error Handling

**Rules**:
- TRY block wraps the entire UPDATE logic
- CATCH inserts error message into #T (Tbl='Customer', Msg=Error_Message())
- After TRY/CATCH: SELECT * FROM #T (empty on success; one row with error on failure)
- No RAISERROR or re-throw - errors are returned as a result set, not as SQL exceptions

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer CID. WHERE CID = @CID target for Customer.Customer update. |
| 2 | @SubAffiliateID | varchar(1024) | NO | - | CODE-BACKED | Sub-affiliate tracking code. Maps to Customer.Customer.SubSerialID. Always set directly (no ISNULL guard) in both paths. |
| 3 | @AffiliateID | int | YES | NULL | CODE-BACKED | Parent affiliate ID. If non-NULL: triggers auto-creation in BackOffice.Affiliate and sets Customer.Customer.SerialID. If NULL: SerialID is not updated. |
| 4 | @ReferralID | int | YES | NULL | CODE-BACKED | Referral tracking ID. ISNULL-preserve: NULL leaves Customer.Customer.ReferralID unchanged. Added 2014-10-26. |
| 5 | @DownloadID | int | YES | NULL | CODE-BACKED | Download/install tracking ID. ISNULL-preserve: NULL leaves Customer.Customer.DownloadID unchanged. Added 2015-08-09. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AffiliateID | BackOffice.Affiliate | Reader | Existence check before auto-create |
| @AffiliateID (if missing) | BackOffice.AffiliateEdit | Caller | Auto-creates affiliate record if not found |
| @CID | Customer.Customer | Modifier | UPDATE SubSerialID, SerialID (if @AffiliateID set), ReferralID, DownloadID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from mobile registration completion and affiliate attribution flows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateSubAffiliateID (procedure)
├── BackOffice.Affiliate (table - existence check for @AffiliateID)
├── BackOffice.AffiliateEdit (procedure - auto-create affiliate if missing)
└── Customer.Customer (view - UPDATE target for affiliate tracking fields)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Affiliate | Table (cross-schema) | Existence check: IF NOT EXISTS SELECT 1 WHERE AffiliateID=@AffiliateID |
| BackOffice.AffiliateEdit | Stored Procedure (cross-schema) | Called with (@AffiliateID, 1, 0) to auto-create missing affiliate record |
| Customer.Customer | View | UPDATE target for SubSerialID, SerialID, ReferralID, DownloadID |

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
| ISNULL-preserve (ReferralID, DownloadID) | Safety | NULL params keep existing values; only @SubAffiliateID is always overwritten |
| Error result set | Error handling | CATCH inserts into #T and returns via SELECT; no re-throw means caller must inspect result set for errors |
| Auto-create affiliate | Business rule | BackOffice.AffiliateEdit called with params (AffiliateID, 1, 0) when affiliate missing - second param likely IsActive=1 |
| SerialID not updated without @AffiliateID | Business rule | Passing only @SubAffiliateID leaves the parent affiliate (SerialID) unchanged |

---

## 8. Sample Queries

### 8.1 Update sub-affiliate with affiliate (auto-creates if needed)
```sql
EXEC Customer.UpdateSubAffiliateID
    @CID = 12345,
    @SubAffiliateID = 'SUB_ABC_123',
    @AffiliateID = 500,
    @ReferralID = NULL,
    @DownloadID = 777;
-- SerialID set to 500; DownloadID set to 777; ReferralID unchanged
```

### 8.2 Update sub-affiliate only (no parent affiliate change)
```sql
EXEC Customer.UpdateSubAffiliateID
    @CID = 12345,
    @SubAffiliateID = 'SUB_XYZ_456';
-- Only SubSerialID updated; SerialID, ReferralID, DownloadID unchanged
```

### 8.3 Check affiliate fields after update
```sql
SELECT CID, SubSerialID, SerialID, ReferralID, DownloadID
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.UpdateSubAffiliateID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateSubAffiliateID.sql*

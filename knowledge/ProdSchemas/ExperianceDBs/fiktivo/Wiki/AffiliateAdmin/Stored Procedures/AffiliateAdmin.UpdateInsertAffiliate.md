# AffiliateAdmin.UpdateInsertAffiliate

> Large upsert procedure for affiliate records handling all affiliate fields including name, email, address, tax info, and account settings, with comprehensive field-level audit logging.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AffiliateID (inserted or updated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** UpdateInsertAffiliate is a large upsert procedure (~57 parameters) that handles both creating new affiliates and updating existing affiliate records. When @AffiliateID=0, a new affiliate is inserted; otherwise, the existing affiliate is updated. The procedure manages the full spectrum of affiliate data fields including personal information, contact details, address, tax configuration, account settings, and operational parameters. Every field change on update is individually audit-logged.

**WHY:** The affiliate record is the central entity in the affiliate management system. It contains all the information needed to identify, contact, compensate, and manage an affiliate partner. A single comprehensive upsert procedure ensures consistent handling of all affiliate fields, reduces code duplication between create and update operations, and centralizes the audit logging logic. The exhaustive audit trail for field-level changes is critical for compliance, dispute resolution, and operational oversight.

**HOW:** The procedure checks @AffiliateID to determine if this is an INSERT (value=0) or UPDATE (value>0). For inserts, it performs a full INSERT into `tblaff_Affiliates` with all provided field values and creates an audit entry for the creation. For updates, it retrieves the current field values, compares each field against the new values, updates the record, and creates individual audit log entries for each field that changed. The procedure also manages related data in `AffiliateAdmin.AffiliatesGroups`, `Affiliate.BlockedCountries`, and `Affiliate.tblaff_AffiliateURLs` as part of the composite save.

---

## 2. Business Logic

### 2.1 Insert vs. Update Detection
The @AffiliateID parameter controls the operation mode:
- **@AffiliateID = 0:** INSERT a new affiliate record. All provided fields populate the new row.
- **@AffiliateID > 0:** UPDATE the existing affiliate. Each field is compared to the current value before updating.

### 2.2 Comprehensive Field Coverage
The ~57 parameters cover all major affiliate data domains:
- **Identity:** Name, email, username, company name
- **Contact:** Phone, mobile, fax, website
- **Address:** Street, city, state, zip, country
- **Tax:** Tax ID, VAT number, tax identification type
- **Account Settings:** AffiliateTypeID, GroupID, status, payment terms
- **Operational:** Commission overrides, tier settings, referral code

### 2.3 Field-Level Audit Logging
On UPDATE, the procedure compares each field's current value to the incoming value. For every field that has changed, a separate audit log entry is created recording:
- The field name
- The old value
- The new value
- The performing user (@UserEmail)
- The AffiliateID

### 2.4 Related Entity Management
Beyond the core `tblaff_Affiliates` record, the procedure also manages:
- **AffiliateAdmin.AffiliatesGroups:** Group assignment for the affiliate
- **Affiliate.BlockedCountries:** Country blocking configuration
- **Affiliate.tblaff_AffiliateURLs:** Associated affiliate URLs

### 2.5 Affiliate Type Resolution
The AffiliateTypeID is validated against `tblaff_AffiliateTypes` to ensure the assigned type exists. The type name is included in audit entries for readability.

### 2.6 Country Resolution
Country-related fields are resolved against `tblaff_Country` for validation and for human-readable audit log entries that include country names alongside country IDs.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

Key parameters are listed below. The procedure accepts ~57 parameters total covering all affiliate data fields.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | INT | No | 0 | CODE-BACKED | 0 for INSERT, >0 for UPDATE of existing affiliate |
| 2 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Admin user performing the change (for audit) |
| 3 | @ReasonOfChange | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | Reason for the change (audit context) |
| 4 | @AffiliateTypeID | INT | Yes | NULL | CODE-BACKED | Assigned affiliate type (commission plan) |
| 5 | @FirstName | NVARCHAR(100) | Yes | NULL | CODE-BACKED | Affiliate first name |
| 6 | @LastName | NVARCHAR(100) | Yes | NULL | CODE-BACKED | Affiliate last name |
| 7 | @Email | NVARCHAR(250) | Yes | NULL | CODE-BACKED | Affiliate contact email |
| 8 | @CompanyName | NVARCHAR(250) | Yes | NULL | CODE-BACKED | Affiliate company name |
| 9 | @Phone | NVARCHAR(50) | Yes | NULL | CODE-BACKED | Primary phone number |
| 10 | @CountryID | INT | Yes | NULL | CODE-BACKED | Affiliate country |
| 11 | @Address | NVARCHAR(500) | Yes | NULL | CODE-BACKED | Street address |
| 12 | @City | NVARCHAR(100) | Yes | NULL | CODE-BACKED | City |
| 13 | @State | NVARCHAR(100) | Yes | NULL | CODE-BACKED | State/province |
| 14 | @ZipCode | NVARCHAR(20) | Yes | NULL | CODE-BACKED | Postal/zip code |
| 15 | @TaxID | NVARCHAR(50) | Yes | NULL | CODE-BACKED | Tax identification number |
| 16 | @GroupID | INT | Yes | NULL | CODE-BACKED | Affiliate group assignment |
| 17 | @Status | INT | Yes | NULL | CODE-BACKED | Affiliate status code |
| 18 | @Website | NVARCHAR(500) | Yes | NULL | CODE-BACKED | Affiliate website URL |
| 19 | @PaymentTerms | INT | Yes | NULL | CODE-BACKED | Payment terms configuration |
| 20 | @OutputAffiliateID | INT | No | OUTPUT | CODE-BACKED | Returns the AffiliateID (new or existing) |
| - | *(~37 additional)* | Various | Yes | NULL | CODE-BACKED | Additional fields: mobile, fax, VAT, tier settings, referral code, commission overrides, etc. |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Affiliates` | Table | INSERT or UPDATE affiliate record |
| `dbo.tblaff_AffiliateTypes` | Table | Validate and resolve affiliate type |
| `AffiliateAdmin.AffiliatesGroups` | Table | Manage group assignment |
| `Affiliate.BlockedCountries` | Table | Manage country blocking |
| `Affiliate.tblaff_AffiliateURLs` | Table | Manage affiliate URLs |
| `dbo.tblaff_Country` | Table | Validate and resolve country |
| `dbo.AuditLog` | Table | INSERT field-level audit entries |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Affiliate create/edit screen | Application | Save new or modified affiliate data |
| Affiliate import process | Application | Bulk affiliate creation |
| API affiliate management | Application | REST endpoint for affiliate CRUD |

---

## 6. Dependencies

### 6.0 Chain
`UpdateInsertAffiliate` -> check @AffiliateID -> INSERT or (SELECT current + compare fields + UPDATE) -> `AuditLog` (INSERT per changed field) -> manage `AffiliatesGroups` + `BlockedCountries` + `AffiliateURLs`

### 6.1 Depends On
- `dbo.tblaff_Affiliates` - Core affiliate table (INSERT/UPDATE target)
- `dbo.tblaff_AffiliateTypes` - Affiliate type validation
- `AffiliateAdmin.AffiliatesGroups` - Group assignment management
- `Affiliate.BlockedCountries` - Country blocking management
- `Affiliate.tblaff_AffiliateURLs` - Affiliate URL management
- `dbo.tblaff_Country` - Country reference data
- `dbo.AuditLog` - Audit trail storage

### 6.2 Depend On This
No known database dependencies. Called from application layer affiliate management module.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Create a new affiliate
DECLARE @NewID INT;
EXEC AffiliateAdmin.UpdateInsertAffiliate
    @AffiliateID = 0,
    @UserEmail = N'admin@company.com',
    @ReasonOfChange = N'New affiliate onboarding',
    @AffiliateTypeID = 3,
    @FirstName = N'John',
    @LastName = N'Doe',
    @Email = N'john.doe@partner.com',
    @CompanyName = N'Doe Marketing LLC',
    @CountryID = 1,
    @OutputAffiliateID = @NewID OUTPUT;
SELECT @NewID AS CreatedAffiliateID;
```

```sql
-- 2. Update an existing affiliate's contact information
DECLARE @ExistingID INT = 1234;
EXEC AffiliateAdmin.UpdateInsertAffiliate
    @AffiliateID = @ExistingID,
    @UserEmail = N'manager@company.com',
    @ReasonOfChange = N'Updated contact details per affiliate request',
    @Phone = N'+1-555-0100',
    @Email = N'new.email@partner.com',
    @Address = N'456 New Street',
    @City = N'New York',
    @OutputAffiliateID = @ExistingID OUTPUT;
```

```sql
-- 3. Change affiliate type and group assignment
DECLARE @AffID INT = 5678;
EXEC AffiliateAdmin.UpdateInsertAffiliate
    @AffiliateID = @AffID,
    @UserEmail = N'admin@company.com',
    @ReasonOfChange = N'Promoted to premium tier',
    @AffiliateTypeID = 7,
    @GroupID = 2,
    @OutputAffiliateID = @AffID OUTPUT;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-5531.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UpdateInsertAffiliate | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertAffiliate.sql*

# dbo.UpdateInsertCountry

## 1. Overview

Upserts a country record in `tblaff_Country`: inserts a new country when `@CountryID = 0`, or updates an existing country otherwise. For updates, separate audit log entries are written for each changed field (Name, Abbreviation, AffiliatesGroupsID). When the affiliate group assignment changes, the human-readable group name is looked up from `tblaff_AffiliatesGroups` to populate `OldFieldDescription` and `NewFieldDescription` in the audit row. The ID of the inserted or updated country is returned via an OUTPUT parameter.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_Country |
| Secondary Tables | dbo.AuditLog, dbo.tblaff_AffiliatesGroups |
| Operation | INSERT or UPDATE, INSERT (audit) |
| Transaction | No |

## 3. Return / Result Set

No result set is returned. The ID of the inserted or updated country is returned via `@OutputCountryID OUTPUT`.

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @ChangedByUserID | IN | INT | required | UserID of the user performing the operation. |
| @CountryID | IN | INT | 0 | 0 to insert a new country; existing CountryID to update. |
| @ChangedSectionID | IN | int | NULL | Audit section ID; value 6 is used for country audit rows. |
| @ReasonOfChange | IN | nvarchar(1000) | NULL | Free-text reason written to audit log rows on update. |
| @ReferencedChangedID | IN | int | NULL | Referenced entity ID for audit rows. |
| @Name | IN | varchar(50) | required | Country name. |
| @Abbreviation | IN | char(2) | required | Two-character country abbreviation/code. |
| @AffiliatesGroupsID | IN | int | NULL | ID of the affiliate group assigned to this country. |
| @OutputCountryID | OUT | int | NULL | OUTPUT: ID of the inserted or updated country. |
| @ActionID | IN | int | NULL | Audit action ID; overridden to 2 for updates. |

## 5. Business Logic

**Insert path (`@CountryID = 0`):**
1. Computes the next `CountryID` as `MAX(CountryID) + 1` from `tblaff_Country` (manual sequence, no IDENTITY).
2. INSERTs the new row with the computed ID, `@Abbreviation`, `@Name`, and `@AffiliatesGroupsID`.
3. Retrieves and sets `@OutputCountryID` by selecting TOP 1 ordered by `CountryID DESC` where `Name` matches.
4. INSERTs an audit row with `ActionID = 1`, `ChangedSectionID = 6`, and reason `'Add new Country with ID: <ID>'`.

**Update path (`@CountryID != 0`):**
1. Forces `@ActionID = 2`.
2. Reads the current `Name`, `Abbreviation`, and `AffiliatesGroupsID` from `tblaff_Country`.
3. For each field that has changed, INSERTs an audit row with `ChangedSectionID = 6`:
   - `Name` change: field `'Country'`, logs old and new name strings.
   - `Abbreviation` change: field `'Abbreviation'`, logs old and new char(2) values.
   - `AffiliatesGroupsID` change: field `'Affiliate Group (Affiliate Manager)(ID)'`, logs old and new integer IDs plus the corresponding `AffiliatesGroupsName` values from `tblaff_AffiliatesGroups` in `OldFieldDescription` / `NewFieldDescription`.
4. UPDATEs `tblaff_Country` setting `Name`, `Abbreviation`, and `AffiliatesGroupsID` for the given `@CountryID`.

**Notes:**
- The manual MAX+1 ID generation is not safe under concurrent inserts; a race condition can produce duplicate IDs.
- The new-ID retrieval after INSERT uses TOP 1 / ORDER BY DESC on Name, which also carries concurrency risk.
- No explicit transaction wraps the insert/update and audit inserts.
- `SET NOCOUNT ON` suppresses row-count messages.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_Country | Table | dbo | Stores country definitions |
| dbo.AuditLog | Table | dbo | Field-level audit trail |
| dbo.tblaff_AffiliatesGroups | Table | dbo | Affiliate group name lookup for audit descriptions |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- Concurrent calls to insert new countries will race on `MAX(CountryID) + 1`; consider converting `CountryID` to an IDENTITY column or using a sequence object.
- The affiliate group name lookup adds two extra SELECT statements on the update path when `AffiliatesGroupsID` changes; this is negligible in practice.

## 8. Usage Examples

```sql
-- Insert a new country
DECLARE @newCountryID INT;
EXEC dbo.UpdateInsertCountry
    @ChangedByUserID  = 99,
    @CountryID        = 0,
    @Name             = 'Freedonia',
    @Abbreviation     = 'FD',
    @AffiliatesGroupsID = 3,
    @OutputCountryID  = @newCountryID OUTPUT;
SELECT @newCountryID AS NewCountryID;

-- Update an existing country's affiliate group
EXEC dbo.UpdateInsertCountry
    @ChangedByUserID     = 99,
    @CountryID           = 42,
    @ReasonOfChange      = N'Reassigned to EMEA group',
    @ReferencedChangedID = 42,
    @Name                = 'Freedonia',
    @Abbreviation        = 'FD',
    @AffiliatesGroupsID  = 5;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| Unknown | Unknown | N/A | Initial creation |

---
*Object: dbo.UpdateInsertCountry | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.UpdateInsertCountry.sql*

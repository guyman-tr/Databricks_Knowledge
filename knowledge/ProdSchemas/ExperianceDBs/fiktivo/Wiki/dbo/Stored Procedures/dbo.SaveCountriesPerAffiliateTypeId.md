# dbo.SaveCountriesPerAffiliateTypeId

## 1. Overview

Synchronizes the country list for a given affiliate type ID in `tblaff_CPACountriesToAffiliateTypeID`. Removes countries that are no longer in the supplied list and inserts countries that are new, performing a merge-style operation without a full delete-and-reinsert cycle. Writes a single audit log entry if any changes occurred, recording both the old and new country lists as XML-formatted strings.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_CPACountriesToAffiliateTypeID |
| Secondary Tables | dbo.AuditLog |
| Operation | DELETE, INSERT, INSERT (audit) |
| Transaction | No explicit transaction |

## 3. Return / Result Set

N/A for stored procedure.

No result set is returned.

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @CountriesTable | IN | CountryListTableType READONLY | required | Table-valued parameter containing the desired country IDs. |
| @AffiliateTypeID | IN | Integer | required | ID of the affiliate type whose country list is being updated. |
| @ChangedByUserID | IN | Integer | NULL | UserID of the user making the change; written to the audit log. |

## 5. Business Logic

1. Captures the current state: serializes existing country IDs for the affiliate type from `tblaff_CPACountriesToAffiliateTypeID` into `@CountriesTable_old` (XML via `FOR XML PATH('Countries')`), and the new desired list from `@CountriesTable` into `@CountriesTable_new`.
2. Sets `@IsNewList = 1` if no existing rows exist for this affiliate type (used for audit messaging).
3. **Delete removed countries:** DELETEs rows from `tblaff_CPACountriesToAffiliateTypeID` that belong to `@AffiliateTypeID` but whose `CountryID` is NOT in `@CountriesTable` (LEFT JOIN + IS NULL pattern). Accumulates the count into `@RowCount`.
4. **Insert new countries:** INSERTs into `tblaff_CPACountriesToAffiliateTypeID` any `CountryID` from `@CountriesTable` that does not already exist for the affiliate type. Adds to `@RowCount`.
5. **Audit:** If `@RowCount <> 0` (any change occurred), inserts one row into `AuditLog` with section ID 2, the old and new XML country lists, action ID 2, and an appropriate reason string ("Insert New List of Countries" or "Update Existing List of Countries").

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_CPACountriesToAffiliateTypeID | Table | dbo | Maps affiliate types to their allowed CPA countries |
| dbo.AuditLog | Table | dbo | Audit trail for country list changes |
| CountryListTableType | User-Defined Table Type | dbo | Table type for @CountriesTable parameter |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- The incremental approach (delete missing + insert new) is more efficient than a full delete-and-reinsert, especially when the list has few changes.
- No explicit transaction; if the DELETE succeeds but the INSERT fails, the country list will be in a partially updated state.
- The `FOR XML PATH('Countries')` serialization produces concatenated XML fragments, not a well-formed XML document; this is consistent with how the AuditLog typically stores field value snapshots in this system.

## 8. Usage Examples

```sql
DECLARE @countries CountryListTableType;
INSERT INTO @countries VALUES (12), (31), (169);

EXEC dbo.SaveCountriesPerAffiliateTypeId
    @CountriesTable   = @countries,
    @AffiliateTypeID  = 7,
    @ChangedByUserID  = 42;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| 2018-01-08 | Geri Reshef | 49927 | Created: AW - CPA Per Country editing for Tier 3 and Copy Plan - DB Changes |

---
*Object: dbo.SaveCountriesPerAffiliateTypeId | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.SaveCountriesPerAffiliateTypeId.sql*

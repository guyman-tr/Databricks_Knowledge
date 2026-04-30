# dbo.UpdateAffiliate_040326_NogaJunk

## 1. Overview

Updates the full profile of an existing affiliate in `tblaff_Affiliates` and synchronizes the affiliate's website URL list in `Affiliate.tblaff_AffiliateURLs`. Generates field-level audit log entries for every field that has actually changed. Covers personal details, login credentials, commission type assignment, group assignment, IB configuration, payment details, and display preferences.

> **Deprecated / Developer Backup:** The `040326_NogaJunk` suffix indicates this is a developer backup snapshot created on 2026-03-04. It should not be used in production code. Use the current production affiliate update procedure for active operations.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_Affiliates |
| Secondary Tables | Affiliate.tblaff_AffiliateURLs, dbo.AuditLog |
| Operation | UPDATE, DELETE, INSERT, INSERT (audit) |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

No result set is returned.

## 4. Parameters

The procedure accepts approximately 62 parameters. Key groupings:

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @AffiliateID | IN | INTEGER | required | ID of the affiliate to update. |
| @UserID | IN | INTEGER | required | ID of the user making the change; written to audit rows. |
| @IBAffiliate | IN | INTEGER | required | IB affiliate level flag. |
| @ManagerID_Demo | IN | INTEGER | required | Demo account manager ID. |
| @ManagerID_Real | IN | INTEGER | required | Real account manager ID. |
| @PaymentDetailsID | IN | INTEGER | required | Primary payment details reference. |
| @PaymentDetails2ID / @PaymentDetails3ID | IN | INTEGER | required | Secondary and tertiary payment details. |
| @PaymentDetailsDefault | IN | INTEGER | required | Which payment details record is the default. |
| @LoginName | IN | NVARCHAR(24) | NULL | Affiliate login name. |
| @LoginPassword | IN | NVARCHAR(24) | NULL | Affiliate login password. |
| @Phrase | IN | NVARCHAR(100) | NULL | Security phrase. |
| @Contact | IN | NVARCHAR(255) | NULL | Contact (first name). |
| @Email | IN | NVARCHAR(255) | NULL | Email address. |
| @TaxID | IN | NVARCHAR(50) | NULL | Tax identification number. |
| @SocialSecurity | IN | NVARCHAR(50) | NULL | Social security number. |
| @CompanyName | IN | NVARCHAR(255) | NULL | Company name. |
| @CompanyAddress | IN | NVARCHAR(255) | NULL | Company address. |
| @Country | IN | NVARCHAR(100) | NULL | Country. |
| @City | IN | NVARCHAR(100) | NULL | City. |
| @State | IN | NVARCHAR(50) | NULL | State/province. |
| @Zip | IN | NVARCHAR(25) | NULL | Postal code. |
| @Telephone | IN | NVARCHAR(50) | NULL | Telephone number. |
| @Fax | IN | NVARCHAR(50) | NULL | Fax number. |
| @WebSiteURL | IN | NVARCHAR(3000) | NULL | Pipe-delimited list of website URLs. |
| @WebSiteTitle | IN | NVARCHAR(255) | NULL | Website title. |
| @Comments | IN | NVARCHAR(max) | NULL | Internal comments. |
| @CountImpressions | IN | BIT | required | Whether to count impressions for this affiliate. |
| @CountClicks | IN | BIT | required | Whether to count clicks. |
| @AccountActivated | IN | BIT | required | Whether the account is active. |
| @SendEmailNotification | IN | BIT | required | Whether to send email notifications. |
| @AcceptedAgreement | IN | BIT | required | Whether the affiliate has accepted the agreement. |
| @AffiliateTypeID | IN | INT | NULL | Commission plan type. |
| @AffiliatesGroupsID | IN | INT | required | Affiliate group assignment. |
| @MarketingExpenseID | IN | BIGINT | required | Marketing channel (expense) ID. |
| @VATNumber | IN | NVARCHAR(100) | NULL | VAT number. |
| @AffiliateCustom1 ... @AffiliateCustom5 | IN | NVARCHAR(255) | NULL | Custom fields (1=Last name, 2-5=custom). |
| @IBCountries | IN | NVARCHAR(max) | NULL | IB affiliate allowed countries. |
| @Reports_Tiers_Summary / @Reports_Tiers_Details | IN | BIT | required | Tier report access flags. |
| @IBProviderID | IN | BIGINT | required | IB provider ID. |
| @IBLabelID | IN | BIGINT | required | IB label ID. |
| @HideExceptIBCRM | IN | BIT | required | Hide affiliate except in IB CRM. |
| @CanShowCashier | IN | BIT | required | Whether the affiliate can show the cashier. |
| @CommunicationLangID | IN | INT | required | Preferred communication language. |
| @PrefferedCurrencyID | IN | INT | NULL | Preferred payment currency. |
| @BirthDayDate | IN | DATETIME | NULL | Date of birth. |
| @ChangedSectionID | IN | INT | NULL | Audit log section ID. |
| @ReasonOfChange | IN | NVARCHAR(1000) | NULL | Reason for the change written to audit rows. |
| @ReferencedChangedID | IN | INTEGER | required | Referenced entity ID for audit rows. |

## 5. Business Logic

1. Reads current field values from `tblaff_Affiliates` for `@AffiliateID` into `_old` variables, including the current `WebSiteURL` assembled by aggregating `Affiliate.tblaff_AffiliateURLs` using `STRING_AGG` with pipe delimiter.
2. UPDATEs `tblaff_Affiliates` with all supplied values (WebSiteURL column intentionally skipped with a comment).
3. **URL synchronization:** DELETEs all rows in `Affiliate.tblaff_AffiliateURLs` for `@AffiliateID`, then re-inserts from `STRING_SPLIT(@WebSiteURL, '|')` with an ordinal assigned via `ROW_NUMBER()`. Empty strings and NULL `@WebSiteURL` are excluded.
4. For each of approximately 30 auditable fields, compares old vs. new and INSERTs an audit row into `AuditLog` if the value changed.
5. `SET NOCOUNT ON` suppresses row-count messages.
6. No explicit transaction wraps the multi-step operation.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_Affiliates | Table | dbo | Primary affiliate profile storage |
| Affiliate.tblaff_AffiliateURLs | Table | Affiliate | Stores one row per website URL per affiliate; replaced on each update |
| dbo.AuditLog | Table | dbo | Field-level change history |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- The URL table is fully replaced on every call (DELETE + INSERT); for affiliates with many URLs this is efficient enough, but it means any concurrent reads of the URL table may see a temporary empty state.
- A comment in the code notes that SQL Server 2022's `STRING_SPLIT` with ordinals would simplify the URL insertion; the current pattern uses `ROW_NUMBER() OVER (ORDER BY current_timestamp)` which assigns non-deterministic ordinals.
- The Jira reference `PART-2028` is embedded as a comment in the source related to using `Affiliate.AffiliateUrls` from a dedicated table.

## 8. Usage Examples

```sql
EXEC dbo.UpdateAffiliate_040326_NogaJunk
    @AffiliateID          = 1001,
    @UserID               = 99,
    @IBAffiliate          = 0,
    @ManagerID_Demo       = 5,
    @ManagerID_Real       = 5,
    @PaymentDetailsID     = 10,
    @PaymentDetails2ID    = 0,
    @PaymentDetails3ID    = 0,
    @PaymentDetailsDefault= 1,
    @Email                = N'partner@example.com',
    @AffiliateTypeID      = 3,
    @AffiliatesGroupsID   = 7,
    @MarketingExpenseID   = 100,
    @WebSiteURL           = N'https://example.com|https://example.com/blog',
    @CountImpressions     = 1,
    @CountClicks          = 1,
    @AccountActivated     = 1,
    @SendEmailNotification= 1,
    @AcceptedAgreement    = 1,
    @IBProviderID         = 0,
    @IBLabelID            = 0,
    @HideExceptIBCRM      = 0,
    @CanShowCashier       = 0,
    @CommunicationLangID  = 1,
    @Reports_Tiers_Summary= 0,
    @Reports_Tiers_Details= 0,
    @ReferencedChangedID  = 1001;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| 2023-09-11 | Noga | PART-2028 | Use AffiliateURLs from dedicated table Affiliate.AffiliateUrls |
| 2026-03-04 | Noga | N/A | Developer backup snapshot created (040326_NogaJunk). Do not use in production. |

---
*Object: dbo.UpdateAffiliate_040326_NogaJunk | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.UpdateAffiliate_040326_NogaJunk.sql*

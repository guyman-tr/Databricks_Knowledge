# DWH_dbo.Fact_BillingDeposit — Review Needed

> Items requiring human domain expert review. Generated alongside the wiki documentation.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|
| BinCodeAsString | First 6-8 digits (Tier 3) | Approved as-is. BIN = 6-8 digits confirmed. | table | guyman | 2026-03-15 |

## Tier 4 (UNVERIFIED) Columns

The following columns were documented based on column name inference only. Please verify:

| # | Column | Current Description | Question |
|---|--------|-------------------|----------|
| 12 | SecuredCardDataAsString | Encrypted/hashed card data from FundingData XML | What encryption is used? Is this PII? |
| 13 | BinCodeAsString | First 6-8 digits of card number (BIN code) from FundingData XML | Confirm BIN length: 6 or 8 digits? |
| 24 | RefundVerificationCode | Verification code for refund processing | What system generates this code? When is it populated? |
| 47 | CIDAsString | Customer ID as string from FundingData XML | Is this always the same as the CID column? Why stored separately? |
| 48 | v | ClientBankNameAsString (truncated alias bug) | Should this column be renamed to ClientBankNameAsString? |
| 63 | AdviseAsString | Payment advisory message from PaymentData XML | What values does this contain? Is it advice/notification text? |
| 87 | MD5AsString | MD5 hash from PaymentData XML | What is being hashed? Is this for dedup or verification? |
| 95 | PaymentGuaranteeAsString | Payment guarantee indicator from PaymentData XML | What values indicate guaranteed vs non-guaranteed? |
| 96 | PaymentModeAsInteger | Payment mode identifier from PaymentData XML | What do the mode values mean? |
| 109 | SecretKeyAsString | Secret key from PaymentData XML | Is this actually stored in cleartext? Security concern. |
| 110 | ThreeDsAsJson | 3D Secure response as JSON from PaymentData XML | What is the JSON structure? |
| 121 | PlatformID | Internal platform ID resolved from Fact_CustomerAction | What do values 99, 102, 105, 108, 111, 115, 117 map to? |

## Columns Needing Clarification

| Column | Issue | Evidence |
|--------|-------|---------|
| Approved | Almost entirely NULL (99.99%). Is this deprecated? | Only ~8,715 non-null out of 73.9M rows |
| BonusAmount | Almost entirely NULL (99.98%). Should analysts use a different table for bonus data? | Only ~11K non-null rows |
| BonusStatusID | 61.4% NULL, 38.3% = 0. What does 0 mean vs NULL? | Distribution: NULL=45.4M, 0=28.3M, 1=87K, 2=80K |
| ExchangeFee | Values range from 0 to 2,310,000 and even 13,000,000. Are extreme values basis points or a different unit? | Top values: 0=25.1M, 150=21.2M, 50=7M |
| PlatformID | Values don't map to Dim_Platform (0-3). What is the mapping? | Common values: 111, 105, 117, 108, 115, 102 |
| v | Truncated alias for ClientBankNameAsString. Is this a known issue? Will it be fixed? | ETL code: `[DWH_dbo].[ExtractXMLValue]('ClientBankNameAsString',f.FundingData) as v` |

## Structural Questions

1. **Column `v` rename**: The column `v` is actually `ClientBankNameAsString` with a truncated alias. Should a schema migration be planned to rename it?
2. **Approved column deprecation**: The `Approved` bit column is 99.99% NULL. Is it safe to consider it fully deprecated? Was it replaced by PaymentStatusID?
3. **PlatformID mapping**: The PlatformID values (99, 102, 105, 108, 111, 115, 117, etc.) in this table don't correspond to Dim_Platform values (0-3). Is there a separate dimension table or mapping for these billing platform IDs?
4. **ExchangeFee units**: ExchangeFee values include very large numbers (2,310,000 and 13,000,000). Are these always basis points? If so, 2,310,000 bps = 23,100% which seems unreasonable.
5. **Historical UpdateDate**: ~32M rows have UpdateDate = 2020-02-09 08:58:22.800. This appears to be the data lake migration date. Is there a way to recover the original update timestamps for pre-migration records?

## Tier 5 Re-Review Needed

> No Tier 5 overrides exist yet — this is the first generation.

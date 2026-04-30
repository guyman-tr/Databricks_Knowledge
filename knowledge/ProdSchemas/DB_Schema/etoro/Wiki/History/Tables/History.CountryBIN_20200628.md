# History.CountryBIN_20200628

> Point-in-time snapshot of the CountryBin table taken on 2020-06-28 - exists in the SSDT repository but is NOT present in the production database.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK, no index |
| **Partition** | No |
| **Temporal** | No - static snapshot |
| **Status** | SSDT-only - NOT in production database |

---

## 1. Business Meaning

History.CountryBIN_20200628 is a point-in-time snapshot of the CountryBin (card BIN lookup) table captured on 2020-06-28. The table name follows eToro's convention of embedding the capture date directly in the table name (YYYYMMDD format).

**This table does not exist in the production database** - attempts to query it return "Invalid object name 'History.CountryBIN_20200628'". It exists only in the SSDT repository as a schema definition, suggesting it was created as a backup during a data migration or significant BIN table update in June 2020, and was later dropped from production without removing the SSDT definition.

The table contains a subset of CountryBin columns (the 2020-era columns, before IsPrepaid, Trace, ValidFrom/ValidTo, ChallengeIndicator3DS, SupportsAFT, IsCFT were added).

---

## 2. Business Logic

This is a static data snapshot with no temporal versioning. It represented the state of BIN routing data as of 2020-06-28 and was used as a reference or fallback during a major BIN table update.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Production Status** | Does NOT exist - "Invalid object name" error |
| **SSDT Status** | Defined in repository |
| **Capture Date** | 2020-06-28 (from table name) |

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | int | NO | Country of the issuing bank. |
| 2 | BinCode | int | NO | 6-digit Bank Identification Number. |
| 3 | IssuingBank | varchar(100) | YES | Issuing bank name. |
| 4 | CardTypeID | int | YES | Card network ID. |
| 5 | CardSubType | varchar(50) | YES | Credit/Debit/Prepaid classification. |
| 6 | CardCategory | varchar(50) | YES | Card tier (Classic, Gold, etc.). |
| 7 | BankWebSite | varchar(50) | YES | Bank website URL. |
| 8 | BankInfo | varchar(255) | YES | Additional bank details. |
| 9 | ShouldCheck3ds | tinyint | YES | 3DS authentication requirement flag. |
| 10 | MinAmountFor3ds | int | YES | Minimum amount threshold for 3DS. |

---

*Generated: 2026-03-19 | Quality: 7.5/10 (limited - table not in production)*
*Object: History.CountryBIN_20200628 | Type: Table | Source: etoro/etoro/History/Tables/History.CountryBIN_20200628.sql*

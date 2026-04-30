# History.CountryBin

> Application-managed temporal history of card BIN (Bank Identification Number) routing data - 197,215 versioned snapshots for 23,742 6-digit BINs across 196 countries, tracking card type, 3DS, CFT, and AFT settings as they change over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - application temporal table (clustered on ValidTo ASC, ValidFrom ASC) |
| **Partition** | No |
| **Temporal** | Application-managed (ValidFrom/ValidTo, NOT SQL Server SYSTEM_VERSIONING) |
| **Indexes** | 1 (clustered on ValidTo ASC, ValidFrom ASC) |
| **Compression** | DATA_COMPRESSION=PAGE, on [DICTIONARY] filegroup |

---

## 1. Business Meaning

History.CountryBin stores the versioned history of the card BIN (Bank Identification Number) lookup table. A BIN is the first 6 digits of a payment card number, identifying the issuing bank, card type (VISA/Mastercard/AMEX), card subtype (credit/debit/prepaid), and the issuing country.

When any BIN record changes (new bank data, updated 3DS settings, changed CFT/AFT flags), the old row is written here before the current record is updated. ValidFrom and ValidTo mark each version's effective window.

197,215 rows covering 23,742 distinct 6-digit BINs across 196 countries. Last activity: December 2025. This is the **6-digit BIN** table (the legacy standard). The newer **8-digit BIN** table is History.CountryBin8.

BIN data is used during payment processing to: determine the card's country of origin, decide whether to require 3D Secure authentication, check if the card supports AFT (Account Funding Transaction) or is a CFT (Credit/Funds Transfer) card.

---

## 2. Business Logic

### 2.1 BIN Versioning

**What**: When a BIN record is updated in the base CountryBin table, the prior version is written here.

**Rules**:
- ValidFrom = when this BIN configuration became effective
- ValidTo = when superseded by the next version
- Each (CountryID, BinCode, ValidFrom) uniquely identifies a version (no PK constraint, but logically unique)

### 2.2 3D Secure (3DS) Settings

| Column | Purpose |
|--------|---------|
| ShouldCheck3ds | Whether 3DS authentication is required for this BIN (tinyint: 0=no, 1=yes) |
| MinAmountFor3ds | Minimum transaction amount that triggers 3DS check (in minor units) |
| ChallengeIndicator3DS | 3DS challenge indicator code (e.g., "01"=no preference, "04"=challenge requested) |

### 2.3 Card Properties

| Column | Purpose |
|--------|---------|
| IsPrepaid | Whether this is a prepaid card (cannot be used for certain funding types) |
| IsCFT | Credit/Funds Transfer capability flag (0=no, 1=yes) |
| SupportsAFT | Whether the card supports Account Funding Transactions |
| CardTypeID | Card network: 1=VISA, 2=Mastercard, etc. |
| CardSubType | "CREDIT", "DEBIT", "PREPAID" etc. |
| CardCategory | Card tier: "CLASSIC", "GOLD", "PLATINUM", etc. |

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 197,215 |
| **ValidFrom Range** | 2021-10-10 to 2025-12-24 |
| **Distinct Countries** | 196 |
| **Distinct 6-digit BINs** | 23,742 |
| **Status** | Inactive since December 2025 (succeeded by CountryBin8) |

Sample:

| CountryID | BinCode | IssuingBank | CardTypeID | CardSubType | IsPrepaid | ShouldCheck3ds | IsCFT | ValidFrom | ValidTo |
|----------|---------|------------|-----------|------------|----------|--------------|-------|-----------|---------|
| 123 | 520000 | PUBLIC BANK BERHAD | 2 | CREDIT | No | 1 | 0 | 2025-12-24 14:27:25 | 2025-12-24 14:27:36 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | VERIFIED | Country of the issuing bank. Implicit FK to Dictionary.Country. 196 distinct countries. |
| 2 | BinCode | int | NO | - | VERIFIED | 6-digit Bank Identification Number (first 6 digits of the card number). Identifies the issuing bank and card program. 23,742 distinct BINs. |
| 3 | IssuingBank | varchar(100) | YES | - | VERIFIED | Name of the bank that issued the card. E.g., "PUBLIC BANK BERHAD". |
| 4 | CardTypeID | int | YES | - | VERIFIED | Card network ID. Implicit FK to Dictionary.CardType. E.g., 1=Visa, 2=Mastercard. |
| 5 | CardSubType | varchar(50) | YES | - | VERIFIED | Card sub-category: "CREDIT", "DEBIT", "PREPAID". Used for fee routing. |
| 6 | CardCategory | varchar(50) | YES | - | CODE-BACKED | Card tier: "CLASSIC", "GOLD", "PLATINUM", "BUSINESS", etc. Used for premium card identification. |
| 7 | BankWebSite | varchar(50) | YES | - | CODE-BACKED | Bank's website URL. Informational only. |
| 8 | BankInfo | varchar(255) | YES | - | CODE-BACKED | Additional bank information. Free text. |
| 9 | ShouldCheck3ds | tinyint | YES | - | VERIFIED | 3DS authentication requirement: 0=not required, 1=required. Drives authentication flow during payment processing. |
| 10 | MinAmountFor3ds | int | YES | - | VERIFIED | Minimum transaction amount (in minor units) above which 3DS is triggered. NULL = always require 3DS if ShouldCheck3ds=1. |
| 11 | IsPrepaid | bit | NO | - | VERIFIED | Whether this is a prepaid card. Prepaid cards may be blocked for certain funding operations. |
| 12 | Trace | nvarchar(733) | NO | - | VERIFIED | JSON audit object capturing change context: HostName, AppName at time of modification. |
| 13 | ValidFrom | datetime2(7) | NO | - | VERIFIED | Application-managed start of this BIN configuration's validity window. |
| 14 | ValidTo | datetime2(7) | NO | - | VERIFIED | Application-managed end of this BIN configuration's validity window. Clustered index leading column. |
| 15 | ChallengeIndicator3DS | varchar(10) | YES | - | CODE-BACKED | 3DS challenge indicator code. E.g., "01"=no preference, "04"=challenge mandated. Used in 3DS 2.x protocol. |
| 16 | SupportsAFT | bit | YES | - | VERIFIED | Whether the card supports Account Funding Transactions (AFT) - card-to-account transfers. |
| 17 | IsCFT | int | NO | - | VERIFIED | Credit/Funds Transfer classification. 0=not a CFT card; 1=CFT card. Affects funding processing rules. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit | Country of the issuing bank. |
| CardTypeID | Dictionary.CardType | Implicit | Card network (Visa, Mastercard, etc.). |

---

## 6. Note on CountryBin8

History.CountryBin8 is the successor table for **8-digit BINs** (the industry standard since 2022). With 698,523 rows and active writes today (2026-03-19), CountryBin8 is the current active BIN lookup while CountryBin (6-digit) has been inactive since December 2025.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Compression |
|-----------|------|-------------|-------------|
| ix_CountryBin | CLUSTERED | ValidTo ASC, ValidFrom ASC | PAGE |

---

## 8. Sample Queries

```sql
-- Get the BIN configuration that was active at a specific time
SELECT CountryID, BinCode, IssuingBank, CardTypeID, CardSubType, IsPrepaid, ShouldCheck3ds
FROM History.CountryBin WITH (NOLOCK)
WHERE BinCode = 520000
  AND ValidFrom <= '2025-06-01'
  AND ValidTo > '2025-06-01';
```

---

*Generated: 2026-03-19 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.CountryBin | Type: Table | Source: etoro/etoro/History/Tables/History.CountryBin.sql*

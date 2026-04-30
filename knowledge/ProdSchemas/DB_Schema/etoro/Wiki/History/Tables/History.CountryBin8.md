# History.CountryBin8

> Application-managed temporal history of 8-digit card BIN routing data - 698,523 actively-versioned snapshots (updated today 2026-03-19) for cards across 83 countries, with extended AFT/CFT/gambling/money-transfer capability flags.

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

History.CountryBin8 stores the versioned history of the 8-digit card BIN (Bank Identification Number) lookup table. The "8" in the name refers to **8-digit BINs** - the extended BIN standard (ISO/IEC 7812) adopted industry-wide from 2022 onward, which expands the identifying prefix from 6 to 8 digits to accommodate the growing number of card programs.

This is the **active** BIN history table (698,523 rows, last updated today 2026-03-19), having superseded History.CountryBin (6-digit, inactive since December 2025).

Compared to CountryBin, CountryBin8 adds:
- **Transaction capability flags**: DomesticTransfer, CrossBorderTransfer, DomesticGambling, CrossBorderGambling, DomesticMoneyTransfer, CrossBorderMoneyTransfer
- **AFT direction flags**: AFTCrossBorder, AFTDomestic (Account Funding Transaction directional support)
- **ProductType**: Card product type field
- 8-digit BinCode (vs 6-digit in CountryBin)

These additional fields support more granular payment routing decisions, particularly for regulatory compliance (gambling restrictions, cross-border money transfer rules) and AFT network requirements.

---

## 2. Business Logic

### 2.1 BIN Versioning (8-digit)

**What**: When any 8-digit BIN record is updated, the prior version is written here.

**Rules**:
- ValidFrom = when this version became effective
- ValidTo = when superseded by the next version
- Very rapid update cycles observed (ValidFrom to ValidTo differences of 1 second in recent data), indicating automated batch BIN updates

### 2.2 Transaction Capability Flags

These flags drive payment acceptance decisions:

| Column | Meaning |
|--------|---------|
| DomesticTransfer | Card supports domestic fund transfers |
| CrossBorderTransfer | Card supports cross-border fund transfers |
| DomesticGambling | Card can be used for domestic gambling transactions |
| CrossBorderGambling | Card can be used for cross-border gambling |
| DomesticMoneyTransfer | Card supports domestic money transfers |
| CrossBorderMoneyTransfer | Card supports cross-border money transfers |
| SupportsAFT | Card supports Account Funding Transactions (AFT) |
| AFTCrossBorder | AFT is allowed for cross-border transactions |
| AFTDomestic | AFT is allowed for domestic transactions |

### 2.3 Relationship to CountryBin (6-digit)

| Table | BIN Length | Status | Rows | Last Activity |
|-------|-----------|--------|------|---------------|
| History.CountryBin | 6-digit | Inactive | 197,215 | Dec 2025 |
| History.CountryBin8 | 8-digit | **Active** | 698,523 | Today (2026-03-19) |

The migration from 6-digit to 8-digit BINs expanded coverage significantly (698K vs 197K rows).

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 698,523 |
| **ValidFrom Range** | 2023-12-13 to 2026-03-19 (active today) |
| **Distinct Countries** | 83 |
| **Status** | Actively versioned - production BIN data |

Sample (most recent):

| CountryID | BinCode | CardTypeID | IsPrepaid | SupportsAFT | ValidFrom | ValidTo |
|----------|---------|-----------|----------|------------|-----------|---------|
| 219 | 46585840 | 1 (Visa) | No | Yes | 2026-03-19 04:56:52 | 2026-03-19 04:57:15 |
| 218 | 46585840 | 1 (Visa) | No | Yes | 2026-03-19 04:56:51 | 2026-03-19 04:56:52 |

Note: Sub-second version windows observed = automated BIN feed processing with rapid successive updates.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | VERIFIED | Country of the issuing bank. Implicit FK to Dictionary.Country. 83 distinct countries. |
| 2 | BinCode | int | NO | - | VERIFIED | 8-digit Bank Identification Number. Identifies the card's issuing bank and program with higher granularity than 6-digit BINs. |
| 3 | IssuingBank | varchar(100) | YES | - | CODE-BACKED | Issuing bank name. |
| 4 | ProductType | varchar(100) | YES | - | CODE-BACKED | Card product type description (e.g., "STANDARD", "BUSINESS", "PREPAID"). Extends CardSubType/CardCategory from CountryBin. |
| 5 | CardTypeID | int | YES | - | VERIFIED | Card network. Implicit FK to Dictionary.CardType. 1=Visa. |
| 6 | CardSubType | varchar(50) | YES | - | VERIFIED | Credit/Debit/Prepaid subclassification. |
| 7 | Category | varchar(100) | YES | - | CODE-BACKED | Broader category (may differ from CardCategory in CountryBin). |
| 8 | CardCategory | varchar(50) | YES | - | CODE-BACKED | Card tier: Classic, Gold, Platinum, etc. |
| 9 | ShouldCheck3ds | tinyint | YES | - | VERIFIED | 3DS authentication requirement: 0=no, 1=yes. |
| 10 | DomesticTransfer | varchar(100) | YES | - | CODE-BACKED | Whether the card supports domestic fund transfers. "SUPPORTED", "NOT_SUPPORTED", etc. |
| 11 | CrossBorderTransfer | varchar(100) | YES | - | CODE-BACKED | Cross-border transfer support flag. |
| 12 | DomesticGambling | varchar(100) | YES | - | CODE-BACKED | Domestic gambling transaction support. Regulatory compliance flag. |
| 13 | CrossBorderGambling | varchar(100) | YES | - | CODE-BACKED | Cross-border gambling transaction support. Regulatory compliance flag. |
| 14 | DomesticMoneyTransfer | varchar(100) | YES | - | CODE-BACKED | Domestic money transfer support. |
| 15 | CrossBorderMoneyTransfer | varchar(100) | YES | - | CODE-BACKED | Cross-border money transfer support. |
| 16 | MinAmountFor3ds | int | YES | - | VERIFIED | Minimum amount threshold for 3DS challenge. |
| 17 | IsPrepaid | bit | YES | - | VERIFIED | Whether this is a prepaid card. |
| 18 | Trace | nvarchar(733) | NO | - | VERIFIED | JSON audit object: HostName, AppName at time of modification. |
| 19 | ValidFrom | datetime2(7) | NO | - | VERIFIED | Start of this BIN version's validity window. Application-managed. |
| 20 | ValidTo | datetime2(7) | NO | - | VERIFIED | End of this BIN version's validity window. Clustered index leading column. |
| 21 | ChallengeIndicator3DS | varchar(2) | YES | - | CODE-BACKED | 3DS 2.x challenge indicator (2-char code, narrower than CountryBin's varchar(10)). |
| 22 | SupportsAFT | bit | YES | - | VERIFIED | Whether the card supports Account Funding Transactions (AFT). Observed: true in recent rows. |
| 23 | IsCFT | int | YES | - | CODE-BACKED | Credit/Funds Transfer flag. NULL in most recent rows. |
| 24 | AFTCrossBorder | bit | YES | - | VERIFIED | AFT support for cross-border transactions. NULL in recent observed rows. |
| 25 | AFTDomestic | bit | YES | - | VERIFIED | AFT support for domestic transactions. NULL in recent observed rows. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit | Country of the issuing bank. |
| CardTypeID | Dictionary.CardType | Implicit | Card network (Visa, Mastercard, etc.). |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Compression |
|-----------|------|-------------|-------------|
| ix_CountryBin8 | CLUSTERED | ValidTo ASC, ValidFrom ASC | PAGE |

---

## 8. Sample Queries

### 8.1 Get current BIN configuration
```sql
-- Use the base table for current state
SELECT CountryID, BinCode, CardTypeID, IsPrepaid, SupportsAFT, ValidFrom
FROM Trade.CountryBin8 WITH (NOLOCK)  -- or Dictionary.CountryBin8
WHERE BinCode = 46585840;
```

### 8.2 History for a specific 8-digit BIN
```sql
SELECT CountryID, BinCode, CardTypeID, IsPrepaid, SupportsAFT, ValidFrom, ValidTo
FROM History.CountryBin8 WITH (NOLOCK)
WHERE BinCode = 46585840
ORDER BY ValidFrom;
```

---

*Generated: 2026-03-19 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.CountryBin8 | Type: Table | Source: etoro/etoro/History/Tables/History.CountryBin8.sql*

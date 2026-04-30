# Dictionary.CountryBin8

> Extended BIN lookup table for 8-digit Bank Identification Numbers (BinCode ≥ 10M). Provides country, card type, and compliance eligibility flags for payment card routing, fraud checks, and transfer/gambling restrictions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table (Temporal) |
| **Key Identifier** | BinCode, CountryID (composite PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **History Table** | History.CountryBin8 |
| **Indexes** | 1 active (PK) |
| **Row Count** | 16,025,634 |

---

## 1. Business Meaning

Dictionary.CountryBin8 stores the extended lookup for 8-digit Bank Identification Numbers (BINs). The payment card industry migrated from 6-digit to 8-digit BINs to accommodate the growth in card issuers; this table serves the newer format. Each row links a BIN (BinCode) to a country (CountryID), issuing bank, card type, and a rich set of MCC-like attributes indicating what the card is eligible for: domestic/cross-border transfers, gambling, and money transfers.

The table has richer data than Dictionary.CountryBin6. Beyond basic BIN-to-country mapping, it includes ProductType, Category, and transfer/gambling eligibility flags (DomesticTransfer, CrossBorderTransfer, DomesticGambling, CrossBorderGambling, DomesticMoneyTransfer, CrossBorderMoneyTransfer). These flags are critical for compliance: they determine whether a card can be used for certain transaction types in specific jurisdictions. BackOffice and payment processing use them to enforce restrictions.

The CHECK constraint CHK_CountryBin8 ensures only 8-digit BINs (BinCode ≥ 10,000,000) are stored. CountryBin6 enforces the opposite (BinCode &lt; 10,000,000). Dictionary.CountryBin is a UNION view over both tables, providing a single interface for BIN lookups regardless of length. System versioning preserves historical BIN-to-country changes in History.CountryBin8.

---

## 2. Business Logic

### 2.1 BIN-to-Compliance Mapping

**What**: 8-digit BINs are resolved to country, card type, and eligibility flags for payment routing and compliance decisions.

**Columns/Parameters Involved**: `BinCode`, `CountryID`, `CardTypeID`, `DomesticTransfer`, `CrossBorderTransfer`, `DomesticGambling`, `CrossBorderGambling`, `ShouldCheck3ds`, `MinAmountFor3ds`, `IsPrepaid`, `SupportsAFT`, `IsCFT`, `AFTCrossBorder`, `AFTDomestic`

**Rules**:
- **BinCode ≥ 10,000,000**: Only 8-digit BINs (enforced by CHK_CountryBin8).
- **CountryID → Dictionary.Country**: BIN's issuing country (NOCHECK FK).
- **CardTypeID → Dictionary.CardType**: Card network (Visa, MasterCard, etc.).
- **Transfer/Gambling flags**: DomesticTransfer, CrossBorderTransfer, DomesticGambling, CrossBorderGambling, DomesticMoneyTransfer, CrossBorderMoneyTransfer — indicate eligibility per transaction type.
- **ShouldCheck3ds** (DEFAULT 0): Whether 3D Secure must be checked for this BIN.
- **MinAmountFor3ds**: Threshold amount above which 3DS is required (NULL if N/A).
- **IsPrepaid** (DEFAULT 0): Prepaid card indicator.
- **SupportsAFT/IsCFT/AFTCrossBorder/AFTDomestic**: Account Funding Transaction and Card Funding Transaction eligibility.
- **ChallengeIndicator3DS** (varchar 2): 3DS challenge preference.

**Diagram**:
```
Card Deposit / Payment Flow:
  Extract BIN from card number
        │
        ├── BIN length 6 → Dictionary.CountryBin6
        │
        └── BIN length 8 → Dictionary.CountryBin8
                │
                ├── Resolve CountryID, CardTypeID, IssuingBank
                ├── Check ShouldCheck3ds, MinAmountFor3ds
                ├── Check DomesticTransfer, CrossBorderTransfer (routing)
                ├── Check DomesticGambling, CrossBorderGambling (compliance)
                └── Check IsPrepaid, SupportsAFT, IsCFT (funding eligibility)
```

---

## 3. Data Overview

| BinCode | CountryID | IssuingBank | ProductType | CardTypeID | ShouldCheck3ds | DomesticTransfer | CrossBorderTransfer | IsPrepaid |
|---------|-----------|-------------|-------------|------------|----------------|------------------|---------------------|-----------|
| 10000001 | 1 | Sample Bank | Credit | 1 | 0 | Y | Y | 0 |
| 55221100 | 1 | Example Bank | Debit | 2 | 1 | Y | N | 0 |
| 40000001 | 2 | Acme Bank | Prepaid | 1 | 1 | Y | Y | 1 |

*Representative sample. Actual data varies. Query via Dictionary.CountryBin view for unified 6/8-digit lookup.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Issuing country of the BIN. FK → Dictionary.Country (NOCHECK). Used for jurisdiction, compliance, and fraud checks. |
| 2 | BinCode | int | NO | - | CODE-BACKED | 8-digit Bank Identification Number (first 8 digits of card). Part of composite PK. Must be ≥ 10,000,000 per CHK_CountryBin8. |
| 3 | IssuingBank | varchar(100) | YES | - | CODE-BACKED | Name of the bank or issuer. Used for display and reporting. |
| 4 | ProductType | varchar(100) | YES | - | CODE-BACKED | Card product type (e.g., Credit, Debit, Prepaid). CountryBin8-only; NULL in CountryBin6. |
| 5 | CardTypeID | int | YES | - | CODE-BACKED | Card network. FK → Dictionary.CardType (Visa=1, MasterCard=2, etc.). |
| 6 | CardSubType | varchar(50) | YES | - | CODE-BACKED | Sub-classification of card type. |
| 7 | Category | varchar(100) | YES | - | CODE-BACKED | Card category (e.g., consumer, commercial). |
| 8 | CardCategory | varchar(50) | YES | - | CODE-BACKED | Additional card category classification. |
| 9 | ShouldCheck3ds | tinyint | YES | 0 | CODE-BACKED | Whether 3D Secure must be validated: 0=no, 1=yes. DEFAULT 0. |
| 10 | DomesticTransfer | varchar(100) | YES | - | CODE-BACKED | Eligibility for domestic transfers (Y/N or code). Compliance flag. |
| 11 | CrossBorderTransfer | varchar(100) | YES | - | CODE-BACKED | Eligibility for cross-border transfers. Compliance flag. |
| 12 | DomesticGambling | varchar(100) | YES | - | CODE-BACKED | Eligibility for domestic gambling transactions. Compliance flag. |
| 13 | CrossBorderGambling | varchar(100) | YES | - | CODE-BACKED | Eligibility for cross-border gambling transactions. Compliance flag. |
| 14 | DomesticMoneyTransfer | varchar(100) | YES | - | CODE-BACKED | Eligibility for domestic money transfers. Compliance flag. |
| 15 | CrossBorderMoneyTransfer | varchar(100) | YES | - | CODE-BACKED | Eligibility for cross-border money transfers. Compliance flag. |
| 16 | MinAmountFor3ds | int | YES | - | CODE-BACKED | Minimum transaction amount (in minor units) above which 3DS is required. NULL if N/A. |
| 17 | IsPrepaid | bit | YES | 0 | CODE-BACKED | Prepaid card indicator: 0=no, 1=yes. DEFAULT 0. Affects funding and AML logic. |
| 18 | Trace | nvarchar(max) | NO | computed | CODE-BACKED | Computed: JSON with HostName, AppName, SUserName, SPID, DBName, ObjectName for auditing last modifier. |
| 19 | ValidFrom | datetime2(7) | NO | generated | CODE-BACKED | System-versioning row start. GENERATED ALWAYS AS ROW START. |
| 20 | ValidTo | datetime2(7) | NO | generated | CODE-BACKED | System-versioning row end. GENERATED ALWAYS AS ROW END. |
| 21 | ChallengeIndicator3DS | varchar(2) | YES | - | CODE-BACKED | 3DS challenge indicator preference (e.g., 01, 02). |
| 22 | SupportsAFT | bit | YES | - | CODE-BACKED | Account Funding Transaction support: 1=yes, 0=no. |
| 23 | IsCFT | int | YES | - | CODE-BACKED | Card Funding Transaction indicator. |
| 24 | AFTCrossBorder | bit | YES | - | CODE-BACKED | AFT cross-border eligibility. |
| 25 | AFTDomestic | bit | YES | - | CODE-BACKED | AFT domestic eligibility. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|---------------|----------------|-------------------|-------------|
| Dictionary.Country | CountryID | FK (NOCHECK) | Issuing country of the BIN |
| Dictionary.CardType | CardTypeID | FK | Card network brand |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.CountryBin | - | View | UNION view with CountryBin6; queries both for unified BIN lookup |
| Billing.CountryBinsGet | BinCode | Procedure | BIN lookup by code |
| Billing.fn_GetCCDepotCountryId | BinCode | Function | Resolve BIN to country for CC depot |
| Billing.IsPrepaidBin | BinCode | Procedure | Check IsPrepaid by BIN |
| Billing.Daily3dReportHTML / Daily3dReport | BinCode | Procedure | 3DS reporting |
| BackOffice.InProcessPaymentsToSendPCIVersion | BinCode | Procedure | PCI payment processing |
| Monitor.GetRecurringDepositsDashboard | BinCode | Procedure | Recurring deposit dashboard |
| Various Billing/BackOffice procs | via Dictionary.CountryBin | Implicit | BIN lookup via unified view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.Country ←── Dictionary.CountryBin8
Dictionary.CardType ←── Dictionary.CountryBin8
Dictionary.CountryBin8 ──► Dictionary.CountryBin (view)
Dictionary.CountryBin8 ──► History.CountryBin8 (temporal)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FK CountryID (NOCHECK) |
| Dictionary.CardType | Table | FK CardTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CountryBin | View | UNION with CountryBin6 |
| History.CountryBin8 | Table | Temporal history |
| Billing.CountryBinsGet | Procedure | BIN lookup |
| Billing.UpdateCountryBin | Procedure | Updates this table when BinCode≥10M |
| 15+ Billing/BackOffice procedures | Procedure | Via CountryBin view or direct |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CountryBin8 | CLUSTERED PK | BinCode ASC, CountryID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CountryBin8 | PRIMARY KEY | Composite (BinCode, CountryID). FILLFACTOR 100, DICTIONARY filegroup. |
| CHK_CountryBin8 | CHECK | BinCode >= 10000000 (8-digit BINs only) |
| FK_CountryBin8_CardType | FOREIGN KEY | CardTypeID → Dictionary.CardType |
| FK_CountryBin8_DCNB_TPL | FOREIGN KEY (NOCHECK) | CountryID → Dictionary.Country |
| DF_DictionaryCountryBin8_TPL_ShouldCheck3ds | DEFAULT | ShouldCheck3ds = 0 |
| DF_CountryBi_IsPrepaid | DEFAULT | IsPrepaid = 0 |

**Special**: System-versioned temporal table. PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo). SYSTEM_VERSIONING = ON (HISTORY_TABLE = History.CountryBin8).

---

## 8. Sample Queries

### 8.1 Lookup BIN by 8-digit code (current rows only)
```sql
SELECT  cb.BinCode,
        cb.CountryID,
        c.Name AS CountryName,
        cb.IssuingBank,
        cb.ProductType,
        cb.CardTypeID,
        cb.ShouldCheck3ds,
        cb.IsPrepaid
FROM    Dictionary.CountryBin8 cb WITH (NOLOCK)
JOIN    Dictionary.Country c WITH (NOLOCK) ON cb.CountryID = c.CountryID
WHERE   cb.BinCode = 55221100;
```

### 8.2 List BINs requiring 3D Secure with threshold
```sql
SELECT  BinCode,
        CountryID,
        IssuingBank,
        ProductType,
        MinAmountFor3ds
FROM    Dictionary.CountryBin8 WITH (NOLOCK)
WHERE   ShouldCheck3ds = 1
    AND MinAmountFor3ds IS NOT NULL
ORDER BY BinCode;
```

### 8.3 Count BINs by country (8-digit only)
```sql
SELECT  cb.CountryID,
        c.Name AS CountryName,
        COUNT(*) AS BinCount
FROM    Dictionary.CountryBin8 cb WITH (NOLOCK)
JOIN    Dictionary.Country c WITH (NOLOCK) ON cb.CountryID = c.CountryID
GROUP BY cb.CountryID, c.Name
ORDER BY BinCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.CountryBin8.

---

*Generated: 2026-03-13 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15+ analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Dictionary.CountryBin8 | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CountryBin8.sql*

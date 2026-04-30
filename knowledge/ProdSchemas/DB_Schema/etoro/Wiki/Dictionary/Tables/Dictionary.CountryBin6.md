# Dictionary.CountryBin6

> BIN (Bank Identification Number) lookup table for 6-digit card BINs. Maps BINs to countries, issuing banks, card types, and payment processing attributes (3DS, prepaid, AFT, CFT). Temporal table with full history audit via History.CountryBin.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table (Temporal — system versioning) |
| **Key Identifier** | CountryID, BinCode (composite, CLUSTERED PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active |
| **History Table** | History.CountryBin |
| **Row Count** | ~324,821 |
| **Note** | BinCode < 10,000,000 (6 digits); CHK_CountryBin6 enforced |

---

## 1. Business Meaning

Dictionary.CountryBin6 is the primary lookup table for 6-digit Bank Identification Numbers (BINs). Each row maps a BIN to the card-issuing country, bank, card type, and processing attributes. During credit card deposit processing, the system uses the first 6 digits of the card number to query this table and determine the card's origin, whether 3D Secure verification is required, whether it is prepaid, and whether it supports AFT (Account Funding Transaction) or CFT (Card Funding Transaction).

The table is temporal: SYSTEM_VERSIONING is enabled with History.CountryBin, so every change to BIN data is audited. This supports compliance, dispute resolution, and historical analysis of BIN attribute changes. The Trace computed column captures who modified each row (host, app, user, SPID, db, object). Paired with Dictionary.CountryBin8 for 8-digit BINs; both are typically UNIONed in the Dictionary.CountryBin view for a unified BIN lookup.

The CHECK constraint (BinCode < 10000000) ensures only 6-digit BINs are stored here. BINs of 8 digits or more belong in Dictionary.CountryBin8. The IX_DCNB_Bincode nonclustered index on BinCode (INCLUDE CardCategory) supports fast BIN lookups during deposit authorization.

---

## 2. Business Logic

### 2.1 BIN Lookup During Deposit

**What**: When a customer attempts a card deposit, the first 6 digits (BIN) are used to look up country, bank, card type, and 3DS/prepaid/AFT/CFT flags.

**Columns/Parameters Involved**: `BinCode`, `CountryID`, `CardTypeID`, `ShouldCheck3ds`, `MinAmountFor3ds`, `IsPrepaid`, `ChallengeIndicator3DS`, `SupportsAFT`, `IsCFT`

**Rules**:
- **BinCode**: 6-digit BIN; must be < 10,000,000 (CHECK constraint).
- **CountryID**: FK to Dictionary.Country; card-issuing country.
- **CardTypeID**: FK to Dictionary.CardType; Visa, Mastercard, etc.
- **ShouldCheck3ds = 1**: 3D Secure verification required for this BIN.
- **MinAmountFor3ds**: Minimum amount (if set) that triggers 3DS check.
- **IsPrepaid = 1**: Card is prepaid; may affect processing rules.
- **SupportsAFT**: Whether BIN supports Account Funding Transaction.
- **IsCFT**: Card Funding Transaction flag; NOT NULL, DEFAULT 0.

**Diagram**:
```
Card Deposit Flow:

  Card number (first 6 digits) ──► BinCode lookup
                                       │
                                       ▼
  Dictionary.CountryBin6 ──► CountryID, IssuingBank, CardTypeID
                          ──► ShouldCheck3ds, MinAmountFor3ds
                          ──► IsPrepaid, SupportsAFT, IsCFT
                                       │
                                       ▼
  Deposit auth / 3DS / routing logic
```

### 2.2 Temporal Versioning

**What**: ValidFrom and ValidTo (GENERATED ALWAYS AS ROW START/END) provide full history in History.CountryBin.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`

**Rules**:
- **ValidFrom**: When row became current.
- **ValidTo**: When row was superseded (9999-12-31 23:59:59.9999999 for current rows).
- History.CountryBin stores all historical versions for audit and time-travel queries.

---

## 3. Data Overview

| CountryID | BinCode | IssuingBank | CardTypeID | ShouldCheck3ds | IsPrepaid | Meaning |
|---|---|---|---|---|---|---|
| 840 | 411234 | Sample Bank USA | 1 | 1 | 0 | Example US Visa BIN; 3DS required. |
| 826 | 512345 | Sample Bank UK | 2 | 0 | 0 | Example UK Mastercard BIN; no 3DS. |
| 376 | 123456 | Example Bank IL | 1 | 1 | 1 | Example Israel prepaid card; 3DS required. |
| 702 | 601234 | Singapore Bank | 3 | 0 | 0 | Example Singapore card; different card type. |
| 784 | 789012 | UAE Bank | 2 | 1 | 0 | Example UAE Mastercard; 3DS required. |

*Note: Values above are representative patterns; actual BIN data is sensitive and varies. Row count ~324,821.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | FK to Dictionary.Country. Card-issuing country. Part of composite PK. |
| 2 | BinCode | int | NO | - | CODE-BACKED | 6-digit BIN (must be < 10,000,000 per CHK_CountryBin6). Part of composite PK. Indexed by IX_DCNB_Bincode. |
| 3 | IssuingBank | varchar(100) | YES | - | CODE-BACKED | Bank name associated with BIN. |
| 4 | CardTypeID | int | YES | - | CODE-BACKED | FK to Dictionary.CardType (Visa, Mastercard, etc.). |
| 5 | CardSubType | varchar(50) | YES | - | CODE-BACKED | Card subcategory. |
| 6 | CardCategory | varchar(50) | YES | - | CODE-BACKED | Card category. Included in IX_DCNB_Bincode. |
| 7 | BankWebSite | varchar(50) | YES | - | CODE-BACKED | Bank website URL. |
| 8 | BankInfo | varchar(255) | YES | - | CODE-BACKED | Additional bank information. |
| 9 | ShouldCheck3ds | tinyint | YES | 0 | CODE-BACKED | Whether 3D Secure check is required. 0=no, 1=yes. |
| 10 | MinAmountFor3ds | int | YES | - | CODE-BACKED | Minimum amount that triggers 3DS check. NULL = no minimum. |
| 11 | IsPrepaid | bit | NO | 0 | CODE-BACKED | Whether card is prepaid. 0=no, 1=yes. |
| 12 | Trace | (computed) | NO | - | CODE-BACKED | Computed: concat(host_name(), app_name(), suser_sname(), SPID, db_name(), object_name()). Audit trace for modifications. |
| 13 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | GENERATED ALWAYS AS ROW START. Temporal row start. |
| 14 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | GENERATED ALWAYS AS ROW END. Temporal row end. |
| 15 | ChallengeIndicator3DS | varchar(10) | YES | - | CODE-BACKED | 3DS challenge indicator value. |
| 16 | SupportsAFT | bit | YES | - | CODE-BACKED | Whether BIN supports Account Funding Transaction. |
| 17 | IsCFT | int | NO | 0 | CODE-BACKED | Card Funding Transaction flag. 0=no, 1=yes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Dictionary.Country | CountryID | FK | Card-issuing country |
| Dictionary.CardType | CardTypeID | FK | Card type (Visa, Mastercard, etc.) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.CountryBin | CountryID, BinCode, … | History Table | Temporal history; same structure |
| Dictionary.CountryBin | View | UNION | Typically UNIONs CountryBin6 and CountryBin8 |
| Deposit/card processing procs | BinCode | Lookup | BIN lookup during card deposit |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CountryBin6 (table)
    ├── Dictionary.Country (CountryID)
    └── Dictionary.CardType (CardTypeID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FK — CountryID references CountryID |
| Dictionary.CardType | Table | FK — CardTypeID references CardTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.CountryBin | Table | System-versioned history table |
| Dictionary.CountryBin | View | UNION of CountryBin6 and CountryBin8 |
| Card deposit / 3DS / BIN lookup logic | Procs/Views | BIN resolution during payments |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCNB_TPL | CLUSTERED PK | CountryID ASC, BinCode ASC | - | - | Active |
| IX_DCNB_Bincode | NONCLUSTERED | BinCode ASC | CardCategory | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DCNB_TPL | PRIMARY KEY | Composite (CountryID, BinCode). CLUSTERED. |
| CHK_CountryBin6 | CHECK | BinCode < 10000000 (6-digit BINs only) |
| FK CountryID | FOREIGN KEY | References Dictionary.Country |
| FK CardTypeID | FOREIGN KEY | References Dictionary.CardType |
| PERIOD FOR SYSTEM_TIME | Temporal | ValidFrom, ValidTo for SYSTEM_VERSIONING |

---

## 8. Sample Queries

### 8.1 Lookup BIN by 6-digit code
```sql
SELECT  cb.CountryID,
        c.Name                      AS CountryName,
        cb.BinCode,
        cb.IssuingBank,
        ct.Name                     AS CardTypeName,
        cb.ShouldCheck3ds,
        cb.MinAmountFor3ds,
        cb.IsPrepaid,
        cb.SupportsAFT,
        cb.IsCFT
FROM    Dictionary.CountryBin6 cb WITH (NOLOCK)
LEFT JOIN Dictionary.Country c WITH (NOLOCK)
        ON cb.CountryID = c.CountryID
LEFT JOIN Dictionary.CardType ct WITH (NOLOCK)
        ON cb.CardTypeID = ct.CardTypeID
WHERE   cb.BinCode = 411234;
```

### 8.2 Find BINs requiring 3DS for a country
```sql
SELECT  BinCode,
        IssuingBank,
        CardCategory,
        MinAmountFor3ds,
        ChallengeIndicator3DS
FROM    Dictionary.CountryBin6 WITH (NOLOCK)
WHERE   CountryID = 840
  AND   ShouldCheck3ds = 1
ORDER BY BinCode;
```

### 8.3 Temporal query — BIN history for a specific BIN
```sql
SELECT  cb.BinCode,
        cb.CountryID,
        cb.IssuingBank,
        cb.ShouldCheck3ds,
        cb.ValidFrom,
        cb.ValidTo
FROM    Dictionary.CountryBin6 FOR SYSTEM_TIME ALL AS cb WITH (NOLOCK)
WHERE   cb.BinCode = 411234
ORDER BY cb.ValidFrom;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: DDL + MCP live data + CountryBin view, Country/CardType FK, temporal schema, CHK_CountryBin6 | Corrections: 0 applied*
*Object: Dictionary.CountryBin6 | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CountryBin6.sql*

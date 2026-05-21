# DWH_dbo.Dim_CountryBin

> Large BIN (Bank Identification Number) lookup table (16.3M rows) mapping 6-digit and 8-digit card BINs to card-issuing country, bank, type, and payment processing attributes (3DS, prepaid).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.CountryBin6 + etoro.Dictionary.CountryBin8 (unified via DWH_staging.etoro_Dictionary_CountryBin) |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full TRUNCATE+INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (BinCode ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_CountryBin` is a 16.3-million-row BIN (Bank Identification Number) lookup table. During credit card deposit processing, the first 6 or 8 digits of the customer's card number are matched against this table to determine the card-issuing country, bank, card type, and processing rules (whether 3D Secure verification is required, whether the card is prepaid, etc.).

The table combines two production sources: `etoro.Dictionary.CountryBin6` (6-digit BINs, ~324K rows upstream) and `etoro.Dictionary.CountryBin8` (8-digit BINs), both pre-merged in the `DWH_staging.etoro_Dictionary_CountryBin` staging table before loading to DWH.

The ETL is a full TRUNCATE+INSERT daily reload from staging. Several processing-level columns from the upstream source are dropped: `ChallengeIndicator3DS`, `SupportsAFT`, `IsCFT`, `DomesticMoneyTransfer`, `CrossBorderMoneyTransfer`.

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryBin6.md` (6-digit BIN details; 8-digit covered by CountryBin8.md).

---

## 2. Business Logic

### 2.1 BIN Lookup During Deposit Authorization

**What**: First 6 or 8 digits of a card number identify the issuing bank, country, and payment processing rules.

**Columns Involved**: `BinCode`, `CountryID`, `CardTypeID`, `ShouldCheck3ds`, `MinAmountFor3ds`, `IsPrepaid`

**Rules**:
- BinCode < 10,000,000 -> 6-digit BIN (from Dictionary.CountryBin6)
- BinCode >= 10,000,000 -> 8-digit BIN (from Dictionary.CountryBin8)
- ShouldCheck3ds=1: 3D Secure verification required for this BIN (29% of rows = 4.8M BINs require 3DS)
- ShouldCheck3ds=0: no 3DS required (71% of rows = 11.6M BINs)
- MinAmountFor3ds: Minimum deposit amount that triggers 3DS check (0 means all amounts)
- IsPrepaid=1: Card is prepaid; may trigger additional fraud checks or processing restrictions
- CountryID: card-issuing country (links to Dim_Country)

**Diagram**:
```
Card deposit: first 6/8 digits of card number -> BinCode lookup
  -> CountryID (issuing country)
  -> CardTypeID (Visa, Mastercard, etc.)
  -> ShouldCheck3ds (0/1)
  -> IsPrepaid (True/False)
  -> IssuingBank (human-readable bank name)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE. For a 16.3M-row table this is an unusually large replicated table - normally REPLICATE is reserved for small (<10M row) dimensions. At this scale, Synapse may choose not to replicate across all nodes. The CLUSTERED INDEX on BinCode is appropriate for point-lookup BIN matching.

**Warning**: Querying this table with full scans (no BinCode filter) is expensive. Always filter by BinCode.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, store as Delta (MANAGED). Z-ORDER BY BinCode for fast BIN lookups. At 16M rows, no partitioning needed but Z-ORDER is recommended.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Lookup BIN attributes for a card | `SELECT * FROM Dim_CountryBin WHERE BinCode = @bin` |
| Find all BINs requiring 3DS | `WHERE ShouldCheck3ds = 1` |
| Prepaid card analysis | `WHERE IsPrepaid = 1` |
| Country-level BIN distribution | `JOIN Dim_Country ON BinCode.CountryID = Dim_Country.CountryID GROUP BY Name` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | ON b.CountryID = c.CountryID | Decode card-issuing country from BIN |
| DWH_dbo.Dim_CardType | ON b.CardTypeID = c.CardTypeID | Decode card type (Visa/MC/etc.) from BIN |

### 3.4 Gotchas

- At 16.3M rows, REPLICATE is unusual - be aware of potential memory pressure on Synapse nodes.
- 6-digit vs 8-digit BIN disambiguation: `BinCode < 10,000,000` = 6-digit BIN; higher = 8-digit. Some cards may match both lengths - 8-digit should take precedence (more specific).
- Several processing-critical columns are dropped from DWH vs production source: `ChallengeIndicator3DS`, `SupportsAFT`, `IsCFT`. Fraud analytics requiring these must query the production etoro.Dictionary.CountryBin directly.
- IssuingBank, CardSubType, CardCategory, BankWebSite, BankInfo are frequently NULL in live data - the BIN may not have enriched metadata.
- BinCode is NOT guaranteed unique at the row level in the DWH (the composite PK of CountryID+BinCode in production is collapsed to CLUSTERED INDEX here).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| 4 stars | Tier 1 | Upstream wiki verbatim |
| 3 stars | Tier 2 | Synapse SP/DDL code |
| 2 stars | Tier 3 | Live data sampling / DDL structure |
| 1 star | Tier 4-Inferred [UNVERIFIED] | Column name guessing |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | int | NO | FK to DWH_dbo.Dim_Country. Card-issuing country. Same ID space as Dim_Country.CountryID (DWH internal ID, not ISO numeric). (Tier 1 - Dictionary.CountryBin6 upstream wiki) |
| 2 | BinCode | int | NO | Bank Identification Number. First 6 or 8 digits of the card number identifying the issuing bank and card product. Values < 10,000,000 are 6-digit BINs; >= 10,000,000 are 8-digit BINs. Clustered index key for fast lookups. (Tier 1 - Dictionary.CountryBin6 upstream wiki) |
| 3 | IssuingBank | varchar(100) | YES | Human-readable name of the card-issuing bank (e.g., "CENTRAL SUPPLIES - TDFS"). NULL when the BIN has no enriched bank metadata. Informational only - not used in deposit authorization logic. (Tier 1 - Dictionary.CountryBin6 upstream wiki) |
| 4 | CardTypeID | int | YES | FK to DWH_dbo.Dim_CardType (if exists). Card network/type: 1=Visa, 2=Master Card, 13=Local Card. Used in deposit routing and reporting. (Tier 1 - Dictionary.CountryBin6 upstream wiki) |
| 5 | CardSubType | varchar(50) | YES | Sub-classification of the card product within its type (e.g., "CREDIT", "DEBIT", "PREPAID"). NULL when not available. Passthrough from staging. (Tier 2 - SP_Dictionaries_DL_To_Synapse passthrough) |
| 6 | CardCategory | varchar(50) | YES | Card product category (e.g., "STANDARD", "GOLD", "PLATINUM", "BUSINESS"). NULL when not available. Passthrough from staging. (Tier 2 - SP_Dictionaries_DL_To_Synapse passthrough) |
| 7 | BankWebSite | varchar(50) | YES | Issuing bank website URL. Informational. NULL in most rows. (Tier 2 - SP_Dictionaries_DL_To_Synapse passthrough) |
| 8 | BankInfo | varchar(255) | YES | Additional bank information text. Informational. NULL in most rows. (Tier 2 - SP_Dictionaries_DL_To_Synapse passthrough) |
| 9 | ShouldCheck3ds | tinyint | YES | Whether 3D Secure verification is required for deposits from this BIN. 1=required (4.8M BINs, 29%), 0=not required (11.6M BINs, 71%). Drives deposit authorization flow. (Tier 1 - Dictionary.CountryBin6 upstream wiki) |
| 10 | MinAmountFor3ds | int | YES | Minimum amount that triggers 3DS check. NULL = no minimum. (Tier 1 - Dictionary.CountryBin6) |
| 11 | IsPrepaid | bit | NO | Whether this is a prepaid card. True=prepaid (may trigger fraud checks or processing restrictions). False=standard credit/debit card. (Tier 1 - Dictionary.CountryBin6 upstream wiki) |
| 12 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() on each daily full reload via SP_Dictionaries_DL_To_Synapse. Reflects ETL run time, not source data change. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CountryID | etoro.Dictionary.CountryBin6/8 | CountryID | passthrough |
| BinCode | etoro.Dictionary.CountryBin6/8 | BinCode | passthrough |
| IssuingBank | etoro.Dictionary.CountryBin6/8 | IssuingBank | passthrough |
| CardTypeID | etoro.Dictionary.CountryBin6/8 | CardTypeID | passthrough |
| CardSubType | etoro.Dictionary.CountryBin6/8 | CardSubType | passthrough |
| CardCategory | etoro.Dictionary.CountryBin6/8 | CardCategory | passthrough |
| BankWebSite | etoro.Dictionary.CountryBin6/8 | BankWebSite | passthrough |
| BankInfo | etoro.Dictionary.CountryBin6/8 | BankInfo | passthrough |
| ShouldCheck3ds | etoro.Dictionary.CountryBin6/8 | ShouldCheck3ds | passthrough (int -> tinyint) |
| MinAmountFor3ds | etoro.Dictionary.CountryBin6/8 | MinAmountFor3ds | passthrough |
| IsPrepaid | etoro.Dictionary.CountryBin6/8 | IsPrepaid | passthrough |
| UpdateDate | - | - | ETL-computed (GETDATE()) |

Upstream wikis: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryBin6.md` and `Dictionary.CountryBin8.md`.

### 5.2 ETL Pipeline

```
etoro.Dictionary.CountryBin6 (6-digit BINs)
etoro.Dictionary.CountryBin8 (8-digit BINs)
  -> [pre-merged in staging]
  -> DWH_staging.etoro_Dictionary_CountryBin (unified, 19 cols)
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, 12 cols)
  -> DWH_dbo.Dim_CountryBin (16.3M rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.CountryBin6 | 6-digit BINs with full processing attributes including ChallengeIndicator3DS, SupportsAFT, IsCFT |
| Source | etoro.Dictionary.CountryBin8 | 8-digit BINs with same structure |
| Staging | DWH_staging.etoro_Dictionary_CountryBin | Pre-merged staging: 19 cols (ProductType, Category, ChallengeIndicator3DS, SupportsAFT, IsCFT, DomesticMoneyTransfer, CrossBorderMoneyTransfer present but dropped) |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. 12 of 19 staging columns loaded. UpdateDate = GETDATE(). |
| Target | DWH_dbo.Dim_CountryBin | Final DWH BIN lookup (16.3M rows) |

**Dropped staging columns** (present in staging but NOT loaded to DWH):
- `ProductType`: Card product type string (different from CardSubType)
- `Category`: Card category string (different from CardCategory)
- `ChallengeIndicator3DS`: 3DS challenge indicator code
- `SupportsAFT`: Account Funding Transaction support flag
- `IsCFT`: Card Funding Transaction flag
- `DomesticMoneyTransfer`: Domestic money transfer support
- `CrossBorderMoneyTransfer`: Cross-border money transfer support

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Card-issuing country lookup. Implicit FK (not enforced). |
| CardTypeID | DWH_dbo.Dim_CardType | Card network type (Visa, Mastercard, etc.). Implicit FK. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.SP_Fact_BillingDeposit | BinCode | Deposit ETL likely joins BIN data for card attributes. [UNVERIFIED - inferred from domain context] |

---

## 7. Sample Queries

### 7.1 Lookup BIN attributes
```sql
SELECT b.BinCode, b.IssuingBank, b.CardTypeID, c.Name AS IssuingCountry,
       b.ShouldCheck3ds, b.IsPrepaid
FROM [DWH_dbo].[Dim_CountryBin] b
JOIN [DWH_dbo].[Dim_Country] c ON b.CountryID = c.CountryID
WHERE b.BinCode = 411234;
```

### 7.2 BINs requiring 3DS by country
```sql
SELECT c.Name AS Country, COUNT(*) AS BinCount
FROM [DWH_dbo].[Dim_CountryBin] b
JOIN [DWH_dbo].[Dim_Country] c ON b.CountryID = c.CountryID
WHERE b.ShouldCheck3ds = 1
GROUP BY c.Name
ORDER BY BinCount DESC;
```

### 7.3 Prepaid BIN share by card type
```sql
SELECT CardTypeID,
       SUM(CASE WHEN IsPrepaid = 1 THEN 1 ELSE 0 END) AS PrepaidBins,
       COUNT(*) AS TotalBins
FROM [DWH_dbo].[Dim_CountryBin]
GROUP BY CardTypeID
ORDER BY TotalBins DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.
Upstream production wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryBin6.md` and `Dictionary.CountryBin8.md`.

---

*Generated: 2026-03-19 | Quality: 7.7/10 (4 stars) | Phases: 9/14 (no Atlassian)*
*Tiers: 6 T1, 5 T2, 1 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 8/10*
*Object: DWH_dbo.Dim_CountryBin | Type: Table | Production Source: etoro.Dictionary.CountryBin6 + etoro.Dictionary.CountryBin8*

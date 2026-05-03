# eMoney_Tribe.CardsSnapshots_CardSnapshot-140457

> 86.2M-row raw card snapshot table landing daily from `FiatDwhDB.Tribe` on `prod-banking` via Generic Pipeline (Append, parquet). Contains one row per card per snapshot date for eToro Money debit cards (UK GBP and EU EUR programs) from 2021-09-05 to present. Covers card lifecycle status, cardholder PII, delivery details, program/product hierarchy, limits/fee/usage groups, and KYC verification. Read by `SP_eMoney_Reconciliation_ETLs` to build `eMoney_dbo.ETL_CardSnapshot`.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 (prod-banking) via Generic Pipeline #531 |
| **Refresh** | Daily (1440 min), Append strategy, incremental by @Created |
| **Synapse Distribution** | HASH([@Id]) |
| **Synapse Index** | CLUSTERED INDEX ([@Id] ASC), NCI on [partition_date], NCI on [@Created] |
| **UC Target** | `emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (raw landing) |

---

## 1. Business Meaning

This table is the raw Synapse landing zone for eToro Money card snapshot data originating from the card issuer platform (FiatDwhDB on prod-banking). Each row represents a point-in-time snapshot of a single debit card, capturing its full lifecycle state: issuance, activation, expiration, loss, theft, and blocking events.

The table holds 86.2M rows spanning from 2021-09-05 to 2026-04-26, with daily append loads via Generic Pipeline #531. The data covers two main card programs: **eToro Money UK GBP** (Program ID 39, ~78% of volume) and **eToro Money EU Card** (Program ID 182, ~22%). All cards operate on the **Visa** network.

`SP_eMoney_Reconciliation_ETLs` reads this table as the primary card-level source, joining it with sibling tribe tables (`CardsSnapshots-890718` for file metadata, `CardsSnapshots_Accounts-350640` and `CardsSnapshots_Account-513255` for account-level data) to produce the consolidated `eMoney_dbo.ETL_CardSnapshot` reconciliation table.

The table contains significant PII: cardholder name, address, date of birth, email, phone number, and masked card numbers. PII columns appear masked in query results (e.g., `******`).

---

## 2. Business Logic

### 2.1 Card Status Lifecycle

**What**: Each card moves through a defined set of statuses tracked by `CardStatusCode`.
**Columns Involved**: CardStatusCode, CardStatusCodeDescription, CardStatusDate, CardStatusChangeSource, CardStatusChangeReasonCode, CardStatusChangeNote, CardStatusChangeOriginatorId
**Rules**:
- A = Activated (41% of recent data)
- E = Expired (29%)
- N = Not Activated (26%)
- S = Stolen (2.6%)
- L = Lost (1%)
- R = Reported (<0.1%)
- B = Blocked (<0.1%)
- T = Temporary (<0.01%)
- `CardStatusChangeSource` is a numeric code (observed values: 0, 2) indicating whether the change was system-initiated or user-initiated
- `CardStatusChangeOriginatorId` identifies the entity (system or agent) that triggered the status change

### 2.2 Card Program and Product Hierarchy

**What**: Cards are organized into a three-level hierarchy: Program > Product > SubProduct.
**Columns Involved**: ProgramName, ProgramId, ProductName, ProductId, SubProductId
**Rules**:
- Program defines the regional and currency scope (e.g., "eToro Money UK GBP" = Program 39, "eToro Money EU Card" = Program 182)
- Product defines the card type (e.g., "eToro Money 459688 Consumer Debit Visa" = Product 24, "eToro Money EU 459689 Debit Visa" = Product 90)
- SubProductId provides further sub-classification (observed: 351 for UK, 664/666 for EU)

### 2.3 Limits, Fees, and Usage Groups

**What**: Each card is assigned to configurable groups controlling spending limits, fees, and usage permissions.
**Columns Involved**: LimitsGroupName, LimitsGroupId, FeeGroupName, FeeGroupId, UsageGroupName, UsageGroupId
**Rules**:
- Limits groups define spending caps (e.g., "eToro Green Account" = 44, "eToro Black EU EUR" = 80)
- Fee groups define fee schedules (e.g., "eToro Green" = 24, "eToro Consumer Green EU" = 38, "eToro Consumer Black EU" = 36)
- Usage groups define allowed transaction types (e.g., "eToro Standard Usage Group UK" = 13, "eToro Money Usage Group EU" = 26)

### 2.4 Dual Address Pattern

**What**: The table stores both registered cardholder address and delivery address separately.
**Columns Involved**: Address/City/State/ZipCode/CountryCode/CountryName (registered) vs DeliveryAddress/DeliveryCity/DeliveryState/DeliveryZipCode/DeliveryCountryCode/DeliveryCountryName (delivery)
**Rules**:
- Registered address = cardholder's legal/registered address
- Delivery address = where the physical card was shipped
- In most observed rows, both addresses match, but they can diverge

### 2.5 Currency Distribution

**What**: Cards are issued in one of two currencies.
**Columns Involved**: DefaultCardCurrency
**Rules**:
- GBP = UK cards (78% of recent volume)
- EUR = EU cards (22% of recent volume)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH on `[@Id]` — co-located with sibling tribe tables for efficient JOINs
- **Clustered Index**: `[@Id]` ASC — optimized for point lookups and JOIN to `CardsSnapshots-890718`
- **NCI**: `partition_date` — supports date-range filters; `@Created` — supports incremental load queries
- **Row count**: 86.2M — use date filters on `partition_date` or `@Created` for any aggregate queries

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many active cards per program? | `WHERE partition_date = (SELECT MAX(partition_date) ...) AND CardStatusCode = 'A' GROUP BY ProgramName` |
| Card status distribution over time | `GROUP BY partition_date, CardStatusCode` with `WHERE partition_date >= '2026-01-01'` |
| Cards issued vs activated in a period | Compare `CardCreationDate` vs `CardActivationDate` with date range filter on `partition_date` |
| Country breakdown | `GROUP BY CountryCode, CountryName` filtered by recent `partition_date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Tribe.CardsSnapshots-890718 | [@Id] = [@Id] | Parent record — file metadata (@FileName) |
| eMoney_Tribe.CardsSnapshots_Accounts-350640 | [@Id] = [@Id] | Account-level snapshot (account IDs) |
| eMoney_Tribe.CardsSnapshots_Account-513255 | [@Id] = [@Id] (via Accounts-350640) | Account details (balance, status, currency) |
| eMoney_dbo.ETL_CardSnapshot | — | Consolidated reconciliation output built from this table |

### 3.4 Gotchas

- **All varchar(max)**: Most columns are `varchar(max)` even for numeric/date values (e.g., ProgramId, CardCreationDate). Cast before arithmetic or date comparisons.
- **Masked PII**: FirstName, LastName, CardNumber, Dob, EmailAddress, PhoneNumber are masked in query results. Do not rely on exact values for PII columns.
- **etr_y/etr_ym/etr_ymd empty**: These eToro partition key columns are consistently NULL/empty in recent data — do not use for filtering.
- **@Created vs Created**: Both columns exist with datetime2(7) type. In sampled rows both carry the same value; `@Created` is the pipeline-native column used by the incremental load pattern.
- **CardStatusChangeSource is numeric**: Despite being varchar, observed values are 0 and 2 — not descriptive text.
- **CountryCode is ISO 3166-1 numeric**: Stored as varchar (e.g., "826" = United Kingdom, "250" = France), not alpha codes. Use CountryCodeAlpha for ISO alpha-3.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP code / ETL transform |
| Tier 3 | Grounded in DDL + sample data + SP context, no upstream wiki available |
| Tier 4 | Inferred from name only (banned for this object) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Created | datetime2(7) | YES | Pipeline-assigned creation timestamp for this snapshot record. Used as the incremental load watermark by SP_eMoney_Reconciliation_ETLs (`WHERE @Created >= @CardSnapshot_DATE`). Indexed (idx_140457_created). (Tier 3 — no upstream wiki, grounded in DDL + SP incremental load pattern) |
| 2 | @Id | varchar(255) | YES | UUID primary key identifying a single card snapshot record. Distribution key and clustered index column. Used as the JOIN key to sibling tribe tables (CardsSnapshots-890718, CardsSnapshots_Accounts-350640). Observed format: GUID (e.g., "ffd2b538-ab17-4867-8cc8-993f3eddc4c1"). (Tier 3 — no upstream wiki, grounded in DDL + SP JOIN pattern) |
| 3 | @CardsSnapshots@Id-890718 | varchar(max) | YES | Foreign key referencing the parent CardsSnapshots-890718 header record. In sampled data, value is identical to @Id, indicating a 1:1 relationship between card snapshot and parent header. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 4 | FileDate | varchar(max) | YES | Date of the source data file from the card issuer platform. Stored as varchar in YYYY-MM-DD format. Observed to match the partition_date value. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 5 | WorkDate | varchar(max) | YES | Business working date for the snapshot, stored as varchar. Format observed: "YYYY-MM-DD HH:MM:SS". Passed through to ETL_CardSnapshot and used to derive DateID. (Tier 3 — no upstream wiki, grounded in DDL + SP usage) |
| 6 | @WorkDate | datetime2(7) | YES | Typed datetime2 version of the business working date. Provides the same date as the varchar WorkDate column but in native datetime format for date arithmetic. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 7 | IssuerIdentificationNumber | varchar(max) | YES | Bank Identification Number (BIN) or Issuer Identification Number from the card network. Observed value: "10079563" (UK), "10084368" (EU). Identifies the issuing institution on the Visa network. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 8 | ProgramName | varchar(max) | YES | Name of the card program. Observed values: "eToro Money UK GBP" (UK program), "eToro Money EU Card" (EU program). Defines the regional and currency scope of the card issuance. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 9 | ProgramId | varchar(max) | YES | Numeric identifier for the card program. Observed values: 39 (UK GBP), 182 (EU). Stored as varchar despite being a numeric ID. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 10 | ProductName | varchar(max) | YES | Name of the card product within the program. Observed values: "eToro Money 459688 Consumer Debit Visa" (UK), "eToro Money EU 459689 Debit Visa" (EU). (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 11 | ProductId | varchar(max) | YES | Numeric identifier for the card product. Observed values: 24 (UK), 90 (EU). Stored as varchar. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 12 | SubProductId | varchar(max) | YES | Sub-product classification within the card product. Observed values: 351 (UK), 664, 666 (EU). Provides further granularity below the product level. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 13 | HolderId | varchar(max) | YES | Cardholder identifier assigned by the card issuer platform. Numeric value (e.g., "678808", "29438"). Links the card to the customer on the issuer side. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 14 | CardNumber | varchar(max) | YES | Masked Primary Account Number (PAN) of the debit card. Displayed as partially masked (e.g., "************5942"). PII — sensitive data. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 15 | CardNumberId | varchar(max) | YES | Internal numeric identifier for the card number record on the issuer platform. Distinct from CardNumber (the PAN). (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 16 | CardRequestId | varchar(max) | YES | Identifier for the card issuance request. May be NULL/empty for cards that were not requested through the standard issuance flow (e.g., auto-renewed cards). (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 17 | IsVirtual | varchar(max) | YES | Whether the card is a virtual card. Observed values: "No" in all sampled rows. Stored as text string, not boolean. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 18 | CardExpirationDate | varchar(max) | YES | Expiration date of the card. Stored as varchar; values appear masked in query results. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 19 | CardCreationDate | varchar(max) | YES | Date the card was created/issued on the issuer platform. Stored as varchar in YYYY-MM-DD format (e.g., "2022-04-13"). (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 20 | CardActivationDate | varchar(max) | YES | Date the card was first activated by the cardholder. NULL if the card has never been activated (CardStatusCode = 'N'). Stored as varchar in YYYY-MM-DD format. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 21 | CardStatusDate | varchar(max) | YES | Date of the most recent card status change. Stored as varchar in YYYY-MM-DD format. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 22 | CardStatusCode | varchar(max) | YES | Single-letter code indicating the current card status. A=Activated, E=Expired, N=Not Activated, S=Stolen, L=Lost, R=Reported, B=Blocked, T=Temporary. Distribution (Apr 2026): A=41%, E=29%, N=26%, S=2.6%, L=1%, R/B/T<0.1%. (Tier 3 — no upstream wiki, grounded in DDL + sample data + distribution analysis) |
| 23 | CardStatusCodeDescription | varchar(max) | YES | Human-readable description of the card status. Observed values: "Activated", "Expired", "Not Activated", "Stolen". (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 24 | CardStatusChangeSource | varchar(max) | YES | Numeric code indicating the source/channel of the status change. Observed values: 0, 2. Stored as varchar. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 25 | CardStatusChangeReasonCode | varchar(max) | YES | Reason code for the card status change. May be empty. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 26 | CardStatusChangeNote | varchar(max) | YES | Free-text note associated with the card status change. Often empty. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 27 | CardStatusChangeOriginatorId | varchar(max) | YES | Identifier of the entity (system or agent) that initiated the card status change. Observed values: numeric IDs (e.g., "23", "48") or empty. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 28 | LimitsGroupName | varchar(max) | YES | Name of the spending limits group assigned to the card. Observed values: "eToro Green Account", "eToro Green EU EUR", "eToro Black EU EUR". (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 29 | LimitsGroupId | varchar(max) | YES | Numeric identifier for the spending limits group. Observed values: 44 (UK Green), 78 (EU Green), 80 (EU Black). Stored as varchar. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 30 | FeeGroupName | varchar(max) | YES | Name of the fee schedule group assigned to the card. Observed values: "eToro Green", "eToro Consumer Green EU", "eToro Consumer Black EU". (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 31 | FeeGroupId | varchar(max) | YES | Numeric identifier for the fee group. Observed values: 24 (UK Green), 38 (EU Green), 36 (EU Black). Stored as varchar. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 32 | UsageGroupName | varchar(max) | YES | Name of the usage permissions group controlling allowed transaction types. Observed values: "eToro Standard Usage Group UK", "eToro Money Usage Group EU". (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 33 | UsageGroupId | varchar(max) | YES | Numeric identifier for the usage group. Observed values: 13 (UK), 26 (EU). Stored as varchar. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 34 | FirstName | varchar(max) | YES | Cardholder first name. PII — values are masked in query results. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 35 | LastName | varchar(max) | YES | Cardholder last name. PII — values are masked in query results. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 36 | Address | varchar(max) | YES | Cardholder registered street address. PII — not passed through to ETL_CardSnapshot by SP_eMoney_Reconciliation_ETLs (selected into temp table but present in final output). (Tier 3 — no upstream wiki, grounded in DDL + SP code) |
| 37 | City | varchar(max) | YES | Cardholder registered city. Observed values: UK and EU city names (e.g., "Aberystwyth", "Glasgow", "ST MAURICE"). (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 38 | State | varchar(max) | YES | Cardholder registered state or region. Often empty for UK addresses; may contain city name for EU addresses. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 39 | ZipCode | varchar(max) | YES | Cardholder registered postal/ZIP code. UK postcodes (e.g., "SY23 3SB") and EU postal codes (e.g., "94410"). (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 40 | CountryCode | varchar(max) | YES | ISO 3166-1 numeric country code of the cardholder's registered address. Observed values: 826=United Kingdom (78%), 276=Germany, 380=Italy, 250=France, 724=Spain, among 44 countries. Stored as varchar. (Tier 3 — no upstream wiki, grounded in DDL + sample data + distribution analysis) |
| 41 | CountryCodeAlpha | varchar(max) | YES | ISO 3166-1 alpha-3 country code. Observed values: "GBR", "FRA", "ITA", etc. Provides the alphabetic equivalent of CountryCode. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 42 | CountryName | varchar(max) | YES | Full country name of the cardholder's registered address. Observed values: "United Kingdom", "France", "Italy", etc. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 43 | Dob | varchar(max) | YES | Cardholder date of birth. Stored as varchar in YYYY-MM-DD format (e.g., "1997-09-20"). PII. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 44 | EmailAddress | varchar(max) | YES | Cardholder email address. PII. Not selected by SP_eMoney_Reconciliation_ETLs into the temp table — excluded from ETL_CardSnapshot downstream. (Tier 3 — no upstream wiki, grounded in DDL + SP code) |
| 45 | PhoneNumber | varchar(max) | YES | Cardholder phone number. PII. Not selected by SP_eMoney_Reconciliation_ETLs into the temp table — excluded from ETL_CardSnapshot downstream. (Tier 3 — no upstream wiki, grounded in DDL + SP code) |
| 46 | PhoneNumberCountryCode | varchar(max) | YES | International dialing country code for the cardholder's phone number. Passed through to ETL_CardSnapshot by SP_eMoney_Reconciliation_ETLs. (Tier 3 — no upstream wiki, grounded in DDL + SP code) |
| 47 | ApplicationIpAddress | varchar(max) | YES | IP address captured at the time of the card application. PII. Passed through to ETL_CardSnapshot. (Tier 3 — no upstream wiki, grounded in DDL + SP code) |
| 48 | KycVerification | varchar(max) | YES | KYC (Know Your Customer) verification status code. Observed value: "0" in all sampled rows. Stored as varchar. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 49 | CardEvent | varchar(max) | YES | Most recent event type recorded for the card. Observed values: "Card Status Change", "Balance update". Indicates the trigger for the latest snapshot record. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 50 | DefaultCardCurrency | varchar(max) | YES | Default currency of the card. GBP=UK cards (78%), EUR=EU cards (22%). Aligns with ProgramName region. (Tier 3 — no upstream wiki, grounded in DDL + sample data + distribution analysis) |
| 51 | Network | varchar(max) | YES | Card payment network. Observed value: "Visa" in all sampled rows. All eToro Money cards operate on the Visa network. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 52 | DeliveryTitle | varchar(max) | YES | Title/salutation for the card delivery address (e.g., "Mr", "Ms"). Mostly empty in sampled data. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 53 | DeliveryFirstName | varchar(max) | YES | First name on the card delivery address. PII — masked in query results. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 54 | DeliveryLastName | varchar(max) | YES | Last name on the card delivery address. PII — masked in query results. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 55 | DeliveryAddress | varchar(max) | YES | Street address for card delivery. May differ from the registered Address if the card was shipped to an alternate location. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 56 | DeliveryCity | varchar(max) | YES | City for card delivery. Observed to match City in most rows. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 57 | DeliveryState | varchar(max) | YES | State/region for card delivery. Often contains the city name (e.g., "Aberystwyth", "Slough"). (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 58 | DeliveryZipCode | varchar(max) | YES | Postal/ZIP code for card delivery. Observed to match ZipCode in most rows. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 59 | DeliveryCountryCode | varchar(max) | YES | ISO 3166-1 numeric country code for the delivery address. Observed to match CountryCode. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 60 | DeliveryCountryName | varchar(max) | YES | Full country name for the delivery address. Observed to match CountryName. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 61 | ActiveWallet | varchar(max) | YES | Active wallet identifier associated with the card. Empty/NULL in all sampled rows. Purpose unclear from available evidence. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 62 | etr_y | varchar(max) | YES | eToro year partition key. Empty/NULL in all recent sampled rows. Likely a legacy or deprecated partition column. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 63 | etr_ym | varchar(max) | YES | eToro year-month partition key. Empty/NULL in all recent sampled rows. Likely a legacy or deprecated partition column. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 64 | etr_ymd | varchar(max) | YES | eToro year-month-day partition key. Empty/NULL in all recent sampled rows. Likely a legacy or deprecated partition column. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 65 | SynapseUpdateDate | datetime | YES | Timestamp of when the row was last loaded/updated in Synapse. Set by the Generic Pipeline at load time. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 66 | partition_date | date | YES | Table partition date, derived from the snapshot date. Indexed (XI_partition_date). Primary date filter for efficient range queries on this large table. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 67 | Created | datetime2(7) | YES | Record creation timestamp. Observed to carry the same value as @Created. May represent the source system creation time vs pipeline creation time. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| All 67 columns | FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 | Same name | Passthrough via Generic Pipeline (Append) |
| SynapseUpdateDate | Synapse ETL | — | GETDATE() at pipeline load |
| partition_date | Synapse ETL | — | Derived from snapshot date |

### 5.2 ETL Pipeline

```
FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 (prod-banking)
  |-- Generic Pipeline #531 (Append, daily, parquet) ---|
  v
Bronze/FiatDwhDB/Tribe/CardsSnapshots_CardSnapshot-140457/ (Data Lake)
  |-- Generic Pipeline (Bronze load) ---|
  v
eMoney_Tribe.CardsSnapshots_CardSnapshot-140457 (86.2M rows, Synapse)
  |-- SP_eMoney_Reconciliation_ETLs (incremental by @Created) ---|
  |   JOIN CardsSnapshots-890718 (header)
  |   JOIN CardsSnapshots_Accounts-350640 (accounts)
  |   JOIN CardsSnapshots_Account-513255 (account detail)
  v
eMoney_dbo.ETL_CardSnapshot (reconciliation table)
  |-- Generic Pipeline (Bronze export) ---|
  v
emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 (UC Bronze)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @CardsSnapshots@Id-890718 | eMoney_Tribe.CardsSnapshots-890718 | Parent snapshot header record |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Element | Description |
|---|---|---|
| eMoney_dbo.SP_eMoney_Reconciliation_ETLs | @Id, most columns | Reads card snapshot data to build ETL_CardSnapshot reconciliation table |
| eMoney_Tribe_tmp.CardsSnapshots_CardSnapshot-140457_tmp | — | Temporary/staging copy of this table |

---

## 7. Sample Queries

### 7.1 Active Cards by Program (Latest Snapshot)

```sql
SELECT ProgramName, COUNT(*) AS active_cards
FROM [eMoney_Tribe].[CardsSnapshots_CardSnapshot-140457]
WHERE partition_date = (SELECT MAX(partition_date) FROM [eMoney_Tribe].[CardsSnapshots_CardSnapshot-140457])
  AND CardStatusCode = 'A'
GROUP BY ProgramName
ORDER BY active_cards DESC;
```

### 7.2 Card Status Trend Over Last 30 Days

```sql
SELECT partition_date, CardStatusCode, COUNT(*) AS card_count
FROM [eMoney_Tribe].[CardsSnapshots_CardSnapshot-140457]
WHERE partition_date >= DATEADD(DAY, -30, GETDATE())
GROUP BY partition_date, CardStatusCode
ORDER BY partition_date, CardStatusCode;
```

### 7.3 Country Distribution for Active EU Cards

```sql
SELECT CountryName, COUNT(*) AS card_count
FROM [eMoney_Tribe].[CardsSnapshots_CardSnapshot-140457]
WHERE partition_date = (SELECT MAX(partition_date) FROM [eMoney_Tribe].[CardsSnapshots_CardSnapshot-140457])
  AND DefaultCardCurrency = 'EUR'
  AND CardStatusCode = 'A'
GROUP BY CountryName
ORDER BY card_count DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode). See SP header comment for Freshservice change reference: https://etoro.freshservice.com/a/changes/20353.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 67 T3, 0 T4, 0 T5 | Elements: 67/67, Logic: 5/10, Lineage: complete*
*Object: eMoney_Tribe.CardsSnapshots_CardSnapshot-140457 | Type: Table | Production Source: FiatDwhDB.Tribe (prod-banking, dormant — no upstream wiki)*

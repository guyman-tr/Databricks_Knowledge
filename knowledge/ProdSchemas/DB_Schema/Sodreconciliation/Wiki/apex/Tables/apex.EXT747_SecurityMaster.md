# apex.EXT747_SecurityMaster

> Stores Apex Clearing's daily Security Master extract - the complete securities reference data including CUSIPs, symbols, pricing, security types, and eligibility codes.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 PK + 1 NC on SodFileId) |

---

## 1. Business Meaning

This table stores Apex Clearing's Extract 747 - the Security Master file. It is the authoritative reference data for all securities held or traded at Apex, including CUSIPs, market symbols, descriptions, pricing, margin eligibility, DTC eligibility, foreign indicator, and option-related fields (underlying CUSIP, strike price, expiration). This is a critical reconciliation table as it provides the security-level reference data needed to validate positions and trades.

Data is imported daily from Apex. Each security gets one row per daily import. Currently receives ~2,166 file imports.

---

## 2. Business Logic

### 2.1 Security Classification Codes

**What**: Multiple single-character code columns classify security attributes.

**Columns/Parameters Involved**: `SecurityTypeCode`, `MarginEligibleCode`, `DTCEligbleCode`, `ForeignCode`, `BookEntryCode`

**Rules**:
- SecurityTypeCode: Apex security type classification (e.g., equity, bond, option)
- MarginEligibleCode: Whether the security can be held in a margin account
- DTCEligbleCode: Whether the security is eligible for DTC (Depository Trust Company) settlement
- ForeignCode: Whether this is a foreign security
- These codes are defined by Apex Clearing's data dictionary

---

## 3. Data Overview

N/A - large reference data table. One row per security per daily import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Auto-generated sequential GUID primary key. |
| 2 | SodFileId | uniqueidentifier | NO | - | VERIFIED | FK to apex.SodFiles.Id. Links to source file import. CASCADE DELETE. |
| 3 | Cusip | varchar(12) | YES | - | CODE-BACKED | CUSIP identifier - the primary US/Canadian security identifier (9-character Committee on Uniform Security Identification Procedures code). |
| 4 | MarketSymbol | varchar(35) | YES | - | CODE-BACKED | Ticker symbol as used on the exchange/market. |
| 5 | ShortDescription | varchar(15) | YES | - | CODE-BACKED | Abbreviated security description. |
| 6 | SecurityTypeCode | varchar(1) | YES | - | CODE-BACKED | Apex security type classifier. Single character code per Apex data dictionary. |
| 7 | CmpQualCode | varchar(1) | YES | - | NAME-INFERRED | Company qualification code. Apex-defined classification. |
| 8 | SecQualCode | varchar(1) | YES | - | NAME-INFERRED | Security qualification code. Apex-defined classification. |
| 9 | MarginEligibleCode | varchar(1) | YES | - | CODE-BACKED | Whether the security is eligible for margin trading at Apex. |
| 10 | Margin100ReqCode | varchar(1) | YES | - | NAME-INFERRED | Whether the security requires 100% margin (non-marginable). |
| 11 | ForeignCode | varchar(1) | YES | - | CODE-BACKED | Whether this is a foreign-domiciled security. |
| 12 | DTCEligbleCode | varchar(1) | YES | - | CODE-BACKED | Whether the security is eligible for DTC (Depository Trust Company) electronic settlement. |
| 13 | ListedMarketCode | varchar(1) | YES | - | CODE-BACKED | Exchange/market where the security is primarily listed. |
| 14 | BookEntryCode | varchar(1) | YES | - | NAME-INFERRED | Whether the security is held in book-entry form (vs physical certificates). |
| 15 | ReOrgCode | varchar(1) | YES | - | NAME-INFERRED | Reorganization status code - indicates if the security is undergoing a corporate reorganization. |
| 16 | Product | varchar(4) | YES | - | NAME-INFERRED | Apex product type classification. |
| 17 | TaxCode | varchar(1) | YES | - | NAME-INFERRED | Tax treatment code for the security. |
| 18 | ClosingPrice | decimal(19,10) | YES | - | CODE-BACKED | Most recent closing price of the security. Used in position valuation and margin calculations. |
| 19 | Description1 | varchar(30) | YES | - | CODE-BACKED | Full security description line 1. |
| 20 | Description2 | varchar(30) | YES | - | CODE-BACKED | Full security description line 2. |
| 21 | Description3 | varchar(30) | YES | - | CODE-BACKED | Full security description line 3. |
| 22 | LastChangeDate | smalldatetime | YES | - | CODE-BACKED | When the security master record was last changed at Apex. |
| 23 | LastTradeDate | smalldatetime | YES | - | CODE-BACKED | Most recent trade date for this security. |
| 24 | LastPriceDate | smalldatetime | YES | - | CODE-BACKED | Date of the ClosingPrice value. |
| 25 | SICCode | nvarchar(max) | YES | - | CODE-BACKED | Standard Industrial Classification code identifying the company's industry sector. |
| 26 | ForeignCountry | varchar(2) | YES | - | CODE-BACKED | ISO country code for foreign securities. |
| 27 | CMORemicIndicator | varchar(1) | YES | - | NAME-INFERRED | Whether the security is a CMO (Collateralized Mortgage Obligation) or REMIC. |
| 28 | OldSecurityNumber | varchar(10) | YES | - | CODE-BACKED | Previous security identifier (MASKED for PII protection). Historical reference when CUSIPs change. |
| 29 | ConversionFactor | decimal(9,4) | YES | - | CODE-BACKED | Conversion factor for convertible securities or options contracts. |
| 30 | Routing | varchar(4) | YES | - | NAME-INFERRED | Order routing designation. |
| 31 | UnderlyingCusip | varchar(12) | YES | - | CODE-BACKED | For options/derivatives: CUSIP of the underlying security. |
| 32 | StrikePrice | decimal(19,10) | YES | - | CODE-BACKED | For options: the strike/exercise price. |
| 33 | ExpireDate | datetime | YES | - | CODE-BACKED | For options: expiration date of the contract. |
| 34 | ProcessDate | datetime | YES | - | CODE-BACKED | Business date this security master snapshot represents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (ON DELETE CASCADE) | Links to source file import |

### 5.2 Referenced By (other objects point to this)

No direct FK references. Used as reference data for reconciliation against position and trade data.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
apex.EXT747_SecurityMaster (table)
└── apex.SodFiles (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId |

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EXT747_SecurityMaster | CLUSTERED PK | Id | - | - | Active |
| IX_EXT747_SecurityMaster_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_EXT747_SecurityMaster_SodFiles_SodFileId | FOREIGN KEY | SodFileId -> apex.SodFiles.Id (CASCADE DELETE, WITH NOCHECK) |

---

## 8. Sample Queries

### 8.1 Get latest security master for a CUSIP

```sql
SELECT sm.Cusip, sm.MarketSymbol, sm.Description1, sm.ClosingPrice, sm.SecurityTypeCode, f.ProcessDate
FROM apex.EXT747_SecurityMaster sm WITH (NOLOCK)
JOIN apex.SodFiles f WITH (NOLOCK) ON sm.SodFileId = f.Id
WHERE sm.Cusip = '037833100' AND f.Status = 2
ORDER BY f.ProcessDate DESC;
```

### 8.2 Find foreign securities

```sql
SELECT sm.Cusip, sm.MarketSymbol, sm.ForeignCountry, sm.Description1
FROM apex.EXT747_SecurityMaster sm WITH (NOLOCK)
JOIN apex.SodFiles f WITH (NOLOCK) ON sm.SodFileId = f.Id
WHERE sm.ForeignCode = 'Y' AND f.ProcessDate = '2026-04-10' AND f.Status = 2
ORDER BY sm.MarketSymbol;
```

### 8.3 Find options with upcoming expiration

```sql
SELECT sm.MarketSymbol, sm.UnderlyingCusip, sm.StrikePrice, sm.ExpireDate
FROM apex.EXT747_SecurityMaster sm WITH (NOLOCK)
JOIN apex.SodFiles f WITH (NOLOCK) ON sm.SodFileId = f.Id
WHERE sm.ExpireDate IS NOT NULL AND sm.ExpireDate <= DATEADD(day, 7, GETDATE()) AND f.Status = 2
ORDER BY sm.ExpireDate;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | File import pipeline: each file parsed and stored into respective table based on format |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.4/10 (Elements: 8.2/10, Logic: 5/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 6 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: apex.EXT747_SecurityMaster | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT747_SecurityMaster.sql*

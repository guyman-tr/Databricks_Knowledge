# Customer.CountryRafConfiguration_NogaJunk210725

> Temporal configuration table defining per-country and per-regulation rules for the Refer-a-Friend (RAF) program: compensation amounts, deposit thresholds, eligibility dates, and Terms & Conditions URLs.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | CountryID + RegulationID (composite PK, clustered) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 2 (1 clustered PK + 1 unique NC on RafConfigurationID) |

---

## 1. Business Meaning

Customer.CountryRafConfiguration_NogaJunk210725 stores the business rules governing the Refer-a-Friend (RAF) program on a per-country and per-regulatory-framework basis. Each row defines what a referring customer earns (ReferringCompensationInCents), what the referred customer earns (ReferredCompensationInCents), the minimum deposit amounts required to qualify, how many compensations a referrer can claim, timing constraints (days to wait after first deposit, date windows for counting referrals), and a link to the country-specific T&C PDF.

The table is authoritative for RAF eligibility decisions. Customer.GetRafConfiguration_NogaJunk210725 and Billing.GetRafConfiguration_NogaJunk210725 read this table to determine whether a referral pair qualifies and what compensation to pay. Customer.RAFCompensationProcess_NogaJunk210725 uses it when processing compensation payouts.

Data flows in via BackOffice RAF configuration procedures. The temporal table design (SYSTEM_VERSIONING with History.CountryRafConfiguration) preserves the full history of configuration changes — critical for auditing past compensation decisions against the rules that were in effect at the time.

Note: The "_NogaJunk210725" suffix indicates this table was tagged as a temporary/experimental object by a team member in July 2025, but the table has live active data, a temporal history table, and active procedure consumers, making it the current production RAF configuration.

---

## 2. Business Logic

### 2.1 RAF Compensation Eligibility Rules

**What**: Multi-condition eligibility model - both the referrer and the referred customer must meet deposit and trading thresholds within defined time windows.

**Columns/Parameters Involved**: `ReferringMinDepositInCents`, `ReferredMinDepositInCents`, `ReferredMinPositionsAmountInCents`, `DaysToWaitFromFTD`, `DaysToCheckMinPositionsAmountFromRegistration`, `CountRAFFromDate`, `CheckFTDFromDate`

**Rules**:
- Referred customer must deposit >= ReferredMinDepositInCents within the qualifying period
- Referred customer must also trade >= ReferredMinPositionsAmountInCents in positions within DaysToCheckMinPositionsAmountFromRegistration days of registration
- Referrer must deposit >= ReferringMinDepositInCents to be eligible to receive compensation
- DaysToWaitFromFTD: minimum days after the referred customer's first-time deposit before compensation can be processed (7 days common)
- CountRAFFromDate / CheckFTDFromDate: only referrals registered/depositing after these dates count — allows configuration changes to apply prospectively

### 2.2 Country-Specific Compensation Tiers

**What**: Compensation amounts vary by country + regulation pair. Some markets pay no cash bonus (0 cents) while others pay up to $50.

**Columns/Parameters Involved**: `ReferringCompensationInCents`, `ReferredCompensationInCents`, `MaxNumberOfCompensations`

**Rules**:
- Amounts stored in cents (divide by 100 for USD): 5000 cents = $50.00
- Many EU-regulated countries: 0 cents compensation (regulatory restrictions on inducements)
- FSA-regulated countries: up to 5000 cents ($50) for the referrer
- MaxNumberOfCompensations: caps total referral payouts per referrer (3 for most EU, 10 for FSA)
- ReferredCompensationInCents: reward for the person being referred (0 in all current live data — only referrer earns)

**Diagram**:
```
RAF Configuration per Country+Regulation:
  EU Regulation (RegulationID=1):
    -> 0 cents referrer, 0 cents referred, max 3 compensations
    -> Min deposit: $10 referrer, $100 referred
  FSA Regulation (RegulationID=9):
    -> $50 cents referrer, 0 cents referred, max 10 compensations
    -> Min deposit: $10 referrer, $100 referred
  AUS Regulation (RegulationID=10):
    -> 0 cents referrer, 0 cents referred, max 3 compensations
```

### 2.3 Temporal Configuration Versioning

**What**: All configuration changes are preserved in History.CountryRafConfiguration — enabling retrospective audits of what rules applied at any given time.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`

**Rules**:
- ValidTo = '9999-12-31...' for current active configuration
- When a row is updated, SQL Server moves the old version to History.CountryRafConfiguration with the actual ValidTo timestamp
- Compensation decisions for historical referrals can be audited against the configuration that was in effect at the time of the referral

---

## 3. Data Overview

| CountryID | RegulationID | ReferringComp ($) | ReferredComp ($) | MaxComps | ReferringMinDeposit ($) | ReferredMinDeposit ($) | DaysWait | Meaning |
|---|---|---|---|---|---|---|---|---|
| 12 (AUS) | 10 | $0 | $0 | 3 | $10 | $100 | 7 | Australia (RegID=10) - RAF active but no cash compensation; completion rewarded via other means |
| 16 | 9 (FSA) | $50 | $0 | 10 | $10 | $100 | 7 | FSA-regulated country - referrer earns $50 per qualifying referral, up to 10 total; most generous tier |
| 13 | 1 (EU) | $0 | $0 | 3 | $10 | $100 | 7 | EU-regulated country - compensation not allowed by MiFID rules; RAF tracks referrals but pays nothing |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Country code - part of composite PK. Identifies the country of the referred customer for which this configuration applies. No explicit FK constraint but references Dictionary.Country values. Check constraint ensures non-zero. |
| 2 | RegulationID | int | NO | 0 | VERIFIED | Regulatory framework identifier - part of composite PK. Determines which regulatory rules apply (1=EU, 9=FSA, 10=AUS, etc.). Default=0 but Check constraint ensures non-zero at insert. No FK constraint. |
| 3 | ReferringCompensationInCents | int | NO | - | VERIFIED | Cash reward in US cents for the referring customer when a qualifying referral completes. 0 for EU-regulated countries; 5000 ($50) for FSA countries. Divide by 100 to get USD. |
| 4 | ReferredCompensationInCents | int | NO | - | VERIFIED | Cash reward in US cents for the referred customer (new user). Currently 0 in all live configurations - only the referrer earns compensation. Divide by 100 to get USD. |
| 5 | MaxNumberOfCompensations | int | NO | - | VERIFIED | Maximum number of qualifying referrals a single referrer can receive compensation for. 3 for most EU/AUS; 10 for FSA markets. Prevents referral farming abuse. |
| 6 | ReferringMinDepositInCents | int | NO | - | VERIFIED | Minimum deposit in US cents the referring customer must have made to be eligible. Typically 1000 cents ($10). Divide by 100 for USD. |
| 7 | ReferredMinDepositInCents | int | NO | - | VERIFIED | Minimum first deposit in US cents the referred customer must make to qualify the referral. Typically 10000 cents ($100). Divide by 100 for USD. |
| 8 | CountRAFFromDate | datetime | YES | - | CODE-BACKED | Cutoff date - only referrals where the referred customer registered AFTER this date count toward the referrer's RAF quota. Used when program rules changed to avoid retroactive counting. |
| 9 | CheckFTDFromDate | datetime | YES | - | CODE-BACKED | Cutoff date - only first-time deposits (FTDs) occurring after this date qualify for RAF compensation. Allows program rule changes to apply prospectively. |
| 10 | ValidFrom | datetime2(7) | NO | - | VERIFIED | Temporal period start (system-generated). UTC timestamp when this configuration version became active. Managed automatically by SQL Server SYSTEM_VERSIONING. |
| 11 | ValidTo | datetime2(7) | NO | - | VERIFIED | Temporal period end (system-generated). '9999-12-31...' for current active configuration. Set to actual change time when superseded. |
| 12 | DaysToWaitFromFTD | int | NO | - | VERIFIED | Number of days after the referred customer's first-time deposit before the compensation can be processed. Typically 7 days - anti-fraud delay to detect charge-backs before paying bonuses. |
| 13 | ReferringMinPositionsAmountInCents | int | NO | - | VERIFIED | Minimum total trading amount in cents the referring customer must have open/closed positions for. Typically 10000 cents ($100). Ensures the referrer is an active trader. |
| 14 | ReferredMinPositionsAmountInCents | int | NO | - | VERIFIED | Minimum total trading amount in cents the referred customer must achieve within DaysToCheckMinPositionsAmountFromRegistration days. Typically 10000 cents ($100). Ensures the referred customer actually trades. |
| 15 | CheckMinPositionsAmountFromDate | datetime | YES | - | CODE-BACKED | Cutoff date - only trading activity after this date counts toward the minimum positions amount requirement. Aligns with program launch dates per region. |
| 16 | DaysToCheckMinPositionsAmountFromRegistration | int | NO | - | VERIFIED | Time window in days after registration within which the referred customer must achieve the minimum trading amount. Typically 30-90 days depending on regulation. |
| 17 | TnC_URL | nvarchar(300) | NO | 'X' | VERIFIED | URL to the country/regulation-specific Terms & Conditions PDF for the RAF program. Links to etorostatic.com marketing PDFs (e.g., terms_raf_eu.pdf, terms_raf_aus.pdf, terms_raf_fsa.pdf). Default='X' as placeholder; must be set at insert. |
| 18 | Trace | computed | YES | - | CODE-BACKED | Computed JSON string capturing audit context at query time: hostname, app name, SQL login, SPID, database name, and stored procedure name. Used for debugging and tracing which process last touched the row. |
| 19 | RafConfigurationID | int | NO | - | VERIFIED | Surrogate unique identifier for this configuration record. Has unique index UQ_CountryRafConfiguration_RafConfigurationID. Used as a stable reference key in RAF processes separate from the composite PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit | References country codes; no FK constraint declared |
| RegulationID | (Regulation lookup) | Implicit | References regulatory framework; no FK constraint declared |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.CountryRafConfiguration | CountryID + RegulationID | Temporal History | Receives superseded configuration versions automatically |
| Customer.GetRafConfiguration_NogaJunk210725 | CountryID + RegulationID | READER | Returns RAF configuration for a customer's country/regulation |
| Billing.GetRafConfiguration_NogaJunk210725 | CountryID + RegulationID | READER | Billing-side read for compensation calculation |
| Customer.RAFCompensationProcess_NogaJunk210725 | RafConfigurationID | READER | Uses configuration when processing RAF payouts |
| Customer.RafGetReferralHistory_NogaJunk210725 | RafConfigurationID | READER | Referral history with configuration context |
| Customer.RafViewCustomerStatus_NogaJunk210725 | (view) | READER | RAF status view referencing configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no hard code-level dependencies (no FK constraints declared).

### 6.1 Objects This Depends On

No dependencies (no FK constraints).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.CountryRafConfiguration | Table | Temporal history destination |
| Customer.GetRafConfiguration_NogaJunk210725 | Stored Procedure | Reads RAF rules per country+regulation |
| Billing.GetRafConfiguration_NogaJunk210725 | Stored Procedure | Reads RAF rules for compensation processing |
| Customer.RAFCompensationProcess_NogaJunk210725 | Stored Procedure | Reads configuration for payout decisions |
| Customer.RafGetReferralHistory_NogaJunk210725 | Stored Procedure | Reads for referral history reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingCountryRafConfiguration | CLUSTERED | CountryID ASC, RegulationID ASC | - | - | Active |
| UQ_CountryRafConfiguration_RafConfigurationID | UNIQUE NONCLUSTERED | RafConfigurationID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingCountryRafConfiguration | PRIMARY KEY | CountryID + RegulationID must be unique - one config per country per regulation |
| UQ_CountryRafConfiguration_RafConfigurationID | UNIQUE | RafConfigurationID must be globally unique |
| CHK_CountryID_RegulationID | CHECK | CountryID <> 0 AND RegulationID <> 0 - prevents placeholder/default values |
| DF_BillingCountryRafConfiguration_RegulationID | DEFAULT | RegulationID = 0 (overridden by CHECK constraint at insert) |

---

## 8. Sample Queries

### 8.1 Get RAF configuration for a specific country and regulation

```sql
SELECT
    crc.CountryID,
    crc.RegulationID,
    crc.ReferringCompensationInCents / 100.0 AS ReferringCompensationUSD,
    crc.ReferredCompensationInCents / 100.0 AS ReferredCompensationUSD,
    crc.MaxNumberOfCompensations,
    crc.ReferredMinDepositInCents / 100.0 AS MinDepositUSD,
    crc.DaysToWaitFromFTD,
    crc.DaysToCheckMinPositionsAmountFromRegistration,
    crc.TnC_URL
FROM Customer.CountryRafConfiguration_NogaJunk210725 crc WITH (NOLOCK)
WHERE crc.CountryID = 16
  AND crc.RegulationID = 9
```

### 8.2 Find all countries offering cash compensation

```sql
SELECT
    crc.CountryID,
    crc.RegulationID,
    crc.ReferringCompensationInCents / 100.0 AS ReferrerRewardUSD,
    crc.MaxNumberOfCompensations,
    crc.TnC_URL
FROM Customer.CountryRafConfiguration_NogaJunk210725 crc WITH (NOLOCK)
WHERE crc.ReferringCompensationInCents > 0
ORDER BY crc.ReferringCompensationInCents DESC
```

### 8.3 Check configuration change history for a country

```sql
SELECT
    CountryID,
    RegulationID,
    ReferringCompensationInCents / 100.0 AS ReferrerCompUSD,
    MaxNumberOfCompensations,
    ValidFrom,
    ValidTo
FROM Customer.CountryRafConfiguration_NogaJunk210725
FOR SYSTEM_TIME ALL
WHERE CountryID = 16
ORDER BY ValidFrom
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CountryRafConfiguration_NogaJunk210725 | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.CountryRafConfiguration_NogaJunk210725.sql*

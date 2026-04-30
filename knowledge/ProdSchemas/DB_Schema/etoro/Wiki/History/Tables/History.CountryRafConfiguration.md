# History.CountryRafConfiguration

> Application-managed temporal history of Refer-A-Friend (RAF) program configuration per country and regulation - 148 versioned snapshots of compensation amounts, deposit minimums, and eligibility rules as they changed through November 2024.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - application temporal (clustered on ValidTo ASC, ValidFrom ASC) |
| **Partition** | No |
| **Temporal** | Application-managed (ValidFrom/ValidTo) |
| **Indexes** | 1 (clustered on ValidTo ASC, ValidFrom ASC) |
| **Compression** | DATA_COMPRESSION=PAGE |

---

## 1. Business Meaning

History.CountryRafConfiguration stores the versioned history of eToro's Refer-A-Friend (RAF) program configuration. RAF is a referral program where existing customers (Referring) earn compensation when they invite new customers (Referred) who then meet qualifying criteria (minimum deposit, minimum trading activity, FTD within a time window).

Each row captures a RAF configuration snapshot for a specific country (CountryID) under a specific regulation (RegulationID), valid between ValidFrom and ValidTo. When a RAF configuration changes - for example, updating compensation amounts, adjusting minimum deposits, or modifying the qualification window - the old configuration is written here.

148 rows covering configurations through November 2024. Observed sample: compensation of 5,000 cents (=$50) for referring, 0 for referred, up to 10 compensations maximum.

---

## 2. Business Logic

### 2.1 RAF Configuration Parameters

**What**: Defines the rules and compensation amounts for the RAF program in a specific country under a specific regulation.

**Key parameters**:

| Column | Meaning |
|--------|---------|
| ReferringCompensationInCents | Bonus paid to the customer who referred (in cents, e.g., 5000 = $50) |
| ReferredCompensationInCents | Bonus paid to the newly referred customer |
| MaxNumberOfCompensations | Maximum number of referral bonuses the referring customer can earn |
| ReferringMinDepositInCents | Minimum deposit required by the referred customer for referring to qualify |
| ReferredMinDepositInCents | Minimum deposit required by the referred customer for referred to qualify |
| DaysToWaitFromFTD | Days to wait after the referred's First Time Deposit before paying the bonus |
| ReferringMinPositionsAmountInCents | Minimum trading positions amount required |
| ReferredMinPositionsAmountInCents | Minimum positions amount for the referred |
| DaysToCheckMinPositionsAmountFromRegistration | Window in which positions requirement must be met |
| TnC_URL | URL to the Terms & Conditions for this RAF configuration |
| CountRAFFromDate | Date from which RAF referrals are counted |
| CheckFTDFromDate | Date from which FTD qualification is checked |
| CheckMinPositionsAmountFromDate | Date from which positions amount check applies |

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 148 |
| **ValidTo Range** | Up to 2024-11-28 |
| **Status** | Inactive since November 2024 |

Sample:

| CountryID | RegulationID | ReferringCompensation | ReferredCompensation | MaxCompensations | RafConfigurationID | ValidFrom | ValidTo |
|----------|-------------|----------------------|---------------------|-----------------|-------------------|-----------|---------|
| 217 | 11 | 5,000 cents ($50) | 0 | 10 | 46 | 2024-08-21 | 2024-11-28 |
| 164 | 1 | 0 | 0 | 3 | 28 | 2024-08-21 | 2024-11-28 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | VERIFIED | Country for which this RAF configuration applies. Implicit FK to Dictionary.Country. |
| 2 | RegulationID | int | NO | - | VERIFIED | Regulatory jurisdiction. Implicit FK to Dictionary.Regulation. Different regulations may have different RAF rules. |
| 3 | ReferringCompensationInCents | int | NO | - | VERIFIED | Bonus in cents for the customer who made the referral. 5000=USD50. 0=no referral bonus. |
| 4 | ReferredCompensationInCents | int | NO | - | VERIFIED | Bonus in cents for the newly referred customer. Often 0. |
| 5 | MaxNumberOfCompensations | int | NO | - | VERIFIED | Maximum number of successful referrals for which the referring customer earns bonuses. |
| 6 | ReferringMinDepositInCents | int | NO | - | VERIFIED | Minimum deposit amount (in cents) the referred customer must make for the referring bonus to be paid. |
| 7 | ReferredMinDepositInCents | int | NO | - | VERIFIED | Minimum deposit amount (in cents) the referred customer must make for their own referred bonus. |
| 8 | CountRAFFromDate | datetime | YES | - | CODE-BACKED | Date from which referrals are counted for this configuration. NULL=no date restriction. |
| 9 | CheckFTDFromDate | datetime | YES | - | CODE-BACKED | Date from which the First Time Deposit (FTD) qualification check applies. NULL=no restriction. |
| 10 | ValidFrom | datetime2(7) | NO | - | VERIFIED | When this RAF configuration version became effective. |
| 11 | ValidTo | datetime2(7) | NO | - | VERIFIED | When this version was superseded. Clustered index leading column. |
| 12 | DaysToWaitFromFTD | int | NO | - | CODE-BACKED | Number of days to wait after the referred customer's FTD before triggering the bonus payment. |
| 13 | ReferringMinPositionsAmountInCents | int | NO | - | CODE-BACKED | Minimum trading amount (cents) the referred must achieve for referring bonus. 0=no requirement. |
| 14 | ReferredMinPositionsAmountInCents | int | NO | - | CODE-BACKED | Minimum trading amount the referred must achieve for their own bonus. |
| 15 | CheckMinPositionsAmountFromDate | datetime | YES | - | CODE-BACKED | Date from which the minimum positions amount check applies. |
| 16 | DaysToCheckMinPositionsAmountFromRegistration | int | NO | - | CODE-BACKED | Time window (days from registration) within which the positions requirement must be met. |
| 17 | TnC_URL | nvarchar(300) | NO | - | CODE-BACKED | URL to the RAF program Terms & Conditions for this country/regulation. |
| 18 | Trace | nvarchar(733) | NO | ' ' | VERIFIED | Audit trail. Default is a single space (DF_TraceEmpty). When populated, JSON with HostName/AppName. |
| 19 | RafConfigurationID | int | NO | 0 | CODE-BACKED | ID from the base RAF configuration table. DEFAULT=0. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit | Country for the RAF program. |
| RegulationID | Dictionary.Regulation | Implicit | Regulatory jurisdiction. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Compression |
|-----------|------|-------------|-------------|
| ix_CountryRafConfiguration | CLUSTERED | ValidTo ASC, ValidFrom ASC | PAGE |

---

*Generated: 2026-03-19 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.CountryRafConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.CountryRafConfiguration.sql*

# Customer.FN_RafViewCustomerStatusByDate_NogaJunk210725

> Deprecated historical RAF eligibility function: given a point-in-time date, returns each customer's RAF (Refer-A-Friend) configuration thresholds and actual performance metrics as of that date, using temporal table lookups.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Inline TVF |
| **Key Identifier** | @V_Date datetime (point-in-time parameter) |
| **Partition** | N/A |
| **Indexes** | N/A (function) |

---

## 1. Business Meaning

Customer.FN_RafViewCustomerStatusByDate_NogaJunk210725 is a point-in-time RAF eligibility analysis function. Given a @V_Date parameter, it returns one row per eligible customer showing both the RAF configuration thresholds that applied on that date AND the customer's actual performance metrics (deposits, positions, referrals). This allows compliance and marketing teams to audit what a customer's RAF compensation eligibility looked like at any historical point in time.

The function uses temporal table queries (`FOR SYSTEM_TIME AS OF @V_Date`) on Customer.CountryRafConfiguration and Customer.RafConfigurationModels. This means the RAF configuration values returned are historically accurate - if the minimum deposit threshold changed on June 1, querying @V_Date=May 31 vs June 2 returns different thresholds for the same customer.

The "NogaJunk210725" suffix indicates this function was deprecated by Noga around mid-2025. The function was created in May 2023 and enhanced in August 2023 to add temporal table support for historical data analysis. As of 2026, it remains in the codebase but is no longer actively used.

---

## 2. Business Logic

### 2.1 Temporal Point-in-Time Configuration Lookup

**What**: RAF rules (minimum deposit, minimum positions, compensation amounts) change over time. This function retrieves what the rules WERE on @V_Date, not what they are today.

**Columns/Parameters Involved**: `@V_Date`, `CountRAFFromDate`, `RafConfigurationID`, `ReferringMinPositionsAmountInCents`, `ReferredMinPositionsAmountInCents`, `ReferringMinDepositInCents`, `ReferredMinDepositInCents`, `DaysToWaitFromFTD`, `CheckFTDFromDate`, `CheckMinPositionsAmountFromDate`

**Rules**:
- `Customer.CountryRafConfiguration FOR SYSTEM_TIME AS OF @V_Date` returns the configuration row that was active on @V_Date
- `Customer.RafConfigurationModels FOR SYSTEM_TIME AS OF @V_Date` returns the compensation model active on that date
- The joining condition is `crc.RegulationID = bc.DesignatedRegulationID AND cc.CountryID = crc.CountryID` - each customer gets the RAF config for their country+regulation combination
- Customers with no matching CountryRafConfiguration on @V_Date (country not eligible for RAF on that date) are excluded by the INNER JOIN

### 2.2 Compensation Model Selection (PI vs Club)

**What**: eToro has two RAF compensation models: PI (Popular Investor level-based) and Club (customer-tier-based). The function selects whichever model offers higher total compensation potential.

**Columns/Parameters Involved**: `MaxNumberOfCompensations`, `ReferringCompensationInCents`, `PlayerLevelID`, `GuruStatusID`

**Rules**:
- `RM_Club` (RafModelTypeID=1): Club model, joined on `RafModelID = ISNULL(cc.PlayerLevelID, 0)`
- `RM_PI` (RafModelTypeID=2): PI model, joined on `RafModelID = ISNULL(bc.GuruStatusID, 0)`
- Selection logic: whichever model has higher `ReferringCompensationInCents * MaxNumberOfCompensations` wins
- If both models are NULL, the base CountryRafConfiguration values are used as fallback
- `MaxNumberOfCompensations`: the winning model's max number of referrals that qualify for compensation
- `ReferringCompensationInCents`: amount paid to the REFERRING customer (in cents) from the winning model

**Diagram**:
```
RM_PI (RafModelTypeID=2) value: PI.Comp * PI.MaxComp
RM_Club (RafModelTypeID=1) value: Club.Comp * Club.MaxComp

if PI.value > Club.value AND PI.MaxComp IS NOT NULL  -> use PI model
elif Club.value >= PI.value AND Club.MaxComp IS NOT NULL -> use Club model
elif both NULL -> use CountryRafConfiguration.default values
```

### 2.3 Actual vs Configured Threshold Comparison

**What**: The function returns both the configured RAF thresholds AND the customer's actual metrics, enabling direct eligibility check at the row level.

**Columns/Parameters Involved**: `Actual_TotalInvestment`, `ReferringMinPositionsAmountInCents`, `Actual_DepositsInCents`, `ReferringMinDepositInCents`, `Actual_DaysSinceFTD`, `DaysToWaitFromFTD`, `Actual_NumberOfCompensations`, `MaxNumberOfCompensations`

**Rules**:
- `Actual_TotalInvestment = catad.TotalInvestment * 100` (converted to cents to match ReferringMinPositionsAmountInCents)
- `Actual_DepositsInCents = SUM(Amount * ExchangeRate * 100) WHERE IsFTD=1 AND PaymentStatusID=2` - approved FTD deposits only
- `Actual_FTDDate = MIN(PaymentDate)` - first deposit date
- `Actual_DaysSinceFTD = DATEDIFF(d, FTDDate, GETUTCDATE())` - days since first deposit (NOTE: uses current time, not @V_Date)
- `Actual_NumberOfCompensations = COUNT(*) FROM Customer.RAFGiven WHERE ReferringCID=CID AND RowInserted <= @V_Date` - referrals compensated up to @V_Date
- Eligibility check: Actual >= Configured for each threshold

---

## 3. Data Overview

N/A for Inline TVF. This function requires a @V_Date parameter and returns one row per eligible customer. In a test environment with temporal tables, representative output would be:

| CID | GCID | CountryID | ReferringCompensationInCents | Actual_DepositsInCents | Actual_NumberOfCompensations | Meaning |
|-----|------|-----------|------------------------------|------------------------|------------------------------|---------|
| (referring customer) | (GCID) | 100 | 2000 | 50000 | 3 | US customer on PI model, $500 FTD, earned 3 RAF compensations of $20 each. |
| (new customer) | (GCID) | 42 | 1500 | 0 | 0 | UK customer with no deposits yet - FTDDate=NULL, not yet eligible. |

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @V_Date | datetime | NO | - | CODE-BACKED | Point-in-time date for temporal table lookups. CountryRafConfiguration and RafConfigurationModels are queried AS OF this date. Use the customer's registration date + 10 days for eligibility checks at registration time (per code comment: "take the configuration date as 10 days after registration"). |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID. From Customer.CustomerStatic. INNER JOIN entry point. |
| 2 | GCID | int | YES | - | VERIFIED | Group Customer ID - cross-product identity key. From Customer.CustomerStatic. |
| 3 | Registered | datetime | YES | - | VERIFIED | Customer registration date. From Customer.CustomerStatic. Used by callers to compute "@V_Date = Registered + 10 days" per code comment. |
| 4 | CountRAFFromDate | datetime | YES | - | CODE-BACKED | Date from which RAF referrals should be counted for this customer's country+regulation config. From Customer.CountryRafConfiguration AS OF @V_Date. |
| 5 | RafConfigurationID | int | YES | - | CODE-BACKED | FK to the RAF configuration set for this customer's country. From Customer.CountryRafConfiguration AS OF @V_Date. Links RM_Club and RM_PI model lookups. |
| 6 | CountryID | int | NO | - | VERIFIED | Customer's country of residence. From Customer.CustomerStatic. Used to join CountryRafConfiguration (country + regulation eligibility). |
| 7 | DesignatedRegulationID | int | YES | - | CODE-BACKED | Regulatory entity assigned to this customer by compliance. From BackOffice.Customer. Used with CountryID to select the applicable RAF country configuration. |
| 8 | VerificationLevelID | int | YES | - | CODE-BACKED | Customer KYC verification tier. From BackOffice.Customer. Used by callers to check if customer meets verification threshold for RAF participation. |
| 9 | ReferringMinPositionsAmountInCents | int | YES | - | CODE-BACKED | Minimum total investment (in cents) the REFERRING customer must have to qualify. From CountryRafConfiguration AS OF @V_Date. Compare to Actual_TotalInvestment. |
| 10 | ReferredMinPositionsAmountInCents | int | YES | - | CODE-BACKED | Minimum total investment (in cents) the REFERRED customer must reach. From CountryRafConfiguration AS OF @V_Date. |
| 11 | Actual_TotalInvestment | decimal | YES | - | CODE-BACKED | Customer's actual lifetime investment in cents: BackOffice.CustomerAllTimeAggregatedData.TotalInvestment * 100. Compare to ReferringMinPositionsAmountInCents. |
| 12 | ReferringMinDepositInCents | int | YES | - | CODE-BACKED | Minimum FTD amount (in cents) the REFERRING customer must have deposited. From CountryRafConfiguration AS OF @V_Date. |
| 13 | ReferredMinDepositInCents | int | YES | - | CODE-BACKED | Minimum FTD amount (in cents) the REFERRED customer must deposit. From CountryRafConfiguration AS OF @V_Date. |
| 14 | Actual_DepositsInCents | decimal | YES | - | CODE-BACKED | Customer's actual approved FTD deposit total in cents: SUM(Amount * ExchangeRate * 100) from Billing.Deposit WHERE IsFTD=1 AND PaymentStatusID=2 (approved). Compare to ReferringMinDepositInCents. NULL if no FTD deposits. |
| 15 | Actual_FTDDate | datetime | YES | - | CODE-BACKED | Customer's first approved deposit date: MIN(PaymentDate) from Billing.Deposit WHERE IsFTD=1 AND PaymentStatusID=2. NULL for customers with no deposits. |
| 16 | Actual_DaysSinceFTD | int | YES | - | CODE-BACKED | Days elapsed since first deposit: DATEDIFF(d, Actual_FTDDate, GETUTCDATE()). NOTE: uses current UTC time, not @V_Date - so this is not fully point-in-time. NULL when Actual_FTDDate is NULL. |
| 17 | DaysToWaitFromFTD | int | YES | - | CODE-BACKED | Minimum days after FTD before RAF compensation can be paid. From CountryRafConfiguration AS OF @V_Date. Compare to Actual_DaysSinceFTD. |
| 18 | ReferralID | int | YES | - | VERIFIED | ID of the customer who referred this customer (the referrer's CID). From Customer.CustomerStatic. NULL for organically registered customers. |
| 19 | PlayerLevelID | int | NO | - | VERIFIED | Customer tier for Club model matching: ISNULL(cc.PlayerLevelID, 0). From Customer.CustomerStatic. Used to join RafConfigurationModels (RM_Club) where RafModelID=PlayerLevelID. 0=Standard, 4=Popular Investor. |
| 20 | GuruStatusID | int | NO | - | CODE-BACKED | Popular Investor status level for PI model matching: ISNULL(bc.GuruStatusID, 0). From BackOffice.Customer. Used to join RafConfigurationModels (RM_PI) where RafModelID=GuruStatusID. 0=not a PI, higher values=PI tier. |
| 21 | CheckFTDFromDate | datetime | YES | - | CODE-BACKED | Date from which FTD deposits must have occurred to count for RAF. From CountryRafConfiguration AS OF @V_Date. Deposits before this date may not qualify. |
| 22 | CheckMinPositionsAmountFromDate | datetime | YES | - | CODE-BACKED | Date from which positions must have been opened to count toward the minimum positions amount. From CountryRafConfiguration AS OF @V_Date. |
| 23 | MaxNumberOfCompensations | int | YES | - | CODE-BACKED | Maximum referral compensations this customer can receive: selected from the higher-value model (PI vs Club). Falls back to CountryRafConfiguration.MaxNumberOfCompensations if both models are NULL. Caps the lifetime number of paid referrals. |
| 24 | Actual_NumberOfCompensations | int | YES | - | CODE-BACKED | Number of RAF compensations already issued to this customer as REFERRING party: COUNT(*) FROM Customer.RAFGiven WHERE ReferringCID=CID AND RowInserted<=@V_Date. Compare to MaxNumberOfCompensations. |
| 25 | ReferringCompensationInCents | int | YES | - | CODE-BACKED | Per-referral compensation amount (in cents) for the REFERRING customer: selected from the higher-value model (PI vs Club), falling back to CountryRafConfiguration.ReferringCompensationInCents if no model match. Multiply by MaxNumberOfCompensations for total potential earnings. |
| 26 | ReferredCompensationInCents | int | YES | - | CODE-BACKED | Per-referral compensation amount (in cents) for the REFERRED (new) customer. Always from CountryRafConfiguration.ReferredCompensationInCents AS OF @V_Date (not model-dependent). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, GCID, Registered, CountryID, ReferralID, PlayerLevelID | Customer.CustomerStatic | INNER JOIN (via BackOffice.CustomerAllTimeAggregatedData) | Customer profile and acquisition data |
| DesignatedRegulationID, VerificationLevelID, GuruStatusID | BackOffice.Customer | INNER JOIN on CID | Regulatory assignment and PI status |
| Actual_TotalInvestment | BackOffice.CustomerAllTimeAggregatedData | INNER JOIN on CID | Lifetime investment aggregate for eligibility check |
| CountRAFFromDate, RafConfigurationID, thresholds | Customer.CountryRafConfiguration | INNER JOIN FOR SYSTEM_TIME AS OF @V_Date | Point-in-time RAF config for country+regulation |
| MaxNumberOfCompensations (Club), ReferringCompensationInCents (Club) | Customer.RafConfigurationModels | LEFT JOIN (RM_Club, RafModelTypeID=1) FOR SYSTEM_TIME AS OF @V_Date | Club-tier compensation model |
| MaxNumberOfCompensations (PI), ReferringCompensationInCents (PI) | Customer.RafConfigurationModels | LEFT JOIN (RM_PI, RafModelTypeID=2) FOR SYSTEM_TIME AS OF @V_Date | PI-tier compensation model |
| Actual_NumberOfCompensations | Customer.RAFGiven | CROSS APPLY (COUNT where RowInserted<=@V_Date) | Compensation history as of point-in-time date |
| Actual_DepositsInCents, Actual_FTDDate | Billing.Deposit | CROSS APPLY (SUM+MIN where IsFTD=1, PaymentStatusID=2) | Approved first-time deposit summary |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Function is marked deprecated (NogaJunk210725). Related functions: Customer.GetRafConfiguration_NogaJunk210725, Customer.GetRafStatusByGCID_NogaJunk210725.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.FN_RafViewCustomerStatusByDate_NogaJunk210725 (function)
|-  BackOffice.CustomerAllTimeAggregatedData (table) [cross-schema]
|-  Customer.CustomerStatic (table)
|-  BackOffice.Customer (table) [cross-schema]
|-  Customer.CountryRafConfiguration (table) [temporal, FOR SYSTEM_TIME AS OF @V_Date]
|-  Customer.RafConfigurationModels (table) [temporal, FOR SYSTEM_TIME AS OF @V_Date, x2: RM_Club + RM_PI]
|-  Customer.RAFGiven (table) [CROSS APPLY]
`-  Billing.Deposit (table) [cross-schema, CROSS APPLY]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerAllTimeAggregatedData | Table (cross-schema) | INNER JOIN on CID - entry point; provides TotalInvestment for Actual_TotalInvestment |
| Customer.CustomerStatic | Table | INNER JOIN on CID - customer profile (GCID, CountryID, Registered, ReferralID, PlayerLevelID) |
| BackOffice.Customer | Table (cross-schema) | INNER JOIN on CID - DesignatedRegulationID, VerificationLevelID, GuruStatusID |
| Customer.CountryRafConfiguration | Table (temporal) | INNER JOIN FOR SYSTEM_TIME AS OF @V_Date - RAF thresholds for country+regulation |
| Customer.RafConfigurationModels | Table (temporal) | LEFT JOIN x2 (RM_Club, RM_PI) FOR SYSTEM_TIME AS OF @V_Date - compensation model selection |
| Customer.RAFGiven | Table | CROSS APPLY - count of compensations issued up to @V_Date |
| Billing.Deposit | Table (cross-schema) | CROSS APPLY - FTD deposit summary (amount + date) |

### 6.2 Objects That Depend On This

No dependents found in SSDT repository. Function is marked deprecated (NogaJunk210725).

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN to BackOffice.CustomerAllTimeAggregatedData | Data filter | Only customers with a BackOffice aggregated record appear |
| INNER JOIN to BackOffice.Customer | Data filter | Only customers with a BackOffice profile appear |
| INNER JOIN to CountryRafConfiguration | Data filter | Only customers whose country+regulation had RAF configured on @V_Date appear |
| FOR SYSTEM_TIME AS OF @V_Date | Temporal filter | Configuration tables queried at a specific historical point; @V_Date must be within system-versioning retention window |
| IsFTD=1 AND PaymentStatusID=2 | Data filter | Only approved first-time deposits count toward Actual_DepositsInCents |
| RowInserted <= @V_Date | Temporal filter | Only RAF compensations recorded before @V_Date count toward Actual_NumberOfCompensations |
| Actual_DaysSinceFTD uses GETUTCDATE() | Non-temporal inconsistency | This column is NOT point-in-time - it uses current time, not @V_Date. All other "Actual_" columns are correctly time-bounded. |

---

## 8. Sample Queries

### 8.1 Check RAF eligibility for all customers as of 30 days ago

```sql
SELECT
    CID,
    GCID,
    CountryID,
    ReferringMinDepositInCents / 100.0 AS MinDepositUSD,
    Actual_DepositsInCents / 100.0 AS ActualDepositUSD,
    ReferringMinPositionsAmountInCents / 100.0 AS MinInvestmentUSD,
    Actual_TotalInvestment / 100.0 AS ActualInvestmentUSD,
    MaxNumberOfCompensations,
    Actual_NumberOfCompensations,
    ReferringCompensationInCents / 100.0 AS CompensationPerReferralUSD
FROM Customer.FN_RafViewCustomerStatusByDate_NogaJunk210725(DATEADD(day, -30, GETUTCDATE()))
WITH (NOLOCK);
```

### 8.2 Customers eligible for RAF compensation on a specific historical date

```sql
DECLARE @CheckDate datetime = '2024-06-01';
SELECT
    CID,
    GCID,
    ReferralID,
    Actual_DepositsInCents,
    ReferringMinDepositInCents,
    Actual_DaysSinceFTD,
    DaysToWaitFromFTD,
    MaxNumberOfCompensations,
    Actual_NumberOfCompensations
FROM Customer.FN_RafViewCustomerStatusByDate_NogaJunk210725(@CheckDate)
WITH (NOLOCK)
WHERE Actual_DepositsInCents >= ReferringMinDepositInCents
  AND Actual_NumberOfCompensations < MaxNumberOfCompensations
  AND ReferralID IS NOT NULL;
```

### 8.3 Compare PI vs Club compensation model for a date

```sql
SELECT
    CID,
    PlayerLevelID,
    GuruStatusID,
    ReferringCompensationInCents / 100.0 AS WinningModelCompUSD,
    MaxNumberOfCompensations,
    (ReferringCompensationInCents * MaxNumberOfCompensations) / 100.0 AS TotalPotentialUSD
FROM Customer.FN_RafViewCustomerStatusByDate_NogaJunk210725('2024-01-01')
WITH (NOLOCK)
ORDER BY TotalPotentialUSD DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (function) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.FN_RafViewCustomerStatusByDate_NogaJunk210725 | Type: Inline TVF | Source: etoro/etoro/Customer/Functions/Customer.FN_RafViewCustomerStatusByDate_NogaJunk210725.sql*

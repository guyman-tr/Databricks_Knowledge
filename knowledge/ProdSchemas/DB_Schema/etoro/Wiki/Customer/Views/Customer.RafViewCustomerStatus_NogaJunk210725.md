# Customer.RafViewCustomerStatus_NogaJunk210725

> RAF eligibility status view (Noga Rozen, May 2023): for each customer in a RAF-eligible country, presents the applicable compensation configuration alongside the customer's actual deposit history, position activity, and number of compensations already given - providing a side-by-side comparison of threshold requirements vs. actual status.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.RafViewCustomerStatus_NogaJunk210725 was created by Noga Rozen (comment: "20/5/23 Noga, will help us check If GCID eligible for RAF") to provide a comprehensive RAF eligibility dashboard in a single view. Each row represents a customer who is in a RAF-eligible country (Dictionary.Country.IsEligibleForRAFBonusCountry=1) and has a matching country+regulation RAF configuration. The view pairs the applicable RAF rules (minimum deposits, minimum positions, waiting periods, compensation amounts) directly alongside the customer's actual data (FTD deposit amount, FTD date, days since FTD, actual number of compensations received, total investment), making RAF eligibility checks a simple comparison without multi-table joins.

The view implements the "best compensation wins" logic from RafConfigurationModels: for each customer, both the Club model (by PlayerLevelID) and the PI model (by GuruStatusID) are LEFT JOINED; the CASE expression selects whichever model offers higher total potential payout (ReferringCompensationInCents * MaxNumberOfCompensations), falling back to the base CountryRafConfiguration values if neither model applies.

Filter logic: only customers satisfying ALL of these conditions are included - (1) exists in BackOffice.CustomerAllTimeAggregatedData, (2) exists in BackOffice.Customer, (3) their country+regulation has a CountryRafConfiguration row, (4) their country has IsEligibleForRAFBonusCountry=1 in Dictionary.Country. Customers in non-RAF-eligible countries or without complete profile data are excluded.

Note: The view references `Customer.CountryRafConfiguration` and `Customer.RafConfigurationModels` (without the _NogaJunk210725 suffix). These are likely synonyms or the view DDL predates the suffix addition.

---

## 2. Business Logic

### 2.1 Best Compensation Wins Model Selection

**What**: The RAF system supports two compensation model types (Club by PlayerLevel, PI by GuruStatus). The view selects whichever offers higher total payout potential.

**Columns/Parameters Involved**: `MaxNumberOfCompensations`, `ReferringCompensationInCents`, `PlayerLevelID`, `GuruStatusID`

**Rules**:
- RM_PI (LEFT JOIN RafConfigurationModels WHERE RafModelTypeID=2 AND RafModelID=ISNULL(GuruStatusID,0))
- RM_Club (LEFT JOIN RafConfigurationModels WHERE RafModelTypeID=1 AND RafModelID=ISNULL(PlayerLevelID,0))
- If PI total (RM_PI.ReferringCompensationInCents * RM_PI.MaxNumberOfCompensations) > Club total AND PI model exists: use PI values
- Elif Club total >= PI total AND Club model exists: use Club values
- Elif both models are NULL (no override): use base crc.MaxNumberOfCompensations / crc.ReferringCompensationInCents
- ReferredCompensationInCents: always from the base crc table (model tables have 0 for referred compensation)

**Diagram**:
```
Customer's RAF compensation tier:
 |
 +-> Look up Club model (RafModelTypeID=1, RafModelID=PlayerLevelID)
 |     -> RM_Club.ReferringCompensationInCents, MaxNumberOfCompensations
 |
 +-> Look up PI model (RafModelTypeID=2, RafModelID=GuruStatusID)
       -> RM_PI.ReferringCompensationInCents, MaxNumberOfCompensations
 |
 CASE: IF PI_total > Club_total AND PI exists -> use PI
       ELIF Club_total >= PI_total AND Club exists -> use Club
       ELIF both NULL -> use base crc values
```

### 2.2 Actual vs Threshold Comparison

**What**: The "Actual_" prefixed columns present the customer's real activity alongside the thresholds they must meet, enabling direct RAF eligibility comparison.

**Columns/Parameters Involved**: `Actual_TotalInvestment`, `ReferringMinPositionsAmountInCents`, `Actual_DepositsInCents`, `ReferredMinDepositInCents`, `Actual_DaysSinceFTD`, `DaysToWaitFromFTD`, `Actual_NumberOfCompensations`, `MaxNumberOfCompensations`

**Rules**:
- Actual_TotalInvestment (cents): catad.TotalInvestment * 100 -> compare to ReferringMinPositionsAmountInCents
- Actual_DepositsInCents: SUM(Amount * ExchangeRate * 100) from Billing.Deposit WHERE IsFTD=1 AND PaymentStatusID=2 -> compare to ReferredMinDepositInCents
- Actual_DaysSinceFTD: DATEDIFF(d, FTDDate, GETUTCDATE()) -> compare to DaysToWaitFromFTD
- Actual_NumberOfCompensations: COUNT(*) from Customer.RAFGiven WHERE ReferringCID=CID -> compare to MaxNumberOfCompensations

---

## 3. Data Overview

N/A for view - returns one row per customer in RAF-eligible countries with complete profile data. Row count depends on how many countries have IsEligibleForRAFBonusCountry=1 and matching CountryRafConfiguration entries.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID. From Customer.CustomerStatic (cc). |
| 2 | GCID | int | YES | - | VERIFIED | Group Customer ID. From CustomerStatic (cc). Used by callers to identify the customer cross-product. |
| 3 | Registered | datetime | NO | - | VERIFIED | Customer registration date. From CustomerStatic (cc). |
| 4 | CountRAFFromDate | datetime | YES | - | VERIFIED | Date from which RAF referrals are counted for this configuration. From CountryRafConfiguration (crc). Referrals before this date are ignored. |
| 5 | RafConfigurationID | int | NO | - | VERIFIED | RAF configuration identifier. From CountryRafConfiguration. Links to RafConfigurationModels for model-level overrides. |
| 6 | CountryID | int | NO | - | VERIFIED | Customer's country of residence. From CustomerStatic (cc). Used with DesignatedRegulationID to find the matching CountryRafConfiguration row. |
| 7 | DesignatedRegulationID | int | NO | - | VERIFIED | The regulation under which this customer operates. From BackOffice.Customer (bc). Together with CountryID, uniquely identifies the applicable CountryRafConfiguration row. |
| 8 | VerificationLevelID | int | YES | - | VERIFIED | KYC verification level. From BackOffice.Customer (bc). Affects RAF eligibility criteria in some configurations. |
| 9 | ReferringMinPositionsAmountInCents | int | YES | - | VERIFIED | Minimum total position amount (in cents) the REFERRING customer must have to qualify for RAF compensation. From CountryRafConfiguration (crc). Compare to Actual_TotalInvestment. |
| 10 | ReferredMinPositionsAmountInCents | int | YES | - | VERIFIED | Minimum total position amount (in cents) the REFERRED customer must achieve to trigger compensation. From CountryRafConfiguration (crc). |
| 11 | Actual_TotalInvestment | decimal | YES | - | VERIFIED | Actual total investment of the REFERRING customer in cents: BackOffice.CustomerAllTimeAggregatedData.TotalInvestment * 100. Compare to ReferringMinPositionsAmountInCents to check if referring threshold is met. |
| 12 | ReferringMinDepositInCents | int | YES | - | VERIFIED | Minimum deposit (in cents) the REFERRING customer must have made to qualify. From CountryRafConfiguration (crc). |
| 13 | ReferredMinDepositInCents | int | YES | - | VERIFIED | Minimum first-time deposit (in cents) the REFERRED customer must make. From CountryRafConfiguration (crc). |
| 14 | Actual_DepositsInCents | decimal | YES | - | VERIFIED | Actual FTD (first-time deposit) amount of this customer in cents: SUM(Amount * ExchangeRate * 100) WHERE IsFTD=1 AND PaymentStatusID=2 from Billing.Deposit. NULL if no approved FTD exists. Compare to ReferredMinDepositInCents or ReferringMinDepositInCents. |
| 15 | Actual_FTDDate | datetime | YES | - | VERIFIED | Date of this customer's first approved FTD payment. MIN(PaymentDate) from Billing.Deposit WHERE IsFTD=1 AND PaymentStatusID=2. NULL if no FTD. |
| 16 | Actual_DaysSinceFTD | int | YES | - | VERIFIED | Number of days since the customer's FTD: DATEDIFF(d, FTDDate, GETUTCDATE()). NULL if no FTD. Compare to DaysToWaitFromFTD to check if the waiting period has elapsed. |
| 17 | DaysToWaitFromFTD | int | YES | - | VERIFIED | Minimum days to wait after the referred customer's FTD before compensation can be paid. From CountryRafConfiguration (crc). Typically 7 days. |
| 18 | ReferralID | int | YES | - | VERIFIED | CID of the customer who referred this customer (their referring partner). From CustomerStatic (cc). NULL if no referral. The RAF process checks this to identify the referrer-referred pair. |
| 19 | PlayerLevelID | int | NO | - | VERIFIED | Customer's player tier: ISNULL(cc.PlayerLevelID, 0). Used to match the Club model (RafModelTypeID=1, RafModelID=PlayerLevelID) in RafConfigurationModels. |
| 20 | GuruStatusID | int | NO | - | VERIFIED | Customer's Popular Investor guru status: ISNULL(bc.GuruStatusID, 0). From BackOffice.Customer. Used to match the PI model (RafModelTypeID=2, RafModelID=GuruStatusID) in RafConfigurationModels. |
| 21 | CheckFTDFromDate | datetime | YES | - | VERIFIED | Date from which FTDs are counted for RAF eligibility. From CountryRafConfiguration. FTDs before this date are excluded. |
| 22 | CheckMinPositionsAmountFromDate | datetime | YES | - | VERIFIED | Date from which minimum position amounts are tracked. From CountryRafConfiguration. Positions before this date are excluded from Actual_TotalInvestment-like checks. |
| 23 | MaxNumberOfCompensations | int | YES | - | VERIFIED | Maximum number of RAF compensations the REFERRING customer can receive. Computed: best of RM_PI.MaxNumberOfCompensations, RM_Club.MaxNumberOfCompensations, or crc.MaxNumberOfCompensations (whichever model offers higher total payout). Compare to Actual_NumberOfCompensations to see remaining quota. |
| 24 | Actual_NumberOfCompensations | int | NO | - | VERIFIED | Actual number of RAF compensations already given to this customer as a referrer: COUNT(*) from Customer.RAFGiven WHERE ReferringCID=CID. Compare to MaxNumberOfCompensations. |
| 25 | ReferringCompensationInCents | int | YES | - | VERIFIED | Amount in cents the REFERRING customer would receive per successful referral. Computed: best of RM_PI.ReferringCompensationInCents, RM_Club.ReferringCompensationInCents, or crc.ReferringCompensationInCents (same best-wins logic as MaxNumberOfCompensations). |
| 26 | ReferredCompensationInCents | int | YES | - | VERIFIED | Amount in cents the REFERRED customer would receive for joining via this referral. Always from crc.ReferredCompensationInCents (model tables always have 0 for referred compensation - only referrers get model-level overrides). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, GCID, Registered, etc. | Customer.CustomerStatic | INNER JOIN (catad -> cc) | Customer identity and ReferralID |
| DesignatedRegulationID, VerificationLevelID, GuruStatusID | BackOffice.Customer | INNER JOIN on CID | Regulation, KYC level, PI status |
| - | BackOffice.CustomerAllTimeAggregatedData | FROM (base, catad) | TotalInvestment for position threshold check |
| RafConfigurationID, thresholds | Customer.CountryRafConfiguration | INNER JOIN on RegulationID+CountryID | RAF rules for this customer's country |
| MaxNumberOfCompensations, etc. | Customer.RafConfigurationModels | LEFT JOIN x2 (Club+PI) | Model-level compensation overrides |
| CountryID | Dictionary.Country | INNER JOIN (IsEligibleForRAFBonusCountry=1) | Eligibility filter - only RAF-eligible countries |
| Actual_NumberOfCompensations | Customer.RAFGiven | CROSS APPLY COUNT(*) | Actual compensations already given |
| Actual_DepositsInCents, Actual_FTDDate | Billing.Deposit | CROSS APPLY SUM/MIN | First-time deposit data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RafSuspectedAbuser_NogaJunk210725 | CID, ReferringCID | Reader (likely) | Checks RAF status for suspected abusers |
| (RAF analysis procedures) | CID, GCID | Reader | RAF eligibility checking and analysis |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RafViewCustomerStatus_NogaJunk210725 (view)
├── BackOffice.CustomerAllTimeAggregatedData (table)
├── Customer.CustomerStatic (table)
├── BackOffice.Customer (table)
├── Customer.CountryRafConfiguration (table) [note: non-suffixed name - likely synonym]
├── Customer.RafConfigurationModels (table) x2 [note: non-suffixed name - likely synonym]
├── Dictionary.Country (table)
├── Customer.RAFGiven (table) [CROSS APPLY]
└── Billing.Deposit (table) [CROSS APPLY]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerAllTimeAggregatedData | Table | FROM base - TotalInvestment for position threshold |
| Customer.CustomerStatic | Table | INNER JOIN on CID - customer identity |
| BackOffice.Customer | Table | INNER JOIN on CID - regulation + PI status |
| Customer.CountryRafConfiguration | Table | INNER JOIN - RAF rules by country/regulation |
| Customer.RafConfigurationModels | Table | LEFT JOIN x2 - Club and PI model overrides |
| Dictionary.Country | Table | INNER JOIN (IsEligibleForRAFBonusCountry=1) - eligibility filter |
| Customer.RAFGiven | Table | CROSS APPLY COUNT - actual compensations given |
| Billing.Deposit | Table | CROSS APPLY SUM/MIN - FTD data |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None. No SCHEMABINDING declared.

---

## 8. Sample Queries

### 8.1 Check RAF eligibility status for a specific customer
```sql
SELECT
    CID, GCID, CountryID, DesignatedRegulationID,
    ReferringMinDepositInCents, Actual_DepositsInCents,
    ReferringMinPositionsAmountInCents, Actual_TotalInvestment,
    DaysToWaitFromFTD, Actual_DaysSinceFTD,
    MaxNumberOfCompensations, Actual_NumberOfCompensations,
    ReferringCompensationInCents, ReferredCompensationInCents
FROM Customer.RafViewCustomerStatus_NogaJunk210725 WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.2 Find customers eligible for more RAF compensations
```sql
SELECT CID, GCID, CountryID, Actual_NumberOfCompensations, MaxNumberOfCompensations,
       MaxNumberOfCompensations - Actual_NumberOfCompensations AS RemainingQuota,
       ReferringCompensationInCents
FROM Customer.RafViewCustomerStatus_NogaJunk210725 WITH (NOLOCK)
WHERE Actual_NumberOfCompensations < MaxNumberOfCompensations
  AND Actual_DepositsInCents >= ReferringMinDepositInCents
ORDER BY RemainingQuota DESC;
```

### 8.3 Check RAF configuration for a referral pair
```sql
SELECT
    referrer.CID AS ReferrerCID,
    referrer.Actual_TotalInvestment, referrer.ReferringMinPositionsAmountInCents,
    referrer.Actual_DaysSinceFTD, referrer.DaysToWaitFromFTD,
    referrer.Actual_NumberOfCompensations, referrer.MaxNumberOfCompensations,
    referrer.ReferringCompensationInCents
FROM Customer.RafViewCustomerStatus_NogaJunk210725 referrer WITH (NOLOCK)
WHERE referrer.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 26 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.RafViewCustomerStatus_NogaJunk210725 | Type: View | Source: etoro/etoro/Customer/Views/Customer.RafViewCustomerStatus_NogaJunk210725.sql*

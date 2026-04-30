# Customer.GetRafStatusByGCID_NogaJunk210725

> Returns the RAF (Refer-A-Friend) program status and fraud flag for a referring customer by GCID, determining how many compensations they have received relative to their tier-specific maximum.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (referring customer); returns RafStatus (0-3) and IsFraud (0/1) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRafStatusByGCID_NogaJunk210725 determines a referring customer's eligibility to receive further RAF compensations. It is called by the UI when a user requests information on their referrals (per PART-475, authored by Noga Rozen, Oct 2022).

The procedure evaluates two things:
1. **RAF status**: Has the customer started referring? Have they hit their compensation cap?
2. **Fraud status**: Is the customer flagged as fraudulent in Customer.FraudUsers?

The `_NogaJunk210725` suffix marks this as a working/experimental SP in the RAF subsystem (July 2025 variant).

RAF compensation caps are tier-sensitive: Popular Investors and Club members get model-specific maximums that may be higher than the standard cap. The procedure resolves the applicable maximum through a competition between PI and Club model values, awarding the best (highest expected total compensation) tier.

**RafStatus values**:
- `0` - No RAF: the customer has not yet referred anyone who triggered a compensation
- `1` - RAF active, under limit: at least one compensation paid but max not reached
- `2` - RAF cap reached: compensations equal or exceed the maximum
- `3` - RAF exists but no configuration found: compensations were given but the country/regulation config is missing (old records from deprecated country setups)

**Change history (from DDL comments)**:
- 09/10/2022: Created (PART-475) - original RAF status SP
- 27/04/2023: Added PI and Club model support (PART-1488)
- 11/06/2023: Remarked exclusion of Romania
- 03/2024: Added @IsBronzePlus parameter for Bronze Plus tier (PART-2869)

---

## 2. Business Logic

### 2.1 Customer Context Lookup

**What**: Resolves the referring customer's internal IDs and tier attributes from their GCID.

**Columns/Parameters Involved**: `@GCID`, `@CID`, `@GuruStatusID`, `@PlayerLevelID`, `@CountryID`, `@RegulationID`

**Rules**:
- INNER JOINs Customer.Customer, BackOffice.Customer, Dictionary.Country
- Only proceeds if the customer's country has IsEligibleForRAFBonusCountry=1 AND CountryID>0
- DesignatedRegulationID from BackOffice.Customer determines which RAF config applies
- GuruStatusID (from BackOffice.Customer): Popular Investor guru tier, determines PI model eligibility
- PlayerLevelID (from Customer.Customer): Club membership level, determines Club model eligibility
- If the customer's country is not RAF-eligible, `@CID` remains 0 and subsequent queries return defaults

### 2.2 Bronze Plus Override

**What**: Overrides PlayerLevelID to 100 when the caller signals the customer is Bronze Plus tier.

**Columns/Parameters Involved**: `@IsBronzePlus`, `@PlayerLevelID`

**Rules**:
- `IF @IsBronzePlus = 1 SET @PlayerLevelID = 100`
- Bronze Plus is a special tier not stored in Customer.Customer.PlayerLevelID
- The caller (UI layer) determines Bronze Plus eligibility and passes it as a parameter
- PlayerLevelID=100 is the sentinel value for Bronze Plus in the RafConfigurationModels lookup

### 2.3 RAF Compensation Count

**What**: Counts how many compensations the referring customer has already received.

**Columns/Parameters Involved**: `@CountRAFCompensations`, `@CID`

**Rules**:
- `SELECT COUNT(*) FROM Customer.RAFGiven WHERE ReferringCID = @CID`
- Counts ALL RAFGiven records for this CID as referring party
- If @CID is still 0 (non-eligible country), count will be 0

### 2.4 Maximum Compensation Resolution (PI vs Club Competition)

**What**: Determines the applicable MaxNumberOfCompensations for this customer by competing PI model and Club model values.

**Columns/Parameters Involved**: `@MaxNumberOfCompensations`, `@GuruStatusID`, `@PlayerLevelID`, `RC.MaxNumberOfCompensations`, `RM_PI.MaxNumberOfCompensations`, `RM_Club.MaxNumberOfCompensations`

**Rules**:
- LEFT JOINs CountryRafConfiguration (RC) filtered by `CountryID=@CountryID AND RegulationID=@RegulationID`
- LEFT JOINs RafConfigurationModels twice:
  - `RM_Club`: RafModelTypeID=1 (Club), RafModelID=@PlayerLevelID, only if @PlayerLevelID>0
  - `RM_PI`: RafModelTypeID=2 (Popular Investor), RafModelID=@GuruStatusID, only if @GuruStatusID>0
- Competition logic (expected total compensation = ReferringCompensationInCents * MaxNumberOfCompensations):
  - PI wins: if PI expected total > Club expected total AND RM_PI.MaxNumberOfCompensations IS NOT NULL
  - Club wins: if Club expected total >= PI expected total AND RM_Club.MaxNumberOfCompensations IS NOT NULL
  - Standard applies: if both RM_Club and RM_PI have NULL ReferringCompensationInCents (no model match)
- If no active config exists (country/regulation not in CountryRafConfiguration with valid ValidFrom/ValidTo): @MaxNumberOfCompensations remains NULL

### 2.5 Status Classification

**What**: Translates count vs max into the RafStatus integer.

**Columns/Parameters Involved**: `@RafStatus`, `@CountRAFCompensations`, `@MaxNumberOfCompensations`

**Rules**:
- Only enters classification block if `@CountRAFCompensations > 0` (at least one compensation given)
- If @MaxNumberOfCompensations IS NULL: `@RafStatus = 3` (RAF exists, no config)
- Else if @MaxNumberOfCompensations > @CountRAFCompensations: `@RafStatus = 1` (under limit)
- Else: `@RafStatus = 2` (cap reached)
- If @CountRAFCompensations = 0: @RafStatus stays 0 (no RAF activity)

### 2.6 Fraud Check

**What**: Checks if the customer is flagged as fraudulent in the FraudUsers table.

**Columns/Parameters Involved**: `@IsFraud`, `@CID`

**Rules**:
- `SELECT DISTINCT @IsFraud=1 FROM Customer.FraudUsers WHERE (CID=@CID OR CID2=@CID) AND Status='Fraud'`
- Checks both CID and CID2 columns (a fraud pair can have either CID in either position)
- Status='Fraud' (case-sensitive depending on collation): only 'Fraud' status, not 'Suspected' or other values
- If no match found: @IsFraud remains 0

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Input: GCID of the referring customer (the one who invited friends). Used to join Customer.Customer.GCID. |
| 2 | @IsBronzePlus | INT | YES | 0 | CODE-BACKED | Input flag: 1 if the referring customer is Bronze Plus tier. Overrides PlayerLevelID to 100 for Club model lookup. Added PART-2869. |
| 3 | RafStatus | int (output) | NO | 0 | CODE-BACKED | RAF program status: 0=no RAF compensations received, 1=RAF active and under the maximum, 2=RAF maximum reached, 3=RAF compensations exist but no active country/regulation configuration found. |
| 4 | IsFraud | int (output) | NO | 0 | CODE-BACKED | Fraud flag: 0=not fraudulent, 1=flagged in Customer.FraudUsers with Status='Fraud'. Checked on both CID and CID2 columns of FraudUsers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.Customer | FROM + INNER JOIN | Resolves GCID to CID, PlayerLevelID, CountryID |
| CID | BackOffice.Customer | INNER JOIN on CID | Resolves GuruStatusID, DesignatedRegulationID |
| CountryID | Dictionary.Country | INNER JOIN | Validates country; filters IsEligibleForRAFBonusCountry=1 |
| CountryID/RegulationID | Customer.CountryRafConfiguration | FROM (config) | Retrieves standard MaxNumberOfCompensations |
| RafConfigurationID | Customer.RafConfigurationModels | LEFT JOIN x2 | Retrieves PI model (type=2) and Club model (type=1) compensations |
| CID | Customer.RAFGiven | WHERE ReferringCID | Counts compensations already paid to the referring customer |
| CID | Customer.FraudUsers | WHERE CID or CID2 | Checks fraud status |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRafStatusByGCID_NogaJunk210725 (procedure)
|-- Customer.Customer (view)
|     |-- Customer.CustomerStatic (table)
|     `-- Customer.CustomerMoney (table)
|-- BackOffice.Customer (view - cross-schema)
|-- Dictionary.Country (table - cross-schema)
|-- Customer.CountryRafConfiguration (table)
|-- Customer.RafConfigurationModels (table)
|-- Customer.RAFGiven (table)
`-- Customer.FraudUsers (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM + INNER JOIN - source of CID, PlayerLevelID, CountryID |
| BackOffice.Customer | View | INNER JOIN on CID - source of GuruStatusID, DesignatedRegulationID |
| Dictionary.Country | Table | INNER JOIN on CountryID - validates RAF eligibility |
| Customer.CountryRafConfiguration | Table | FROM (config) - standard RAF config per country/regulation |
| Customer.RafConfigurationModels | Table | LEFT JOIN x2 - PI and Club model compensation overrides |
| Customer.RAFGiven | Table | WHERE ReferringCID=@CID - counts compensations given |
| Customer.FraudUsers | Table | WHERE (CID or CID2)=@CID - fraud status check |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Non-eligible country returns status 0 | Short-circuit | If customer country not in RAF-eligible set, @CID=0, count=0, status=0 |
| @IsBronzePlus sentinel value | Design | PlayerLevelID=100 is Bronze Plus sentinel; not stored in CustomerStatic |
| PI vs Club competition formula | Business rule | Winner = highest (ReferringCompensationInCents * MaxNumberOfCompensations); tie goes to Club |
| FraudUsers double-column check | Data model | Either CID or CID2 may identify the customer in a fraud pair |

---

## 8. Sample Queries

### 8.1 Get RAF status for a referring customer
```sql
EXEC Customer.GetRafStatusByGCID_NogaJunk210725 @GCID = 1983785, @IsBronzePlus = 0;
```

### 8.2 Get RAF status for a Bronze Plus customer
```sql
EXEC Customer.GetRafStatusByGCID_NogaJunk210725 @GCID = 1983785, @IsBronzePlus = 1;
```

### 8.3 Direct query to check RAF compensation count for a CID
```sql
-- Step 1: Get CID from GCID
SELECT CID, PlayerLevelID, CountryID FROM Customer.Customer WITH (NOLOCK) WHERE GCID = 1983785;

-- Step 2: Count compensations
SELECT COUNT(*) AS CompensationCount FROM Customer.RAFGiven WITH (NOLOCK) WHERE ReferringCID = 123456;

-- Step 3: Check fraud
SELECT * FROM Customer.FraudUsers WITH (NOLOCK) WHERE (CID = 123456 OR CID2 = 123456) AND Status = 'Fraud';
```

### 8.4 RafStatus meaning reference
```sql
-- Status code meanings:
-- 0 = No RAF: no compensations given yet (or non-eligible country)
-- 1 = Active: compensations given, under the maximum
-- 2 = Capped: maximum compensations reached
-- 3 = Orphan: compensations exist but config deleted/expired
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-475 | Jira | Original RAF status SP creation (Oct 2022), requested by Moshe O, used by UI to show referral status |
| PART-1488 | Jira | Added PI (Popular Investor) and Club model support (27/4/23) |
| PART-2869 | Jira | Added @IsBronzePlus parameter to support Bronze Plus tier (3/2024) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 3 Jira (from DDL comments) | Procedures: 0 SQL callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetRafStatusByGCID_NogaJunk210725 | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetRafStatusByGCID_NogaJunk210725.sql*

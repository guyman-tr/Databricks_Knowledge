# Customer.CheckFraudUsers_NogaJunk210725

> Parameterless RAF fraud detection procedure that identifies pairs of customer accounts sharing the same funding transaction with suspicious identity similarities (IP, name, address, birthdate), scores them with a weighted algorithm, classifies the fraud type, and replaces all rows in Customer.FraudUsers_NogaJunk210725 with the fresh results.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - full refresh procedure |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.CheckFraudUsers_NogaJunk210725 is the execution engine for the RAF (Refer-A-Friend) fraud detection workflow. Every time it runs, it scans all active RAF relationships - customers who referred other customers - filters out high-value players and Popular Investors (who are exempt from fraud scrutiny), then cross-checks whether any two RAF-connected customers shared the same deposit funding method (FundingID). Sharing a FundingID across accounts is a strong signal that two accounts are operated by the same person or coordinated group, exploiting the RAF referral bonus by self-referring.

The procedure exists to protect eToro's RAF bonus program from abuse. The RAF bonus rewards customers for referring new depositors. Without fraud detection, a single actor could create multiple accounts, refer themselves, deposit using the same payment method, claim bonuses across all accounts, and then withdraw. This procedure identifies those patterns and writes the results into Customer.FraudUsers_NogaJunk210725 for review by the compliance/fraud team.

Data flow: called by the SQL_RAF service role on a scheduled basis (confirmed by EXECUTE permission in UsersPermissions/SQL_RAF.sql). It reads live data from Customer.Customer (RAF user pairs), BackOffice.Customer (guru status and verification level), Billing.Deposit (shared FundingIDs), and Dictionary.Country (RAF-eligible countries). It then runs the full detection pipeline through temp tables and atomically replaces all rows in Customer.FraudUsers_NogaJunk210725 using TRUNCATE + INSERT within a transaction.

---

## 2. Business Logic

### 2.1 RAF Eligibility Filtering

**What**: Determines which customer pairs are in scope for fraud detection.

**Columns/Parameters Involved**: `PlayerLevelID`, `GuruStatusID`, `Registered`, `ReferralID`

**Rules**:
- Only customers with ReferralID > 0 (referred by someone) are in scope
- The referrer (C1) must NOT be Platinum, Platinum Plus, or Diamond (PlayerLevelID NOT IN (2,6,7)) - per PART-3907 (2025-01-28)
- The referrer must NOT be a Popular Investor (ISNULL(BC1.GuruStatusID,0) = 0)
- The referee (C2) must have registered within the last 1 year (DATEADD(year,-1,GETUTCDATE()))
- Change history: PART-3907 (2025-01-28) excluded Platinum/Platinum Plus/Diamond from fraud detection; previously only Platinum was excluded per FB-50210 (2018)

**Diagram**:
```
RAF Pair (C1=referrer, C2=referred)
     |
     +-- C1.PlayerLevelID IN (2,6,7)? --> EXCLUDE (high-value customer)
     |
     +-- C1.GuruStatusID != 0?         --> EXCLUDE (Popular Investor)
     |
     +-- C2.Registered > 1 year ago?   --> EXCLUDE (old registration)
     |
     v
  IN SCOPE --> #RAFUsers
```

### 2.2 Shared FundingID Detection

**What**: Identifies cases where multiple RAF-connected customers used the same funding transaction/method.

**Columns/Parameters Involved**: `FundingID`, `PaymentStatusID`, `IsEligibleForRAFBonusCountry`, `VerificationLevelID`, `PlayerLevelID`

**Rules**:
- Only successful deposits considered: PaymentStatusID = 2
- FundingID > 11: excludes test/internal funding methods
- ModificationDate >= 2017-04-24: RAF program inception date
- PlayerLevelID != 4: additional player level exclusion at deposit level
- IsEligibleForRAFBonusCountry = 1: only countries where RAF bonuses are paid
- VerificationLevelID = 3: only fully verified customers (KYC complete)
- Groups by FundingID - the same funding instrument used by multiple RAF accounts = primary fraud signal

### 2.3 Identity Similarity Scoring Algorithm

**What**: Scores each suspicious account pair using SQL DIFFERENCE() phonetic matching and exact comparison on key identity fields.

**Columns/Parameters Involved**: `IP_Dif`, `Zip_Dif`, `UserName_Dif`, `BirthDateApart`, `FirstName_Dif`, `LastName_Dif`, `Address_Dif`, `City_Dif`, `Main_Scoring`

**Rules**:
- SQL DIFFERENCE() returns 0 (no similarity) to 4 (strong similarity) for string fields
- BirthDateApart scoring: 0 days = 4pts, 1 day = 3pts, <=7 days = 2pts, <=31 days = 1pt, >31 = 0
- IP_Dif/Zip_Dif: 1 if exact match (same IP/ZIP), 0 if different
- Main_Scoring = BirthDate_pts + FirstName_Dif + LastName_Dif + max(Address_Dif + City_Dif, OppAddress_Dif) + IIF(SharedFund>1, 12, 0)
- The +12 bonus for SharedFund > 1 (multiple shared funding events) creates a strong tier break

**Diagram**:
```
Main_Scoring components:
  BirthDate proximity (0-4 pts)
+ FirstName similarity (0-4 pts)
+ LastName similarity (0-4 pts)
+ max(Address+City, OppositeAddress) (0-8 pts)
+ SharedFund>1 bonus (+12 pts)
= Main_Scoring (range: 0 to 32+)
```

### 2.4 Fraud Type Classification

**What**: Classifies the primary reason for fraud suspicion with priority ordering.

**Columns/Parameters Involved**: `Fraud_Type`, `Status`, `Recommendation`

**Rules** (evaluated in CASE priority order):
- `'x'`: names AND address both score >=7 - strongest classic identity match
- `'n'`: names+birthdate combined >=11 but address differs - name match without address
- `'on'`: opposite names match >=7 (FirstName vs LastName2 + FirstName2 vs LastName) - name swap/reversal pattern
- `'oa'`: opposite address match >=7 but direct address differs - address swap pattern
- `'legit'` (name path): low name scores AND high address score AND SharedFund<=1 AND BirthDateApart>7 - distinct people sharing address legitimately
- `'s'`: partial name match but address score low - mixed signals
- `'f'`: first name low but last name high AND address matches - family member pattern
- `'legit'` (score path): total composite score <=8 AND SharedFund<=1 - below fraud threshold
- `'ip'`: same IP address (fallthrough from score-based checks)
- `'zip'`: same ZIP code (fallthrough)
- `'Other Fraud'`: default catch-all
- Status derivation: 'legit' Fraud_Type -> Status='Legit'; all others -> Status='Fraud'
- Recommendation derivation: Fraud_Type!='legit' AND Main_Scoring BETWEEN 9 AND 11 -> 'Review'; else 'Unchange'

### 2.5 Atomic Table Replacement

**What**: The procedure replaces ALL rows in Customer.FraudUsers_NogaJunk210725 as a single transaction.

**Rules**:
- Detection logic runs OUTSIDE the transaction (first TRY block)
- TRUNCATE + INSERT runs INSIDE a BEGIN TRAN / COMMIT TRAN (second TRY block)
- If INSERT fails, ROLLBACK restores the old data
- This means the fraud table always contains a complete consistent snapshot - never partially updated

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. It is called without arguments and performs a full refresh of Customer.FraudUsers_NogaJunk210725.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | Parameterless procedure. All inputs are read directly from production tables (Customer.Customer, BackOffice.Customer, Billing.Deposit, Dictionary.Country). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| C1.CID / C2.CID | Customer.Customer | JOIN (read) | RAF pair resolution - referrer (C1) and referred (C2) customer data |
| BC1.CID / BC.CID / BC2.CID | BackOffice.Customer | JOIN (read) | GuruStatusID (Popular Investor check) and VerificationLevelID |
| dep.CID | Billing.Deposit | JOIN (read) | Shared FundingID detection - successful deposits by RAF users |
| cc.CountryID | Dictionary.Country | JOIN (read) | IsEligibleForRAFBonusCountry flag and Country name for output |
| (target) | Customer.FraudUsers_NogaJunk210725 | TRUNCATE + INSERT | Full replacement of fraud detection results |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_RAF service role | EXECUTE permission | Caller | Called by the RAF service on a scheduled basis to refresh the fraud detection results |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.CheckFraudUsers_NogaJunk210725 (procedure)
├── Customer.Customer (view)
├── BackOffice.Customer (table - cross-schema)
├── Billing.Deposit (table - cross-schema)
├── Dictionary.Country (table - cross-schema)
└── Customer.FraudUsers_NogaJunk210725 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | Read - RAF pair identification (referrer C1 and referred C2, PlayerLevelID, IP, address fields) |
| BackOffice.Customer | Table | Read - GuruStatusID (Popular Investor exclusion) and VerificationLevelID (KYC check) |
| Billing.Deposit | Table | Read - FundingID grouping for shared-deposit detection, PaymentStatusID filter |
| Dictionary.Country | Table | Read - IsEligibleForRAFBonusCountry flag, Country name for output rows |
| Customer.FraudUsers_NogaJunk210725 | Table | Write - TRUNCATE then INSERT; the sole output target of this procedure |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_RAF service | External caller | Calls this procedure on a scheduled basis via EXECUTE permission granted in UsersPermissions/SQL_RAF.sql |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| First TRY/CATCH block | Error handling | Detection logic (all temp table operations). On error: THROW (propagates to caller). Transaction NOT opened yet. |
| Second TRY/CATCH block | Transaction | TRUNCATE + INSERT wrapped in BEGIN TRAN. On error: ROLLBACK + THROW. Ensures atomic replacement. |
| CREATE CLUSTERED INDEX #RAFUsersFinal_CID | Performance | Clustered index on #RAFUsersFinal.CID for efficient JOIN in the CustPerFunding CTE. |

---

## 8. Sample Queries

### 8.1 Check last run results - fraud type summary

```sql
SELECT
    Fraud_Type,
    Status,
    Recommendation,
    COUNT(*) AS PairCount,
    AVG(CAST(Main_Scoring AS FLOAT)) AS AvgScore,
    MAX(Main_Scoring) AS MaxScore
FROM Customer.FraudUsers_NogaJunk210725 WITH (NOLOCK)
GROUP BY Fraud_Type, Status, Recommendation
ORDER BY PairCount DESC
```

### 8.2 Find highest-scoring fraud pairs for manual review

```sql
SELECT TOP 20
    fu.FundingID,
    fu.CID,
    fu.CID2,
    fu.Main_Scoring,
    fu.Fraud_Type,
    fu.SharedFund,
    fu.IP_Dif,
    fu.BirthDateApart,
    fu.Recommendation
FROM Customer.FraudUsers_NogaJunk210725 fu WITH (NOLOCK)
WHERE fu.Status = 'Fraud'
ORDER BY fu.Main_Scoring DESC, fu.SharedFund DESC
```

### 8.3 Verify a specific customer is not in fraud table before RAF payout

```sql
SELECT
    fu.CID,
    fu.CID2,
    fu.Fraud_Type,
    fu.Status,
    fu.Main_Scoring,
    fu.FundingID
FROM Customer.FraudUsers_NogaJunk210725 fu WITH (NOLOCK)
WHERE fu.CID = @CID OR fu.CID2 = @CID
ORDER BY fu.Main_Scoring DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [RAF Service](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11412833500/RAF+Service) | Confluence | RAF service architecture context confirming SQL_RAF is the scheduling service for RAF fraud procedures (2021 page) |
| [ONBRD-7577](https://etoro-jira.atlassian.net/browse/ONBRD-7577) | Jira | Phone column removed from fraud calculation (2024-08-18) |
| [PART-3907](https://etoro-jira.atlassian.net/browse/PART-3907) | Jira | Platinum, Platinum Plus, and Diamond customers excluded from fraud procedure (2025-01-28) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 1 Confluence + 2 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CheckFraudUsers_NogaJunk210725 | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.CheckFraudUsers_NogaJunk210725.sql*

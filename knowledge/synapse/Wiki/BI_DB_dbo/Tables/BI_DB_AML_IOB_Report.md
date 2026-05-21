# BI_DB_dbo.BI_DB_AML_IOB_Report

> AML compliance report for customers enrolled in eToro's Interest on Balance (IOB) program — tracking account balance, deposits/withdrawals since IOB opt-in, open positions, and Proof of Income document status to support AML monitoring of customers receiving interest payments.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_AML_IOB_Report |
| **OpsDB Priority** | 0 (no intra-schema dependencies) |
| **Refresh** | Daily — TRUNCATE + INSERT (full rebuild) |
| **Author** | Lior Ben Dor (2025-07-03) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Rows** | ~4.97M total / ~318K distinct CIDs (~15.6 rows/CID — fan-out from JOIN to multi-row BI_DB_AML_Documents_Request) |
| | |
| **UC Target** | Not migrated |

---

## 1. Business Meaning

BI_DB_AML_IOB_Report is the AML team's compliance monitoring view for customers enrolled in eToro's IOB (Interest on Balance) program — a feature that pays daily interest on uninvested cash balances. The AML angle: interest payments can be a money laundering vector (a customer deposits funds, earns interest, then withdraws the now-"legitimized" funds). This table aggregates the financial activity of all opted-in customers since their IOB enrollment date, enabling the AML team to identify unusual deposit/withdrawal patterns relative to their earned interest.

The report answers key compliance questions: Has the customer made large deposits since opting in? Have they immediately withdrawn (suggesting "parking" money for interest)? Do they have an open Proof of Income document on file? Are they eligible for interest payments under their regulation, or are they receiving interest they shouldn't be?

The `Is_Eligible` flag identifies which IOB customers are actually eligible based on their regulatory jurisdiction (CySEC, FCA, ASIC, ASIC & GAML, FSRA, FSA Seychelles — excludes BVI and FINRA/US), country (US and internal eToro entity excluded), and account status (Normal status only, standard club tiers). Non-eligible customers who nevertheless opted in are flagged with Is_Eligible=0 — a compliance concern in itself.

The `Payment_interest_June` column contains the actual interest payment amount for June 2025. This is hardcoded in the SP (date range 2025-06-01 to 2025-07-01) — the column represents a historical snapshot of the first month of interest payments and is not updated to track subsequent months.

**Data quality warning**: The table has ~4.97M rows for ~318K distinct CIDs (~15.6 rows/CID). This is caused by a LEFT JOIN to `BI_DB_AML_Documents_Request` which itself has multiple rows per CID (multi-regulation). All columns except `DateAdded_Proof_of_Income` are duplicated across these rows. Use `SELECT DISTINCT CID, ...` or filter to one row per CID when computing customer-level metrics.

---

## 2. Business Logic

### 2.1 IOB Opt-in Population

**What**: Only customers who explicitly opted into the IOB interest program are included.

**Columns Involved**: `CID`, `Date_IOB_switched_on`

**Rules**:
- Population base: `External_Interest_Trade_InterestConsent WHERE ConsentStatusID=1` — only opted-in customers.
- `Date_IOB_switched_on = ValidFrom`: The date the customer's IOB consent became active. Financial metrics (deposits, withdrawals) are calculated from this date onwards.
- Non-opted customers are completely absent from this table.
- Blocked (PlayerStatusID=2) and BUR (PlayerStatusID=4) customers are excluded via the INNER JOIN on Dim_PlayerStatus, even if they consented.

### 2.2 IOB Eligibility Assessment

**What**: The Is_Eligible flag determines whether an IOB-enrolled customer actually qualifies for interest payments.

**Columns Involved**: `Is_Eligible`, `PlayerStatus`, `Regulation`, `Country`, `Club`

**Rules**:
- `Is_Eligible = 1` requires ALL four conditions:
  1. **PlayerStatus = Normal** (PlayerStatusID=1 only — any restriction disqualifies)
  2. **Regulation** is one of: CySEC, FCA, ASIC, ASIC & GAML, FSRA, FSA Seychelles. BVI and FINRA/US are excluded (regulatory restrictions prevent IOB for those entities).
  3. **Country** is NOT United States (CountryID=219) AND NOT the internal eToro entity (CountryID=250).
  4. **Club** is one of: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond (all standard retail tiers).
- A customer with Is_Eligible=0 has opted in but is not currently qualifying — requires compliance review.

### 2.3 Financial Activity Since IOB Enrollment

**What**: Deposits and withdrawals are measured only from the IOB opt-in date onward, not lifetime.

**Columns Involved**: `Deposits_since_IOB_date`, `Withdrawals_since_IOB_date`, `Date_IOB_switched_on`

**Rules**:
- Both metrics use `DateID >= ValidFromInt` (the IOB opt-in date as an INT YYYYMMDD) as the time boundary.
- `Deposits_since_IOB_date` = SUM of Fact_CustomerAction.Amount WHERE ActionTypeID=7 (Deposits) since IOB opt-in.
- `Withdrawals_since_IOB_date` = SUM of Fact_CustomerAction.Amount WHERE ActionTypeID=8 (Cash Out / Withdrawals) since IOB opt-in.
- Both ISNULL → 0 if no activity.
- High withdrawal ratio vs deposits since IOB opt-in is the primary AML signal.

### 2.4 Account Balance

**What**: The customer's current realized equity as of yesterday.

**Columns Involved**: `Account_Balance`

**Rules**:
- Sourced from `V_Liabilities.RealizedEquity` for DateID = yesterday (not `Liabilities+ActualNWA` as used in BI_DB_AML_Documents_Request).
- `RealizedEquity` represents the customer's realized (settled) cash balance, excluding unrealized position gains/losses.
- ISNULL → 0 if no V_Liabilities record.

### 2.5 June 2025 Interest Snapshot

**What**: The hardcoded June 2025 interest payment column.

**Columns Involved**: `Payment_interest_June`

**Rules**:
- Sourced from `DWH_dbo.etoro_History_Credit` WHERE CompensationReasonID IN (57, 62) AND CreditTypeID=6 AND Occurred between 2025-06-01 and 2025-07-01.
- This date range is hardcoded in the SP — the column does NOT update to track subsequent months.
- Represents the total interest credited to the customer in June 2025 specifically.
- ISNULL → 0 if no interest payment in that month.
- CreditTypeID=6 and CompensationReasonID 57/62 identify the IOB interest payment transaction type.

### 2.6 ETL Pattern and Fan-out Issue

**What**: Full daily rebuild with a known row multiplication issue.

**Rules**:
- TRUNCATE + INSERT (no date parameter). Priority 0 in OpsDB.
- The LEFT JOIN to `BI_DB_AML_Documents_Request` causes fan-out: that table has multiple rows per CID (one per regulatory entity, ~1.9x average, plus potential duplicates). The result is ~15.6 rows per CID in this table.
- For customer-level analysis, always deduplicate: `SELECT DISTINCT CID, column_list` or `WHERE ROW_NUMBER() OVER (PARTITION BY CID ORDER BY 1) = 1`.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN + HEAP. No distribution key. With ~5M rows, full scans are still manageable but prefer filtering by CID for targeted lookups.

### 3.2 Deduplication Required

Because of the BI_DB_AML_Documents_Request join fan-out, queries must deduplicate before computing aggregates:

```sql
-- WRONG: will inflate counts and sums by ~15.6x
SELECT COUNT(*), SUM(Account_Balance) FROM BI_DB_AML_IOB_Report

-- CORRECT: deduplicate first
SELECT COUNT(DISTINCT CID), SUM(Account_Balance) / COUNT(*) * COUNT(DISTINCT CID)
FROM BI_DB_AML_IOB_Report
```

### 3.3 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Count distinct IOB customers | COUNT(DISTINCT CID) |
| Non-eligible IOB customers | WHERE Is_Eligible = 0 (then DISTINCT CID) |
| High withdrawal ratio (AML signal) | WHERE Withdrawals_since_IOB_date > Deposits_since_IOB_date |
| Missing Proof of Income | WHERE DateAdded_Proof_of_Income IS NULL |
| Top earners June 2025 | ORDER BY Payment_interest_June DESC (first DISTINCT by CID) |
| IOB customers opted in before a date | WHERE Date_IOB_switched_on < '2024-01-01' |

### 3.4 Gotchas

- **~15.6 rows per CID by design flaw**: Always use DISTINCT or ROW_NUMBER deduplication before customer-level analysis.
- **Payment_interest_June is frozen at June 2025**: The column does not roll forward to current months.
- **No VerificationLevelID filter**: Unlike BI_DB_AML_Documents_Request, this table includes all verification levels (1=registered, 2=partial, 3=full). VerificationLevelID is stored for reporting but not used as a filter.
- **Account_Balance uses RealizedEquity**: This is settled cash only, not total portfolio value. A customer with open positions may show a low Account_Balance despite high total equity.
- **DateAdded_Proof_of_Income may be duplicated**: Due to the multi-row source, the same date appears on all duplicated rows for a customer — values are consistent, but there are multiple identical rows.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ***** | Tier 1 - upstream wiki verbatim | varies by source |
| **** | Tier 2 - SP code / DWH wiki | (Tier 2 - SP_AML_IOB_Report) |
| — | Propagation blacklist | ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer account ID — eToro RealCID. Population: customers who opted into the IOB (Interest on Balance) program (ConsentStatusID=1 in External_Interest_Trade_InterestConsent), who are valid (IsValidCustomer=1) and non-blocked (PlayerStatusID NOT IN 2,4). Due to the join to BI_DB_AML_Documents_Request, appears ~15.6 times per CID on average. (Tier 1 - Customer.CustomerStatic via Dim_Customer) |
| 2 | Regulation | varchar(250) | YES | Regulatory entity under which the customer is registered. Values: CySEC, FCA, ASIC, ASIC & GAML, FSRA, FSA Seychelles, BVI, and others. One of the Is_Eligible criteria is that Regulation must be one of: CySEC, FCA, ASIC, ASIC & GAML, FSRA, FSA Seychelles. (Tier 1 - upstream wiki, Dictionary.Regulation) |
| 3 | Country | varchar(250) | YES | Customer's KYC country of residence. US (United States) and the eToro internal entity (CountryID=250) are excluded from Is_Eligible=1. (Tier 1 - upstream wiki, Dictionary.Country) |
| 4 | CitizenshipCountry | varchar(250) | YES | Customer's country of citizenship. NULL if not recorded in Dim_Customer. (Tier 1 - upstream wiki, Dictionary.Country) |
| 5 | POBCountry | varchar(250) | YES | Customer's place of birth country. NULL if not recorded. (Tier 1 - upstream wiki, Dictionary.Country) |
| 6 | PlayerStatus | varchar(250) | YES | Customer's current account restriction status name. Blocked (2) and BUR (4) excluded by population filter. Is_Eligible=1 requires PlayerStatus='Normal'. Values present: Normal, Deposit Blocked, Warning, etc. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 7 | PlayerStatusReason | varchar(250) | YES | Broad reason category for the customer's current PlayerStatus change. NULL if no reason recorded (PlayerStatusReasonID=0). 44 possible values. (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) |
| 8 | PlayerStatusSubReasonName | varchar(250) | YES | Granular sub-reason for the PlayerStatus change, providing second-level classification beneath PlayerStatusReason. NULL if no sub-reason recorded. 83 possible values. (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) |
| 9 | Club | varchar(250) | YES | Customer loyalty tier / club name from Dim_PlayerLevel. Is_Eligible=1 requires Club IN (Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond). Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 10 | RegisteredReal | datetime | YES | Timestamp when the customer's real account was created, sourced from Customer.CustomerStatic. (Tier 1 - Customer.CustomerStatic via Dim_Customer) |
| 11 | FirstDepositDate | datetime | YES | Date and time of the customer's first deposit. NULL if never deposited (IsDepositor=0). Computed by SP_Dim_Customer. (Tier 2 - SP_Dim_Customer via Dim_Customer) |
| 12 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. DDL default=-1; SP_Dim_Customer converts NULLs to 0 via ISNULL. |
| 13 | IsDepositor | int | YES | Flag: 1=customer has ever made a deposit, 0=no deposit history. Computed by SP_Dim_Customer. (Tier 2 - SP_Dim_Customer via Dim_Customer) |
| 14 | Is_Eligible | int | YES | Binary IOB eligibility flag. 1 = customer meets all criteria for interest payments; 0 = opted in but does not currently qualify. Criteria for 1: PlayerStatusID=1 (Normal) AND RegulationID IN (CySEC, FCA, ASIC, ASIC & GAML, FSRA, FSA Seychelles) AND CountryID NOT IN (United States, eToro entity) AND PlayerLevelID IN (Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond). Customers with Is_Eligible=0 require compliance review. (Tier 2 - SP_AML_IOB_Report) |
| 15 | Account_Balance | money | YES | Customer's realized equity (settled cash balance) as of yesterday, from DWH_dbo.V_Liabilities.RealizedEquity. ISNULL→0. Note: this is RealizedEquity only — excludes unrealized gains/losses from open positions. A customer with large open positions may show a lower Account_Balance than their total portfolio value. (Tier 2 - SP_AML_IOB_Report via V_Liabilities) |
| 16 | Date_IOB_switched_on | datetime | YES | The date and time when the customer's IOB (Interest on Balance) consent became active. Sourced from External_Interest_Trade_InterestConsent.ValidFrom. This is the baseline date for Deposits_since_IOB_date and Withdrawals_since_IOB_date calculations. (Tier 2 - SP_AML_IOB_Report via External_Interest_Trade_InterestConsent) |
| 17 | Deposits_since_IOB_date | money | YES | Total amount deposited by the customer since their IOB opt-in date (Date_IOB_switched_on). SUM(Fact_CustomerAction.Amount) WHERE ActionTypeID=7 (Deposits) AND DateID >= IOB consent date. ISNULL→0. The primary financial signal for AML monitoring — unexpectedly large deposits after IOB opt-in. (Tier 2 - SP_AML_IOB_Report via Fact_CustomerAction) |
| 18 | Withdrawals_since_IOB_date | money | YES | Total amount withdrawn by the customer since their IOB opt-in date. SUM(Fact_CustomerAction.Amount) WHERE ActionTypeID=8 (Cash Out / Withdrawal) AND DateID >= IOB consent date. ISNULL→0. High withdrawals relative to deposits since IOB opt-in is a primary AML money-laundering signal (deposit, earn interest, withdraw). (Tier 2 - SP_AML_IOB_Report via Fact_CustomerAction) |
| 19 | Has_Open_Position | int | YES | Flag: 1=customer had at least one open position as of yesterday (found in BI_DB_PositionPnL for yesterday's DateID), 0=no open positions. (Tier 2 - SP_AML_IOB_Report via BI_DB_PositionPnL) |
| 20 | DateAdded_Proof_of_Income | datetime | YES | Upload date of the customer's most recent accepted Proof of Income document. Sourced from BI_DB_AML_Documents_Request.DocumentDateAdded_POIncome via LEFT JOIN on CID. NULL if no Proof of Income document found. Due to multi-row source, the same value is duplicated across all rows for the same CID in this table. Required for AML economic profile review of high-balance IOB customers. (Tier 2 - BI_DB_AML_Documents_Request.DocumentDateAdded_POIncome) |
| 21 | Payment_interest_June | money | YES | Total IOB interest payment credited to the customer in June 2025. SUM(DWH_dbo.etoro_History_Credit.Payment) WHERE CompensationReasonID IN (57,62) AND CreditTypeID=6 AND Occurred between 2025-06-01 and 2025-07-01. ISNULL→0. The date range is hardcoded in the SP — this column does NOT update to track subsequent months. Represents the first monthly interest payment cohort. (Tier 2 - SP_AML_IOB_Report via etoro_History_Credit) |
| 22 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was inserted by the ETL pipeline (GETDATE() at INSERT time). All rows share the same timestamp per daily run. Not a business date. (Propagation blacklist — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | etoro.Customer.CustomerStatic | CID | Via Dim_Customer.RealCID + External_Interest_Trade_InterestConsent |
| Regulation | etoro.Dictionary.Regulation | Name | Lookup via Dim_Regulation |
| Country | etoro.Dictionary.Country | Name | Lookup via Dim_Country (residence) |
| CitizenshipCountry | etoro.Dictionary.Country | Name | Lookup via Dim_Country (citizenship); LEFT JOIN |
| POBCountry | etoro.Dictionary.Country | Name | Lookup via Dim_Country (POB); LEFT JOIN |
| PlayerStatus | etoro.Dictionary.PlayerStatus | Name | Lookup via Dim_PlayerStatus |
| PlayerStatusReason | etoro.Dictionary.PlayerStatusReasons | Name | Lookup via Dim_PlayerStatusReasons; LEFT JOIN |
| PlayerStatusSubReasonName | etoro.Dictionary.PlayerStatusSubReasons | Name | Lookup via Dim_PlayerStatusSubReasons; LEFT JOIN; renamed |
| Club | etoro.Dictionary.PlayerLevel | Name | Lookup via Dim_PlayerLevel |
| RegisteredReal | etoro.Customer.CustomerStatic | RegisteredReal | Passthrough via Dim_Customer |
| FirstDepositDate | etoro.BackOffice.Customer / Billing | — | SP_Dim_Customer computed |
| VerificationLevelID | etoro.BackOffice.Customer | VerificationLevelID | Passthrough via Dim_Customer |
| IsDepositor | — | — | SP_Dim_Customer computed |
| Is_Eligible | — | Multiple | SP-computed eligibility flag |
| Account_Balance | DWH_dbo.V_Liabilities | RealizedEquity | ISNULL(RealizedEquity,0) for yesterday |
| Date_IOB_switched_on | Interest_Trade.InterestConsent | ValidFrom | Passthrough |
| Deposits_since_IOB_date | DWH_dbo.Fact_CustomerAction | Amount | SUM(ActionTypeID=7) since IOB date |
| Withdrawals_since_IOB_date | DWH_dbo.Fact_CustomerAction | Amount | SUM(ActionTypeID=8) since IOB date |
| Has_Open_Position | BI_DB_PositionPnL | CID | EXISTS check for yesterday |
| DateAdded_Proof_of_Income | BI_DB_AML_Documents_Request | DocumentDateAdded_POIncome | Passthrough via LEFT JOIN |
| Payment_interest_June | DWH_dbo.etoro_History_Credit | Payment | SUM for June 2025 (hardcoded) |
| UpdateDate | — | — | GETDATE() at INSERT time |

### 5.2 ETL Pipeline

```
Interest_Trade.InterestConsent (opted-in customers, ConsentStatusID=1)
  -> External_Interest_Trade_InterestConsent
  -> SP_AML_IOB_Report (#BasePop step)
  -> BI_DB_dbo.BI_DB_AML_IOB_Report

etoro.Dictionary.* (Regulation, Country, PlayerStatus, PlayerStatusReasons,
                    PlayerStatusSubReasons, PlayerLevel)
  -> DWH_dbo.Dim_* (dimension tables)
  -> SP_AML_IOB_Report (#pop step)

DWH_dbo.V_Liabilities (RealizedEquity, yesterday)
  -> SP_AML_IOB_Report (#equity step)

DWH_dbo.etoro_History_Credit (IOB interest payments, June 2025 hardcoded)
  -> SP_AML_IOB_Report (#interest step)

DWH_dbo.Fact_CustomerAction (deposits=7, withdrawals=8, since IOB date)
  -> SP_AML_IOB_Report (#deposits, #CO steps)

BI_DB_dbo.BI_DB_PositionPnL (open positions, yesterday)
  -> SP_AML_IOB_Report (#open_position step)

BI_DB_dbo.BI_DB_AML_Documents_Request (Proof of Income date)
  -> SP_AML_IOB_Report (#final LEFT JOIN — causes row fan-out)
  -> BI_DB_dbo.BI_DB_AML_IOB_Report
```

| Step | Object | Description |
|------|--------|-------------|
| Sources | External_Interest_Trade_InterestConsent + Dim_Customer + 7 dim tables | Population build |
| Steps 2-6 | V_Liabilities, Fact_CustomerAction, BI_DB_PositionPnL, etoro_History_Credit | Financial enrichment |
| Step 7 | BI_DB_AML_Documents_Request | Proof of Income date (causes fan-out) |
| ETL | SP_AML_IOB_Report (Priority 0, Daily) | 6-step temp pipeline then TRUNCATE+INSERT |
| Target | BI_DB_dbo.BI_DB_AML_IOB_Report | ~5M rows (fan-out), ROUND_ROBIN HEAP |

---

## 6. Relationships

### 6.1 References To (this object reads from)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.External_Interest_Trade_InterestConsent | CID, GCID, ConsentStatusID, ValidFrom | IOB opt-in roster and consent date |
| DWH_dbo.Dim_Customer | All customer attributes | Population base and customer profile |
| DWH_dbo.Dim_Regulation | Name | Regulation name |
| DWH_dbo.Dim_Country | Name | Country name (x3: residence, citizenship, POB) |
| DWH_dbo.Dim_PlayerStatus | Name | Status name (excludes Blocked/BUR) |
| DWH_dbo.Dim_PlayerLevel | Name | Club tier name |
| DWH_dbo.Dim_PlayerStatusReasons | Name | Status reason name |
| DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | Status sub-reason name |
| DWH_dbo.V_Liabilities | RealizedEquity | Account balance (settled cash) for yesterday |
| DWH_dbo.Fact_CustomerAction | Amount | Deposits (ActionTypeID=7) and withdrawals (ActionTypeID=8) since IOB opt-in |
| DWH_dbo.etoro_History_Credit | Payment | IOB interest payments for June 2025 |
| BI_DB_dbo.BI_DB_PositionPnL | CID | Open position existence check for yesterday |
| BI_DB_dbo.BI_DB_AML_Documents_Request | DocumentDateAdded_POIncome | Most recent Proof of Income document date |

### 6.2 Referenced By (other objects read from this)

No downstream objects identified reading from this table in the current SP inventory. Consumed directly by the AML team via BI tools.

---

## 7. Sample Queries

### 7.1 Non-eligible IOB customers requiring review (deduplicated)

```sql
SELECT DISTINCT
       CID,
       Regulation,
       Country,
       Club,
       PlayerStatus,
       Is_Eligible,
       CAST(Date_IOB_switched_on AS DATE) AS IOB_Date
FROM   [BI_DB_dbo].[BI_DB_AML_IOB_Report]
WHERE  Is_Eligible = 0
ORDER  BY IOB_Date;
```

### 7.2 High withdrawal ratio since IOB opt-in (AML signal, deduplicated)

```sql
SELECT DISTINCT
       CID,
       Regulation,
       Country,
       Deposits_since_IOB_date,
       Withdrawals_since_IOB_date,
       Account_Balance,
       Payment_interest_June,
       DateAdded_Proof_of_Income
FROM   [BI_DB_dbo].[BI_DB_AML_IOB_Report]
WHERE  Withdrawals_since_IOB_date > Deposits_since_IOB_date * 0.8
AND    Deposits_since_IOB_date > 10000
ORDER  BY Withdrawals_since_IOB_date DESC;
```

### 7.3 IOB customers with high balance and no Proof of Income

```sql
SELECT DISTINCT
       CID,
       Regulation,
       Country,
       Account_Balance,
       Deposits_since_IOB_date,
       DateAdded_Proof_of_Income,
       VerificationLevelID
FROM   [BI_DB_dbo].[BI_DB_AML_IOB_Report]
WHERE  Account_Balance > 50000
AND    DateAdded_Proof_of_Income IS NULL
ORDER  BY Account_Balance DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-22 | Batch: 45 | Quality: 8.8/10 (Phase 16 adversarial eval PASS) | Schema: BI_DB_dbo*
*Tiers: 11 T1, 10 T2, 0 T3, 0 T4, 1 BL | Elements: 22/22, Logic: 9.0/10, Relationships: 8.5/10, Sources: 8.5/10*
*Object: BI_DB_dbo.BI_DB_AML_IOB_Report | Type: Table | Writer: SP_AML_IOB_Report | Priority: 0 | Refresh: Daily*

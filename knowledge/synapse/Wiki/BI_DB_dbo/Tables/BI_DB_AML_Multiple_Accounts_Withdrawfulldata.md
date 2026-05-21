# BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdrawfulldata

> AML multiple-accounts withdrawal detail table -- 48,529 rows listing every customer who shares a withdrawal FundingID with at least one other verified depositing customer, enriched with demographics, compliance status, financial liabilities snapshot, and the most recent risk alert. Refreshed daily via SP_AML_Multiple_Accounts (TRUNCATE + INSERT, Step 14).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_BillingWithdraw + DWH_dbo.Dim_Customer + DWH_dbo.V_Liabilities + AlertServiceDB (via SP_AML_Multiple_Accounts) |
| **Refresh** | Daily (SP_AML_Multiple_Accounts @Date, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_AML_Multiple_Accounts_Withdrawfulldata` is one of several tables produced by `SP_AML_Multiple_Accounts` for the **Multiple Accounts Dashboard**, an AML (Anti-Money Laundering) monitoring tool. This table provides the **withdrawal-side full detail**: for every FundingID (payment instrument) that was used to withdraw by 2 or more distinct verified, depositing customers, this table lists each of those customers along with their current demographics, compliance status, financial snapshot, and most recent risk alert.

The table serves compliance and AML analysts who need to identify patterns of shared payment instruments across multiple accounts -- a common indicator of fraud, money laundering, or multi-accounting violations. The SP filters to customers where `IsValidCustomer=1`, `IsDepositor=1`, and `VerificationLevelID>=2`, and excludes FundingIDs 1-7 (reserved/internal instruments).

**Key statistics** (sampled 2025-03-13):
- 48,529 rows, 46,527 distinct CIDs, 20,282 distinct FundingIDs
- 158 countries, 9 regulations represented
- ~20% of rows (9,687) have an associated risk alert
- ~14% (6,678) have an eToro Money AccountProgram
- All rows share the same UpdateDate (single daily TRUNCATE + INSERT)

The companion tables in the same SP are: `BI_DB_AML_Multiple_Accounts_Withdraw` (FID-level summary), `BI_DB_AML_Multiple_Accounts_Dep` / `_Dep_fulldata` (deposit side), `_DeviceID` / `_DeviceID_FullData` (shared device IDs), and `_SameIP` / `_SameIP_FullData` (shared IPs).

---

## 2. Business Logic

### 2.1 Shared FundingID Detection (Withdrawal Side)

**What**: Identifies FundingIDs used for withdrawals by 2+ distinct customers meeting compliance criteria.

**Columns Involved**: `FundingID`, `CID`

**Rules**:
- Source: `DWH_dbo.Fact_BillingWithdraw` joined to `DWH_dbo.Dim_Customer`
- Customer filter: `IsValidCustomer=1 AND IsDepositor=1 AND VerificationLevelID>=2`
- FundingID exclusion: IDs 1-7 are excluded (reserved/internal payment instruments)
- Withdrawal filter: `Amount_WithdrawToFunding > 0`
- Threshold: `HAVING COUNT(DISTINCT CID) >= 2` -- only shared instruments
- The DISTINCT keyword ensures each CID appears once per FundingID

### 2.2 Financial Snapshot Enrichment

**What**: Each customer row is enriched with their liabilities snapshot from V_Liabilities for the @Date parameter day.

**Columns Involved**: `Liabilities`, `RealizedEquity`, `PositionPnL`, `TotalEquity`

**Rules**:
- `Liabilities`: Customer obligations from V_Liabilities (InProcessCashouts + net equity above bonus credit)
- `RealizedEquity`: Direct passthrough from V_Liabilities (Fact_SnapshotEquity)
- `PositionPnL`: Unrealized profit/loss from V_Liabilities (Fact_CustomerUnrealized_PnL)
- `TotalEquity`: Computed as `ISNULL(Liabilities, 0) + ISNULL(ActualNWA, 0)` -- total customer balance including bonus credit
- LEFT JOIN: customers without a V_Liabilities row for the date will have NULL financial columns

### 2.3 Risk Alert Association

**What**: Each customer is matched to their most recent risk alert from AlertServiceDB.

**Columns Involved**: `AlertID`, `CreationDate`, `ModificationDate`, `AlertType`, `AlertTypeDescription`, `CategoryName`, `TriggerType`, `StatusType`, `StatusReason`

**Rules**:
- Source: `External_AlertServiceDB_Alert_Alert` with a 7-table join chain through AlertTemplate, AlertType, Category, TriggerType, AlertStatus, StatusType, StatusReason
- Recency: `ROW_NUMBER() OVER (PARTITION BY CID ORDER BY ModificationDate DESC)` with filter `RN=1` -- only the most recent alert
- LEFT JOIN: customers without any alert have NULL for all alert columns (~80% of rows)
- Observed alert types: PossibleCompromisedAccount, WithdrawWithLowTradingRatio, MultipleAccountsFunding

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP index. At 48K rows this is a small table -- full scans are fast. No distribution key optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Which FundingIDs are shared by the most customers? | `GROUP BY FundingID, COUNT(DISTINCT CID) ORDER BY 2 DESC` |
| Find blocked customers sharing payment instruments | `WHERE PlayerStatus LIKE '%Blocked%'` |
| Customers with AML-related alerts sharing instruments | `WHERE AlertType IS NOT NULL AND CategoryName = 'Risk'` |
| Country-level multi-accounting patterns | `GROUP BY Country ORDER BY COUNT(*) DESC` |
| High-value customers sharing instruments | `WHERE TotalEquity > 1000 ORDER BY TotalEquity DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdraw | ON FundingID | FID-level summary (total users, group type, approved amounts) |
| DWH_dbo.Dim_Customer | ON CID = RealCID | Additional customer attributes not in this table |
| DWH_dbo.Fact_BillingWithdraw | ON FundingID and CID | Individual withdrawal transaction details |

### 3.4 Gotchas

- **Daily full refresh**: The table is TRUNCATE + INSERT daily. All rows share the same UpdateDate. There is no history -- only the latest snapshot.
- **NULL financial columns**: Liabilities, RealizedEquity, PositionPnL, TotalEquity may be NULL if V_Liabilities has no row for the customer on the @Date. However, current data shows 0 NULL Liabilities rows.
- **NULL alert columns**: ~80% of rows have NULL for all alert columns (AlertID through StatusReason) -- these customers have no risk alerts.
- **AccountProgram sparsely populated**: Only ~14% of rows (6,678 / 48,529) have a non-empty AccountProgram. NULL/empty means the customer has no valid eToro Money account.
- **PlayerStatus trailing spaces**: Live data shows trailing whitespace on some PlayerStatus values (e.g., "Blocked                                            "). Use RTRIM() or LIKE for string comparisons.
- **FundingIDs 1-7 excluded**: The SP explicitly excludes these reserved internal FundingIDs. They will never appear in this table.
- **BirthDate is date-only**: The SP casts BirthDate to DATE, discarding the time component present in Dim_Customer.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 -- upstream wiki verbatim | (Tier 1 -{production source}) |
| Tier 2 -- SP/ETL code | (Tier 2 -{SP name}) |
| Tier 3 -- no upstream wiki, inferred from SP code and data | (Tier 3 -AlertServiceDB, no upstream wiki) |

### 4.1 Customer Identity & Demographics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FundingID | int | YES | FK to Billing.Funding -- the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected. This table only contains FundingIDs shared by 2+ customers; IDs 1-7 (reserved/internal) are excluded. Passthrough from Fact_BillingWithdraw. (Tier 1 -Billing.Withdraw) |
| 2 | CID | int | YES | Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in Dim_Customer. (Tier 1 -Customer.CustomerStatic) |
| 3 | GCID | int | YES | Group Customer ID -- cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from Dim_Customer. (Tier 1 -Customer.CustomerStatic) |
| 4 | UserName | nvarchar(250) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer. (Tier 1 -Customer.CustomerStatic) |
| 5 | BirthDate | datetime | YES | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. DWH note: CAST to DATE in SP (time component discarded), stored as datetime in this table. Passthrough from Dim_Customer. (Tier 1 -Customer.CustomerStatic) |
| 6 | PhoneVerifiedName | nvarchar(250) | YES | Human-readable verification state label for the customer's phone number. Values: NotVerified, AutomaticallyVerified, ManualyVerified (production typo preserved), Initiated, Rejected, AbuseFlag. Dim-lookup passthrough from Dim_PhoneVerified via Dim_Customer.PhoneVerifiedID. (Tier 1 -Dictionary.PhoneVerified) |
| 7 | RegisteredReal | datetime | YES | Account registration date (renamed from Registered). Default=getdate(). Passthrough from Dim_Customer. (Tier 1 -Customer.CustomerStatic) |
| 8 | FirstDepositDate | datetime | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. Passthrough from Dim_Customer. (Tier 2 -SP_Dim_Customer) |
| 9 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified (34.2%), 1=partial (12.4%), 2=intermediate (6.2%), 3=fully verified (47.1%). Default=0. This table only contains customers with VerificationLevelID >= 2. Passthrough from Dim_Customer. (Tier 1 -BackOffice.Customer) |
| 10 | Country | nvarchar(250) | YES | Full country name in English. Unique per row in Dim_Country. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via Dim_Customer.CountryID. (Tier 1 -Dictionary.Country) |
| 11 | Regulation | nvarchar(250) | YES | Short code for the regulatory entity governing this customer's account. Used in analytics dashboards. Values match production Dictionary.Regulation.Name. Dim-lookup passthrough from Dim_Regulation.Name via Dim_Customer.RegulationID. (Tier 1 -Dictionary.Regulation) |
| 12 | PlayerStatus | nvarchar(250) | YES | Human-readable restriction state label for the customer's account. Values: Normal, Blocked, Blocked Upon Request, Warning, Under Investigation, Chat Blocked, Trade & MIMO Blocked, Deposit Blocked, Copy Block, Pending Verification, Failed Verification, Block Deposit & Trading, and others. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. Dim-lookup passthrough from Dim_PlayerStatus.Name via Dim_Customer.PlayerStatusID. (Tier 1 -Dictionary.PlayerStatus) |
| 13 | PlayerStatusReason | nvarchar(250) | YES | Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), By request (22), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). Used in BackOffice reporting and customer history views. Dim-lookup passthrough from Dim_PlayerStatusReasons.Name via Dim_Customer.PlayerStatusReasonID. (Tier 1 -Dictionary.PlayerStatusReasons) |
| 14 | PlayerStatusSubReasonName | nvarchar(250) | YES | Human-readable sub-reason label (renamed from production `Name`). Nullable. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check. Key values: Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75). Dim-lookup passthrough from Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName via Dim_Customer.PlayerStatusSubReasonID. (Tier 1 -Dictionary.PlayerStatusSubReasons) |
| 15 | Club | nvarchar(250) | YES | eToro Club tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Dim-lookup passthrough from Dim_PlayerLevel.Name via Dim_Customer.PlayerLevelID. (Tier 1 -Dictionary.PlayerLevel) |
| 16 | AffiliateID | int | YES | Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. Passthrough from Dim_Customer. (Tier 1 -Customer.CustomerStatic) |
| 17 | City | nvarchar(250) | YES | City in Unicode. Passthrough from Dim_Customer. (Tier 1 -Customer.CustomerStatic) |
| 18 | Zip | nvarchar(250) | YES | Postal code. Used in LinkedAccountHash1. Passthrough from Dim_Customer. (Tier 1 -Customer.CustomerStatic) |
| 19 | BuildingNumber | nvarchar(250) | YES | Building/apartment number. Separate from Address for structured address storage. Passthrough from Dim_Customer. (Tier 1 -Customer.CustomerStatic) |
| 20 | Gender | nvarchar(250) | YES | Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only in production. Used in LinkedAccountHash1. Passthrough from Dim_Customer. (Tier 1 -Customer.CustomerStatic) |
| 21 | EvMatchStatusName | nvarchar(250) | YES | Human-readable label for the EV (eVerification) identity match status. Values: None, PartiallyVerified, Verified, NotVerified. Renamed from `Name` in the production source. Dim-lookup passthrough from Dim_EvMatchStatus via Dim_Customer.EvMatchStatus. (Tier 2 -SP_AML_Multiple_Accounts, via Dim_EvMatchStatus) |
| 22 | HasWallet | int | YES | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. Passthrough from Dim_Customer. (Tier 1 -BackOffice.Customer) |
| 23 | AccountProgram | nvarchar(250) | YES | eToro Money account program display name (e.g., "iban", "card"). NULL or empty when the customer has no valid eToro Money account. Sourced from eMoney_Dim_Account where IsValidETM=1 and IsTestAccount=0. (Tier 2 -SP_eMoney_Dim_Account) |

### 4.2 Financial Snapshot

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 24 | Liabilities | money | YES | Customer obligations to the platform -- InProcessCashouts plus the portion of net equity above bonus credit. From V_Liabilities for the @Date parameter day. NULL if no V_Liabilities row exists for the customer on that date. (Tier 2 -V_Liabilities, computed) |
| 25 | RealizedEquity | money | YES | Customer realized equity snapshot from Fact_SnapshotEquity via V_Liabilities. Passthrough from V_Liabilities. (Tier 2 — Fact_SnapshotEquity) |
| 26 | PositionPnL | money | YES | Unrealized profit/loss on open positions from Fact_CustomerUnrealized_PnL via V_Liabilities. Passthrough from V_Liabilities. (Tier 2 — Fact_CustomerUnrealized_PnL) |
| 27 | TotalEquity | money | YES | Total customer balance including bonus credit. Computed as `ISNULL(Liabilities, 0) + ISNULL(ActualNWA, 0)` in SP_AML_Multiple_Accounts. Equivalent to RealizedEquity + PositionPnL per Confluence V_Liabilities documentation. (Tier 2 -SP_AML_Multiple_Accounts) |

### 4.3 Risk Alert (Most Recent per CID)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 28 | AlertID | int | YES | Unique identifier of the most recent risk alert for this customer from AlertServiceDB. NULL (~80% of rows) when the customer has no risk alerts. Selected via ROW_NUMBER() PARTITION BY CID ORDER BY ModificationDate DESC, RN=1. (Tier 3 -AlertServiceDB, no upstream wiki) |
| 29 | CreationDate | datetime | YES | Timestamp when the most recent risk alert was created in AlertServiceDB. NULL when no alert exists. (Tier 3 -AlertServiceDB, no upstream wiki) |
| 30 | ModificationDate | datetime | YES | Timestamp of the most recent modification to the alert record. Used for recency ranking (ROW_NUMBER ORDER BY ModificationDate DESC). NULL when no alert exists. (Tier 3 -AlertServiceDB, no upstream wiki) |
| 31 | AlertType | nvarchar(250) | YES | Alert type name from AlertServiceDB dictionary. Observed values include: PossibleCompromisedAccount, WithdrawWithLowTradingRatio, MultipleAccountsFunding. Resolved via Alert -> AlertTemplate -> AlertType dictionary chain. NULL when no alert exists. (Tier 3 -AlertServiceDB, no upstream wiki) |
| 32 | AlertTypeDescription | nvarchar(250) | YES | Human-readable description of the alert type. Observed values: "Possible compromised account", "WithdrawWithLowTradingRatio", "Multiple Accounts Funding". Resolved via Alert -> AlertTemplate -> AlertType.Description. NULL when no alert exists. (Tier 3 -AlertServiceDB, no upstream wiki) |
| 33 | CategoryName | nvarchar(250) | YES | Alert category from AlertServiceDB dictionary. Observed values: Risk, Cashouts. Resolved via Alert -> AlertTemplate -> Category dictionary. NULL when no alert exists. (Tier 3 -AlertServiceDB, no upstream wiki) |
| 34 | TriggerType | nvarchar(250) | YES | Alert trigger type from AlertServiceDB dictionary. Observed values: OneTime, Recurring. Resolved via Alert -> AlertTemplate -> TriggerType dictionary. NULL when no alert exists. (Tier 3 -AlertServiceDB, no upstream wiki) |
| 35 | StatusType | nvarchar(250) | YES | Current status of the alert. Observed values: Clear, Open, InProgress. Resolved via Alert -> AlertStatus -> StatusType dictionary. NULL when no alert exists. (Tier 3 -AlertServiceDB, no upstream wiki) |
| 36 | StatusReason | nvarchar(250) | YES | Reason for the current alert status. Observed values: No action needed, Resolved with client. Resolved via Alert -> AlertStatus -> StatusReason dictionary. NULL when no alert exists. (Tier 3 -AlertServiceDB, no upstream wiki) |

### 4.4 Metadata

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 37 | UpdateDate | datetime | YES | ETL load timestamp. GETDATE() at INSERT time in SP_AML_Multiple_Accounts. All rows share the same value per daily refresh. Not a business date. (Tier 2 -SP_AML_Multiple_Accounts) |

---

## 5. Lineage

### 5.1 Production Sources

| Source | DWH Columns | Transform |
|--------|-------------|-----------|
| DWH_dbo.Fact_BillingWithdraw (fbw) | FundingID | DISTINCT FundingIDs shared by 2+ customers (HAVING COUNT(DISTINCT CID) >= 2) |
| DWH_dbo.Dim_Customer (dc) | CID (from RealCID), GCID, UserName, BirthDate (CAST to DATE), RegisteredReal, FirstDepositDate, VerificationLevelID, AffiliateID, City, Zip, BuildingNumber, Gender, HasWallet | Filtered: IsValidCustomer=1, IsDepositor=1, VerificationLevelID>=2 |
| DWH_dbo.Dim_Country (dc1) | Country (from Name) | JOIN on CountryID = DWHCountryID |
| DWH_dbo.Dim_Regulation (dr) | Regulation (from Name) | JOIN on DWHRegulationID = RegulationID |
| DWH_dbo.Dim_PlayerStatus (dps) | PlayerStatus (from Name) | JOIN on PlayerStatusID |
| DWH_dbo.Dim_PlayerLevel (dpl) | Club (from Name) | JOIN on PlayerLevelID |
| DWH_dbo.Dim_PhoneVerified (dpv) | PhoneVerifiedName | LEFT JOIN on PhoneVerifiedID |
| DWH_dbo.Dim_PlayerStatusReasons (dpsr) | PlayerStatusReason (from Name) | LEFT JOIN on PlayerStatusReasonID |
| DWH_dbo.Dim_PlayerStatusSubReasons (dpssr) | PlayerStatusSubReasonName | LEFT JOIN on PlayerStatusSubReasonID |
| DWH_dbo.Dim_EvMatchStatus (dems) | EvMatchStatusName | LEFT JOIN on EvMatchStatusID = EvMatchStatus |
| eMoney_dbo.eMoney_Dim_Account (mda) | AccountProgram | LEFT JOIN on RealCID = CID, IsValidETM=1, IsTestAccount=0 |
| DWH_dbo.V_Liabilities (vl) | Liabilities, RealizedEquity, PositionPnL, TotalEquity (computed) | LEFT JOIN on CID and DateID = @DateID |
| AlertServiceDB (7-table chain) | AlertID, CreationDate, ModificationDate, AlertType, AlertTypeDescription, CategoryName, TriggerType, StatusType, StatusReason | ROW_NUMBER() PARTITION BY CID ORDER BY ModificationDate DESC, RN=1 |
| ETL-computed | UpdateDate | GETDATE() at INSERT |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_BillingWithdraw (withdrawal transactions)
  + DWH_dbo.Dim_Customer (IsValidCustomer=1, IsDepositor=1, VerificationLevelID>=2)
  |
  v [SP Step 02: #fid_Withdraw — FundingIDs with COUNT(DISTINCT CID) >= 2]
  |
  v [SP Step 06: #fid_full_data_withdraw — DISTINCT customer details per shared FundingID]
      + DWH_dbo.Dim_Country, Dim_Regulation, Dim_PlayerStatus, Dim_PlayerLevel
      + DWH_dbo.Dim_PhoneVerified, Dim_PlayerStatusReasons, Dim_PlayerStatusSubReasons
      + DWH_dbo.Dim_EvMatchStatus, eMoney_dbo.eMoney_Dim_Account
  |
  v [SP Step 06: #CO_liabilities — LEFT JOIN V_Liabilities on CID + @DateID]
  |
  v [SP Step 06: #fulldataco — LEFT JOIN #riskalert (most recent alert per CID)]
      AlertServiceDB: Alert -> AlertTemplate -> AlertType/Category/TriggerType
                      Alert -> AlertStatus -> StatusType/StatusReason
  |
  v [SP Step 14: TRUNCATE + INSERT]
BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdrawfulldata (48,529 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| FundingID | DWH_dbo.Fact_BillingWithdraw | Withdrawal transactions for this payment instrument |
| CID | DWH_dbo.Dim_Customer | Customer demographics and compliance attributes |
| Country | DWH_dbo.Dim_Country | Country lookup (denormalized name stored) |
| Regulation | DWH_dbo.Dim_Regulation | Regulation lookup (denormalized name stored) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdraw | FundingID | FID-level withdrawal summary (companion table in same SP) |

---

## 7. Sample Queries

### 7.1 FundingIDs shared by the most customers

```sql
SELECT FundingID,
       COUNT(DISTINCT CID) AS SharedCustomers,
       COUNT(CASE WHEN AlertID IS NOT NULL THEN 1 END) AS WithAlerts
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Withdrawfulldata]
GROUP BY FundingID
ORDER BY SharedCustomers DESC;
```

### 7.2 Blocked customers sharing payment instruments with active alerts

```sql
SELECT CID, UserName, Country, Regulation,
       RTRIM(PlayerStatus) AS PlayerStatus,
       PlayerStatusReason,
       AlertType, StatusType,
       TotalEquity
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Withdrawfulldata]
WHERE PlayerStatus LIKE '%Blocked%'
  AND AlertID IS NOT NULL
ORDER BY TotalEquity DESC;
```

### 7.3 Country-level multi-accounting withdrawal patterns

```sql
SELECT Country,
       COUNT(DISTINCT CID) AS Customers,
       COUNT(DISTINCT FundingID) AS SharedFundingIDs,
       SUM(CASE WHEN AlertID IS NOT NULL THEN 1 ELSE 0 END) AS AlertCount
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Withdrawfulldata]
GROUP BY Country
ORDER BY Customers DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources available for this regen-harness run. SP comment header attributes authorship to Lior Ben Dor (2023-11-13, migrated to Synapse).

---

*Generated: 2026-04-28 | Quality: 8.5/10*
*Tiers: 22 T1, 6 T2, 9 T3, 0 T4, 0 T5 | Elements: 37/37, Logic: 9/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdrawfulldata | Type: Table | Production Source: DWH_dbo.Fact_BillingWithdraw + Dim_Customer + V_Liabilities + AlertServiceDB*

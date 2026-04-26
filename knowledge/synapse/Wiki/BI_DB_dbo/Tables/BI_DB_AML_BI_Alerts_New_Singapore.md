# BI_DB_AML_BI_Alerts_New_Singapore

**Schema**: BI_DB_dbo | **Type**: Table | **Priority**: P0 | **Generated**: 2026-04-22

---

## 1. Business Meaning

Daily AML alert log for customers under **MAS (Monetary Authority of Singapore)** regulation — eToro's Singapore regulatory jurisdiction. The SP fires a Singapore-specific set of alert rules covering geographic anomalies, deposit/withdrawal structuring, dormancy, excessive account value changes, expiring identity documents, and KYC income discrepancies.

This is the most geographically-specialized of the three AML alert tables. The alert rule set (`SGNew009`–`SGNew032` + `SG GEO005`) is designed for MAS compliance requirements and differs substantially from the base `BI_DB_AML_BI_Alerts_New` alert codes. The unique `AdditionalInfoExpiryDate` column captures document expiry data for the `SGNew028` (Expiring ID) alert.

**Population scope**: Customers with `RegulationID = 13 OR DesignatedRegulationID = 13` (MAS) who are depositors (`IsDepositor=1`) and not blocked. The "designated regulation" filter means customers primarily regulated under FCA, FSA Seychelles, etc. who also have a Singapore designation are included — explaining why FCA (75.4%) dominates the Regulation column despite this being a Singapore-focused table.

**Owner**: Pavlina Masoura (created 2025-02-20, last modified 2025-08-25).

---

## 2. ETL Pipeline

### 2.1 Load Pattern

```
SP_AML_BI_Alerts_New_Singapore @Date
  |
  |-- DELETE FROM BI_DB_AML_BI_Alerts_New_Singapore WHERE AlertDate = @Date
  |-- [build temp tables: #dimcustomer, #pop (MAS scope), deposits, withdrawals,
  |    customer actions (90d window), KYC panels, high-risk country lookups]
  |-- [compute 20+ alert rule branches (UNION ALL into #final)]
  |-- [join #final to self for Total_Alerts_of_TheCategory counter]
  |-- [apply dedup suppression: SGNew025 within 14 days, SGNew015 within 90 days]
  |-- INSERT into target
  v
BI_DB_AML_BI_Alerts_New_Singapore (accumulating)
```

**Pattern**: Accumulating DELETE+INSERT. Re-running for the same `@Date` replaces that day's rows only.

**Dedup suppression**: Unlike the base table, this SP actively suppresses certain recurring alerts:
- `SGNew025` (Daily Deposits Structuring) — not inserted if same CID already has SGNew025 within the last 14 days
- `SGNew015` (Account Funded But No Trading Activity) — not inserted if same CID already has SGNew015 within the last 90 days

### 2.2 Population Scope

Customers are filtered via: `RegulationID=13 OR DesignatedRegulationID=13`. This includes both primary MAS customers and customers whose account is designated for Singapore oversight regardless of primary regulation. Verification Level must be 3 (fully verified). Employee accounts excluded via `PlayerLevelID <> 4`.

### 2.3 Alert Categories

| AlertCategory | Live % | Description |
|---------------|--------|-------------|
| MIMO - Login | 58.4% | Geographic login anomalies |
| MIMO - Deposit | 23.1% | Deposit/login country mismatches |
| MIMO | 9.4% | Structuring, HRC transactions, crypto, profile changes |
| OnBoarding | 4.2% | KYC income/employment mismatches, dormancy, inactivity |
| MIMO - Cashouts | 0.9% | Cashout country mismatches |

*Note: AlertCategory values contain trailing spaces in most branches (e.g. `'OnBoarding '`, `'MIMO '`). Apply RTRIM() when filtering.*

### 2.4 Alert Rules

| AlertType | AlertCategory | Trigger |
|-----------|--------------|---------|
| SGNew009: Unjustified Source of Income | OnBoarding | KYC Q18 source-of-income inconsistent with deposit level |
| SGNew010: Count of Deposits VS Debit cards | MIMO | Excessive deposits relative to registered debit cards |
| SG New 011A: Not Employed AND total approved deposits >= USD50k | OnBoarding | KYC Q9 = unemployed and lifetime deposits >= $50K |
| SG New 011B: Not Employed AND total approved deposits >= USD100k | OnBoarding | KYC Q9 = unemployed and lifetime deposits >= $100K |
| SGNew012: Deposit Country <> Country of Birth/Nationality/Residence | MIMO - Deposit | Deposit originated from a country different from declared residence/birth/nationality |
| SGNew013: Withdrawal Country <> Country of Birth/Nationality/Residence | MIMO - Cashouts | Cashout to a country different from declared residence/birth/nationality |
| SGNew014: Login Country <> Country of Birth/Nationality/Residence | MIMO - Deposit | Login from a country different from declared residence/birth/nationality (last 45 days, proxy excluded) |
| SGNew015: Account Funded But No Trading Activity | OnBoarding | Depositor with no trading positions (90-day dedup) |
| SGNew016: Activity Seen In A Dormant Account | OnBoarding | Activity detected in previously dormant account |
| SGNew017: Excessive Change in Account Value | MIMO | Unusually large swing in portfolio value |
| SGNew018: Excessive Daily Deposits (Account Level) | MIMO | Daily deposits exceeding per-account threshold |
| SGNew019: Excessive Daily Deposits (Logical Entity Level) | MIMO | Daily deposits exceeding group/entity threshold |
| SGNew020: Excessive Daily Withdrawals (Account Level) | MIMO | Daily withdrawals exceeding per-account threshold |
| SGNew021: Excessive Daily Withdrawals (Logical Entity Level) | MIMO | Daily withdrawals exceeding group/entity threshold |
| SGNew023: Frequent Changes to Clients Data | MIMO | Multiple profile data changes within a short window |
| SGNew024: U-Turn of Funds | MIMO | Deposit immediately followed by equivalent cashout |
| SGNew025: Daily Deposits Structuring | MIMO | Repeated near-threshold deposits ($10K–$19,999 range; 14-day dedup) |
| SGNew026: Daily Withdrawals Structuring | MIMO | Repeated near-threshold withdrawals |
| SGNew027: Transactions to/from High-Risk Countries | MIMO | Activity involving HRC-flagged countries |
| SGNew028: Expiring ID | MIMO | Customer identity document approaching expiry (populates AdditionalInfoExpiryDate) |
| SG GEO005: HRC Logins | MIMO - Login | Logins from High-Risk Countries (>15 login days required) |
| SGNew029: Buy & Transfer Out Cryptos Within a Short Period | MIMO | Rapid crypto purchase and transfer |
| SGNew032: Multiple Jurisdictions Login Within 2 Hours | MIMO | Logins from 2+ distinct jurisdictions within 2-hour window |

---

## 3. Shape

| Property | Value |
|----------|-------|
| Distribution | ROUND_ROBIN |
| Index | HEAP |
| Columns | 15 |
| CID type | bigint (differs from base table int) |
| AlertDate type | datetime (stores as date 00:00:00 time; differs from base table date) |
| Live Row Count | 2,133 |
| Date Range | 2025-02-01 to 2026-04-10 |
| Distinct CIDs | 1,431 |

---

## 4. Elements

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 1 | CID | bigint | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) | T1 |
| 2 | AlertID | nvarchar(max) | YES | Synthetic UUID (NEWID()) generated at INSERT time. Not stable — re-running for the same date generates new GUIDs. Do not use as a join key. | T2 |
| 3 | AlertCategory | nvarchar(max) | YES | Classification family for the alert. Values: 'OnBoarding ', 'MIMO ', 'MIMO - Deposit', 'MIMO - Cashouts', 'MIMO - Login', 'MIMO'. Note trailing space in most values — apply RTRIM() when filtering. | T2 |
| 4 | Total_Alerts_of_TheCategory | bigint | YES | Count of prior firings for this CID × AlertType combination, plus 1. Tracks how many times this customer has triggered this specific alert. | T2 |
| 5 | AlertDate | datetime | NOT NULL | The date (@Date parameter) for which the alert was generated, stored as datetime with time 00:00:00. | T2 |
| 6 | AlertType | nvarchar(max) | YES | SG-series alert code and description. 23 defined codes; 20 appear in live data. See alert rules table above. | T2 |
| 7 | Regulation | nvarchar(max) | YES | Customer's regulation name at SP run time. Dominated by FCA (75.4%) because MAS-designated customers include those with FCA as primary regulation. | T2 |
| 8 | Country | nvarchar(max) | YES | Customer's KYC country name at SP run time via Fact_SnapshotCustomer JOIN Dim_Country. | T2 |
| 9 | PlayerStatus | nvarchar(max) | YES | Customer's player status at SP run time. Blocked (2) and Blocked Upon Request (4) excluded at population level. | T2 |
| 10 | Club | nvarchar(max) | YES | Customer's club level name at SP run time (Bronze/Silver/Gold/Platinum/Diamond/Platinum Plus). | T2 |
| 11 | AccountType | nvarchar(max) | YES | Customer's account type name at SP run time (Private/Corporate/etc.). | T2 |
| 12 | RiskScoreName | nvarchar(max) | YES | Current risk classification label from Dim_RiskClassification via Fact_SnapshotCustomer snapshot JOIN (not change-history LAG). | T2 |
| 13 | HasWallet | int | YES | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. (Tier 1 — BackOffice.Customer) | T1 |
| 14 | AdditionalInfoExpiryDate | date | YES | Populated ONLY for `SGNew028: Expiring ID` alerts. Stores the customer's identity document expiry date that triggered the alert. NULL for all other alert types. | T2 |
| 15 | UpdateDate | datetime | NOT NULL | GETDATE() at INSERT time. ETL metadata — do not use for business logic. | Blacklist |

---

## 5. Distributions (Live Data)

### AlertType Distribution

| AlertType | Count | % |
|-----------|-------|---|
| SG GEO005: HRC Logins | 1,246 | 58.4% |
| SGNew014: Login Country <> Country of Birth/Nationality/Residence | 431 | 20.2% |
| SGNew032: Multiple Jurisdictions Login Within 2 Hours | 71 | 3.3% |
| SGNew016: Activity Seen In A Dormant Account | 69 | 3.2% |
| SGNew012: Deposit Country <> Country of Birth/Nationality/Residence | 61 | 2.9% |
| SGNew010: Count of Deposits VS Debit cards | 58 | 2.7% |
| SGNew017: Excessive Change in Account Value | 23 | 1.1% |
| SGNew018: Excessive Daily Deposits (Account Level) | 22 | 1.0% |
| SGNew019: Excessive Daily Deposits (Logical Entity Level) | 22 | 1.0% |
| SGNew021: Excessive Daily Withdrawals (Logical Entity Level) | 21 | 1.0% |
| SGNew023: Frequent Changes to Clients Data | 21 | 1.0% |
| SGNew013: Withdrawal Country <> Country of Birth/Nationality/Residence | 19 | 0.9% |
| SGNew020: Excessive Daily Withdrawals (Account Level) | 18 | 0.8% |
| SGNew027: Transactions to/from High-Risk Countries | 18 | 0.8% |
| Others (SGNew009, SGNew011A/B, SGNew015, SGNew025, SGNew026) | 33 | 1.5% |

### Regulation Distribution

| Regulation | Count | % |
|------------|-------|---|
| FCA | 1,609 | 75.4% |
| FSA Seychelles | 215 | 10.1% |
| ASIC & GAML | 145 | 6.8% |
| MAS | 131 | 6.1% |
| BVI | 21 | 1.0% |
| Others | 15 | 0.7% |

---

## 6. Relationships

| Related Table | Join Type | Join Key | Notes |
|---------------|-----------|----------|-------|
| BI_DB_AML_BI_Alerts_New | Sibling | CID | Base global alert table; Singapore rules are MAS-only overlay |
| DWH_dbo.Dim_Customer | Reference | CID = RealCID | Source for CID, HasWallet; T1 columns |
| DWH_dbo.Fact_SnapshotCustomer | Source | CID = RealCID | Customer snapshot; risk classification |
| DWH_dbo.Fact_BillingDeposit | Source | CID | Deposit aggregation (lifetime, rolling windows) |
| DWH_dbo.Fact_CustomerAction | Source | CID = RealCID | Login, deposit, cashout event detection (90-day window) |
| BI_DB_dbo.BI_DB_KYC_Panel | Source | CID = RealCID | Q9 employment, Q15/Q18 source of income |

---

## 7. Sample Queries

```sql
-- All Singapore alerts for a specific customer
SELECT AlertType, AlertDate, AlertCategory, AdditionalInfoExpiryDate
FROM BI_DB_dbo.BI_DB_AML_BI_Alerts_New_Singapore
WHERE CID = <cid>
ORDER BY AlertDate DESC;

-- Expiring ID alerts with document expiry date
SELECT CID, AlertDate, AdditionalInfoExpiryDate
FROM BI_DB_dbo.BI_DB_AML_BI_Alerts_New_Singapore
WHERE AlertType = 'SGNew028: Expiring ID'
  AND AdditionalInfoExpiryDate IS NOT NULL
ORDER BY AdditionalInfoExpiryDate;

-- Geo anomaly summary by regulation
SELECT RTRIM(AlertCategory) AS AlertCategory, Regulation, COUNT(*) AS Cnt
FROM BI_DB_dbo.BI_DB_AML_BI_Alerts_New_Singapore
WHERE AlertDate >= DATEADD(MONTH, -1, GETDATE())
GROUP BY RTRIM(AlertCategory), Regulation
ORDER BY Cnt DESC;
```

---

## 8. Notes & Gotchas

- **FCA dominates despite MAS scope**: The population filter includes `DesignatedRegulationID=13`, capturing FCA/FSA Seychelles customers who are also MAS-designated. FCA represents 75.4% of rows — this is correct and expected.
- **AlertCategory trailing spaces**: All category values except standalone 'MIMO' and 'MIMO - Deposit'/'MIMO - Cashouts'/'MIMO - Login' have a trailing space (e.g. `'OnBoarding '`, `'MIMO '`). Always use `RTRIM(AlertCategory)` or `LIKE` for filtering.
- **CID is bigint here, int in base table**: Unlike `BI_DB_AML_BI_Alerts_New` (int CID), this table uses bigint. Do not assume type compatibility in JOINs.
- **AlertDate is datetime, not date**: Stored as `2025-02-01 00:00:00`. Comparing with a DATE column may behave unexpectedly. Cast with `CAST(AlertDate AS DATE)`.
- **AdditionalInfoExpiryDate is only meaningful for SGNew028**: All other alert types will have NULL here. Do not use this column for general date filtering.
- **SGNew028 not in live data**: The Expiring ID alert fires for document expiry dates approaching future; may not appear in historical data if no customers currently have expiring documents. The column exists and is populated when the alert fires.
- **Dedup suppression**: SGNew025 will not appear more than once per CID in any 14-day window; SGNew015 will not appear more than once per CID in any 90-day window. The SP enforces this at INSERT time.
- **KYC Q15 vs Q18 bug history**: Before 2025-05-21, `SGNew011A` incorrectly read Q15 answers instead of Q18. Historical rows before that date may contain incorrect alert signals.

---

*Quality Score: 9.1/10 | Tiers: 2 T1, 12 T2, 1 Blacklist | SP: SP_AML_BI_Alerts_New_Singapore*

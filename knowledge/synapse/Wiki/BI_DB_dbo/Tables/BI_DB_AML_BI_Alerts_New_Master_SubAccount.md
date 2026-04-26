# BI_DB_AML_BI_Alerts_New_Master_SubAccount

**Schema**: BI_DB_dbo | **Type**: Table | **Priority**: P0 | **Generated**: 2026-04-22

---

## 1. Business Meaning

Daily AML alert log for customers participating in **master/sub-account relationships** — where a single individual holds multiple linked eToro accounts (one master, one or more sub-accounts). The SP aggregates deposit activity across all accounts in the group and fires alerts when the **combined** lifetime or annual deposits breach regulatory thresholds or violate KYC economic profile declarations.

This table extends the base `BI_DB_AML_BI_Alerts_New` alert system with a Master Account dimension: each alert row carries both `CID` (the specific account that triggered the condition) and `MasterAccountCID` (the umbrella account for the entire group). The counter `Total_Alerts_of_TheCategory` is tracked at master-account level, not individual CID level.

**Key behavioral differences from BI_DB_AML_BI_Alerts_New:**
- Scoped to master/sub account customers only (requires `External_etoro_BackOffice_Customer.MasterAccountCID IS NOT NULL`)
- Deposit thresholds aggregate across all accounts in the master group
- All 12 alert codes are `OnBoarding` category (no MIMO/cashout variants)
- SP only inserts first-time alerts (`Total_Alerts_of_TheCategory = 1`), except MA008 which fires on every additional $1M milestone above $2M
- Risk classification sourced from `DWH_dbo.Dim_RiskClassification` (change history), not the External risk table

**Owner**: Georgios Kyriakou (created 2025-02-10). Last modified: 2025-11-10 (Pavlina Masoura — removed employee accounts).

---

## 2. ETL Pipeline

### 2.1 Load Pattern

```
SP_AML_BI_Alerts_New_Master_SubAccount @Date
  |
  |-- DELETE FROM BI_DB_AML_BI_Alerts_New_Master_SubAccount WHERE AlertDate = @Date
  |-- [build temp tables: #cids, #risk_score, deposits, KYC panels, thresholds]
  |-- [compute #final via 12 alert rule branches (UNION ALL)]
  |-- [join #final to self to compute Total_Alerts_of_TheCategory per MasterAccountCID]
  |-- INSERT into target WHERE Total_Alerts_of_TheCategory = 1
  |                            OR AlertType = 'MA008'
  v
BI_DB_AML_BI_Alerts_New_Master_SubAccount (accumulating)
```

**Pattern**: Accumulating DELETE+INSERT (identical to base alerts table). Re-running for the same `@Date` replaces that day's rows only. Prior dates preserved.

**First-Time Filter**: Unlike the base table, this SP explicitly filters `Total_Alerts_of_TheCategory = 1` at INSERT time. MA008 (recurring $1M milestones) is excluded from this filter and inserts on every qualifying date.

### 2.2 Customer Scope

The SP starts by building `#cids` from `BI_DB_dbo.External_etoro_BackOffice_Customer`, selecting all master+sub-account pairs where:
- `MasterAccountCID IS NOT NULL AND <> 0`
- Both the CID and MasterAccountCID pass: `IsValidCustomer=1`, `PlayerStatusID NOT IN (2,4)`, `VerificationLevelID IN (2,3)`, `PlayerLevelID <> 4` (excludes employees)

### 2.3 Deposit Aggregation

Deposits are rolled up to master-account level in `#TotalDepositsLifetimeCombineMasterandSubAccount` — the SUM of lifetime deposits across all sub-accounts for the same MasterAccountCID. Threshold tables (`#50K`, `#100K`, ..., `#6M`) track the first date each combined deposit total crossed each milestone.

### 2.4 Risk Classification Source

Risk comes from `DWH_dbo.Fact_SnapshotCustomer` + `DWH_dbo.Dim_RiskClassification`, using the most recent change detected via LAG(). This differs from the base table which uses `External_RiskClassification_dbo_V_RiskClassificationDataLake`.

### 2.5 Alert Rules

| AlertType | Trigger Condition | Regulations Scoped |
|-----------|------------------|-------------------|
| MA001 | Combined lifetime deposits >= $50K AND RC = High/Unacceptable | CySEC, ASIC, ASIC & GAML, FSA Seychelles |
| MA002 | Combined lifetime deposits >= $100K AND RC = High/Unacceptable | FSRA, FCA |
| MA003 | Combined lifetime deposits >= $250K (first time) | All |
| MA004 | Combined lifetime deposits >= $500K (first time) | All |
| MA005 | Combined lifetime deposits >= $1M (first time) | All |
| MA006 | Combined lifetime deposits >= $1.5M (first time) | All |
| MA007 | Combined lifetime deposits >= $2M (first time) | All |
| MA008 | Each additional $1M above $2M milestone (recurring) | All |
| MA009 | KYC Q15 Source of Income inconsistent with deposit level (Pension/Inheritance/etc.) | All |
| MA011 | KYC Q10+Q11 Annual Income < Current-year deposits | All |
| MA013 | KYC Annual Planned Investments < Current-year deposits | All |
| MA014 | Occupation inconsistent with deposit level | All |

---

## 3. Shape

| Property | Value |
|----------|-------|
| Distribution | ROUND_ROBIN |
| Index | HEAP |
| Columns | 15 |
| Live Row Count | 1,495 |
| Date Range | 2025-01-01 to 2026-04-03 |
| Distinct CIDs | 1,273 |
| Distinct MasterCIDs | 1,168 |

---

## 4. Elements

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 1 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) | T1 |
| 2 | MasterAccountCID | int | YES | The CID of the master account in the master/sub-account group. Equals CID when the triggering customer is the master account itself; differs when a sub-account activity triggered the alert. Counter and deposit aggregations operate at this level. | T2 |
| 3 | AlertID | nvarchar(max) | YES | Synthetic UUID (NEWID()) generated at INSERT time. Not stable — re-running for the same date generates new GUIDs. Do not use as a join key. | T2 |
| 4 | AlertCategory | nvarchar(max) | YES | Always 'OnBoarding' (with occasional trailing space artefact in early SP branches). All MA-series alerts are OnBoarding; no MIMO or cashout categories exist in this table. | T2 |
| 5 | AlertType | nvarchar(max) | YES | Hardcoded MA-series alert code and description. 12 distinct codes: MA001–MA009, MA011, MA013, MA014. MA010 and MA012 are intentional gaps (never implemented). See distribution below. | T2 |
| 6 | Total_Alerts_of_TheCategory | int | YES | Count of prior firings for this MasterAccountCID × AlertType combination, plus 1. Counts at master-account level (not individual CID). Since SP only inserts first-time rows, this value is always 1 in the table except for MA008 recurring milestone rows. | T2 |
| 7 | AlertDate | date | YES | The date parameter (@Date) passed to the SP — the date the alert was generated for. | T2 |
| 8 | Regulation | nvarchar(max) | YES | Customer's regulation name at SP run time (CySEC, FCA, ASIC, etc.) via Fact_SnapshotCustomer JOIN Dim_Regulation. | T2 |
| 9 | Country | nvarchar(max) | YES | Customer's KYC country name at SP run time via Fact_SnapshotCustomer JOIN Dim_Country. | T2 |
| 10 | PlayerStatus | nvarchar(max) | YES | Customer's player status at SP run time. Blocked and Blocked Upon Request customers excluded at population level. | T2 |
| 11 | Club | nvarchar(max) | YES | Customer's club level name at SP run time (Bronze/Silver/Gold/Platinum/Diamond/Platinum Plus). | T2 |
| 12 | AccountType | nvarchar(max) | YES | Customer's account type name at SP run time (Private/Corporate/etc.). | T2 |
| 13 | RiskScoreName | nvarchar(max) | YES | Most recent risk classification label from Dim_RiskClassification (Low/Medium/High/Unacceptable). Derived from Fact_SnapshotCustomer risk change history (most recent row only). Note: source differs from base BI_DB_AML_BI_Alerts_New (which uses External_RiskClassification). | T2 |
| 14 | HasWallet | int | YES | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. (Tier 1 — BackOffice.Customer) | T1 |
| 15 | UpdateDate | datetime | NOT NULL | GETDATE() at INSERT time. ETL metadata — do not use for business logic. | Blacklist |

---

## 5. Distributions (Live Data)

### AlertType Distribution

| AlertType | Count | % |
|-----------|-------|---|
| MA011: Annual Income Vs Annual deposits | 1,050 | 70.2% |
| MA014: Occupation VS Deposits | 121 | 8.1% |
| MA001: Lifetime Deposits >= 50K and RC High/Unacceptable | 78 | 5.2% |
| MA003: Lifetime Deposits > 250K | 65 | 4.3% |
| MA002: Lifetime Deposits >= 100K and RC High/Unacceptable | 41 | 2.7% |
| MA013: Annual Planned Investments VS Annual Deposits | 38 | 2.5% |
| MA004: Lifetime Deposits > 500K | 38 | 2.5% |
| MA009: Unjustified Source of Income | 22 | 1.5% |
| MA005: Lifetime Deposits > 1M | 18 | 1.2% |
| MA006: Lifetime Deposits > 1.5M | 10 | 0.7% |
| MA007: Lifetime Deposits > 2M | 9 | 0.6% |
| MA008: Each additional 1M above 2M | 5 | 0.3% |

### Regulation Distribution

| Regulation | Count | % |
|------------|-------|---|
| CySEC | 867 | 58.0% |
| FCA | 421 | 28.2% |
| ASIC & GAML | 130 | 8.7% |
| FSA Seychelles | 63 | 4.2% |
| FSRA | 11 | 0.7% |
| ASIC | 3 | 0.2% |

---

## 6. Relationships

| Related Table | Join Type | Join Key | Notes |
|---------------|-----------|----------|-------|
| BI_DB_AML_BI_Alerts_New | Sibling | CID | Base single-account alert table; MA-series are exclusively multi-account scenarios |
| DWH_dbo.Dim_Customer | Reference | CID = RealCID | Source for CID, HasWallet; T1 columns |
| BI_DB_dbo.External_etoro_BackOffice_Customer | Source | CID | Defines master/sub account groups |
| DWH_dbo.Fact_SnapshotCustomer | Source | CID = RealCID | Customer snapshot at SP run date |
| DWH_dbo.Fact_BillingDeposit | Source | CID | Lifetime and calendar-year deposit aggregation |
| BI_DB_dbo.BI_DB_KYC_Panel | Source | CID = RealCID | Q10 (annual income), Q11 (net worth), Q15 (source of income) |

---

## 7. Sample Queries

```sql
-- All MA011 alerts for a master account group
SELECT CID, MasterAccountCID, AlertType, AlertDate, Regulation
FROM BI_DB_dbo.BI_DB_AML_BI_Alerts_New_Master_SubAccount
WHERE MasterAccountCID = <master_cid>
ORDER BY AlertDate;

-- Recent high-value deposit threshold breaches
SELECT CID, MasterAccountCID, AlertType, AlertDate
FROM BI_DB_dbo.BI_DB_AML_BI_Alerts_New_Master_SubAccount
WHERE AlertType IN ('MA005: Lifetime Depostits > 1M (Multiple accounts)',
                    'MA006: Lifetime Depostits > 1.5M (Multiple accounts)',
                    'MA007: Lifetime Depostits > 2M (Multiple accounts)')
  AND AlertDate >= DATEADD(MONTH, -3, GETDATE())
ORDER BY AlertDate DESC;
```

---

## 8. Notes & Gotchas

- **First-time only inserts**: The SP filters `Total_Alerts_of_TheCategory = 1` at INSERT time. This means the table contains at most one row per MasterAccountCID per AlertType for threshold-crossing alerts. MA008 is the only recurring alert (fires for each additional $1M milestone).
- **MasterAccountCID = CID when master account fires**: The UNION in `#cids` includes both the master and sub accounts separately. When a master account row triggers an alert, `MasterAccountCID = CID`.
- **Deposit aggregation is group-level**: Thresholds are based on the combined deposits of ALL accounts under the same MasterAccountCID, not just the individual CID.
- **AlertCategory trailing space**: Early SP branches write `'OnBoarding '` (with trailing space). WHERE filters should use `RTRIM` or `LIKE`.
- **Risk source differs from base table**: `RiskScoreName` here comes from `Dim_RiskClassification` (change history), not `External_RiskClassification_dbo_V_RiskClassificationDataLake`. The label vocabulary includes 'Unacceptable' here; the base table uses 'None' instead.
- **MA010 and MA012 are intentional gaps**: These codes were planned but never implemented in the SP.
- **Small table**: Only 1,495 rows as of 2026-04-03 — this is expected given the first-time-only insert behavior and the niche master/sub-account population.
- **Employee accounts removed**: Pavlina Masoura removed employee accounts (PlayerLevelID=4 exclusion) on 2025-11-10.

---

*Quality Score: 9.2/10 | Tiers: 2 T1, 12 T2, 1 Blacklist | SP: SP_AML_BI_Alerts_New_Master_SubAccount*

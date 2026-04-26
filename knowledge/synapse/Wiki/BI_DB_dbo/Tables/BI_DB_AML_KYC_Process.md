# BI_DB_dbo.BI_DB_AML_KYC_Process

> AML compliance work-queue table identifying active VL3 depositors with expired or missing identity/address proof documents and customers not yet electronically verified — the daily input list for AML KYC case handlers. Also captures a small subset of high-value UAE Pass clients (FTDA ≥ $15K) with incomplete UAE Pass verification.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | HEAP |
| **Column Count** | 27 |
| **Row Count** | 923,261 (as of 2026-04-12) |
| **Grain** | One row per CID |
| **Refresh** | Daily (OpsDB Priority 0 — base layer) |
| **Writer SP** | BI_DB_dbo.SP_AML_KYC_Process |
| **ETL Pattern** | TRUNCATE + INSERT (full refresh) |
| **UC Target** | Pending |

---

## 1. Business Meaning

`BI_DB_AML_KYC_Process` is the daily work-queue for the eToro AML (Anti-Money Laundering) compliance team. It surfaces the universe of customers who are fully verified at VerificationLevel 3 (the highest KYC tier) but still have outstanding document compliance gaps — specifically: expired or absent Proof of Identity (POI), expired or absent Proof of Address (POA), or absence of Electronic Verification (EV) match. These customers require case handling to obtain or renew documents to satisfy regulatory requirements under CySEC, FCA, ASIC, and other jurisdictions.

The table is built from two population segments controlled by the `Ind` column:

- **Main_POP** (923,169 rows, 99.99%): VL3 depositors with active accounts (not Blocked or Blocked Upon Request), who are not EV-verified (`EvMatchStatus ≠ 2`) and whose POI or POA is either missing or expired.
- **UAE_Pass_15K_Client** (92 rows, 0.01%): VL3 depositors whose first deposit was ≥ $15,000 and who have not completed UAE Pass verification (`EIDStatusID ≠ 2`). The UAE Pass is the UAE digital identity system; high-value depositors in UAE-regulated accounts must complete it.

Each row enriches the customer's compliance profile with risk classification (`RiskScoreName`), AML screening result (`ScreeningStatus`), equity and revenue figures, eToro Money wallet flags, and the exact document expiry dates — giving case handlers everything needed to prioritize and action cases without joining additional tables.

### Business Usage

- **AML KYC Case Management**: Primary daily input list for AML analysts. Filtered by regulation, risk score, and document gap type.
- **Regulatory Reporting**: Tracks how many VL3 customers across each jurisdiction have outstanding document requirements.
- **Risk Prioritization**: `RiskScoreName` (Medium/High) and `Equity` enable case handlers to prioritize high-value or high-risk customers.
- **UAE Pass Monitoring**: The 92 UAE_Pass_15K_Client rows are tracked separately for the UAE regulatory team.

---

## 2. Business Logic

### 2.1 Main Population Filter

**What**: Selects customers who are fully verified but have an incomplete or expired compliance document profile.

**Rules** (applied to DWH_dbo.Dim_Customer):
- `VerificationLevelID = 3` — fully verified customers only
- `IsValidCustomer = 1` — standard valid trading accounts
- `IsDepositor = 1` — must have made at least one deposit
- `PlayerStatusID NOT IN (2, 4)` — excludes Blocked and Blocked Upon Request accounts
- `EvMatchStatus ≠ 2` — not fully EV-matched (so Has_EV = 0 for all rows)
- AND at least one of:
  - `IsIDProofExpiryDate <= GETDATE()` OR `IsIDProof = 0 OR IsIDProof IS NULL` (POI expired/missing)
  - `IsAddressProofExpiryDate <= GETDATE()` OR `IsAddressProof = 0 OR IsAddressProof IS NULL` (POA expired/missing)

**POI/POA flag breakdown** (as of 2026-04-12):

| Has_POI | Is_POI_Expired | Has_POA | Is_POA_Expired | Count | % |
|---------|----------------|---------|----------------|-------|---|
| 1 | 0 | 1 | 1 | 575,284 | 62.3% |
| 1 | 1 | 1 | 1 | 279,918 | 30.3% |
| 1 | 1 | 1 | 0 | 60,612 | 6.6% |
| NULL | 0 | NULL | 0 | 3,771 | 0.4% |
| other | — | — | — | 3,676 | 0.4% |

Most customers (62.3%) have a valid POI but an expired POA; 30.3% have both documents expired.

### 2.2 UAE Pass Population

**What**: A separate population for high-value UAE Pass clients requiring completion of UAE digital identity verification.

**Rules**:
- `FirstDepositAmount >= 15,000` (FTDA ≥ $15K threshold for UAE Pass requirement)
- Same base criteria as Main_POP (VerificationLevelID=3, IsValidCustomer=1, IsDepositor=1, PlayerStatusID NOT IN (2,4))
- `EIDStatusID ≠ 2` (EIDStatusID=2 = Completed — excluded from the queue since no action needed)

**UAE_Pass_Status derivation** (from BackOffice.Customer.EIDStatusID):
- `NULL` → `'None'` (UAE Pass not started)
- `1` → `'PartiallyCompleted'`
- All 92 UAE Pass rows currently show `'PartiallyCompleted'`

The two populations are UNION ALL-merged into the final table, each carrying their Ind label.

### 2.3 Equity Calculation

**What**: Net equity for each customer as a financial context signal for case prioritization.

**Formula**: `Equity = ISNULL(V_Liabilities.Liabilities, 0) + ISNULL(V_Liabilities.ActualNWA, 0)`

**Source**: `DWH_dbo.V_Liabilities` filtered to `DateID = CAST(CONVERT(CHAR(8), GETDATE()-1, 112) AS INT)` (yesterday's snapshot).

Note: Many customers in this population have low or zero equity (sample shows 0.00 for first 7 rows; range includes active traders with equity up to several thousand USD).

### 2.4 Revenue Calculation

**What**: All-time cumulative revenue generated by this customer (commissions and rollover fees).

**Formula**: `Revenue = SUM(FullCommissions + RollOverFee)` from `BI_DB_dbo.BI_DB_DailyCommisionReport` up to `DateID <= GETDATE()-1`. No further date bound — this is the customer's entire revenue history.

### 2.5 Has_eMoney Flag

**What**: Indicates whether the customer has an active eToro Money (ETM) wallet.

**Formula**: `Has_eMoney = 1` if customer CID appears in `eMoney_dbo.eMoney_Dim_Account` WHERE `IsValidETM=1 AND IsTestAccount=0 AND ISNULL(CurrencyBalanceStatusID,0) ≠ 4` (not blocked).

### 2.6 Document Expiry Flags

**What**: Binary flags derived from expiry date comparisons, enabling simple filter queries.

**Formula**:
- `Is_POI_Expired = CASE WHEN POI_ExpiryDate <= GETDATE() THEN 1 ELSE 0 END`
- `Is_POA_Expired = CASE WHEN POA_ExpiryDate <= GETDATE() THEN 1 ELSE 0 END`

---

## 3. Query Advisory

### 3.1 Distribution

ROUND_ROBIN HEAP — no hash key; all data segments receive equal row counts. For filtered queries (by regulation, risk score), a full scan is performed. Table is moderate at ~923K rows; queries are fast without date partitioning.

### 3.2 One Row Per CID

The table holds one row per customer (unique by CID). A `WHERE CID = @target` lookup will return at most 1 row.

### 3.3 Column Name Typo Warning

**`Equiy_IBAN`** has a persistent DDL typo — the 'T' in "Equity" is missing. This is encoded in both the SP and the DDL table definition. Always reference as `Equiy_IBAN` (not `Equity_IBAN`) when querying. The column represents IBAN-based balance from `BI_DB_DDR_Fact_AUM.IBANBalance`; it is 0 for the vast majority of customers in this population.

### 3.4 Common Query Patterns

| Question | Approach |
|----------|----------|
| KYC queue by regulation | `GROUP BY Regulation ORDER BY COUNT(*) DESC` |
| High-priority cases (high equity + high risk) | `WHERE RiskScoreName = 'High' AND Equity > X ORDER BY Equity DESC` |
| Expired POI only | `WHERE Is_POI_Expired = 1 AND Is_POA_Expired = 0` |
| UAE Pass queue | `WHERE Ind = 'UAE_Pass_15K_Client'` |
| Customers with eToro Money wallet | `WHERE Has_eMoney = 1` |

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source |
|------|--------|
| Tier 1 | Upstream DWH wiki verbatim copy |
| Tier 2 | SP code derivation |
| Propagation | ETL metadata (canonical description from config) |

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within eToro platform. Universal customer identifier across all DWH tables. (Tier 1 — DWH_dbo.Dim_Customer.RealCID) |
| 2 | Regulation | nvarchar(50) | YES | Short code for the regulatory jurisdiction governing this account. Values: CySEC (59.5%), FCA (19.5%), FSA Seychelles (11.4%), ASIC & GAML (4.1%), FSRA (2.8%), FinCEN+FINRA (1.3%), ASIC (1.1%), FinCEN (0.4%), others. Determines applicable KYC requirements. (Tier 1 — DWH_dbo.Dim_Regulation.Name) |
| 3 | Country | nvarchar(100) | YES | Full country name in English for the customer's country of residence. Used to determine regulatory framework, leverage limits, and document requirements. (Tier 1 — DWH_dbo.Dim_Country.Name) |
| 4 | PlayerStatus | varchar(50) | YES | Human-readable account restriction state label. All rows in this table have an active status (Normal or Warning) — Blocked (2) and Blocked Upon Request (4) are excluded by the population filter. In practice, nearly all rows = 'Normal'. (Tier 1 — DWH_dbo.Dim_PlayerStatus.Name) |
| 5 | PlayerStatusReason | varchar(50) | YES | Human-readable reason label for the current PlayerStatus. Key values observed: None, KYC, Failed Verification - 15 Days, FATCA, CRS, W-8BEN. NULL for customers with no specific reason assigned. (Tier 1 — DWH_dbo.Dim_PlayerStatusReasons.Name) |
| 6 | PlayerStatusSubReasonName | varchar(50) | YES | Second-level detail for the account status change, working beneath PlayerStatusReason. Provides granular sub-category (e.g., 'Failed Verification - 15 Days' as sub-reason of 'KYC'). NULL for customers with no sub-reason. (Tier 1 — DWH_dbo.Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName) |
| 7 | Club | varchar(50) | YES | Customer experience tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Bronze is most common for this KYC population. Determines platform features and permissions. (Tier 1 — DWH_dbo.Dim_PlayerLevel.Name) |
| 8 | RiskScoreName | nvarchar(4000) | YES | AML risk classification assigned by the RiskClassification system. Values: Medium (94.1%, 868,706 rows), High (5.6%, 51,809 rows), Low (0.3%, 2,649 rows), NULL (97 rows — not yet classified). Sourced from DE_OUTPUT/Risk_Classification via External_RiskClassification_dbo_V_RiskClassificationDataLake. (Tier 2 — SP_AML_KYC_Process, External_RiskClassification) |
| 9 | ScreeningStatus | nvarchar(50) | YES | AML/compliance screening outcome from the ScreeningService. Values observed: NoMatch (vast majority — no risk identified on sanctions lists or PEP registries). (Tier 1 — DWH_dbo.Dim_ScreeningStatus.Name) |
| 10 | AccountType | nvarchar(50) | YES | Account category classifying ownership structure and purpose. Values: Private (99.9%, 922,667 rows), Joint Account (307), Corporate (258), SMSF (16), others (12). (Tier 1 — DWH_dbo.Dim_AccountType.Name) |
| 11 | Has_EV | int | YES | Electronic Verification match flag. 0 = not EV-matched; 1 = fully EV-matched. By population definition (EvMatchStatus ≠ 2 filter), ALL rows in this table have Has_EV = 0. (Tier 2 — SP_AML_KYC_Process: CASE WHEN dc.EvMatchStatus <> 2 THEN 0 ELSE 1 END) |
| 12 | EvMatchStatusName | varchar(30) | YES | Human-readable label for the EV (eVerification) identity match status. Values: None (no match attempted), NotVerified (match ran but failed). Verified (2) customers are excluded from this table by definition. (Tier 1 — DWH_dbo.Dim_EvMatchStatus.EvMatchStatusName) |
| 13 | Has_POI | int | YES | Whether an identity proof (POI) document is on file for this customer (1/0). Sourced from Dim_Customer.IsIDProof. NULL observed for ~3,771 rows with no documents on file at all. (Tier 1 — DWH_dbo.Dim_Customer.IsIDProof) |
| 14 | Is_POI_Expired | int | YES | Whether the identity proof document is currently expired: 1 = expired (POI_ExpiryDate <= today), 0 = not expired or no expiry date. Computed at SP run time. (Tier 2 — SP_AML_KYC_Process: CASE WHEN POI_ExpiryDate <= GETDATE() THEN 1 ELSE 0 END) |
| 15 | POI_ExpiryDate | datetime | YES | Expiry date of the customer's identity proof document. NULL if no POI document is on file. Sourced from Dim_Customer.IsIDProofExpiryDate. (Tier 1 — DWH_dbo.Dim_Customer.IsIDProofExpiryDate) |
| 16 | Has_POA | int | YES | Whether an address proof (POA) document is on file for this customer (1/0). Sourced from Dim_Customer.IsAddressProof. NULL for customers with no documents on file. (Tier 1 — DWH_dbo.Dim_Customer.IsAddressProof) |
| 17 | Is_POA_Expired | int | YES | Whether the address proof document is currently expired: 1 = expired (POA_ExpiryDate <= today), 0 = not expired or no expiry date. Computed at SP run time. (Tier 2 — SP_AML_KYC_Process: CASE WHEN POA_ExpiryDate <= GETDATE() THEN 1 ELSE 0 END) |
| 18 | POA_ExpiryDate | datetime | YES | Expiry date of the customer's address proof document. NULL if no POA document is on file. Sourced from Dim_Customer.IsAddressProofExpiryDate. (Tier 1 — DWH_dbo.Dim_Customer.IsAddressProofExpiryDate) |
| 19 | HasWallet | int | YES | 1 if the customer has an active eToro Money wallet linked to their trading account; 0 otherwise. Sourced from BackOffice.Customer via Dim_Customer. (Tier 1 — DWH_dbo.Dim_Customer.HasWallet) |
| 20 | Has_eMoney | int | YES | 1 if the customer has a valid, non-blocked eToro Money (ETM) account; 0 if none. Derived from eMoney_dbo.eMoney_Dim_Account (IsValidETM=1, IsTestAccount=0, CurrencyBalanceStatusID≠4). (Tier 2 — SP_AML_KYC_Process) |
| 21 | Equity | money | YES | Net equity (USD) as of yesterday: Liabilities + ActualNWA from DWH_dbo.V_Liabilities. 0 for customers with no open positions or funds. (Tier 2 — SP_AML_KYC_Process, DWH_dbo.V_Liabilities) |
| 22 | Revenue | money | YES | All-time cumulative trading revenue (USD) generated by this customer: SUM(FullCommissions + RollOverFee) from BI_DB_DailyCommisionReport up to yesterday. Provides financial context for case prioritization. (Tier 2 — SP_AML_KYC_Process, BI_DB_dbo.BI_DB_DailyCommisionReport) |
| 23 | Equiy_IBAN | money | YES | IBAN-held balance equity (USD) as of yesterday from BI_DB_DDR_Fact_AUM.IBANBalance. **Note: column name has a DDL typo — 'Equiy_IBAN' instead of 'Equity_IBAN'.** 0 for all observed rows — IBAN-based funds are rare for this KYC population. (Tier 2 — SP_AML_KYC_Process, BI_DB_dbo.BI_DB_DDR_Fact_AUM) |
| 24 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at each full refresh. (Propagation — ETL metadata) |
| 25 | VerificationLevel3Date | datetime | YES | First date this customer reached KYC Verification Level 3 (fully verified). MIN(FromDateID) WHERE VerificationLevelID=3 from Fact_SnapshotCustomer, sourced via BI_DB_CIDFirstDates. (Tier 1 — BI_DB_dbo.BI_DB_CIDFirstDates.VerificationLevel3Date) |
| 26 | UAE_Pass_Status | nvarchar(50) | YES | UAE digital identity verification status for UAE Pass population members. Values: NULL/empty (Main_POP rows), 'PartiallyCompleted' (92 UAE Pass rows currently), 'None' (UAE Pass not started), 'Completed' (excluded from table). Derived from BackOffice.Customer.EIDStatusID. (Tier 2 — SP_AML_KYC_Process, External_etoro_BackOffice_Customer) |
| 27 | Ind | nvarchar(50) | YES | Population segment identifier. Values: 'Main_POP' (923,169 rows — missing/expired POI/POA, not EV-verified), 'UAE_Pass_15K_Client' (92 rows — high-value UAE Pass incomplete). Used to split the table into two compliance streams. (Tier 2 — SP_AML_KYC_Process: hardcoded string per SELECT branch) |

---

## 5. Lineage

### 5.1 Production Chain

```
RiskClassification system → DE_OUTPUT/Risk_Classification (lake)
  → External_RiskClassification_dbo_V_RiskClassificationDataLake → RiskScoreName

etoro.BackOffice.Customer → Bronze/etoro/BackOffice/Customer (lake)
  → External_etoro_BackOffice_Customer → UAE_Pass_Status (EIDStatusID mapping)

DWH_dbo.Dim_Customer (+ Dim_Regulation/Country/PlayerStatus/Level/ScreeningStatus/
  AccountType/EvMatchStatus/PlayerStatusReasons/PlayerStatusSubReasons)
  → Population #pop_Final (UNION ALL of Main_POP + UAE_Pass_15K_Client)

DWH_dbo.V_Liabilities (DateID=yesterday) → Equity
eMoney_dbo.eMoney_Dim_Account → Has_eMoney
BI_DB_dbo.BI_DB_DailyCommisionReport → Revenue
BI_DB_dbo.BI_DB_DDR_Fact_AUM (DateID=yesterday) → Equiy_IBAN
BI_DB_dbo.BI_DB_CIDFirstDates → VerificationLevel3Date

SP_AML_KYC_Process (TRUNCATE + INSERT)
  → BI_DB_dbo.BI_DB_AML_KYC_Process
```

### 5.2 Regulation Distribution

| Regulation | Count | % |
|-----------|-------|---|
| CySEC | 548,887 | 59.5% |
| FCA | 179,827 | 19.5% |
| FSA Seychelles | 105,181 | 11.4% |
| ASIC & GAML | 38,055 | 4.1% |
| FSRA | 25,872 | 2.8% |
| FinCEN+FINRA | 11,844 | 1.3% |
| ASIC | 10,274 | 1.1% |
| FinCEN | 3,286 | 0.4% |
| BVI + others | 35 | <0.1% |

---

## 6. Relationships

### 6.1 Sources (this table reads from)

| Source | Join | Purpose |
|--------|------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Primary identity, document proofs, compliance flags |
| DWH_dbo.Dim_Regulation | RegulationID = DWHRegulationID | Regulation name resolution |
| DWH_dbo.Dim_Country | CountryID = DWHCountryID | Country name resolution |
| DWH_dbo.Dim_PlayerStatus | PlayerStatusID = PlayerStatusID | Status name + filter |
| DWH_dbo.Dim_PlayerLevel | PlayerLevelID = PlayerLevelID | Club/tier name |
| DWH_dbo.Dim_ScreeningStatus | ScreeningStatusID = ScreeningStatusID | Screening outcome |
| DWH_dbo.Dim_AccountType | AccountTypeID = AccountTypeID | Account category |
| DWH_dbo.Dim_EvMatchStatus | EvMatchStatus = EvMatchStatusID | EV status label |
| DWH_dbo.Dim_PlayerStatusReasons | PlayerStatusReasonID = PlayerStatusReasonID | Status reason |
| DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonID = PlayerStatusSubReasonID | Status sub-reason |
| BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | CID = CID | AML risk score |
| BI_DB_dbo.External_etoro_BackOffice_Customer | CID = CID | UAE Pass status |
| DWH_dbo.V_Liabilities | CID = CID, DateID = yesterday | Equity |
| eMoney_dbo.eMoney_Dim_Account | CID = CID | eToro Money flag |
| BI_DB_dbo.BI_DB_DailyCommisionReport | RealCID = CID | Revenue |
| BI_DB_dbo.BI_DB_DDR_Fact_AUM | RealCID = CID, DateID = yesterday | IBAN balance |
| BI_DB_dbo.BI_DB_CIDFirstDates | CID = CID | VerificationLevel3Date |

### 6.2 Downstream Consumers

Consumed by AML compliance team reports and case management tools (specific Synapse/reporting objects not identified in current SP scan).

---

## 7. Sample Queries

### 7.1 Daily KYC queue by regulation and document gap type

```sql
SELECT
    Regulation,
    CASE
        WHEN Is_POI_Expired = 1 AND Is_POA_Expired = 1 THEN 'Both Expired'
        WHEN Is_POI_Expired = 1 THEN 'POI Expired'
        WHEN Is_POA_Expired = 1 THEN 'POA Expired'
        WHEN Has_POI = 0 OR Has_POI IS NULL THEN 'Missing POI'
        WHEN Has_POA = 0 OR Has_POA IS NULL THEN 'Missing POA'
        ELSE 'Other'
    END AS GapType,
    COUNT(*) AS CustomerCount
FROM [BI_DB_dbo].[BI_DB_AML_KYC_Process]
WHERE Ind = 'Main_POP'
GROUP BY Regulation,
    CASE
        WHEN Is_POI_Expired = 1 AND Is_POA_Expired = 1 THEN 'Both Expired'
        WHEN Is_POI_Expired = 1 THEN 'POI Expired'
        WHEN Is_POA_Expired = 1 THEN 'POA Expired'
        WHEN Has_POI = 0 OR Has_POI IS NULL THEN 'Missing POI'
        WHEN Has_POA = 0 OR Has_POA IS NULL THEN 'Missing POA'
        ELSE 'Other'
    END
ORDER BY CustomerCount DESC;
```

### 7.2 High-priority cases (High risk + significant equity)

```sql
SELECT
    CID,
    Regulation,
    Country,
    RiskScoreName,
    Equity,
    Revenue,
    Is_POI_Expired,
    Is_POA_Expired,
    VerificationLevel3Date
FROM [BI_DB_dbo].[BI_DB_AML_KYC_Process]
WHERE RiskScoreName = 'High'
  AND Equity > 1000
  AND Ind = 'Main_POP'
ORDER BY Equity DESC;
```

### 7.3 UAE Pass queue

```sql
SELECT
    CID,
    Country,
    UAE_Pass_Status,
    Equity,
    Revenue,
    FirstDepositDate  -- note: not in this table; join to Dim_Customer if needed
FROM [BI_DB_dbo].[BI_DB_AML_KYC_Process]
WHERE Ind = 'UAE_Pass_15K_Client'
ORDER BY Equity DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian Confluence sources identified for this specific object.

---

*Generated: 2026-04-22 | Quality: 8.3/10 | Batch: 46*
*Tiers: 16 T1, 10 T2, 0 T3, 0 T4, 0 T5, 1 propagation | Columns: 27/27*
*Object: BI_DB_dbo.BI_DB_AML_KYC_Process | Writer SP: SP_AML_KYC_Process | Priority: 0*

# BI_DB_dbo.BI_DB_AML_High_Risk_Wallet

> Daily AML compliance snapshot of all fully-verified, High-AML-Risk, non-blocked customers — capturing risk profile, wallet enrollment date, and occupation declaration to support retroactive review of customers who may have gained wallet access before or after their risk escalation to 'High'.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_AML_High_Risk_Wallet |
| **OpsDB Priority** | 0 (no intra-schema dependencies) |
| **Refresh** | Daily — TRUNCATE + INSERT (full rebuild) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Rows** | ~566K total / ~143K distinct CIDs (multi-regulation: ~4 rows per CID average) |
| | |
| **UC Target** | Not migrated |

---

## 1. Business Meaning

BI_DB_AML_High_Risk_Wallet is the AML team's daily roster of every fully-verified (VerificationLevelID=3) customer classified as 'High' AML risk by the RiskClassification system — regardless of whether they hold an eToro Money (crypto wallet) account. The table name refers to the wallet compliance angle: the primary compliance question it answers is whether a customer who is High Risk enrolled in eToro Money before or after their risk was classified as High.

This matters because eToro Money customers have access to crypto assets, cross-border transfers, and financial operations that carry additional AML regulatory scrutiny. If a customer's AML risk classification escalated to High after they already had a wallet, that may require retroactive review and enhanced due diligence. The `Risk_before_Wallet` flag directly answers this question: 1 = customer was already High Risk when they joined the wallet (or has always been High Risk with no prior score); 0 = the wallet was opened before the risk escalation happened.

The table covers all regulatory entities (CySEC, FCA, FSA Seychelles, BVI, ASIC, etc.). A customer registered under multiple regulations appears as one row per regulation (~4 rows/CID average due to the multi-regulation structure of eToro). Customers with `HasWallet=0` and `FirstWalletDate=NULL` are included — the table is not limited to wallet holders but uses wallet enrollment as a risk stratification axis.

The `RiskScore_Explanation` column provides the composite list of non-zero AML risk parameters that drove the 'High' classification, enabling analysts to understand WHY a customer is High Risk without querying the RiskClassification system directly.

---

## 2. Business Logic

### 2.1 Population Filter

**What**: The table contains a narrower population than BI_DB_AML_Documents_Request — fully verified High Risk customers only.

**Columns Involved**: `CID`, `RiskScoreName`, `VerificationLevelID`

**Rules**:
- `VerificationLevelID = 3`: ONLY fully verified customers (level 3). Partially verified (level 2) are excluded. This is stricter than BI_DB_AML_Documents_Request (which uses > 1).
- `RiskScoreName = 'High'`: Population is limited to customers with exactly 'High' classification in the RiskClassification system. 'Low', 'Medium', and 'Very High' customers are excluded. This filter is applied as an INNER JOIN on the External_RiskClassification table.
- `PlayerStatusID NOT IN (2, 4)`: Blocked and BUR customers excluded via INNER JOIN on Dim_PlayerStatus. Note: 'Deposit Blocked' (ID=10) IS included — deposit-blocked High Risk customers are still in scope.
- `IsValidCustomer = 1`: Standard validity filter from Dim_Customer.

### 2.2 Risk_before_Wallet Flag

**What**: Binary flag indicating whether the customer held 'High' AML risk status at the time they joined eToro Money.

**Columns Involved**: `Risk_before_Wallet`, `FirstWalletDate`, `PreviousRiskUpdateDate`, `FirstDepositDate`

**Rules**:
- `PreviousRiskUpdateDate IS NULL AND FirstWalletDate >= FirstDepositDate → 1`: Customer has no recorded previous risk score (has always been High Risk, or no history prior to current score). Since the wallet was opened after the first deposit, and the customer was always High Risk, they were High Risk when they got the wallet.
- `FirstWalletDate IS NOT NULL AND FirstWalletDate >= PreviousRiskUpdateDate → 1`: The wallet enrollment date is on or after the date the previous (pre-High) risk score was set. Since the current score is High and was set after PreviousRiskUpdateDate, this means the wallet was opened during or after the risk escalation period → customer was High Risk (or becoming High Risk) at wallet enrollment.
- `ELSE 0`: Wallet was opened before the risk timeline conditions above were met. Typically means the customer joined the wallet when they had a lower risk classification, and the risk escalation to High occurred later.
- `FirstWalletDate IS NULL → 0` (no wallet enrollment found).

### 2.3 GCID Cross-Account Wallet Lookup

**What**: FirstWalletDate is resolved using GCID (Group Customer ID) rather than CID, enabling wallet enrollment detection across all of a customer's regulatory accounts.

**Columns Involved**: `GCID`, `FirstWalletDate`

**Rules**:
- A customer may have multiple CIDs (one per regulatory entity: eToro CySEC, eToro UK FCA, etc.) but shares a single GCID (person-level identifier).
- `EXW_Wallet.CustomerWalletsView` is joined on GCID — so if the customer enrolled their wallet under any of their accounts, the earliest enrollment date appears as `FirstWalletDate` for ALL of their CID rows.
- This means `FirstWalletDate` is the same across all regulation rows for the same person.

### 2.4 ETL Pattern

**What**: Full daily rebuild.

**Rules**:
- No date parameters — SP rebuilds the entire table from scratch each day.
- Priority 0: runs early in the SB_Daily batch with no intra-schema dependencies.
- `UpdateDate = GETDATE()` at INSERT — all rows share the same timestamp per daily run.
- Multi-regulation fan-out: ~4 rows per distinct CID due to the multi-regulatory nature of the eToro platform.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN + HEAP. No distribution key. For CID lookups, use WHERE CID = @CID. For analytical queries, the 566K row size makes full scans acceptable.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Count distinct High Risk customers (not rows) | COUNT(DISTINCT CID) |
| Find wallet customers who were already High Risk | WHERE Risk_before_Wallet = 1 AND FirstWalletDate IS NOT NULL |
| Find High Risk customers WITHOUT a wallet | WHERE FirstWalletDate IS NULL (or HasWallet = 0) |
| Find PEP customers who are also High Risk | WHERE ScreeningStatus = 'PEP' |
| Understand WHY a customer is High Risk | SELECT RiskScore_Explanation — comma-separated risk drivers |
| Find High Risk customers from FATF countries | WHERE RiskGroupID = 3 |
| Check when a customer's risk previously changed | SELECT PreviousRiskUpdateDate |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_AML_Documents_Request | ON adr.CID = hrw.CID | Add document status (POI/POA/POIncome/Selfie dates) |
| BI_DB_dbo.BI_DB_AMLPeriodicReview | ON apr.RealCID = hrw.CID | Check if customer is in periodic review queue |
| DWH_dbo.Dim_Customer | ON dc.RealCID = hrw.CID | Add additional customer attributes |

### 3.4 Gotchas

- **~566K rows, ~143K distinct CIDs**: Full scans are feasible but multi-row per CID — always use DISTINCT when counting customers.
- **HasWallet vs FirstWalletDate**: `HasWallet` comes from BackOffice.Customer (current flag); `FirstWalletDate` comes from EXW_Wallet.CustomerWalletsView (event history). These may disagree for edge cases where wallet was deactivated. Use `FirstWalletDate IS NOT NULL` for "ever had a wallet."
- **RiskScoreName is always 'High'**: The INNER JOIN filter guarantees this. The column exists for reference clarity but always = 'High'.
- **VerificationLevelID=3 only**: Unlike BI_DB_AML_Documents_Request (VerificationLevelID > 1), this table excludes partially verified (level 2) customers.
- **Occupation_Answer is NULL when no KYC panel record**: The INNER JOIN on BI_DB_KYC_Panel means customers who haven't completed the KYC questionnaire Q18 will have NULL occupation.
- **UpdateDate staleness**: As of 2026-04-13, UpdateDate is 9 days behind the generation date (2026-04-22) — check OpsDB for SP_AML_High_Risk_Wallet run history.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ***** | Tier 1 - upstream wiki verbatim | varies by source |
| **** | Tier 2 - SP code / DWH wiki | (Tier 2 - SP_AML_High_Risk_Wallet) |
| *** | Tier 3 - live data inference | (Tier 3 - live data) |
| — | Propagation blacklist | ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer account ID — eToro RealCID. Primary key for customer lookups; appears once per regulation per customer. Population limited to IsValidCustomer=1, VerificationLevelID=3, RiskScoreName='High', PlayerStatusID NOT IN(2,4). (Tier 1 - Customer.CustomerStatic via Dim_Customer) |
| 2 | GCID | int | YES | Group Customer ID — person-level identifier spanning all of a customer's eToro accounts across regulatory jurisdictions. Used to JOIN to EXW_Wallet.CustomerWalletsView for wallet enrollment history. The same person shares one GCID across all their CID rows. (Tier 1 - Customer.CustomerStatic via Dim_Customer) |
| 3 | Age | int | YES | Customer age in full years at SP run time. Computed as DATEDIFF(YEAR, Dim_Customer.BirthDate, GETDATE()). Recalculated on every daily refresh. NULL if BirthDate is NULL in Dim_Customer. (Tier 2 - SP_AML_High_Risk_Wallet) |
| 4 | Regulation | varchar(250) | YES | Regulatory entity under which this customer row is registered. Each customer appears once per regulation they are registered under. Values: CySEC, FCA, FSA Seychelles, BVI, ASIC, FINRA, etc. (Tier 1 - upstream wiki, Dictionary.Regulation) |
| 5 | Country | varchar(250) | YES | Customer's KYC country of residence name. Used with RiskGroupID for AML country-risk assessment. (Tier 1 - upstream wiki, Dictionary.Country) |
| 6 | RiskGroupID | int | YES | Country-level AML risk tier from Dim_Country.RiskGroupID. Values: 0=None (standard-risk country), 1=High risk country, 2=High risk new clients, 3=High risk FATF jurisdictions (8 countries), 4=Verified before deposit (special compliance requirement, not high-risk). Used to further stratify High-AML-Risk customers by their country of residence risk tier. (Tier 1 - upstream wiki, Dim_Country) |
| 7 | PlayerStatus | varchar(250) | YES | Customer's current account restriction status name. Blocked (2) and BUR (4) customers are excluded by the population filter. Other statuses present: Normal, Deposit Blocked, Warning, Under Investigation, Trade & MIMO Blocked, etc. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 8 | Club | varchar(250) | YES | Customer loyalty tier / club name from Dim_PlayerLevel. Values: Bronze, Silver, Gold, Platinum, Diamond, etc. Reflects trading volume-based VIP status. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 9 | ScreeningStatus | varchar(250) | YES | World-Check AML screening outcome name. NULL = no screening record. Values: Unknown, NoMatch, PendingInvestigation, PEP, RiskMatch, Technical, MultipleMatch, SanctionsMatch. A customer can be both High AML Risk (RiskScoreName='High') and a PEP simultaneously. (Tier 3 - live data, Dim_ScreeningStatus) |
| 10 | RiskScoreName | nvarchar(250) | YES | Named AML risk level from the RiskClassification system. Always = 'High' in this table — the INNER JOIN filter on the External_RiskClassification guarantees this. Column exists for reference and JOIN compatibility. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake) |
| 11 | RiskScore_Explanation | nvarchar(max) | YES | Comma-separated list of non-zero AML risk parameter names that contributed to the 'High' risk classification. Sourced from RiskClassification.dbo.V_RiskClassificationDataLake. Explains WHICH specific risk factors drove the High classification (e.g., country of residence risk, PEP status, transaction pattern, income mismatch). NULL if no explanation string was generated. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake) |
| 12 | PreviousRiskUpdateDate | date | YES | Date when the customer's PREVIOUS (pre-'High') AML risk score was in effect, cast to DATE. Sourced from RiskClassification History CTE in V_RiskClassificationDataLake. NULL if the customer has always been 'High' risk or has no prior risk history. Used in the Risk_before_Wallet computation. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake) |
| 13 | FirstDepositDate | date | YES | Date of the customer's first deposit, cast to DATE. NULL if IsDepositor=0 (never deposited). Computed by SP_Dim_Customer from deposit transaction history. Used in the Risk_before_Wallet computation when PreviousRiskUpdateDate IS NULL. (Tier 2 - SP_Dim_Customer via Dim_Customer) |
| 14 | HasWallet | int | YES | Flag indicating whether the customer currently has an eToro Money (crypto wallet) account. 1=yes, 0=no. Sourced from BackOffice.Customer via Dim_Customer. This is the current state flag — distinct from FirstWalletDate (historical enrollment event). (Tier 1 - BackOffice.Customer via Dim_Customer) |
| 15 | IsDepositor | int | YES | Flag indicating whether the customer has ever made a deposit. 1=yes, 0=no. Computed by SP_Dim_Customer. (Tier 2 - SP_Dim_Customer via Dim_Customer) |
| 16 | Risk_before_Wallet | int | YES | Binary compliance flag: 1 = the customer was 'High' AML risk at or before their eToro Money wallet enrollment; 0 = wallet was opened before the risk escalation, or customer has no wallet. Logic: 1 if (PreviousRiskUpdateDate IS NULL AND FirstWalletDate >= FirstDepositDate) OR (FirstWalletDate IS NOT NULL AND FirstWalletDate >= PreviousRiskUpdateDate). Used to identify customers requiring retroactive enhanced due diligence. (Tier 2 - SP_AML_High_Risk_Wallet) |
| 17 | Occupation_Answer | nvarchar(250) | YES | Customer's self-declared occupation from KYC questionnaire Q18. Sourced from BI_DB_KYC_Panel.Q18_AnswerText. NULL if the customer has no KYC panel record. Examples from live data: 'Finance Industry', 'Retail (fashion)'. Used for AML economic profile review (unexpected occupation + high deposits = alert). (Tier 2 - SP_AML_High_Risk_Wallet via BI_DB_KYC_Panel) |
| 18 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was inserted by the ETL pipeline (GETDATE() at INSERT time). All rows share the same timestamp per daily run. Not a business date. (Propagation blacklist — ETL metadata) |
| 19 | FirstWalletDate | date | YES | Date of the customer's first eToro Money (crypto wallet) enrollment across any of their accounts, derived from EXW_Wallet.CustomerWalletsView using GCID as the join key. MIN(Occurred) per GCID, cast to DATE. NULL if the customer has never enrolled in eToro Money (no record in CustomerWalletsView). Shared across all CID rows for the same person (GCID-level resolution). (Tier 2 - SP_AML_High_Risk_Wallet via EXW_Wallet.CustomerWalletsView) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | etoro.Customer.CustomerStatic | CID | Passthrough via Dim_Customer.RealCID |
| GCID | etoro.Customer.CustomerStatic | GCID | Passthrough via Dim_Customer |
| Age | etoro.Customer.CustomerStatic | BirthDate | DATEDIFF(YEAR, BirthDate, GETDATE()) |
| Regulation | etoro.Dictionary.Regulation | Name | Lookup via Dim_Regulation |
| Country | etoro.Dictionary.Country | Name | Lookup via Dim_Country |
| RiskGroupID | etoro.Dictionary.Country | RiskGroupID | Lookup via Dim_Country (same join as Country) |
| PlayerStatus | etoro.Dictionary.PlayerStatus | Name | Lookup via Dim_PlayerStatus (INNER, excludes 2,4) |
| Club | etoro.Dictionary.PlayerLevel | Name | Lookup via Dim_PlayerLevel |
| ScreeningStatus | (no upstream wiki) | Name | Lookup via Dim_ScreeningStatus; LEFT JOIN |
| RiskScoreName | RiskClassification.dbo.V_RiskClassificationDataLake | RiskScoreName | INNER JOIN filter: always = 'High' |
| RiskScore_Explanation | RiskClassification.dbo.V_RiskClassificationDataLake | RiskScore_Explanation | Passthrough |
| PreviousRiskUpdateDate | RiskClassification (History CTE) | PreviousRiskUpdateDate | CAST to DATE |
| FirstDepositDate | etoro.BackOffice.Customer / Billing | — | SP_Dim_Customer computed; CAST to DATE |
| HasWallet | etoro.BackOffice.Customer | HasWallet | Passthrough via Dim_Customer |
| IsDepositor | — | — | SP_Dim_Customer computed |
| Risk_before_Wallet | — | FirstWalletDate + PreviousRiskUpdateDate + FirstDepositDate | SP-computed CASE flag |
| Occupation_Answer | BI_DB_KYC_Panel / etoro KYC system | Q18_AnswerText | Passthrough (renamed) |
| UpdateDate | — | — | GETDATE() at INSERT time |
| FirstWalletDate | EXW_Wallet.CustomerWalletsView | Occurred | MIN(Occurred) per GCID; CAST to DATE |

### 5.2 ETL Pipeline

```
etoro.Dictionary.* (Regulation, Country, PlayerStatus, PlayerLevel)
  -> DWH_dbo.Dim_* (dimension tables)
  -> SP_AML_High_Risk_Wallet (#pop step)
  -> BI_DB_dbo.BI_DB_AML_High_Risk_Wallet

RiskClassification.dbo.V_RiskClassificationDataLake
  -> External_RiskClassification_dbo_V_RiskClassificationDataLake
  -> SP_AML_High_Risk_Wallet (#pop step, INNER JOIN WHERE RiskScoreName='High')
  -> BI_DB_dbo.BI_DB_AML_High_Risk_Wallet

EXW_Wallet.CustomerWalletsView (via EXW schema, GCID-joined)
  -> SP_AML_High_Risk_Wallet (#joinDate step, MIN(Occurred) per GCID)
  -> BI_DB_dbo.BI_DB_AML_High_Risk_Wallet

BI_DB_dbo.BI_DB_KYC_Panel (Q18 occupation)
  -> SP_AML_High_Risk_Wallet (#occupation step)
  -> BI_DB_dbo.BI_DB_AML_High_Risk_Wallet
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Dim_Customer + RiskClassification External + 5 dim tables | Population: High Risk, VerificationLevel=3, non-blocked |
| Step 2 | EXW_Wallet.CustomerWalletsView | First wallet date per GCID |
| Step 3 | BI_DB_KYC_Panel | Occupation from KYC Q18 |
| ETL | SP_AML_High_Risk_Wallet (Priority 0, Daily) | 3-step temp pipeline then TRUNCATE+INSERT |
| Target | BI_DB_dbo.BI_DB_AML_High_Risk_Wallet | ~566K rows, ROUND_ROBIN HEAP |

---

## 6. Relationships

### 6.1 References To (this object reads from)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | RealCID, GCID, BirthDate, FirstDepositDate, HasWallet, IsDepositor, RegulationID, CountryID, PlayerStatusID, PlayerLevelID, ScreeningStatusID, VerificationLevelID, IsValidCustomer | Customer population and attributes |
| DWH_dbo.Dim_Regulation | Name | Regulation label |
| DWH_dbo.Dim_Country | Name, RiskGroupID | Country name and risk tier |
| DWH_dbo.Dim_PlayerStatus | Name | Status name (INNER JOIN, excludes Blocked/BUR) |
| DWH_dbo.Dim_PlayerLevel | Name | Club tier name |
| DWH_dbo.Dim_ScreeningStatus | Name | Screening outcome name |
| BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | RiskScoreName, RiskScore_Explanation, PreviousRiskUpdateDate, GCID | AML risk details (INNER JOIN, RiskScoreName='High') |
| EXW_Wallet.CustomerWalletsView | Gcid, Occurred | First wallet enrollment date per person |
| BI_DB_dbo.BI_DB_KYC_Panel | Q18_AnswerText | KYC occupation declaration |

### 6.2 Referenced By (other objects read from this)

No downstream objects identified reading from this table in the current SP inventory. The table is primarily consumed directly by the AML team via BI tools.

---

## 7. Sample Queries

### 7.1 High Risk customers who had wallet access before risk escalation

```sql
SELECT CID,
       GCID,
       Regulation,
       Country,
       RiskGroupID,
       FirstDepositDate,
       FirstWalletDate,
       PreviousRiskUpdateDate,
       Risk_before_Wallet,
       RiskScore_Explanation
FROM   [BI_DB_dbo].[BI_DB_AML_High_Risk_Wallet]
WHERE  Risk_before_Wallet = 0
AND    FirstWalletDate IS NOT NULL
ORDER  BY FirstWalletDate;
```

### 7.2 PEP customers who are also High Risk with wallet

```sql
SELECT CID,
       Regulation,
       Country,
       Club,
       ScreeningStatus,
       RiskScore_Explanation,
       FirstWalletDate,
       Risk_before_Wallet,
       Occupation_Answer
FROM   [BI_DB_dbo].[BI_DB_AML_High_Risk_Wallet]
WHERE  ScreeningStatus = 'PEP'
AND    FirstWalletDate IS NOT NULL
ORDER  BY FirstWalletDate;
```

### 7.3 High Risk customers from FATF countries, by regulation

```sql
SELECT Regulation,
       Country,
       COUNT(DISTINCT CID)                                          AS Customers,
       SUM(CASE WHEN FirstWalletDate IS NOT NULL THEN 1 ELSE 0 END) AS WithWallet,
       SUM(Risk_before_Wallet)                                      AS RiskBeforeWallet
FROM   [BI_DB_dbo].[BI_DB_AML_High_Risk_Wallet]
WHERE  RiskGroupID = 3  -- FATF high-risk jurisdictions
GROUP  BY Regulation, Country
ORDER  BY Customers DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-22 | Batch: 45 | Quality: 9.1/10 (Phase 16 adversarial eval PASS) | Schema: BI_DB_dbo*
*Tiers: 11 T1, 6 T2, 1 T3, 0 T4, 1 BL | Elements: 19/19, Logic: 9.0/10, Relationships: 8.5/10, Sources: 9.0/10*
*Object: BI_DB_dbo.BI_DB_AML_High_Risk_Wallet | Type: Table | Writer: SP_AML_High_Risk_Wallet | Priority: 0 | Refresh: Daily*

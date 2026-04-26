# BI_DB_dbo.AML_German_Video_Ident

> Daily AML monitoring report of German KYC-verified customers with crypto exposure — tracking Video Ident and Bank Ident completion status for BaFin-regulated identity verification compliance.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Sources** | DWH_dbo.Dim_Customer + Dim_Regulation/PlayerStatus/PlayerLevel/Country/EvMatchStatus/ScreeningStatus + Fact_CustomerAction + V_Liabilities + BI_DB_PositionPnL + External_RiskClassification + general.SolarisBankIdentDb + general.VideoIdentDb |
| **Refresh** | Daily (OpsDB P0) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Writer SP** | SP_AML_German_Video_Ident |
| | |
| **UC Target** | pending |

---

## 1. Business Meaning

`BI_DB_dbo.AML_German_Video_Ident` is a daily AML compliance report targeting German eToro customers who hold crypto assets (open crypto positions or active eToro Money wallet) and have completed full KYC verification (Level 3). The table is used by the AML team to monitor whether these customers have completed the German-specific identity verification methods — Video Ident (video-call identity check) and Bank Ident (Solaris Bank identity check) — which are required under BaFin and German AML regulations.

The population is: German residents (CountryID=79), fully KYC-verified (VerificationLevelID=3), active depositors (IsValidCustomer=1, IsDepositor=1), active accounts (PlayerStatusID NOT IN (2,4)), who either have an active eToro Money wallet (HasWallet=1) OR hold open real crypto positions (Has_Open_RealCrypto=1). As of 2026-04-23, this yields **198,613 customers**.

The SP `SP_AML_German_Video_Ident` runs daily with a `@Date` parameter. It builds the population from DWH dimension joins, computes crypto equity via `BI_DB_PositionPnL`, aggregates deposits from `Fact_CustomerAction`, retrieves equity from `V_Liabilities`, and checks identity verification status from two external source tables (`SolarisBankIdentDb_SolarisBankIdent` and `VideoIdentDb_VideoIdent`). The `Is_Pass_BankIdent` and `Is_Pass_VideoIdent` flags are the key AML compliance outputs.

**Note**: The `EquityRealCrypto` column is declared in the DDL but the SP does NOT insert a value for it — it is always NULL. The column was computed in an intermediate temp table (#crypto) but excluded from the final INSERT.

The ETL pipeline:

```
DWH_dbo.Dim_Customer (German, KYC3, depositor)
  ├─ DWH_dbo.Dim_Regulation          → Regulation text
  ├─ DWH_dbo.Dim_PlayerStatus        → PlayerStatus text (excl. IDs 2,4)
  ├─ DWH_dbo.Dim_PlayerLevel         → Club (level name)
  ├─ DWH_dbo.Dim_Country ×3          → Country / POBCountry / CitizenshipCountry
  ├─ DWH_dbo.Dim_EvMatchStatus       → EvMatchStatusName
  ├─ DWH_dbo.Dim_ScreeningStatus     → ScreeningStatus
  └─ External_RiskClassification     → RiskScoreName, RiskScore_Explanation
         +
  BI_DB_dbo.BI_DB_PositionPnL        → Has_Open_RealCrypto flag (IsSettled=1, Crypto)
         │  Filter: HasWallet=1 OR Has_Open_RealCrypto=1
         ▼
  DWH_dbo.Fact_CustomerAction        → TotalDeposit (ActionTypeID=7)
  DWH_dbo.V_Liabilities              → TotalEquity (Liabilities + ActualNWA)
  general.SolarisBankIdentDb         → Is_Pass_BankIdent (latest by _ts, GlobalStatus)
  general.VideoIdentDb               → Is_Pass_VideoIdent (latest by UpdatedOn, Status)
         │  SP_AML_German_Video_Ident (TRUNCATE + INSERT, @Date parameter)
         ▼
  BI_DB_dbo.AML_German_Video_Ident
  (ROUND_ROBIN HEAP — 198,613 rows as of 2026-04-23)
```

---

## 2. Business Logic

### 2.1 Population Criteria

**What**: The table covers a tightly-defined subset of eToro's customer base.

**Rules** (applied in #pop base query):
| Criterion | Filter | Notes |
|-----------|--------|-------|
| Country | `Dim_Country.DWHCountryID = 79` (Germany) | Country text always = 'Germany' in output |
| KYC Level | `VerificationLevelID = 3` | Fully verified only |
| Valid depositor | `IsValidCustomer = 1 AND IsDepositor = 1` | Active accounts with at least one deposit |
| Account status | `PlayerStatusID NOT IN (2, 4)` | Excludes two specific restricted/closed status IDs |

**Crypto exposure filter** (applied in #finalpop):
- `HasWallet = 1` (active eToro Money wallet) **OR**
- `Has_Open_RealCrypto = 1` (open real crypto positions via BI_DB_PositionPnL on run date)

### 2.2 Identity Verification Flags

**Bank Ident (Is_Pass_BankIdent)**:
- Source: `general.SolarisBankIdentDb_SolarisBankIdent`
- Logic: `MAX(CASE WHEN RN=1 AND GlobalStatus = 'successful' THEN 1 ELSE 0 END)`
- `RN=1` uses `ROW_NUMBER() OVER (PARTITION BY GCID ORDER BY _ts DESC)` — the most recent attempt
- **Sample**: Predominantly 0 (most German customers have NOT completed Bank Ident)

**Video Ident (Is_Pass_VideoIdent)**:
- Source: `general.VideoIdentDb_VideoIdent`
- Logic: `MAX(CASE WHEN RN=1 AND Status = 'Success' THEN 1 ELSE 0 END)`
- `RN=1` uses `ROW_NUMBER() OVER (PARTITION BY GCID ORDER BY CAST(UpdatedOn AS DATE) DESC)` — the most recent attempt
- **Sample**: Mix of 0 and 1

### 2.3 Crypto Equity Calculation

**Has_Open_RealCrypto**: `MAX(CASE WHEN #crypto.CID IS NOT NULL THEN 1 ELSE 0 END)` — 1 if any open real crypto position existed on the run date. Sources from `BI_DB_PositionPnL WHERE IsSettled=1` joined to `Dim_Instrument WHERE InstrumentTypeID=10` (Crypto).

**EquityRealCrypto**: ALWAYS NULL. The SP computes crypto equity (`SUM(Amount + PositionPnL)`) in the `#crypto` temp table but does NOT include this column in the final INSERT statement. Do not use this column.

### 2.4 Financial Totals

**TotalDeposit**: `SUM(Fact_CustomerAction.Amount) WHERE ActionTypeID = 7` — lifetime total deposit amount in USD.

**TotalEquity**: `ISNULL(V_Liabilities.Liabilities, 0) + ISNULL(V_Liabilities.ActualNWA, 0)` on the run date.

---

## 3. Query Advisory

- **Country is always 'Germany'**: No need to filter on Country — the entire table is Germany only.
- **EquityRealCrypto is always NULL**: Do not use this column. It is a dead column in the DDL not populated by the SP.
- **198,613 rows**: Moderately sized table. Full scans are acceptable but ROUND_ROBIN HEAP means no optimized joins — use DWH_dbo dimension tables (REPLICATE) for lookups.
- **Is_Pass_BankIdent / Is_Pass_VideoIdent are point-in-time**: Values reflect the most recent verification attempt as of the SP run date. Historical verification status is not preserved.
- **TotalDeposit is cumulative**: Lifetime deposits, not date-bounded.
- **GCID can be NULL**: Older accounts predating GCID introduction have NULL GCID. Use CID as the primary identifier.

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | GCID | int | YES | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — DWH_dbo.Dim_Customer wiki, originally Customer.CustomerStatic) |
| 2 | CID | int | YES | Customer ID (RealCID) — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — DWH_dbo.Dim_Customer wiki, originally Customer.CustomerStatic) |
| 3 | Regulation | varchar(500) | YES | Regulatory entity governing this account, denormalized from Dim_Regulation by name. FK lookup of Dim_Customer.RegulationID. Sample: CySEC (dominant), FCA. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_Regulation JOIN) |
| 4 | PlayerStatus | varchar(500) | YES | Compliance and trading account status text name from Dim_PlayerStatus. Reflects account lifecycle: Normal, Trade & MIMO Blocked, etc. Population excludes statuses 2 and 4 (restricted/closed). (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_PlayerStatus JOIN) |
| 5 | Club | varchar(500) | YES | Customer experience/permission level text name from Dim_PlayerLevel (PlayerLevelID). Branded as 'Club' in this report. Sample values: Bronze, Silver, Platinum, Platinum Plus. Determines available features and risk limits. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_PlayerLevel JOIN) |
| 6 | Country | varchar(500) | YES | Country of residence name from Dim_Country. Always 'Germany' in this table — SP filters CountryID=79 (Germany). (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_Country JOIN) |
| 7 | POBCountry | varchar(500) | YES | Place of birth country name from Dim_Country (POBCountryID). May differ from Country (residence). Added for enhanced KYC (HLD: RD-4436). NULL if POBCountryID not set. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_Country LEFT JOIN) |
| 8 | EvMatchStatusName | varchar(500) | YES | Electronic verification match result name from Dim_EvMatchStatus (EvMatchStatus). Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_EvMatchStatus LEFT JOIN) |
| 9 | RegisteredReal | datetime | YES | Account registration date (renamed from Registered). Default=getdate() at creation. (Tier 1 — DWH_dbo.Dim_Customer wiki, originally Customer.CustomerStatic) |
| 10 | FirstDepositDate | datetime | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 11 | FirstDepositAmount | money | YES | Amount of first deposit in USD. Updated from FTDAmountInUsd. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 12 | HasWallet | int | YES | 1 if the customer has an active eToro Money wallet linked to their trading account. Part of the inclusion filter: rows appear only when HasWallet=1 OR Has_Open_RealCrypto=1. (Tier 1 — DWH_dbo.Dim_Customer wiki, originally BackOffice.Customer) |
| 13 | ScreeningStatus | varchar(500) | YES | Compliance screening status text name from Dim_ScreeningStatus. Updated from ScreeningService. Sample: NoMatch, PEP, Adverse Media. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_ScreeningStatus LEFT JOIN) |
| 14 | RiskScoreName | varchar(500) | YES | AML risk score classification from External_RiskClassification_dbo_V_RiskClassificationDataLake. Sample: Low, Medium, High. NULL if CID not found in RiskClassification. (Tier 2 — SP_AML_German_Video_Ident, External_RiskClassification) |
| 15 | Has_Open_RealCrypto | int | YES | SP-derived flag: 1 if the customer had open real crypto positions (BI_DB_PositionPnL WHERE IsSettled=1, InstrumentTypeID=10 Crypto) on the run date; 0 otherwise. Part of the inclusion filter. (Tier 2 — SP_AML_German_Video_Ident) |
| 16 | EquityRealCrypto | money | YES | **ALWAYS NULL.** Column exists in DDL but SP_AML_German_Video_Ident does NOT include it in the INSERT. Crypto equity (SUM of Amount + PositionPnL for crypto positions) was computed in an intermediate temp table (#crypto) but excluded from the final write. Dead column. (Tier 2 — SP code analysis; always NULL) |
| 17 | TotalDeposit | money | YES | Lifetime total deposit amount (USD) from Fact_CustomerAction WHERE ActionTypeID=7 (Deposit). Cumulative — not date-bounded. NULL if no deposit records found (LEFT JOIN). (Tier 2 — SP_AML_German_Video_Ident via Fact_CustomerAction) |
| 18 | TotalEquity | money | YES | Total customer equity on the run date: ISNULL(V_Liabilities.Liabilities, 0) + ISNULL(V_Liabilities.ActualNWA, 0). NULL if not found in V_Liabilities for that DateID. (Tier 2 — SP_AML_German_Video_Ident via DWH_dbo.V_Liabilities) |
| 19 | Is_Pass_BankIdent | int | YES | 1 if the customer's most recent Solaris Bank identity check (SolarisBankIdentDb_SolarisBankIdent, ranked by _ts DESC) has GlobalStatus='successful'; 0 otherwise. German bank-based identity verification. 0 for customers who never attempted or failed Bank Ident. (Tier 2 — SP_AML_German_Video_Ident, general.SolarisBankIdentDb_SolarisBankIdent) |
| 20 | Is_Pass_VideoIdent | int | YES | 1 if the customer's most recent Video Ident check (VideoIdentDb_VideoIdent, ranked by UpdatedOn DESC) has Status='Success'; 0 otherwise. German video identity verification. 0 for customers who never attempted or failed Video Ident. (Tier 2 — SP_AML_German_Video_Ident, general.VideoIdentDb_VideoIdent) |
| 21 | UpdateDate | datetime | YES | ETL load timestamp set to GETDATE() by SP_AML_German_Video_Ident on each daily run. Does NOT reflect production modification date. (Tier 5 — ETL metadata propagation) |
| 22 | CitizenshipCountry | nvarchar(500) | YES | Country of citizenship text name from Dim_Country (CitizenshipCountryID). May differ from Country (residence). Added 2018 for enhanced KYC. NULL if CitizenshipCountryID not set. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_Country LEFT JOIN) |
| 23 | RiskScore_Explanation | nvarchar(500) | YES | Free-text explanation of the AML risk score assignment from External_RiskClassification_dbo_V_RiskClassificationDataLake. Describes the factors contributing to the risk classification. NULL if CID not in RiskClassification. (Tier 2 — SP_AML_German_Video_Ident, External_RiskClassification) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| GCID | etoro.Customer.CustomerStatic | GCID | Passthrough via Dim_Customer |
| CID | etoro.Customer.CustomerStatic | RealCID | Renamed to CID |
| Regulation | etoro.BackOffice.Customer → Dictionary.Regulation | Name | Dim_Regulation JOIN |
| PlayerStatus | etoro.Dictionary.PlayerStatus | Name | Dim_PlayerStatus JOIN |
| Club | etoro.Dictionary.PlayerLevel | Name | Dim_PlayerLevel JOIN |
| Country | etoro.Dictionary.Country | Name | Dim_Country JOIN (CountryID=79) |
| POBCountry | etoro.Dictionary.Country | Name | Dim_Country LEFT JOIN (POBCountryID) |
| CitizenshipCountry | etoro.Dictionary.Country | Name | Dim_Country LEFT JOIN (CitizenshipCountryID) |
| EvMatchStatusName | etoro.Dictionary.EvMatchStatus | EvMatchStatusName | Dim_EvMatchStatus LEFT JOIN |
| RegisteredReal | etoro.Customer.CustomerStatic | Registered | Passthrough via Dim_Customer |
| FirstDepositDate | etoro.CustomerFinanceDB | — | SP_Dim_Customer FTD logic |
| FirstDepositAmount | etoro.CustomerFinanceDB | FTDAmountInUsd | SP_Dim_Customer |
| HasWallet | etoro.BackOffice.Customer | HasWallet | Passthrough via Dim_Customer |
| ScreeningStatus | ScreeningService | — | Dim_ScreeningStatus LEFT JOIN |
| RiskScoreName | RiskClassification data lake | RiskScoreName | External_RiskClassification LEFT JOIN |
| RiskScore_Explanation | RiskClassification data lake | RiskScore_Explanation | External_RiskClassification LEFT JOIN |
| Has_Open_RealCrypto | BI_DB_dbo.BI_DB_PositionPnL | — | SP-derived CASE flag, InstrumentTypeID=10 |
| EquityRealCrypto | — | — | Always NULL — not inserted by SP |
| TotalDeposit | DWH_dbo.Fact_CustomerAction | Amount | SUM WHERE ActionTypeID=7 |
| TotalEquity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | ISNULL sum |
| Is_Pass_BankIdent | general.SolarisBankIdentDb_SolarisBankIdent | GlobalStatus | MAX CASE, latest by _ts |
| Is_Pass_VideoIdent | general.VideoIdentDb_VideoIdent | Status | MAX CASE, latest by UpdatedOn |
| UpdateDate | — | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
[DWH Dimensions]
DWH_dbo.Dim_Customer (KYC3, German, active depositor)
  + Dim_Regulation / Dim_PlayerStatus / Dim_PlayerLevel
  + Dim_Country (×3) / Dim_EvMatchStatus / Dim_ScreeningStatus
  + External_RiskClassification_dbo_V_RiskClassificationDataLake
    → #pop (base German KYC3 population)

BI_DB_dbo.BI_DB_PositionPnL (IsSettled=1, InstrumentTypeID=10 Crypto)
    → #crypto (per-customer crypto equity — used for Has_Open_RealCrypto flag only)

#pop + #crypto → #finalpop (WHERE HasWallet=1 OR Has_Open_RealCrypto=1)

DWH_dbo.Fact_CustomerAction (ActionTypeID=7) → #deposit (TotalDeposit)
DWH_dbo.V_Liabilities (@DateID)             → #equity (TotalEquity)
general.SolarisBankIdentDb_SolarisBankIdent  → #bankIdent2 (Is_Pass_BankIdent)
general.VideoIdentDb_VideoIdent              → #videoident2 (Is_Pass_VideoIdent)

#finalpop + #deposit + #equity + #bankIdent2 + #videoident2 → #finaltable
    │  SP_AML_German_Video_Ident (TRUNCATE + INSERT, @Date parameter)
    ▼
BI_DB_dbo.AML_German_Video_Ident
(ROUND_ROBIN HEAP — 198,613 rows as of 2026-04-23)
```

---

## 6. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| DWH_dbo.Dim_Customer | CID = RealCID | Source of all customer-level attributes; this table is a denormalized subset |
| DWH_dbo.Fact_CustomerAction | CID = RealCID | Source of TotalDeposit; also used for broader transaction analysis |
| DWH_dbo.V_Liabilities | CID | Source of TotalEquity |
| BI_DB_dbo.BI_DB_PositionPnL | CID | Source of Has_Open_RealCrypto flag |
| BI_DB_dbo.BI_DB_AMLPeriodicReview | CID | Sibling AML table: broader periodic review population (includes non-German, non-crypto customers) |
| BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | CID | Source of risk score fields |

---

## 7. Sample Queries

```sql
-- Full German crypto AML monitoring list
SELECT CID, GCID, PlayerStatus, Club, ScreeningStatus,
       RiskScoreName, HasWallet, Has_Open_RealCrypto,
       Is_Pass_BankIdent, Is_Pass_VideoIdent
FROM [BI_DB_dbo].[AML_German_Video_Ident]
ORDER BY CID;

-- Customers who failed both identity checks (AML risk)
SELECT CID, GCID, PlayerStatus, Club, ScreeningStatus, RiskScoreName,
       TotalDeposit, TotalEquity
FROM [BI_DB_dbo].[AML_German_Video_Ident]
WHERE Is_Pass_BankIdent = 0
  AND Is_Pass_VideoIdent = 0
  AND RiskScoreName IN ('High', 'Very High')
ORDER BY TotalEquity DESC;

-- PEP screening + ident completion summary
SELECT ScreeningStatus,
       COUNT(*) AS CustomerCount,
       SUM(Is_Pass_BankIdent) AS Passed_BankIdent,
       SUM(Is_Pass_VideoIdent) AS Passed_VideoIdent,
       AVG(CAST(TotalEquity AS FLOAT)) AS AvgEquity
FROM [BI_DB_dbo].[AML_German_Video_Ident]
GROUP BY ScreeningStatus
ORDER BY CustomerCount DESC;
```

---

## 8. Atlassian Sources

No Confluence pages identified for this specific table. Consult the DATA space in Confluence for AML/compliance documentation covering German BaFin regulations, Video Ident, and Bank Ident requirements.

---

*Tier breakdown: GCID/CID/Regulation/PlayerStatus/Club/Country/POBCountry/CitizenshipCountry/EvMatchStatusName/RegisteredReal/FirstDepositDate/FirstDepositAmount/HasWallet/ScreeningStatus (Tier 1 — DWH_dbo.Dim_Customer wiki) | RiskScoreName/RiskScore_Explanation/Has_Open_RealCrypto/TotalDeposit/TotalEquity/Is_Pass_BankIdent/Is_Pass_VideoIdent (Tier 2 — SP logic) | EquityRealCrypto (Tier 2 — always NULL, dead column) | UpdateDate (Tier 5 — ETL metadata)*
*Quality score: 8.8/10 (Phase 16 adversarial evaluation, 2026-04-23)*

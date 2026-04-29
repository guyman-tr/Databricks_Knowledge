# BI_DB_dbo.BI_DB_OPS_VerificationLevel2Stuck

> 20.2K-row operations compliance table identifying customers stuck at verification level 2 who meet all prerequisites to advance to VL3. Daily TRUNCATE+INSERT from Dim_Customer + screening services + document checks + risk alerts. Regulation-specific eligibility rules for CySEC, FCA, FSA Seychelles, ASIC, FSRA, and FinCEN. Registrations from 2009 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer (primary) via `SP_OPS_VerificationLevel2Stuck` |
| **Refresh** | Daily (TRUNCATE+INSERT, no date parameter — uses GETDATE()) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Pavlina Masoura (2024-03-06) |
| **Row Count** | ~20,219 (as of 2026-04-12) |

---

## 1. Business Meaning

`BI_DB_OPS_VerificationLevel2Stuck` identifies customers who are stuck at KYC verification level 2 and appear to meet all the prerequisites for promotion to level 3 (fully verified). The table serves as an operations compliance worklist — these customers have passed electronic verification (EV) or submitted valid unexpired identity/address documents, have verified phone numbers, and meet regulation-specific screening requirements, yet remain at VL2.

The population is filtered to: VerificationLevelID=2, PlayerStatusID IN (1=Normal, 13=Pending Verification), PhoneVerifiedID IN (1=AutomaticallyVerified, 2=ManuallyVerified). Additional regulation-specific filters apply at the final stage:

- **CySEC + Normal KYCFlow**: Pass through directly (no screening required)
- **CySEC + non-Normal KYCFlow**: Require ScreeningStatusCheck=1 (NoMatch)
- **FCA / FSA Seychelles / ASIC / ASIC & GAML / FSRA**: Require screening NoMatch
- **FinCEN / FinCEN+FINRA / FINRAONLY**: Require screening NoMatch + email verified + SSN verified (via EV or SSN Card document)

Multi-step verification checks: EV match status, POI/POA document validity (most recent, non-expired), selfie liveliness/motion check, SSN card presence, active risk alert screening (HighRiskLogin, KycRelations, CreditCardBruteForce, FundingStolenReportedByProcessor), and elderly flag (US >=60, non-US >=70).

As of 2026-04-12: 20,219 accounts. 49% FinCEN+FINRA, 17% FCA, 16% CySEC. KYCFlow: VBD 60%, HRC 24%. Age range 18-100 (avg 51). 97% Normal status, 3% Pending Verification.

---

## 2. Business Logic

### 2.1 EVorDocsVerified — Dual-Path Identity Confirmation

**What**: Customer is verified if they passed electronic verification (EV) OR have valid unexpired POI and POA documents.
**Columns Involved**: `EVorDocsVerified`, `EvMatchStatusName`
**Rules**:
- Path 1: `EvMatchStatusName = 'Verified'` → EVCheck=1
- Path 2: Most recent POI document (DocumentTypeID=2) is not expired AND most recent POA document (DocumentTypeID=1) is not expired
- EVorDocsVerified = 1 if Path 1 OR Path 2 succeeds
- Only customers with EVorDocsVerified=1 proceed to the final population

### 2.2 Regulation-Specific Eligibility Rules

**What**: Different regulatory jurisdictions have different requirements for VL2→VL3 promotion eligibility.
**Columns Involved**: `DesignatedRegulation`, `KYCFLow`, `ScreeningStatusCheck`, `EmailVerifiedCheck`
**Rules**:
- CySEC + Normal KYCFlow: no screening required
- CySEC + non-Normal KYCFlow (VBD, HRC, VBT): screening NoMatch required
- FCA / FSA Seychelles / ASIC / ASIC & GAML / FSRA: screening NoMatch required
- FinCEN / FinCEN+FINRA / FINRAONLY: screening NoMatch + email verified + SSN verified (EV or SSN Card doc)

### 2.3 Elderly Check — Age-Based Flag

**What**: Flags elderly customers for additional review with different thresholds by country.
**Columns Involved**: `ElderlyCheck`, `Age`, `Country`
**Rules**:
- US customers: ElderlyCheck=1 if Age >= 60
- All other countries: ElderlyCheck=1 if Age >= 70

### 2.4 Active Alerts Check

**What**: Identifies customers with active risk alerts that may block verification.
**Columns Involved**: `NoActiveAlertsCheck`
**Rules**:
- Checks BI_DB_RiskAlertManagementTool for alert types: HighRiskLogin, KycRelations, CreditCardBruteForce, FundingStolenReportedByProcessor
- Only alerts with StatusType IN ('Active', 'Follow Up') are considered
- NoActiveAlertsCheck=1 means NO active alerts (clear); 0 means active alerts exist

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no preferred join key. For JOINs to Dim_Customer use `CID = RealCID`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many customers stuck by regulation? | `SELECT DesignatedRegulation, COUNT(*) FROM ... GROUP BY DesignatedRegulation` |
| Stuck customers who could be auto-promoted? | `WHERE NoActiveAlertsCheck=1 AND SelfieCheck=1 AND ElderlyCheck=0` |
| Elderly stuck customers in US | `WHERE Country = 'United States' AND ElderlyCheck = 1` |
| Stuck with active risk alerts | `WHERE NoActiveAlertsCheck = 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `CID = RealCID` | Full customer profile |
| BI_DB_dbo.BI_DB_CIDFirstDates | `CID = CID` | Additional milestone dates |

### 3.4 Gotchas

- **VerificationLevelID is always 2**: By design — the table only contains VL2 customers
- **DesignatedRegulation vs Regulation**: Two separate columns from two different Dim_Regulation joins. DesignatedRegulation = the intended regulation (from DesignatedRegulationID), Regulation = the current regulation (from RegulationID). These can differ for migrated or reassigned customers
- **ScreeningStatusCheck = 0**: Does NOT necessarily mean failed screening — it means the screening status is NOT 'NoMatch' (could be pending, in-progress, or matched)
- **NoActiveAlertsCheck naming**: 1 = NO active alerts (good), 0 = has active alerts (blocking). The name is counterintuitive — it's a "check passed" flag, not an "alerts exist" flag
- **KYCFLow typo**: Column is named `KYCFLow` (capital L) in the DDL, matching the SP code. May cause case-sensitive query issues
- **Age is approximate**: Computed as DATEDIFF(YEAR, BirthDate, GETDATE()) which counts calendar year boundaries, not actual age — can be off by 1 year

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge, limited confidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Mapped from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 3 | RegistrationDate | datetime | YES | Account registration date. CAST(RegisteredReal AS DATE) from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 4 | VerificationLevel2Date | datetime | YES | First date customer reached verification level 2. MIN(FromDateID) WHERE VerificationLevelID=2. Passthrough from BI_DB_CIDFirstDates. (Tier 2 — SP_CIDFirstDates, Fact_SnapshotCustomer) |
| 5 | DesignatedRegulation | varchar(max) | YES | Short code for the designated (intended) regulation based on customer's DesignatedRegulationID. Values: CySEC, FCA, FSA Seychelles, ASIC & GAML, FSRA, FINRAONLY, FinCEN+FINRA, FinCEN, ASIC. Passthrough from Dim_Regulation. (Tier 1 — Dictionary.Regulation) |
| 6 | KYCFLow | varchar(max) | YES | KYC flow type short name from ComplianceStateDB. Values: Normal, VBD (Verify Before Deposit), HRC (High Risk Country), VBT (Verify Before Trade). Joined via GCID → KycFlow → KYCFlowType. (Tier 2 — SP_OPS_VerificationLevel2Stuck, ComplianceStateDB) |
| 7 | Country | varchar(max) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 8 | VerificationLevelID | int | YES | KYC verification level. Always 2 in this table due to WHERE filter. FK to Dictionary.VerificationLevel. Passthrough from Dim_Customer. (Tier 1 — BackOffice.Customer) |
| 9 | Age | int | YES | Customer age in years at SP execution time. DATEDIFF(YEAR, BirthDate, GETDATE()). Approximate — counts calendar year boundaries, not actual birthday. (Tier 2 — SP_OPS_VerificationLevel2Stuck) |
| 10 | EvMatchStatusName | varchar(max) | YES | Human-readable label for the EV match status. Renamed from Name in production source. Values: None, PartiallyVerified, Verified, NotVerified. Passthrough from Dim_EvMatchStatus. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 11 | ScreeningStatus | varchar(max) | YES | Screening service result name. Key value for eligibility: 'NoMatch' = clear. From External_ScreeningService_Dictionary_ScreeningStatus via UserScreening. (Tier 2 — SP_OPS_VerificationLevel2Stuck, ScreeningService) |
| 12 | ScreeningStatusCheck | int | YES | Binary flag: 1 if ScreeningStatus = 'NoMatch' (clear), 0 otherwise. Used in regulation-specific eligibility rules. (Tier 2 — SP_OPS_VerificationLevel2Stuck) |
| 13 | EmailVerifiedCheck | int | YES | Binary flag: 1 if IsEmailVerified=1, 0 otherwise. Required for FinCEN regulation eligibility. (Tier 2 — SP_OPS_VerificationLevel2Stuck) |
| 14 | PhoneVerifiedName | varchar(max) | YES | Human-readable verification state label. Note: ID=2 has value "ManualyVerified" — a production typo (single 'l') preserved verbatim from etoro.Dictionary.PhoneVerified. Always AutomaticallyVerified or ManualyVerified in this table (WHERE filter). Passthrough from Dim_PhoneVerified. (Tier 1 — Dictionary.PhoneVerified) |
| 15 | IsEmailVerified | int | YES | Raw email verification flag from Dim_Customer. 1=verified, 0=not verified. Source for EmailVerifiedCheck. Passthrough from Dim_Customer. (Tier 1 — BackOffice.Customer) |
| 16 | PlayerStatus | varchar(max) | YES | Human-readable restriction state label. Only Normal or Pending Verification appear (WHERE filter). Passthrough from Dim_PlayerStatus. (Tier 1 — Dictionary.PlayerStatus) |
| 17 | DocumentStatusName | varchar(max) | YES | Human-readable document review status. 1=Uploaded, 2=PendingReview, 3=Approved, 4=Declined, 5=Expired. Passthrough from Dim_DocumentStatus. (Tier 1 — Dictionary.DocumentStatus) |
| 18 | Regulation | varchar(max) | YES | Short code for the current regulation (from RegulationID). May differ from DesignatedRegulation for migrated/reassigned customers. Passthrough from Dim_Regulation. (Tier 1 — Dictionary.Regulation) |
| 19 | EVorDocsVerified | int | YES | Binary flag: 1 if customer passed EV (Verified) OR has valid non-expired POI and POA documents. Always 1 in this table — customers with EVorDocsVerified=0 are filtered out. (Tier 2 — SP_OPS_VerificationLevel2Stuck) |
| 20 | NoActiveAlertsCheck | int | YES | Binary flag: 1 = no active risk alerts (clear for promotion), 0 = has active alerts (HighRiskLogin, KycRelations, CreditCardBruteForce, FundingStolenReportedByProcessor with Active/Follow Up status). (Tier 2 — SP_OPS_VerificationLevel2Stuck, BI_DB_RiskAlertManagementTool) |
| 21 | SelfieCheck | int | YES | Binary flag: 1 if customer has submitted a selfie document (DocumentTypeID=18 SelfieLiveliness or 23 SelfieMotion); 0 otherwise. (Tier 2 — SP_OPS_VerificationLevel2Stuck) |
| 22 | ElderlyCheck | int | YES | Binary flag: 1 if customer is elderly (US: Age>=60, non-US: Age>=70); 0 otherwise. Flags customers requiring additional review. (Tier 2 — SP_OPS_VerificationLevel2Stuck) |
| 23 | UpdateDate | datetime | NO | ETL execution timestamp. GETDATE() at SP execution time. All rows share the same value per daily run. (Tier 2 — SP_OPS_VerificationLevel2Stuck) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | rename (RealCID → CID) via Dim_Customer |
| GCID | Customer.CustomerStatic | GCID | passthrough via Dim_Customer |
| RegistrationDate | Customer.CustomerStatic | Registered | CAST to date via Dim_Customer |
| Country | Dictionary.Country | Name | dim-lookup via Dim_Country |
| VerificationLevelID | BackOffice.Customer | VerificationLevelID | passthrough via Dim_Customer |
| DesignatedRegulation | Dictionary.Regulation | Name | dim-lookup via DesignatedRegulationID |
| PhoneVerifiedName | Dictionary.PhoneVerified | PhoneVerifiedName | dim-lookup via Dim_PhoneVerified |
| PlayerStatus | Dictionary.PlayerStatus | Name | dim-lookup via Dim_PlayerStatus |
| DocumentStatusName | Dictionary.DocumentStatus | DocumentStatusName | dim-lookup via Dim_DocumentStatus |
| Regulation | Dictionary.Regulation | Name | dim-lookup via RegulationID |
| IsEmailVerified | BackOffice.Customer | IsEmailVerified | passthrough via Dim_Customer |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (VL2 + Normal/PendingVerification + Phone verified)
  + DWH_dbo.Dim_Country, Dim_PhoneVerified, Dim_PlayerStatus
  + DWH_dbo.Dim_EvMatchStatus, Dim_DocumentStatus, Dim_Regulation (x2)
  + BI_DB_dbo.BI_DB_CIDFirstDates (VL2 date)
  + External_ScreeningService (screening status)
  + External_ComplianceStateDB (KYC flow type)
  |
  |-- SP_OPS_VerificationLevel2Stuck (daily TRUNCATE+INSERT)
  |   Step 1: Build #population — base VL2 customers + dim lookups
  |   Step 2: Build #EVCheck — EV verification status
  |   Step 3: Build #documentsPOA/POI — latest non-expired docs
  |   Step 4: Build #DocsEVCheck — dual-path EV OR docs verified
  |   Step 5: Filter to EVorDocsVerified=1 → #population1
  |   Step 6: Build #elderly, #alerts, #SSN, #selfie checks
  |   Step 7: Build #final — apply regulation-specific eligibility rules
  |   Step 8: TRUNCATE + INSERT into target
  v
BI_DB_dbo.BI_DB_OPS_VerificationLevel2Stuck (20.2K rows, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Primary customer dimension |
| Country | DWH_dbo.Dim_Country (Name) | Country dimension |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus (Name) | Account status |
| DesignatedRegulation, Regulation | DWH_dbo.Dim_Regulation (Name) | Regulatory authority (two joins) |
| EvMatchStatusName | DWH_dbo.Dim_EvMatchStatus | EV identity verification |
| DocumentStatusName | DWH_dbo.Dim_DocumentStatus | Document review state |
| PhoneVerifiedName | DWH_dbo.Dim_PhoneVerified | Phone verification state |
| VerificationLevel2Date | BI_DB_dbo.BI_DB_CIDFirstDates | Customer milestone dates |
| NoActiveAlertsCheck | BI_DB_dbo.BI_DB_RiskAlertManagementTool | Risk alert screening |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 VL2-Stuck Customers Ready for Auto-Promotion

```sql
SELECT CID, GCID, Country, DesignatedRegulation, KYCFLow
FROM BI_DB_dbo.BI_DB_OPS_VerificationLevel2Stuck
WHERE NoActiveAlertsCheck = 1
  AND SelfieCheck = 1
  AND ElderlyCheck = 0
ORDER BY VerificationLevel2Date ASC
```

### 7.2 Elderly Stuck Customers by Regulation

```sql
SELECT DesignatedRegulation, Country, COUNT(*) AS cnt
FROM BI_DB_dbo.BI_DB_OPS_VerificationLevel2Stuck
WHERE ElderlyCheck = 1
GROUP BY DesignatedRegulation, Country
ORDER BY cnt DESC
```

### 7.3 Customers with Active Risk Alerts Blocking Promotion

```sql
SELECT CID, GCID, Country, DesignatedRegulation, EvMatchStatusName, ScreeningStatus
FROM BI_DB_dbo.BI_DB_OPS_VerificationLevel2Stuck
WHERE NoActiveAlertsCheck = 0
ORDER BY RegistrationDate ASC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable due to permissions).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 11 T1, 12 T2, 0 T3, 0 T4, 0 T5 | Elements: 23/23, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_OPS_VerificationLevel2Stuck | Type: Table | Production Source: DWH_dbo.Dim_Customer via SP_OPS_VerificationLevel2Stuck*

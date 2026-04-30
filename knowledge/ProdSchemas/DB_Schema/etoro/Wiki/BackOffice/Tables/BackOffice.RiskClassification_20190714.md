# BackOffice.RiskClassification_20190714

> Historical AML risk classification snapshot taken on 2019-07-14, containing per-customer risk scores, alert flags, and compliance questionnaire answers for point-in-time audit reference.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | CID (no formal PK constraint) |
| **Partition** | No |
| **Indexes** | 0 (no indexes) |

---

## 1. Business Meaning

`BackOffice.RiskClassification_20190714` is a point-in-time archival snapshot of the AML (Anti-Money Laundering) risk classification data for all customers as it stood on July 14, 2019. The date in the table name identifies this as a named snapshot taken on that specific date - the eToro back-office was preserving the state of the live risk scoring table (likely `BackOffice.RiskClassification`) at a specific moment, either for a regulatory review, compliance audit, a major schema migration, or before a risk model change.

This table exists as an immutable historical reference. The fact that it has no primary key, no foreign key constraints, and no indexes confirms it is a pure data archive, not an operational table. It was populated once (from the live classification table) and has not been modified since. Analysts and compliance teams can query it to understand what the risk assessments looked like on that specific date.

The `qq_*` prefix columns (22 of them) represent individual questions from the AML compliance questionnaire that analysts completed for each customer. The `Score*` columns represent numeric risk scores across multiple risk dimensions. `MaxScore` is the aggregate/worst-case risk score that drives overall risk classification.

---

## 2. Business Logic

### 2.1 Multi-Dimensional AML Risk Scoring

**What**: Each customer receives individual scores across distinct risk dimensions, which combine to a MaxScore that drives overall risk classification.

**Columns/Parameters Involved**: `MaxScore`, `ScoreCountryOnboardingClients`, `ScoreCountryExistingClients`, `ScoreNetDeposit`, `ScoreAge`, `ScorePEPStatus`, `ScoreAnnualIncome`, `ScoreCashAndAssets`, `ScoreInvestPlan`, `ScoreMainIncome`, `ScoreOccupation`, `ScoreExpectedOriginFunds`, `ScoreExpectedDestinationPayments`, `ScoreFTD_Bank_MOP`

**Rules**:
- Each `Score*` column contributes a numeric risk points value for that dimension.
- `MaxScore` is the highest single dimension score (or composite worst case) - not a sum.
- `WithAlert` flag indicates whether any alert conditions were triggered.
- `AlertCountry`, `AlertAge`, `AlertNameFilled` are specific binary alert flags.
- `IsFTD` (First Time Deposit) and `IsFWTD` (First Wallet Transaction Date) are derived boolean flags from the dates.

### 2.2 AML Questionnaire Responses (qq_ Columns)

**What**: 22 binary compliance questionnaire answers, each representing a specific AML/KYC risk indicator.

**Columns/Parameters Involved**: All `qq_*` columns

**Rules**:
- All `qq_*` columns are INT NOT NULL. Likely 0/1 binary flags (0=No/Low risk, 1=Yes/High risk indicator).
- These represent answers to formal AML questionnaire questions completed by compliance staff at the July 2019 snapshot point.
- The `qq_` naming prefix stands for "questionnaire question".

---

## 3. Data Overview

This is a historical snapshot table (2019-07-14). No representative sample available from live data - the table contains the state of all customers as of that date. Column structure indicates the data type and business area:

| Column Group | Columns | Meaning |
|-------------|---------|---------|
| Identity | CID, Country, Regulation, Desk | Customer identification and regulatory context |
| Date markers | FirstDepositDate, FirstWalletTransDate, FirstDate, LastAuditDate, LastMaxScoreChangeDate, AuditDueDate, Date | Timeline tracking for first activity and audit cycle |
| Flags | IsFTD, IsFWTD, WithAlert, AuditDueDateExpired, AlertCountry, AlertAge, AlertNameFilled | Binary status indicators |
| Risk scores | MaxScore, 12x Score* columns | Numeric risk dimension scores |
| Questionnaire | 22x qq_* columns | AML compliance questionnaire responses |
| Metadata | UpdateDate | Snapshot capture timestamp |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | NAME-INFERRED | Customer ID. De facto row identifier even without a formal PK constraint. References Customer.Customer.CID as of 2019-07-14. |
| 2 | Country | varchar(50) | NO | - | NAME-INFERRED | Customer's country of residence as of the snapshot date. Used as input for country-based risk scoring. |
| 3 | FirstDepositDate | datetime | YES | - | NAME-INFERRED | Date and time of the customer's first deposit, as known on 2019-07-14. |
| 4 | FirstWalletTransDate | datetime | YES | - | NAME-INFERRED | Date and time of the customer's first wallet transaction (eToro Money / crypto transfer). |
| 5 | FirstDate | date | YES | - | NAME-INFERRED | Earlier of FirstDepositDate and FirstWalletTransDate - the customer's first financial activity date. |
| 6 | Regulation | varchar(50) | YES | - | NAME-INFERRED | Regulatory jurisdiction name (e.g., "CySEC", "FCA") assigned to this customer on the snapshot date. |
| 7 | IsFTD | int | NO | - | NAME-INFERRED | 1 if the customer had made their First Time Deposit by the snapshot date. 0 otherwise. |
| 8 | IsFWTD | int | NO | - | NAME-INFERRED | 1 if the customer had made their First Wallet Transaction by the snapshot date. 0 otherwise. |
| 9 | MaxScore | bigint | YES | - | NAME-INFERRED | Maximum AML risk score across all scoring dimensions for this customer. Drives the overall risk classification level. |
| 10 | WithAlert | int | YES | - | NAME-INFERRED | 1 if any alert threshold was exceeded for this customer. Flags the customer for enhanced due diligence review. |
| 11 | ScoreCountryOnboardingClients | int | YES | - | NAME-INFERRED | Risk score contribution from the customer's country (onboarding clients dimension). Higher = higher-risk country. |
| 12 | ScoreCountryExistingClients | int | YES | - | NAME-INFERRED | Risk score contribution from the customer's country (existing clients dimension). Separate scoring factor from onboarding. |
| 13 | ScoreNetDeposit | int | YES | - | NAME-INFERRED | Risk score contribution based on net deposit amount. Larger net deposits increase risk score. |
| 14 | ScoreAge | int | NO | - | NAME-INFERRED | Risk score contribution from customer's age. Certain age ranges (very young or elderly) may carry higher risk. |
| 15 | ScorePEPStatus | int | YES | - | NAME-INFERRED | Risk score contribution from Politically Exposed Person status. PEP = higher risk under AML regulations. |
| 16 | ScoreAnnualIncome | int | YES | - | NAME-INFERRED | Risk score contribution based on declared annual income. Mismatches with activity can increase risk. |
| 17 | ScoreCashAndAssets | int | YES | - | NAME-INFERRED | Risk score contribution from declared liquid assets and wealth. |
| 18 | ScoreInvestPlan | int | YES | - | NAME-INFERRED | Risk score based on the customer's stated investment plan/purpose. |
| 19 | ScoreMainIncome | int | YES | - | NAME-INFERRED | Risk score based on the customer's declared primary income source. |
| 20 | ScoreOccupation | int | YES | - | NAME-INFERRED | Risk score contribution from the customer's occupation/profession. |
| 21 | ScoreExpectedOriginFunds | int | YES | - | NAME-INFERRED | Risk score based on declared origin of funds. Certain source-of-funds carry higher AML risk. |
| 22 | ScoreExpectedDestinationPayments | int | YES | - | NAME-INFERRED | Risk score based on expected destination of payments/withdrawals. |
| 23 | ScoreFTD_Bank_MOP | int | NO | - | NAME-INFERRED | Risk score based on the method of payment used for the first deposit (bank vs. other MOPs). |
| 24 | AlertCountry | int | NO | - | NAME-INFERRED | 1 if the customer's country triggered a specific country-level alert. 0 otherwise. |
| 25 | AlertAge | int | NO | - | NAME-INFERRED | 1 if the customer's age triggered an age-related alert. 0 otherwise. |
| 26 | AlertNameFilled | int | NO | - | NAME-INFERRED | 1 if the customer's name was fully filled in (alerting to missing name data). 0 if name was incomplete. |
| 27 | Desk | varchar(50) | YES | - | NAME-INFERRED | Back-office desk or team assignment responsible for this customer's review. |
| 28 | LastAuditDate | date | YES | - | NAME-INFERRED | Date of the most recent AML audit review for this customer prior to the snapshot. |
| 29 | LastMaxScoreChangeDate | date | YES | - | NAME-INFERRED | Date when MaxScore last changed, showing when the risk profile was last updated. |
| 30 | AuditDueDate | date | YES | - | NAME-INFERRED | Scheduled next audit date for this customer based on their risk level. |
| 31 | AuditDueDateExpired | int | NO | - | NAME-INFERRED | 1 if AuditDueDate had passed without an audit being completed at snapshot time. 0 otherwise. |
| 32 | Date | date | YES | - | NAME-INFERRED | Reference date for this record, likely the snapshot date (2019-07-14) or the record's processing date. |
| 33 | qq_HighPublicProfile | int | NO | - | NAME-INFERRED | AML questionnaire: Does the customer have a high public profile (media, politics, public figure)? |
| 34 | qq_DisclosureSubjected | int | NO | - | NAME-INFERRED | AML questionnaire: Is the customer subject to public disclosure requirements? |
| 35 | qq_RegionSupervised | int | NO | - | NAME-INFERRED | AML questionnaire: Is the customer from a region with effective AML supervision? |
| 36 | qq_JurisdictionNonCorrupt | int | NO | - | NAME-INFERRED | AML questionnaire: Is the customer from a jurisdiction rated as non-corrupt? |
| 37 | qq_AML_CFT_Failure | int | NO | - | NAME-INFERRED | AML questionnaire: Has the customer's jurisdiction had AML/CFT compliance failures? |
| 38 | qq_BackgroundConsistent | int | NO | - | NAME-INFERRED | AML questionnaire: Is the customer's financial background consistent with their declared profile? |
| 39 | qq_TransactionSuspicious | int | NO | - | NAME-INFERRED | AML questionnaire: Have any transactions been flagged as suspicious? |
| 40 | qq_IdentityEvidence | int | NO | - | NAME-INFERRED | AML questionnaire: Is there adequate identity evidence for this customer? |
| 41 | qq_AvoidBusinessRelations | int | NO | - | NAME-INFERRED | AML questionnaire: Should business relations with this customer be avoided? |
| 42 | qq_OwnershipTransparent | int | NO | - | NAME-INFERRED | AML questionnaire: Is the customer's ownership/beneficiary structure transparent? |
| 43 | qq_AssetHoldingVehicle | int | NO | - | NAME-INFERRED | AML questionnaire: Does the customer use asset holding vehicles (shell companies, trusts)? |
| 44 | qq_TransactionsUnusual | int | NO | - | NAME-INFERRED | AML questionnaire: Have transactions been considered unusual relative to expected profile? |
| 45 | qq_SecrecyUnreasonable | int | NO | - | NAME-INFERRED | AML questionnaire: Has the customer shown unreasonable secrecy about their financial affairs? |
| 46 | qq_NFTF | int | NO | - | NAME-INFERRED | AML questionnaire: NFTF (Non-Face-To-Face) customer flag - customer was onboarded remotely. |
| 47 | qq_IdentityDoubts | int | NO | - | NAME-INFERRED | AML questionnaire: Are there doubts about the customer's identity? |
| 48 | qq_ExpectedProductsUsed | int | NO | - | NAME-INFERRED | AML questionnaire: Are the products being used consistent with the customer's expected usage? |
| 49 | qq_NonProfitOrgAbused | int | NO | - | NAME-INFERRED | AML questionnaire: Is there risk of non-profit organization abuse in connection with this customer? |
| 50 | qq_CooperativeClient | int | NO | - | NAME-INFERRED | AML questionnaire: Is the customer cooperative with identity and compliance requests? |
| 51 | qq_IdentityAnonymous | int | NO | - | NAME-INFERRED | AML questionnaire: Has the customer attempted to maintain anonymity? |
| 52 | qq_TransactionComplexity | int | NO | - | NAME-INFERRED | AML questionnaire: Are the customer's transactions unusually complex without clear economic purpose? |
| 53 | qq_PaymentsThirdParty | int | NO | - | NAME-INFERRED | AML questionnaire: Does the customer make or receive third-party payments? |
| 54 | qq_WealthExplained | int | NO | - | NAME-INFERRED | AML questionnaire: Is the source of the customer's wealth adequately explained? |
| 55 | UpdateDate | datetime | NO | - | NAME-INFERRED | Timestamp when this row was last updated in the original live risk table, prior to the snapshot. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer.CID | Implicit | Identifies the customer this risk snapshot belongs to |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Archive table - unlikely to be referenced by operational procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf table, no FKs, archive snapshot).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found. Archive/snapshot table for reference use only.

---

## 7. Technical Details

### 7.1 Indexes

N/A - no indexes defined on this archive table.

### 7.2 Constraints

None. This is a pure data archive with no constraints.

---

## 8. Sample Queries

### 8.1 Get the 2019 risk profile for a specific customer

```sql
SELECT CID, Country, Regulation, MaxScore, WithAlert, ScoreAge, ScorePEPStatus
FROM BackOffice.RiskClassification_20190714 WITH (NOLOCK)
WHERE CID = 99999;
```

### 8.2 Find high-risk customers in the 2019 snapshot

```sql
SELECT CID, Country, MaxScore, WithAlert, Desk, LastAuditDate
FROM BackOffice.RiskClassification_20190714 WITH (NOLOCK)
WHERE WithAlert = 1
ORDER BY MaxScore DESC;
```

### 8.3 Customers with overdue audits at snapshot time

```sql
SELECT CID, AuditDueDate, LastAuditDate, MaxScore, Country
FROM BackOffice.RiskClassification_20190714 WITH (NOLOCK)
WHERE AuditDueDateExpired = 1
ORDER BY AuditDueDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 6/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 55 NAME-INFERRED | Phases: 3/11 (DDL, Live Data, Doc Gen)*
*Note: All NAME-INFERRED elements are expected for an archive snapshot with no active procedure references. Business meaning is inferred from column naming conventions in AML compliance context.*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.RiskClassification_20190714 | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.RiskClassification_20190714.sql*

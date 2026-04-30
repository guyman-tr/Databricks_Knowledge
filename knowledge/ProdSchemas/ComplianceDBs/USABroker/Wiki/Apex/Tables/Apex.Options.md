# Apex.Options

> Comprehensive options trading record tracking each customer's suitability assessment results, eligibility status, Apex approval status, and reasoning form workflow for options trading access.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) + 1 nonclustered (OptionsApexID) |

---

## 1. Business Meaning

Apex.Options is the central record for tracking a customer's options trading eligibility and approval status within the Apex Clearing brokerage system. Each customer has at most one row, tracking three independent but related assessments: (1) the suitability/appropriateness test result, (2) the eligibility determination, and (3) the Apex Clearing approval status. These three dimensions must all be satisfied before a customer can trade options.

This table exists because options trading is a regulated activity requiring explicit suitability assessment (FINRA Rule 2360). The platform must verify the customer understands options risks, meets eligibility criteria, and has received approval from the clearing house before enabling options trading. Additionally, stock and crypto eligibility are tracked separately as newer extensions.

Data flows through four specialized save procedures, each responsible for a different aspect: SaveOptionsAppropriateness (suitability test results), SaveOptionsEligibility (eligibility determination), SaveOptionsStatus (Apex approval status and control), and SaveOptionsReasoningStatus (reasoning form workflow). All use an upsert pattern - creating the row with defaults (0/None) for unrelated fields on first insert, then updating only their specific columns. The ApplicationName column tracks which service last modified the record. System versioning (History.Options) provides a full audit trail.

---

## 2. Business Logic

### 2.1 Three-Dimensional Options Access Control

**What**: Options trading access requires three independent checks to all pass: appropriateness (suitability), eligibility, and Apex approval status.

**Columns/Parameters Involved**: `AppropriatenessTestResultID`, `EligibilityStatusID`, `OptionsStatusID`, `OptionsStatusControlID`

**Rules**:
- AppropriatenessTestResultID must be 2 (Passed) - customer demonstrated understanding of options
- EligibilityStatusID must be 1 (Allowed) - customer meets eligibility criteria
- OptionsStatusID must be 3 (Approved) - Apex Clearing has approved the application
- OptionsStatusControlID must NOT be 1 (Blocked) - no administrative override blocking access
- If any dimension fails, options trading is blocked regardless of the others

**Diagram**:
```
Options Trading Access Decision:

Appropriateness Test   Eligibility Status   Apex Approval   Admin Control
   (Passed?)              (Allowed?)         (Approved?)     (Not Blocked?)
      |                      |                   |               |
      v                      v                   v               v
   [2=Passed]           [1=Allowed]          [3=Approved]    [0=None/2=Allowed]
      |                      |                   |               |
      +----------+-----------+-------------------+               |
                 |                                               |
                 v                                               |
         All three pass? ----YES----> OptionsStatusControl ------+
                 |                         check                 |
                 NO                                             YES
                 |                                               |
                 v                                               v
         OPTIONS BLOCKED                              OPTIONS ENABLED
```

### 2.2 Segmented Update Pattern

**What**: Four separate procedures each update a different subset of columns, allowing independent services to manage their domain without interfering with other fields.

**Columns/Parameters Involved**: All columns are segmented across four update procedures

**Rules**:
- SaveOptionsAppropriateness: manages AppropriatenessTestResultID, AppropriatenessProductID, AppropriatenessRecalculationReasonID, AppropriatenessTestDate
- SaveOptionsEligibility: manages EligibilityStatusID, EligibilityStatusReasonID, StocksElegibilityStatusID, CryptoElegibilityStatusID
- SaveOptionsStatus: manages OptionsStatusID, OptionsApexID, OptionsStatusControlID
- SaveOptionsReasoningStatus: manages ReasoningStatusID, ReasoningFormID
- All procedures use ISNULL(@param, existingValue) to preserve existing values when NULL is passed
- All procedures update ApplicationName to track the last modifier
- On INSERT, all procedures initialize non-owned fields to 0 (None/default)

### 2.3 Reasoning Form Workflow

**What**: When a customer wants to change their options level or re-apply after rejection, they must complete a reasoning form explaining why. The form goes through a review workflow tracked by ReasoningStatusID.

**Columns/Parameters Involved**: `ReasoningStatusID`, `ReasoningFormID`

**Rules**:
- ReasoningStatusID follows the workflow: 0=None -> 1=PendingReasoningScreen -> 2=PendingManualReview -> 3=Allowed / 4=DisallowedByManualReview
- ReasoningFormID links to Apex.OptionsReasoningForm for the specific form instance
- See [Reasoning Status](_glossary.md#reasoning-status) for full value definitions

---

## 3. Data Overview

| GCID | OptionsStatusID | EligibilityStatusID | AppropTestResult | OptionsApexID | ApplicationName | Meaning |
|------|----------------|--------------------|--------------------|---------------|-----------------|---------|
| 255 | 0 (None) | 0 (Disallowed) | 0 (None) | NULL | UsaBroker | Customer has an options record but no assessments completed yet. Default state after initial record creation by the UsaBroker service. |
| 479 | 0 (None) | 0 (Disallowed) | 0 (None) | NULL | WatchlistApi, watchlist-api | Record created by watchlist service. Multiple application names indicate multiple services touched this record. |
| 560 | 0 (None) | 0 (Disallowed) | 0 (None) | NULL | COAKVU-2520 | Record tagged with a Jira ticket reference as ApplicationName, indicating a manual/migration operation. OptionsStatusControlID=2 (Allowed) override despite no approval. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Primary key - one options record per customer. Used as the lookup key by all Options procedures. |
| 2 | AppropriatenessTestResultID | int | NO | - | VERIFIED | Result of the suitability/appropriateness assessment for options trading. FK to Dictionary.AppropriatenessTestResult: 0=None (not tested), 1=Failed (blocked), 2=Passed (approved). See [Appropriateness Test Result](_glossary.md#appropriateness-test-result). Set by SaveOptionsAppropriateness. (Dictionary.AppropriatenessTestResult) |
| 3 | AppropriatenessProductID | int | NO | - | VERIFIED | The financial product being assessed for appropriateness. FK to Dictionary.AppropriatenessProduct: 0=None, 1=CFD, 2=FPSL, 3=Options. See [Appropriateness Product](_glossary.md#appropriateness-product). Set by SaveOptionsAppropriateness. (Dictionary.AppropriatenessProduct) |
| 4 | AppropriatenessRecalculationReasonID | int | NO | - | CODE-BACKED | Reason why the appropriateness test was recalculated. Implicit FK to Dictionary.AppropriatenessRecalculationReason: 0=None, 1=BulkRecalculation, 2=RegulationChanged, 3=ReachedVerificationLevel2, 4=AnswerChanged, 5=Manual. See [Appropriateness Recalculation Reason](_glossary.md#appropriateness-recalculation-reason). Set by SaveOptionsAppropriateness. |
| 5 | EligibilityStatusID | int | NO | - | VERIFIED | Whether the customer is eligible for options trading. FK to Dictionary.EligibilityStatus: 0=Disallowed, 1=Allowed. See [Eligibility Status](_glossary.md#eligibility-status). Set by SaveOptionsEligibility. (Dictionary.EligibilityStatus) |
| 6 | EligibilityStatusReasonID | int | NO | - | CODE-BACKED | Reference to the specific reason for the eligibility determination. Observed values include 4165 and 0. Not linked to a Dictionary table - likely references an internal reason code system. Set by SaveOptionsEligibility. |
| 7 | OptionsStatusID | int | NO | - | VERIFIED | The Apex Clearing approval status for options trading. FK to Dictionary.OptionsStatus: 0=None, 1=Pending, 2=InProcess, 3=Approved, 4=Rejected. See [Options Status](_glossary.md#options-status). Only status 3 (Approved) enables options trading. Set by SaveOptionsStatus. (Dictionary.OptionsStatus) |
| 8 | OptionsApexID | nvarchar(50) | YES | - | CODE-BACKED | The Apex Clearing identifier for the options application/approval. Assigned by Apex when the options application is submitted. NULL until an application is sent to Apex. Indexed for reverse lookup by GetOptionsByOptionsApexId. Set by SaveOptionsStatus. |
| 9 | ApplicationName | nvarchar(50) | YES | - | CODE-BACKED | Name of the service/application that last modified this record. Acts as an audit trail for which system component made the most recent change. Known values: "UsaBroker", "WatchlistApi, watchlist-api", Jira ticket references for manual operations. Updated by every save procedure. |
| 10 | OptionsStatusControlID | int | NO | 0 | VERIFIED | Administrative override for options trading access. FK to Dictionary.OptionsStatusControl: 0=None (no override), 1=Blocked (admin-blocked regardless of approval), 2=Allowed (admin-allowed). See [Options Status Control](_glossary.md#options-status-control). Set by SaveOptionsStatus. (Dictionary.OptionsStatusControl) |
| 11 | BeginTime | datetime2(0) | NO | dateadd(second,(-1),sysutcdatetime()) | CODE-BACKED | System versioning row start time. Records when this version became active. Part of SYSTEM_TIME period for temporal table History.Options. |
| 12 | EndTime | datetime2(0) | NO | '9999.12.31 23:59:59.99' | CODE-BACKED | System versioning row end time. '9999-12-31' indicates current active row. Part of SYSTEM_TIME period. |
| 13 | ReasoningStatusID | int | YES | - | CODE-BACKED | Status of the options reasoning form workflow. Implicit FK to Dictionary.ReasoningStatus: 0=None, 1=PendingReasoningScreen, 2=PendingManualReview, 3=Allowed, 4=DisallowedByManualReview. See [Reasoning Status](_glossary.md#reasoning-status). NULL until reasoning workflow is initiated. Set by SaveOptionsReasoningStatus. |
| 14 | ReasoningFormID | uniqueidentifier | YES | - | CODE-BACKED | GUID linking to the specific reasoning form instance in Apex.OptionsReasoningForm. NULL until the user initiates a reasoning form submission. Set by SaveOptionsReasoningStatus. |
| 15 | AppropriatenessTestDate | datetime | YES | - | CODE-BACKED | Timestamp of when the appropriateness/suitability test was last taken or recalculated. NULL if no test has been performed. Set by SaveOptionsAppropriateness. Used for regulatory record-keeping and determining when a retest may be required. |
| 16 | StocksElegibilityStatusID | int | YES | - | CODE-BACKED | Eligibility status specifically for stock trading. Implicit FK to Dictionary.EligibilityStatus: 0=Disallowed, 1=Allowed. NULL for legacy records created before this column was added. Set by SaveOptionsEligibility. Note: column name has typo "Elegibility" instead of "Eligibility". |
| 17 | CryptoElegibilityStatusID | int | YES | - | CODE-BACKED | Eligibility status specifically for cryptocurrency trading. Implicit FK to Dictionary.EligibilityStatus: 0=Disallowed, 1=Allowed. NULL for legacy records created before this column was added. Set by SaveOptionsEligibility. Note: column name has typo "Elegibility" instead of "Eligibility". |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AppropriatenessProductID | Dictionary.AppropriatenessProduct | FK | Product being assessed for suitability |
| AppropriatenessTestResultID | Dictionary.AppropriatenessTestResult | FK | Pass/fail result of suitability assessment |
| EligibilityStatusID | Dictionary.EligibilityStatus | FK | Options eligibility determination |
| OptionsStatusID | Dictionary.OptionsStatus | FK | Apex Clearing approval status |
| OptionsStatusControlID | Dictionary.OptionsStatusControl | FK | Administrative override control |
| AppropriatenessRecalculationReasonID | Dictionary.AppropriatenessRecalculationReason | Implicit | Reason for recalculation |
| ReasoningStatusID | Dictionary.ReasoningStatus | Implicit | Reasoning form workflow status |
| StocksElegibilityStatusID | Dictionary.EligibilityStatus | Implicit | Stocks-specific eligibility |
| CryptoElegibilityStatusID | Dictionary.EligibilityStatus | Implicit | Crypto-specific eligibility |
| ReasoningFormID | Apex.OptionsReasoningForm | Implicit | Links to reasoning form instance |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.GetOptions | @GCID | Reader | Retrieves full options record for a customer |
| Apex.GetOptionsByOptionsApexId | OptionsApexID | Reader | Reverse lookup by Apex options application ID |
| Apex.SaveOptionsAppropriateness | @GCID | Writer | Upserts appropriateness test results |
| Apex.SaveOptionsEligibility | @GCID | Writer | Upserts eligibility determination |
| Apex.SaveOptionsStatus | @GCID | Writer | Upserts Apex approval status and control |
| Apex.SaveOptionsReasoningStatus | @GCID | Writer | Upserts reasoning form workflow status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.Options (table)
├── Dictionary.AppropriatenessProduct (table) [FK]
├── Dictionary.AppropriatenessTestResult (table) [FK]
├── Dictionary.EligibilityStatus (table) [FK]
├── Dictionary.OptionsStatus (table) [FK]
└── Dictionary.OptionsStatusControl (table) [FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AppropriatenessProduct | Table | FK for AppropriatenessProductID |
| Dictionary.AppropriatenessTestResult | Table | FK for AppropriatenessTestResultID |
| Dictionary.EligibilityStatus | Table | FK for EligibilityStatusID |
| Dictionary.OptionsStatus | Table | FK for OptionsStatusID |
| Dictionary.OptionsStatusControl | Table | FK for OptionsStatusControlID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.GetOptions | Stored Procedure | Reader |
| Apex.GetOptionsByOptionsApexId | Stored Procedure | Reader |
| Apex.SaveOptionsAppropriateness | Stored Procedure | Writer |
| Apex.SaveOptionsEligibility | Stored Procedure | Writer |
| Apex.SaveOptionsStatus | Stored Procedure | Writer |
| Apex.SaveOptionsReasoningStatus | Stored Procedure | Writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Options | CLUSTERED PK | GCID ASC | - | - | Active |
| ix_Options_OptionsApexID | NONCLUSTERED | OptionsApexID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Options | PRIMARY KEY | Clustered on GCID - one record per customer |
| FK_Options_AppropriatenessProduct | FOREIGN KEY | AppropriatenessProductID -> Dictionary.AppropriatenessProduct |
| FK_Options_AppropriatenessTestResult | FOREIGN KEY | AppropriatenessTestResultID -> Dictionary.AppropriatenessTestResult |
| FK_Options_EligibilityStatus | FOREIGN KEY | EligibilityStatusID -> Dictionary.EligibilityStatus |
| FK_Options_OptionsStatus | FOREIGN KEY | OptionsStatusID -> Dictionary.OptionsStatus |
| FK_Options_OptionsStatusControl | FOREIGN KEY | OptionsStatusControlID -> Dictionary.OptionsStatusControl |
| DF_Options_BeginTime | DEFAULT | BeginTime = dateadd(second,(-1),sysutcdatetime()) |
| DF_Options_EndTime | DEFAULT | EndTime = '9999.12.31 23:59:59.99' |
| (unnamed) | DEFAULT | OptionsStatusControlID = 0 |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.Options |

---

## 8. Sample Queries

### 8.1 Get a customer's full options status with resolved names

```sql
SELECT o.GCID, atr.Name AS TestResult, ap.Name AS Product,
       es.Name AS Eligibility, os.Name AS OptionsStatus,
       osc.Name AS StatusControl, o.OptionsApexID, o.ApplicationName
FROM Apex.Options o WITH (NOLOCK)
INNER JOIN Dictionary.AppropriatenessTestResult atr WITH (NOLOCK) ON atr.AppropriatenessTestResultID = o.AppropriatenessTestResultID
INNER JOIN Dictionary.AppropriatenessProduct ap WITH (NOLOCK) ON ap.AppropriatenessProductID = o.AppropriatenessProductID
INNER JOIN Dictionary.EligibilityStatus es WITH (NOLOCK) ON es.EligibilityStatusID = o.EligibilityStatusID
INNER JOIN Dictionary.OptionsStatus os WITH (NOLOCK) ON os.OptionsStatusID = o.OptionsStatusID
INNER JOIN Dictionary.OptionsStatusControl osc WITH (NOLOCK) ON osc.OptionsStatusControlID = o.OptionsStatusControlID
WHERE o.GCID = 12345;
```

### 8.2 Find customers with approved options but blocked by admin control

```sql
SELECT o.GCID, o.OptionsApexID, o.ApplicationName
FROM Apex.Options o WITH (NOLOCK)
WHERE o.OptionsStatusID = 3 -- Approved
  AND o.OptionsStatusControlID = 1; -- Blocked
```

### 8.3 Find customers pending reasoning form review

```sql
SELECT o.GCID, rs.ReasoningStatusText, o.ReasoningFormID, o.ApplicationName
FROM Apex.Options o WITH (NOLOCK)
LEFT JOIN Dictionary.ReasoningStatus rs WITH (NOLOCK) ON rs.ReasoningStatusID = o.ReasoningStatusID
WHERE o.ReasoningStatusID = 2; -- PendingManualReview
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.Options | Type: Table | Source: USABroker/Apex/Tables/Apex.Options.sql*

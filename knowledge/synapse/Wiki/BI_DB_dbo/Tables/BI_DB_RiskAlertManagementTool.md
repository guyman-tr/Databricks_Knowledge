# BI_DB_dbo.BI_DB_RiskAlertManagementTool

> 5.33M-row daily flattened extract of the Risk Alert Management system (AlertServiceDB). Each row represents one risk/compliance alert with its current status, assignee, metadata from 7 dictionary lookups, and 81 JSON-parsed contextual fields from UnsatisfiedRulesData and Resource columns. Categories include KYC (66%), Risk (25%), Cashouts (7%), and AML (2%). Active since November 2020. Refreshed daily via SP_RiskAlertManagementTool.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | AlertServiceDB (External tables) via SP_RiskAlertManagementTool |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE+INSERT by ModificationDate/FollowUpDate (upsert pattern) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table provides a **flattened, queryable view** of the eToro Risk Alert Management system for compliance and operations teams. The source is the AlertServiceDB microservice, which generates automated alerts when customer behavior triggers risk rules (e.g., high-risk logins, name conflicts on deposits, suspicious withdrawal patterns, Sift fraud scores).

Each row represents a single **alert instance** at its most recent state. The table is an upsert: when an alert is modified or its follow-up date matches the run date, the old row is replaced with the current state.

**Three column groups**:
1. **Core alert metadata** (cols 1-21): Alert ID, CID, assignee, status, category, type, timestamps, ticket references
2. **UnsatisfiedRulesData / EvaluationContext** (cols 22-65): 44 fields extracted from the `UnsatisfiedRulesData` JSON column at path `$.EvaluationContext`. These describe WHY the alert fired (e.g., Sift fraud score, name conflict score, deposit threshold breached).
3. **Resource** (cols 66-105): 37 fields extracted from the `Resource` JSON column. These describe the TRIGGERING RESOURCE (e.g., crypto wallet address, card GUID, MOP details, deposit ID). Many have "1" suffix because they share names with EvaluationContext fields.

**Key alert types** (from live data):
- HighRiskLogin (61%): Unusual login patterns
- PossibleCompromisedAccount: Suspected account takeover
- DepositNameConflict: Name on deposit MOP doesn't match account
- HighCORedeem: Large cashout with low trading ratio
- SiftScore: Sift ML fraud score exceeds threshold
- MultipleAccounts: Same identity across multiple CIDs

---

## 2. Business Logic

### 2.1 Alert Lifecycle

**What**: Alerts progress through status states.
**Columns Involved**: StatusType, StatusReason, Alert Status Reason
**Rules**:
- Active (62%): Alert open and pending review
- Clear (38%): Alert resolved — either "No action needed" or investigated and closed
- Follow Up (<1%): Alert needs future follow-up (FollowUpDate set)

### 2.2 Deduplication Logic

**What**: Ensures only the latest state of each alert is kept.
**Columns Involved**: RN, RN1
**Rules**:
- RN = ROW_NUMBER() PARTITION BY AlertID ORDER BY ModificationDate DESC (within #current temp table)
- RN1 = ROW_NUMBER() PARTITION BY AlertID ORDER BY ModificationDate DESC (in final assembly after JSON join)
- Only RN=1 rows survive in #current (latest modification per alert)
- Both RN values are stored for debugging/audit purposes

### 2.3 JSON Flattening Pattern

**What**: Two JSON columns are parsed into 81 flat columns.
**Columns Involved**: Cols 22-105
**Rules**:
- OPENJSON with explicit WITH schema on UnsatisfiedRulesData (path: $.EvaluationContext) → 44 columns
- OPENJSON with explicit WITH schema on Resource (root level) → 37 columns
- Only rows with ISJSON()=1 are parsed (malformed JSON is excluded)
- LEFT JOIN from #current → columns are NULL when JSON doesn't contain the field
- Duplicate-named fields get "1" suffix (e.g., MeansOfPayments from EvalContext, MeansOfPayments1 from Resource)

### 2.4 Upsert Pattern

**What**: Daily refresh replaces existing alerts with their latest state.
**Columns Involved**: AlertID, ModificationDate, FollowUpDate
**Rules**:
- DELETE WHERE ModificationDate on @Date OR FollowUpDate on @Date (clears previous day's version)
- DELETE WHERE AlertID IN (today's batch) — ensures full replacement
- INSERT today's alerts with all flattened fields

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no distribution key optimization. Table is large (5.33M rows) but queries typically filter on AlertType, CategoryName, or CID. Consider adding NCI on CID for customer-level lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Active alerts by category | `WHERE StatusType = 'Active' GROUP BY CategoryName` |
| Customer's alert history | `WHERE CID = @cid ORDER BY CreationDate DESC` |
| High-risk login volume trend | `WHERE AlertType = 'HighRiskLogin' GROUP BY CAST(CreationDate AS DATE)` |
| Alerts with Sift score context | `WHERE SiftScore IS NOT NULL AND AlertType = 'SiftScore'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer demographics and KYC status |
| BI_DB_dbo.BI_DB_CIDFirstDates | CID = CID | Customer country, region, registration date |

### 3.4 Gotchas

- **Column name with space**: `[Alert Status Reason]` — must be quoted in SQL
- **All JSON-extracted columns are nvarchar(255)**: Numeric values (SiftScore, FtdAmount, Threshold) stored as strings — CAST before arithmetic
- **"1" suffix columns**: These are NOT version numbers — they represent the same logical field from a DIFFERENT JSON source (Resource vs EvaluationContext)
- **NULL JSON fields**: Most JSON fields are NULL for any given alert — each AlertType populates only its relevant subset
- **Tables column**: Always 'Current' — hardcoded literal, no historical distinction (legacy from when Historical table also existed)
- **RN/RN1**: Always 1 in final output (deduplication artifacts) — can be ignored for analysis
- **CurrenctISON**: Typo in column name (should be CurrencyISON)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 2 | Derived from SP code analysis | SP source code |
| Tier 4 | Low confidence — JSON field inferred from name only | JSON path name |
| Tier 5 | ETL infrastructure / metadata | System convention |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AlertID | int | YES | Unique alert identifier from AlertServiceDB.Alert_Alert.Id. Primary key (not enforced in Synapse). (Tier 2 — SP_RiskAlertManagementTool) |
| 2 | CID | int | YES | Customer ID associated with the alert. References Dim_Customer.RealCID. (Tier 2 — SP_RiskAlertManagementTool) |
| 3 | Assignee | bigint | YES | ID of the compliance officer assigned to investigate this alert. From Alert_Alert.Assignee. (Tier 2 — SP_RiskAlertManagementTool) |
| 4 | ModifiedBy | int | YES | ID of the user who last modified this alert's status or assignment. (Tier 2 — SP_RiskAlertManagementTool) |
| 5 | Comment | varchar(max) | YES | Free-text comment added by the assignee during investigation. May contain investigation notes, escalation reasons, or resolution details. (Tier 2 — SP_RiskAlertManagementTool) |
| 6 | CreationDate | datetime | YES | UTC timestamp when the alert was first created by the risk engine. (Tier 2 — SP_RiskAlertManagementTool) |
| 7 | ModificationDate | datetime | YES | UTC timestamp of the most recent status change or update. Used as the partition key for daily DELETE+INSERT. (Tier 2 — SP_RiskAlertManagementTool) |
| 8 | TicketID | nvarchar(4000) | YES | External ticket reference (e.g., Jira/Zendesk ticket) linked to this alert for tracking. (Tier 2 — SP_RiskAlertManagementTool) |
| 9 | FundingID | bigint | YES | Funding transaction ID that triggered this alert (for deposit/withdrawal-related alerts). NULL for non-funding alerts. (Tier 2 — SP_RiskAlertManagementTool) |
| 10 | ResourceType | bigint | YES | Type identifier for the resource that triggered the alert (deposit, withdrawal, login, etc.). (Tier 2 — SP_RiskAlertManagementTool) |
| 11 | FollowUpDate | datetime | YES | Scheduled date for follow-up action. Used in daily load filter (alerts are refreshed when FollowUpDate matches run date). (Tier 2 — SP_RiskAlertManagementTool) |
| 12 | AlertType | varchar(max) | YES | Alert type name. Values: HighRiskLogin, PossibleCompromisedAccount, DepositNameConflict, HighCORedeem, SiftScore, WithdrawWithLowTradingRatio, DividendCheckRequired, MultipleAccounts, KycRelations, BinToRegCountryConflict. From Dictionary_AlertType.Name. (Tier 2 — SP_RiskAlertManagementTool) |
| 13 | AlertTypeDescription | varchar(max) | YES | Human-readable description of the alert type. From Dictionary_AlertType.Description. (Tier 2 — SP_RiskAlertManagementTool) |
| 14 | CategoryName | varchar(max) | YES | Alert category. 8 values: KYC, Risk, Cashouts, AML, eToroMoney, Deposits, Tax, Trading. From Dictionary_Category.Name. (Tier 2 — SP_RiskAlertManagementTool) |
| 15 | TriggerType | varchar(max) | YES | How the alert was triggered. 3 values: OneTime, Recurring, None. From Dictionary_TriggerType.Name. (Tier 2 — SP_RiskAlertManagementTool) |
| 16 | StatusType | varchar(max) | YES | Current alert lifecycle status. 3 values: Active, Clear, Follow Up. From Dictionary_StatusType.Name. (Tier 2 — SP_RiskAlertManagementTool) |
| 17 | StatusReason | varchar(max) | YES | Reason for the current status (e.g., "No action needed", "Follow up due"). From Dictionary_StatusReason.Name. (Tier 2 — SP_RiskAlertManagementTool) |
| 18 | Alert Status Reason | varchar(max) | YES | Classification-level reason for the alert status. From Dictionary_StatusClassification.Name via ReasonToClassification mapping. Column name has a space. (Tier 2 — SP_RiskAlertManagementTool) |
| 19 | Tables | varchar(max) | YES | Always 'Current'. Hardcoded literal indicating this is the current state (legacy from when Historical alerts were also loaded). (Tier 2 — SP_RiskAlertManagementTool) |
| 20 | RN | int | YES | ROW_NUMBER() PARTITION BY AlertID ORDER BY ModificationDate DESC in #current. Always 1 in output (deduplication artifact). (Tier 2 — SP_RiskAlertManagementTool) |
| 21 | RN1 | int | YES | ROW_NUMBER() PARTITION BY AlertID ORDER BY ModificationDate DESC in final assembly. Always 1 in output (deduplication artifact). (Tier 2 — SP_RiskAlertManagementTool) |
| 22 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by the pipeline (GETDATE()). (Tier 5 — ETL metadata) |
| 23 | AllowedTelesignScore | nvarchar(255) | YES | EvalContext JSON: Telesign score threshold that triggered the alert. (Tier 4 — JSON $.EvaluationContext.AllowedTelesignScore) |
| 24 | AmopCustomerName | nvarchar(255) | YES | EvalContext JSON: Customer name from approved MOP (means of payment) registration. (Tier 4 — JSON $.EvaluationContext.AmopCustomerName) |
| 25 | ChangeDate | nvarchar(255) | YES | EvalContext JSON: Date of the change that triggered the alert (stored as string). (Tier 4 — JSON $.EvaluationContext.ChangeDate) |
| 26 | ChangeType | nvarchar(255) | YES | EvalContext JSON: Type of change that triggered the alert (e.g., KYC change, address change). (Tier 4 — JSON $.EvaluationContext.ChangeType) |
| 27 | DaysPeriod | nvarchar(255) | YES | EvalContext JSON: Time window in days used for the alert rule evaluation. (Tier 4 — JSON $.EvaluationContext.DaysPeriod) |
| 28 | DepositCustomerName | nvarchar(255) | YES | EvalContext JSON: Customer name on the deposit transaction (for name conflict alerts). (Tier 4 — JSON $.EvaluationContext.DepositCustomerName) |
| 29 | DepositId | nvarchar(255) | YES | EvalContext JSON: Deposit transaction ID that triggered the alert. (Tier 4 — JSON $.EvaluationContext.DepositId) |
| 30 | DeviceId | nvarchar(255) | YES | EvalContext JSON: Device identifier associated with the triggering event. (Tier 4 — JSON $.EvaluationContext.DeviceId) |
| 31 | EventType | nvarchar(255) | YES | EvalContext JSON: Type of event that triggered the rule evaluation. (Tier 4 — JSON $.EvaluationContext.EventType) |
| 32 | ForceTriggerAlert | nvarchar(255) | YES | EvalContext JSON: Whether the alert was force-triggered (bypassing normal thresholds). (Tier 4 — JSON $.EvaluationContext.ForceTriggerAlert) |
| 33 | ForceTriggerAlertReason | nvarchar(255) | YES | EvalContext JSON: Reason for force-triggering the alert. (Tier 4 — JSON $.EvaluationContext.ForceTriggerAlertReason) |
| 34 | FtdAmount | nvarchar(255) | YES | EvalContext JSON: First-time deposit amount (stored as string). Relevant for deposit threshold alerts. (Tier 4 — JSON $.EvaluationContext.FtdAmount) |
| 35 | FtdDate | nvarchar(255) | YES | EvalContext JSON: First-time deposit date (stored as string). (Tier 4 — JSON $.EvaluationContext.FtdDate) |
| 36 | FundingId | nvarchar(255) | YES | EvalContext JSON: Funding transaction ID in the evaluation context. (Tier 4 — JSON $.EvaluationContext.FundingId) |
| 37 | FundingTypeId | nvarchar(255) | YES | EvalContext JSON: Funding type identifier (payment method type). (Tier 4 — JSON $.EvaluationContext.FundingTypeId) |
| 38 | KYCLevel | nvarchar(255) | YES | EvalContext JSON: Customer's KYC verification level at alert time. (Tier 4 — JSON $.EvaluationContext.KYCLevel) |
| 39 | KycCountryId | nvarchar(255) | YES | EvalContext JSON: Country ID from KYC verification. (Tier 4 — JSON $.EvaluationContext.KycCountryId) |
| 40 | KycCustomerName | nvarchar(255) | YES | EvalContext JSON: Customer name from KYC documents. (Tier 4 — JSON $.EvaluationContext.KycCustomerName) |
| 41 | KycQuestionId | nvarchar(255) | YES | EvalContext JSON: KYC questionnaire question ID that triggered the alert. (Tier 4 — JSON $.EvaluationContext.KycQuestionId) |
| 42 | KycYear | nvarchar(255) | YES | EvalContext JSON: Year of KYC review. (Tier 4 — JSON $.EvaluationContext.KycYear) |
| 43 | MOPsWithMinimumTransactions | nvarchar(255) | YES | EvalContext JSON: Number of means-of-payment with minimum transaction count. (Tier 4 — JSON $.EvaluationContext.MOPsWithMinimumTransactions) |
| 44 | MeansOfPayments | nvarchar(255) | YES | EvalContext JSON: Means of payment details in the evaluation context. (Tier 4 — JSON $.EvaluationContext.MeansOfPayments) |
| 45 | MopBankCountryCode | nvarchar(255) | YES | EvalContext JSON: Country code of the bank associated with the MOP. (Tier 4 — JSON $.EvaluationContext.MopBankCountryCode) |
| 46 | MopCountryCode | nvarchar(255) | YES | EvalContext JSON: Country code of the MOP issuer. (Tier 4 — JSON $.EvaluationContext.MopCountryCode) |
| 47 | NameConflictDescription | nvarchar(255) | YES | EvalContext JSON: Description of the name mismatch detected between account and deposit source. (Tier 4 — JSON $.EvaluationContext.NameConflictDescription) |
| 48 | NameConflictScore | nvarchar(255) | YES | EvalContext JSON: Numeric score indicating severity of the name conflict (stored as string). (Tier 4 — JSON $.EvaluationContext.NameConflictScore) |
| 49 | NextDepositMilestone | nvarchar(255) | YES | EvalContext JSON: Next deposit amount milestone for threshold-based alerts. (Tier 4 — JSON $.EvaluationContext.NextDepositMilestone) |
| 50 | NextThreshold | nvarchar(255) | YES | EvalContext JSON: Next threshold value that would trigger escalation. (Tier 4 — JSON $.EvaluationContext.NextThreshold) |
| 51 | NumberOfMOPsWithinTimeFrame | nvarchar(255) | YES | EvalContext JSON: Count of distinct MOPs used within the evaluation time frame. (Tier 4 — JSON $.EvaluationContext.NumberOfMOPsWithinTimeFrame) |
| 52 | PhoneVerifiedHistoryItemCount | nvarchar(255) | YES | EvalContext JSON: Number of phone verification history items. (Tier 4 — JSON $.EvaluationContext.PhoneVerifiedHistoryItemCount) |
| 53 | PhoneVerifiedHistorySearchFrom | nvarchar(255) | YES | EvalContext JSON: Start date for phone verification history search. (Tier 4 — JSON $.EvaluationContext.PhoneVerifiedHistorySearchFrom) |
| 54 | RegulationId | nvarchar(255) | YES | EvalContext JSON: Regulation ID of the customer at alert time. (Tier 4 — JSON $.EvaluationContext.RegulationId) |
| 55 | RelatedCids | nvarchar(255) | YES | EvalContext JSON: Related customer IDs identified by the rule (e.g., multiple accounts). (Tier 4 — JSON $.EvaluationContext.RelatedCids) |
| 56 | RiskClassification | nvarchar(255) | YES | EvalContext JSON: Customer's risk classification level at alert time. (Tier 4 — JSON $.EvaluationContext.RiskClassification) |
| 57 | RuleType | nvarchar(255) | YES | EvalContext JSON: Type of risk rule that was evaluated. (Tier 4 — JSON $.EvaluationContext.RuleType) |
| 58 | SiftScore | nvarchar(255) | YES | EvalContext JSON: Sift Science ML fraud score (stored as string). Higher = more suspicious. (Tier 4 — JSON $.EvaluationContext.SiftScore) |
| 59 | SubReason | nvarchar(255) | YES | EvalContext JSON: Sub-reason for the alert trigger (additional detail beyond StatusReason). (Tier 4 — JSON $.EvaluationContext.SubReason) |
| 60 | TelesignScore | nvarchar(255) | YES | EvalContext JSON: Telesign phone verification risk score (stored as string). (Tier 4 — JSON $.EvaluationContext.TelesignScore) |
| 61 | Threshold | nvarchar(255) | YES | EvalContext JSON: Threshold value that was breached to trigger the alert. (Tier 4 — JSON $.EvaluationContext.Threshold) |
| 62 | TimeFrameInDays | nvarchar(255) | YES | EvalContext JSON: Time frame in days for the rule evaluation window. (Tier 4 — JSON $.EvaluationContext.TimeFrameInDays) |
| 63 | TotalCidsCount | nvarchar(255) | YES | EvalContext JSON: Total count of related CIDs identified by the rule. (Tier 4 — JSON $.EvaluationContext.TotalCidsCount) |
| 64 | TotalDeposit | nvarchar(255) | YES | EvalContext JSON: Total deposit amount in the evaluation window. (Tier 4 — JSON $.EvaluationContext.TotalDeposit) |
| 65 | UsCountryId | nvarchar(255) | YES | EvalContext JSON: US country identifier (for US-specific regulatory alerts). (Tier 4 — JSON $.EvaluationContext.UsCountryId) |
| 66 | YearlySum | nvarchar(255) | YES | EvalContext JSON: Yearly cumulative sum relevant to the alert threshold. (Tier 4 — JSON $.EvaluationContext.YearlySum) |
| 67 | AccountGuid | nvarchar(255) | YES | Resource JSON: GUID of the account/MOP resource that triggered the alert. (Tier 4 — JSON $.Resource.AccountGuid) |
| 68 | MeansOfPayments1 | nvarchar(255) | YES | Resource JSON: Means of payment details from the triggering resource. "1" suffix distinguishes from EvalContext.MeansOfPayments. (Tier 4 — JSON $.Resource.MeansOfPayments) |
| 69 | ForceTriggerAlert1 | nvarchar(255) | YES | Resource JSON: Force trigger flag from the resource context. "1" suffix distinguishes from EvalContext.ForceTriggerAlert. (Tier 4 — JSON $.Resource.ForceTriggerAlert) |
| 70 | CurrenctISON | nvarchar(255) | YES | Resource JSON: Currency ISO name/code (note: column name typo — "Currenct" instead of "Currency"). (Tier 4 — JSON $.Resource.CurrenctISON) |
| 71 | DaysPeriod1 | nvarchar(255) | YES | Resource JSON: Days period from the resource context. "1" suffix distinguishes from EvalContext.DaysPeriod. (Tier 4 — JSON $.Resource.DaysPeriod) |
| 72 | CardGuid | nvarchar(255) | YES | Resource JSON: GUID of the card/MOP used in the triggering transaction. (Tier 4 — JSON $.Resource.CardGuid) |
| 73 | RelatedCids1 | nvarchar(255) | YES | Resource JSON: Related CIDs from the resource context. "1" suffix distinguishes from EvalContext.RelatedCids. (Tier 4 — JSON $.Resource.RelatedCids) |
| 74 | CustomerName | nvarchar(255) | YES | Resource JSON: Customer name associated with the triggering resource. (Tier 4 — JSON $.Resource.CustomerName) |
| 75 | DepositId1 | nvarchar(255) | YES | Resource JSON: Deposit ID from the resource context. "1" suffix distinguishes from EvalContext.DepositId. (Tier 4 — JSON $.Resource.DepositId) |
| 76 | ChangeDate1 | nvarchar(255) | YES | Resource JSON: Change date from the resource context. "1" suffix distinguishes from EvalContext.ChangeDate. (Tier 4 — JSON $.Resource.ChangeDate) |
| 77 | FundingId1 | nvarchar(255) | YES | Resource JSON: Funding ID from the resource context. "1" suffix distinguishes from EvalContext.FundingId. (Tier 4 — JSON $.Resource.FundingId) |
| 78 | ChangeType1 | nvarchar(255) | YES | Resource JSON: Change type from the resource context. "1" suffix distinguishes from EvalContext.ChangeType. (Tier 4 — JSON $.Resource.ChangeType) |
| 79 | ForceTriggerAlertReason1 | nvarchar(255) | YES | Resource JSON: Force trigger reason from the resource context. "1" suffix distinguishes from EvalContext.ForceTriggerAlertReason. (Tier 4 — JSON $.Resource.ForceTriggerAlertReason) |
| 80 | FundingTypeId1 | nvarchar(255) | YES | Resource JSON: Funding type ID from the resource context. "1" suffix distinguishes from EvalContext.FundingTypeId. (Tier 4 — JSON $.Resource.FundingTypeId) |
| 81 | ChangedBy | nvarchar(255) | YES | Resource JSON: User/system that made the change in the triggering resource. (Tier 4 — JSON $.Resource.ChangedBy) |
| 82 | Gcid | nvarchar(255) | YES | Resource JSON: Global Customer ID (cross-platform identifier). (Tier 4 — JSON $.Resource.Gcid) |
| 83 | CorrelationId | nvarchar(255) | YES | Resource JSON: Correlation ID for distributed tracing of the triggering event. (Tier 4 — JSON $.Resource.CorrelationId) |
| 84 | NumberOfMOPsWithinTimeFrame1 | nvarchar(255) | YES | Resource JSON: MOP count from the resource context. "1" suffix distinguishes from EvalContext. (Tier 4 — JSON $.Resource.NumberOfMOPsWithinTimeFrame) |
| 85 | Created | nvarchar(255) | YES | Resource JSON: Creation timestamp of the triggering resource (stored as string). (Tier 4 — JSON $.Resource.Created) |
| 86 | Identifier | nvarchar(255) | YES | Resource JSON: Generic identifier for the triggering resource. (Tier 4 — JSON $.Resource.Identifier) |
| 87 | Status | nvarchar(255) | YES | Resource JSON: Status of the triggering resource at alert time. (Tier 4 — JSON $.Resource.Status) |
| 88 | CryptoReceiverAddress | nvarchar(255) | YES | Resource JSON: Cryptocurrency receiver wallet address (for crypto-related alerts). (Tier 4 — JSON $.Resource.CryptoReceiverAddress) |
| 89 | Name1 | nvarchar(255) | YES | Resource JSON: Name field from the resource. "1" suffix for disambiguation. (Tier 4 — JSON $.Resource.Name) |
| 90 | StatusChangeReason1 | nvarchar(255) | YES | Resource JSON: Reason for the resource's status change. "1" suffix for disambiguation. (Tier 4 — JSON $.Resource.StatusChangeReason) |
| 91 | CryptoSenderAddress | nvarchar(255) | YES | Resource JSON: Cryptocurrency sender wallet address (for crypto-related alerts). (Tier 4 — JSON $.Resource.CryptoSenderAddress) |
| 92 | ProviderHolderId | nvarchar(255) | YES | Resource JSON: External payment provider's holder/account ID. (Tier 4 — JSON $.Resource.ProviderHolderId) |
| 93 | TotalDeposit1 | nvarchar(255) | YES | Resource JSON: Total deposit from the resource context. "1" suffix distinguishes from EvalContext.TotalDeposit. (Tier 4 — JSON $.Resource.TotalDeposit) |
| 94 | CryptoWalletstatus | nvarchar(255) | YES | Resource JSON: Status of the crypto wallet involved (e.g., verified, unverified). (Tier 4 — JSON $.Resource.CryptoWalletstatus) |
| 95 | StatusName1 | nvarchar(255) | YES | Resource JSON: Status name from the resource. "1" suffix for disambiguation. (Tier 4 — JSON $.Resource.StatusName) |
| 96 | Type | nvarchar(255) | YES | Resource JSON: Type classification of the triggering resource. (Tier 4 — JSON $.Resource.Type) |
| 97 | SubReason1 | nvarchar(255) | YES | Resource JSON: Sub-reason from the resource context. "1" suffix distinguishes from EvalContext.SubReason. (Tier 4 — JSON $.Resource.SubReason) |
| 98 | WhenExpression1 | nvarchar(255) | YES | Resource JSON: Rule expression/condition that was evaluated. (Tier 4 — JSON $.Resource.WhenExpression) |
| 99 | DeviceId1 | nvarchar(255) | YES | Resource JSON: Device ID from the resource context. "1" suffix distinguishes from EvalContext.DeviceId. (Tier 4 — JSON $.Resource.DeviceId) |
| 100 | FtdDate1 | nvarchar(255) | YES | Resource JSON: FTD date from the resource context. "1" suffix distinguishes from EvalContext.FtdDate. (Tier 4 — JSON $.Resource.FtdDate) |
| 101 | LastDigits | nvarchar(255) | YES | Resource JSON: Last digits of the card/MOP number (masked PCI-compliant reference). (Tier 4 — JSON $.Resource.LastDigits) |
| 102 | NameOnMop1 | nvarchar(255) | YES | Resource JSON: Name on the means of payment (for name conflict detection). (Tier 4 — JSON $.Resource.NameOnMop) |
| 103 | RiskClassification1 | nvarchar(255) | YES | Resource JSON: Risk classification from the resource context. "1" suffix distinguishes from EvalContext.RiskClassification. (Tier 4 — JSON $.Resource.RiskClassification) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-----------------|---------------|-----------|
| AlertID–FollowUpDate (core) | External_AlertServiceDB_Alert_Alert | Various | Direct passthrough + dim lookups |
| AlertType–Alert Status Reason | AlertServiceDB Dictionary tables | Name | Dim-lookup via Configuration tables |
| Cols 23-66 (EvalContext) | External_AlertServiceDB_Alert_Alert | UnsatisfiedRulesData | OPENJSON($.EvaluationContext) |
| Cols 67-103 (Resource) | External_AlertServiceDB_Alert_Alert | Resource | OPENJSON($) |

### 5.2 ETL Pipeline

```
AlertServiceDB (production microservice)
  |-- Generic Pipeline (External tables) ---|
  v
BI_DB_dbo.External_AlertServiceDB_Alert_Alert (core + JSON)
  + External_AlertServiceDB_Configuration_AlertTemplate
  + External_AlertServiceDB_Dictionary_AlertType/Category/TriggerType/StatusType/StatusReason/StatusClassification
  + External_AlertServiceDB_Configuration_AlertStatus/ReasonToClassification
    |-- SP_RiskAlertManagementTool @Date (Daily, Priority 0)
    |-- OPENJSON(UnsatisfiedRulesData, '$.EvaluationContext') → 44 cols
    |-- OPENJSON(Resource) → 37 cols
    |-- ROW_NUMBER deduplication + DELETE/INSERT upsert
    v
BI_DB_dbo.BI_DB_RiskAlertManagementTool (5.33M rows, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension lookup |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers in SSDT.

---

## 7. Sample Queries

### 7.1 Active Alerts by Category and Type

```sql
SELECT
    CategoryName,
    AlertType,
    COUNT(*) AS ActiveAlerts,
    COUNT(DISTINCT CID) AS AffectedCustomers
FROM [BI_DB_dbo].[BI_DB_RiskAlertManagementTool]
WHERE StatusType = 'Active'
GROUP BY CategoryName, AlertType
ORDER BY ActiveAlerts DESC
```

### 7.2 Name Conflict Alerts with Score Detail

```sql
SELECT
    AlertID, CID, CreationDate,
    NameConflictDescription,
    CAST(NameConflictScore AS FLOAT) AS ConflictScore,
    DepositCustomerName,
    KycCustomerName
FROM [BI_DB_dbo].[BI_DB_RiskAlertManagementTool]
WHERE AlertType = 'DepositNameConflict'
  AND NameConflictScore IS NOT NULL
ORDER BY CAST(NameConflictScore AS FLOAT) DESC
```

### 7.3 Crypto-Related Alerts

```sql
SELECT
    AlertID, CID, AlertType, StatusType,
    CryptoReceiverAddress,
    CryptoSenderAddress,
    CryptoWalletstatus
FROM [BI_DB_dbo].[BI_DB_RiskAlertManagementTool]
WHERE CryptoReceiverAddress IS NOT NULL
   OR CryptoSenderAddress IS NOT NULL
ORDER BY CreationDate DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table. The AlertServiceDB is a standalone compliance microservice.

---

*Generated: 2026-04-26 | Quality: 7.5/10 | Phases: 14/14*
*Tiers: 0 T1, 21 T2, 0 T3, 81 T4, 1 T5 | Elements: 103/105, Logic: 7/10, Completeness: 8/10*
*Object: BI_DB_dbo.BI_DB_RiskAlertManagementTool | Type: Table | Production Source: AlertServiceDB via SP_RiskAlertManagementTool*

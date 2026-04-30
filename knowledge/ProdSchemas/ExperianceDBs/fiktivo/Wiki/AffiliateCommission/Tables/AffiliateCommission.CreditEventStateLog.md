# AffiliateCommission.CreditEventStateLog

> Audit/diagnostic log table recording the processing state transitions of credit events through the commission pipeline, including error details and full event context for troubleshooting.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | No PK defined (heap with clustered index implied by data) |
| **Partition** | No |
| **Indexes** | None defined |

---

## 1. Business Meaning

CreditEventStateLog is an audit and diagnostic log table that records every state transition a credit event passes through during commission processing. Each row captures a specific processing step - success, failure, retry, or diagnostic information - along with the full credit event context at that moment. This provides a complete forensic trail for investigating commission processing issues.

This table exists because the credit commission pipeline is complex and asynchronous, with multiple processing steps (event creation, organic check, re-attribution, commission calculation, error handling). When something goes wrong (e.g., "Procedure or function InsertCredit has too many arguments specified"), the state log captures the full context of the failure, enabling developers to diagnose and fix issues without needing to reproduce the exact conditions.

The table has 14.3 million rows, making it one of the largest tables in the schema. It has explicit FKs to Dictionary.EventState (state classification) and Dictionary.ServiceType (which service performed the action). Many columns are nullable because diagnostic/info-only log entries (like "read 0 messages") don't need the full credit context.

---

## 2. Business Logic

### 2.1 State Transition Logging

**What**: Every processing step generates a log entry with state classification and optional error details.

**Columns/Parameters Involved**: `EventStateID`, `ServiceTypeID`, `AdditionalData`, `DateAdded`

**Rules**:
- EventStateID classifies the state (FK to Dictionary.EventState): processing states, error states, info states
- ServiceTypeID identifies which service wrote the log (FK to Dictionary.ServiceType)
- AdditionalData captures error messages, diagnostic info, or processing notes (e.g., "read 0 messages from CreditEvent")
- CreditID can be NULL for system-level entries that don't relate to a specific credit
- Full credit context (Amount, CID, AffiliateID, etc.) is captured at log time for forensic analysis

### 2.2 Error Diagnosis Pattern

**What**: Failed processing steps capture the exact error and full event state.

**Columns/Parameters Involved**: `EventStateID`, `AdditionalData`, all credit context columns

**Rules**:
- Error entries include the exception message in AdditionalData
- The same CreditID may appear with multiple EventStateIDs showing the sequence: attempt -> error -> retry -> success
- Credit context columns capture the state AT THE TIME of the event, not the current state

---

## 3. Data Overview

| CreditID | EventStateID | DateAdded | AdditionalData | Meaning |
|---|---|---|---|---|
| NULL | 34 | 2024-01-21 13:48 | "read 0 messages from CreditEvent on source: AzureWestEurope" | System-level info entry. No credit involved. Reports that a polling cycle found no new messages. |
| 2156778390 | 19 | 2024-01-21 13:48 | "Procedure or function InsertCredit has too many arguments specified." | Error state for credit 2156778390. InsertCredit call failed due to parameter mismatch - likely during a schema migration. |
| 2156778390 | 16 | 2024-01-21 13:48 | NULL | Processing state for the same credit, logged milliseconds before the error. Amount was 20000. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | YES | - | CODE-BACKED | Credit event being logged. NULL for system-level entries not tied to a specific credit. |
| 2 | EventStateID | int | NO | - | VERIFIED | State classification. FK to Dictionary.EventState. Identifies what processing step or error occurred. See [Event State](../_glossary.md#event-state). |
| 3 | DateAdded | datetime | NO | - | CODE-BACKED | Timestamp when this log entry was created. Primary time dimension for log analysis. |
| 4 | AdditionalData | nvarchar(max) | YES | - | CODE-BACKED | Free-text diagnostic data. Error messages, processing notes, or status information. NULL when no additional context is needed. |
| 5 | ServiceTypeID | int | NO | - | VERIFIED | Service that wrote this log entry. FK to Dictionary.ServiceType. Identifies which component of the pipeline produced this state. |
| 6 | CreditDate | datetime | YES | - | CODE-BACKED | Credit event timestamp at log time. NULL for non-credit entries. |
| 7 | AffiliateID | int | YES | - | CODE-BACKED | Affiliate attribution at log time. |
| 8 | AffiliateCampaign | nvarchar(1024) | YES | - | CODE-BACKED | Campaign tracking at log time. |
| 9 | Amount | float | YES | - | CODE-BACKED | Credit amount at log time. May differ between log entries for the same CreditID if the amount was adjusted. |
| 10 | IsFirstDeposit | bit | YES | - | CODE-BACKED | FTD status at log time. |
| 11 | Type | tinyint | YES | - | CODE-BACKED | CreditTypeID at log time. 1=Deposit, 4/5=Chargeback. |
| 12 | DownloadID | bigint | YES | - | CODE-BACKED | Download tracking at log time. |
| 13 | BannerID | int | YES | - | CODE-BACKED | Banner reference at log time. |
| 14 | CountryID | bigint | YES | - | CODE-BACKED | Customer country at log time. |
| 15 | ProviderID | bigint | YES | - | CODE-BACKED | Provider at log time. |
| 16 | RealProviderID | bigint | YES | - | CODE-BACKED | Execution entity at log time. |
| 17 | OriginalProviderID | bigint | YES | - | CODE-BACKED | Original provider at log time. |
| 18 | FunnelID | int | YES | - | CODE-BACKED | Funnel tracking at log time. |
| 19 | LabelID | int | YES | - | CODE-BACKED | Label classification at log time. |
| 20 | PlayerLevelID | int | YES | - | CODE-BACKED | Player level at log time. |
| 21 | CID | bigint | YES | - | CODE-BACKED | Customer ID at log time. |
| 22 | OriginalCID | bigint | YES | - | CODE-BACKED | Original customer at log time. |
| 23 | Source | nvarchar(50) | YES | - | CODE-BACKED | Processing node at log time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EventStateID | Dictionary.EventState | FK (explicit) | State classification |
| ServiceTypeID | Dictionary.ServiceType | FK (explicit) | Service identification |
| CreditID | AffiliateCommission.Credit | Implicit | Credit being logged |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.InsertCreditEventStateLog | INSERT | Writer | Creates log entries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.CreditEventStateLog (table)
├── Dictionary.EventState (table) [FK]
└── Dictionary.ServiceType (table) [FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.EventState | Table | FK on EventStateID |
| Dictionary.ServiceType | Table | FK on ServiceTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.InsertCreditEventStateLog | Stored Procedure | Writer |

---

## 7. Technical Details

### 7.1 Indexes

None defined. Heap table. With 14.3M rows, this may cause performance issues for diagnostic queries. PAGE compression is applied.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_AffiliateCommission_CreditEventStateLog_EventStateID | FOREIGN KEY | EventStateID -> Dictionary.EventState |
| FK_AffiliateCommission_CreditEventStateLog_ServiceTypeID | FOREIGN KEY | ServiceTypeID -> Dictionary.ServiceType |

---

## 8. Sample Queries

### 8.1 Recent errors for a credit
```sql
SELECT CreditID, EventStateID, DateAdded, AdditionalData, ServiceTypeID
FROM AffiliateCommission.CreditEventStateLog WITH (NOLOCK)
WHERE CreditID = 2156778390
ORDER BY DateAdded DESC;
```

### 8.2 Error entries with state names
```sql
SELECT TOP 20 l.CreditID, l.EventStateID, es.Description AS StateName,
       l.DateAdded, l.AdditionalData, l.Source
FROM AffiliateCommission.CreditEventStateLog l WITH (NOLOCK)
JOIN Dictionary.EventState es WITH (NOLOCK) ON l.EventStateID = es.EventStateID
WHERE l.AdditionalData IS NOT NULL AND l.AdditionalData LIKE '%error%'
ORDER BY l.DateAdded DESC;
```

### 8.3 System-level info entries
```sql
SELECT TOP 20 EventStateID, DateAdded, AdditionalData, ServiceTypeID
FROM AffiliateCommission.CreditEventStateLog WITH (NOLOCK)
WHERE CreditID IS NULL
ORDER BY DateAdded DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 9.6/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CreditEventStateLog | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.CreditEventStateLog.sql*

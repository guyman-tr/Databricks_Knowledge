# Dictionary.PlayerStatusSubReasons

> Lookup table defining the 83 granular sub-reasons for account status changes — providing detailed classification under each parent reason for compliance investigations, chargebacks, verification failures, and screening results.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PlayerStatusSubReasonID (INT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Row Count** | 83 (MCP verified) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.PlayerStatusSubReasons provides the second level of detail for account status changes, working beneath Dictionary.PlayerStatusReasons. While the Reason gives the broad category (e.g., "Chargeback"), the SubReason gives the specific detail (e.g., "ACH CHBK", "Credit Card CHBK", "PayPal CHBK"). This two-level classification gives compliance, risk, and operations teams the granularity needed for investigation tracking and reporting.

The 83 sub-reasons span: fraud types (1-6), verification failures (7, 24-26), chargeback sources (35-45), screening results (13-16, 31-34), AML triggers (17-21), compliance investigations (28, 50), deposit issues (22-23, 29, 46-48, 53, 69, 78-79), account types (54-58), regulatory requirements (60, 66-68, 70-72, 76), and operational states (59-65, 73-75, 77, 80-82).

The valid combinations of Reason→SubReason are governed by BackOffice.PlayerStatusReasonToSubReason (FK on this table). The SubReason is stored on Customer.CustomerStatic alongside the Reason, and flows through to History.Customer, Customer views, and BackOffice reporting.

---

## 2. Business Logic

### 2.1 Sub-Reason Categories

**What**: Major groupings of the 83 sub-reasons.

**Columns/Parameters Involved**: `PlayerStatusSubReasonID`, `Name`

**Rules**:
- **None (0)**: Default/no sub-reason specified
- **Fraud/Abuse (1-6, 49, 64-65)**: Fraud, fake docs, attack, affiliate fraud, 3rd party, lost funds, 3rd party trading, market abuse, affiliate abuse
- **Verification (7, 24-26, 59, 61, 81-82)**: Failed verification, closed verification, selfie, expired POI/POA, pending docs, 15-day failure, POI/POA required
- **Chargeback Sources (35-45)**: ACH, credit card, PayPal, PWMB, other MOP, 3rd party, CO logic, currency difference, fraud, risk refunded, service/complaint — each CHBK variant
- **Screening (13-16, 31-34)**: WCH negative results, sanctions, PEP failed verification, possible match — old and new naming conventions
- **AML/Investigation (17-21, 73-74)**: Investigation, cross border, AML trigger, business method, mixed funds, SAR filed, law enforcement request
- **Deposit-Related (22-23, 29, 46-48, 53, 69, 78-79)**: FTD, redeposit, PWMB failed deposit, 3rd party FTD/business MOP/redeposit, ACH failed deposit, failed min FTD, preapproved monitoring, failed deposit
- **Warnings (62-63)**: 1st warning, 2nd warning/termination
- **Account Types (54-58)**: Affiliate account/re-linked/terminated, PI 2nd account, PI account
- **Regulatory (60, 66-68, 70-72, 76)**: Corp expired LEI, FATCA, CRS, FATCA0013, corporate LEI issues, corporate/SMSF pending docs, W-8BEN
- **Other (8-12, 50-52, 75, 77, 80)**: Service/technical issues, risk refunded, currency differences, CO logic, no triggers, PayPal investigation, risk check, low risk, vulnerable client, negative balance, UAE PASS reactivation

### 2.2 Reason-to-SubReason Hierarchy

**What**: How sub-reasons relate to parent reasons.

**Columns/Parameters Involved**: `PlayerStatusSubReasonID`

**Rules**:
- Valid combinations stored in BackOffice.PlayerStatusReasonToSubReason (FK on both columns)
- BackOffice UI presents only valid sub-reasons after a reason is selected
- When updating status via BackOffice.UpdateRiskUserInfo, both @playerStatusReasonId and @PlayerStatusSubReasonID are required
- History.Customer records both for audit trail

---

## 3. Data Overview

The table contains 83 rows (IDs 0-82). Key representative entries:

| PlayerStatusSubReasonID | Name | Category |
|---|---|---|
| 0 | None | Default |
| 1 | Fraud | Fraud/Abuse |
| 2 | Fake docs | Fraud/Abuse |
| 5 | 3rd Party | Fraud/Abuse |
| 7 | Failed Verification | Verification |
| 14 | Sanctions | Screening |
| 17 | Investigation | AML |
| 19 | AML Trigger | AML |
| 22 | FTD | Deposit |
| 35 | ACH CHBK | Chargeback |
| 36 | Credit Card CHBK | Chargeback |
| 37 | PayPal CHBK | Chargeback |
| 38 | PWMB CHBK | Chargeback |
| 54 | Affiliate Account | Account Type |
| 58 | PI account | Account Type |
| 62 | 1st Warning | Warning |
| 64 | Market Abuse | Fraud/Abuse |
| 66 | FATCA | Regulatory |
| 73 | SAR filed | AML |
| 75 | Vulnerable Client | Other |
| 76 | W-8BEN | Regulatory |
| 81 | POI Required | Verification |
| 82 | POA Required | Verification |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerStatusSubReasonID | int | NO | - | VERIFIED | Primary key identifying the granular sub-reason. Range 0-82. Referenced by BackOffice.PlayerStatusReasonToSubReason (FK) and Customer.CustomerStatic (FK). Used as parameter in BackOffice.UpdateRiskUserInfo. 0=None (default). Provides second-level detail beneath PlayerStatusReasonID. |
| 2 | Name | varchar(50) | YES | - | VERIFIED | Human-readable sub-reason label. Nullable (same as parent Reasons table). Used in BackOffice reporting JOINs and customer history views. Displayed in BackOffice UI alongside the parent reason. Contains abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, LEI=Legal Entity Identifier, PEP=Politically Exposed Person, SAR=Suspicious Activity Report, WCH=World Check, CRS=Common Reporting Standard. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.PlayerStatusReasonToSubReason | PlayerStatusSubReasonID | Explicit FK | Maps valid reason-to-subreason combinations |
| Customer.CustomerStatic | PlayerStatusSubReasonID | Explicit FK | Stores customer's current status sub-reason |
| History.Customer | PlayerStatusSubReasonID | Column | Historical snapshot of sub-reason per change |
| Customer.Customer | PlayerStatusSubReasonID | View SELECT | Customer view exposes sub-reason |
| Customer.CustomerSafty | PlayerStatusSubReasonID | View SELECT | Schema-bound customer view exposes sub-reason |
| BackOffice.GetBlockedCustomers | @PlayerStatusSubReasonIDs | Parameter/WHERE/JOIN | Filters blocked customers by sub-reason |
| BackOffice.GetPendingClosureAccountsByLastChangeDate | @PlayerStatusSubReasonIDs | Parameter/WHERE | Filters pending closure by sub-reasons |
| BackOffice.GetClosedAccountsByLastChangeDate | @PlayerStatusSubReasonIDs | Parameter/WHERE | Filters closed accounts by sub-reasons |
| BackOffice.GetHistoryCustomer | PlayerStatusSubReasonID | JOIN | History display resolves sub-reason name |
| BackOffice.GetPlayerStatusReasonMapping | - | SELECT | Loads sub-reason mapping for UI |
| BackOffice.LoadPlayerStatusReasonMapping | - | SELECT/JOIN | Caches sub-reason mappings |
| BackOffice.UpdateRiskUserInfo | @PlayerStatusSubReasonID | Parameter UPDATE | Sets customer status sub-reason |
| Customer.GetCustomerRelationsWithPlayerStatuses | - | JOIN | Resolves sub-reason for relations |
| Customer.GetRiskUserInfo | PlayerStatusSubReasonID | SELECT | Returns current sub-reason |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.PlayerStatusSubReasons (table)
  └── referenced by BackOffice.PlayerStatusReasonToSubReason (FK)
  └── referenced by Customer.CustomerStatic (FK)
  └── stored in History.Customer
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.PlayerStatusReasonToSubReason | Table | FK — valid reason-to-subreason mappings |
| Customer.CustomerStatic | Table | FK — stores current sub-reason |
| History.Customer | Table | Historical sub-reason snapshots |
| Customer.Customer | View | Exposes PlayerStatusSubReasonID |
| BackOffice.GetBlockedCustomers | Stored Procedure | Filters by sub-reason IDs |
| BackOffice.UpdateRiskUserInfo | Stored Procedure | Sets status sub-reason |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_PlayerStatusSubReasons | CLUSTERED PK | PlayerStatusSubReasonID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_PlayerStatusSubReasons | PRIMARY KEY | Unique sub-reason identifier, FILLFACTOR 90, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all sub-reasons
```sql
SELECT  PlayerStatusSubReasonID,
        Name
FROM    Dictionary.PlayerStatusSubReasons WITH (NOLOCK)
ORDER BY PlayerStatusSubReasonID;
```

### 8.2 Find all chargeback-related sub-reasons
```sql
SELECT  PlayerStatusSubReasonID,
        Name
FROM    Dictionary.PlayerStatusSubReasons WITH (NOLOCK)
WHERE   Name LIKE '%CHBK%'
ORDER BY PlayerStatusSubReasonID;
```

### 8.3 Show reason → sub-reason hierarchy
```sql
SELECT  dsr.PlayerStatusReasonID,
        dsr.Name            AS Reason,
        dss.PlayerStatusSubReasonID,
        dss.Name            AS SubReason
FROM    BackOffice.PlayerStatusReasonToSubReason map WITH (NOLOCK)
JOIN    Dictionary.PlayerStatusReasons dsr WITH (NOLOCK)
        ON map.PlayerStatusReasonID = dsr.PlayerStatusReasonID
JOIN    Dictionary.PlayerStatusSubReasons dss WITH (NOLOCK)
        ON map.PlayerStatusSubReasonID = dss.PlayerStatusSubReasonID
ORDER BY dsr.Name, dss.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data (83 sub-reasons) and codebase analysis across BackOffice and Customer schemas. Abbreviation glossary derived from industry-standard compliance terminology.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 14 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PlayerStatusSubReasons | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PlayerStatusSubReasons.sql*

# History.BackOfficeCustomer

> SCD Type 2 history table for BackOffice.Customer: archives a complete snapshot of the customer's back-office classification, regulatory status, verification level, sales assignment, and compliance state every time any of these fields changes.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CustomerHistoryID (PK, INT IDENTITY, CLUSTERED) |
| **Partition** | No (stored on HISTORY filegroup) |
| **Indexes** | 4 active (1 clustered PK, 2 nonclustered, 1 columnstore) |

---

## 1. Business Meaning

History.BackOfficeCustomer is the **slowly-changing dimension type 2 (SCD2) audit table** for `BackOffice.Customer` - the central customer management record used by eToro's back-office operations team. Every time any field on BackOffice.Customer changes - sales status, manager assignment, verification level, regulatory classification, compliance flags - a new snapshot row is inserted here with a ValidFrom timestamp, and the previous row's ValidTo is closed. The current-state row always has ValidTo = '3000-01-01'.

This is one of eToro's largest and most critical history tables: **145 million rows** for nearly 19 million distinct customers since June 2014, continuously updated as customers progress through registration, verification, and compliance workflows.

**Business purpose**: Enables point-in-time reconstruction of any customer's back-office state - essential for regulatory compliance audits ("what was this customer's regulation and verification level on January 15th?"), dispute investigation, sales team performance tracking, and data warehouse reporting. Tax reports, CRM sync, DWH views, and compliance procedures all query this table.

**SCD2 mechanics**: The application (typically BackOffice stored procedures) is responsible for closing the previous row (UPDATE ValidTo) and inserting a new row when any field changes. The `Trace` column captures full connection metadata (host, app, SQL user, original login, SPID, proc name) as JSON - enabling investigation of which application path triggered each change.

---

## 2. Business Logic

### 2.1 SCD2 Insert Pattern

**What**: When any field in BackOffice.Customer changes, the history table receives a new snapshot with the new state.

**Columns/Parameters Involved**: `CID`, `ValidFrom`, `ValidTo`, all status columns

**Rules**:
- ValidTo='3000-01-01 00:00:00.000' marks the current active row
- When a change occurs: previous row's ValidTo is set to the new row's ValidFrom timestamp
- ValidFrom and ValidTo use DATETIME (not UTC) - local server time
- Multiple changes in quick succession create very short-lived rows (milliseconds to seconds)
- Each row represents the complete state of BackOffice.Customer at the point in time between ValidFrom and ValidTo

**Diagram**:
```
Customer CID=25484479 changes state at 07:19:
  Row 1: ValidFrom=07:19:19.273, ValidTo=07:19:19.280 (7ms - near-simultaneous change)
  Row 2: ValidFrom=07:19:19.280, ValidTo=07:19:35.470 (16 seconds)
  Row 3: ValidFrom=07:19:35.470, ValidTo=3000-01-01 (current)
```

### 2.2 Customer Status Fields

**What**: The table tracks four major customer status dimensions simultaneously.

**Columns/Parameters Involved**: `SalesStatusID`, `VerificationLevelID`, `AcceptanceStatusID`, `DocumentStatusID`

**Rules**:
- SalesStatusID: 0=New, 1=Follow Up, 2=Close, 3=New-NA (sales team assignment category)
- VerificationLevelID: 0=Level 0 (lowest), higher levels = more verification completed. Queried in the DWH IX_HistoryBackOfficeCustomer covering index
- AcceptanceStatusID: 0=Pending, 1=Accepted, 2=Rejected, 3=Follow Up (KYC/AML compliance decision)
- DocumentStatusID: document verification state (ID documents, proof of address)

### 2.3 Regulatory Classification

**What**: Multiple regulatory and compliance classification fields govern what products and leverage the customer can access.

**Columns/Parameters Involved**: `RegulationID`, `DesignatedRegulationID`, `MifidCategorizationID`, `AsicClassificationID`, `SeychellesCategorizationID`

**Rules**:
- RegulationID: primary regulatory jurisdiction (1=Cyprus, 2=EU, 4=Australia, 5=UK/FCA, 10=Global, 11=US-Apex)
- MifidCategorizationID: EU MiFID II client category (1=Retail, 2=Professional, 3=Eligible Counterparty, 4=Not Applicable, 5=Elected Professional)
- AsicClassificationID: Australian ASIC client type (NULL=default retail, 4=retail, others=wholesale/sophisticated)
- SeychellesCategorizationID: Seychelles FSA classification (0=retail per source, 1/2=other categories)
- DesignatedRegulationID: override for customers subject to a specific regulation different from their primary

### 2.4 Trace JSON Audit Field

**What**: The Trace column captures full connection context at INSERT time via a computed DEFAULT.

**Columns/Parameters Involved**: `Trace`

**Rules**:
- Default expression: `concat('{"HostName": "',host_name(),'","AppName": "',app_name(),'","SUserName": "',suser_name(),'","OriginalLogin": "',original_login(),'","SPID": "',@@spid,'","DBName": "',db_name(),'","ObjectName": "',object_name(@@procid),'"}')`
- Provides full connection metadata: which server, which application, which login, which stored procedure
- Enables precise tracing of what application path triggered a customer status change

---

## 3. Data Overview

145,148,050 rows for 18,764,972 distinct customers, June 2014 to March 2026. Extremely active - new rows inserted constantly as customers register and progress through onboarding/compliance. Multiple rows per customer are the norm.

| CustomerHistoryID | CID | ValidFrom | ValidTo | SalesStatusID | AccountTypeID | RegulationID | VerificationLevelID | AcceptanceStatusID | Meaning |
|---|---|---|---|---|---|---|---|---|---|
| 145667647 | 25484479 | 2026-03-19 07:19:35 | 3000-01-01 | 0 | 1 | 5 | 0 | 0 | Current state (ValidTo=3000-01-01). New customer (SalesStatusID=0), Real account (AccountTypeID=1), UK/FCA regulation (RegulationID=5), Level 0 verification, Pending acceptance. |
| 145667646 | 25484479 | 2026-03-19 07:19:19 | 2026-03-19 07:19:35 | 0 | 1 | 5 | 0 | 0 | Previous version active for 16 seconds. Same values - shows two near-simultaneous writes during customer registration. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerHistoryID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK. NOT FOR REPLICATION (independent sequence per replica). Clustered PK. Included in nonclustered index IX_H_BackOfficeCustomer for efficient per-customer history lookups. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID - FK to BackOffice.Customer(CID). The customer whose state changed. Part of multiple index key columns for customer-centric lookups. |
| 3 | ValidFrom | datetime | NO | - | CODE-BACKED | Local server timestamp when this state version became active. NOT UTC. Second column of the clustered PK covering index (IX_H_BackOfficeCustomer). Also in Idx_History_BackOfficeCustomer_CID_ValidFrom_ValidTo covering (RegulationID, AMLComment). |
| 4 | ValidTo | datetime | NO | - | CODE-BACKED | Local server timestamp when this state version was superseded. '3000-01-01 00:00:00.000' = current active row. Also in Idx_History_BackOfficeCustomer_CID_ValidFrom_ValidTo. |
| 5 | SalesStatusID | int | NO | - | VERIFIED | Sales team classification of this customer. 0=New (fresh registration, uncontacted), 1=Follow Up (sales rep assigned), 2=Close (churned/closed), 3=New-NA (new but not applicable for sales). References Dictionary.SalesStatus. |
| 6 | ManagerID | int | YES | - | CODE-BACKED | Sales/account manager assigned to this customer. FK to BackOffice.Manager(ManagerID). NULL = unassigned. Included in IX_H_BackOfficeCustomer for fast manager lookups. References BackOffice.Manager. |
| 7 | IsAffiliate | bit | NO | 0 | CODE-BACKED | Whether this customer was referred through an affiliate program. Default=0 (not affiliate). Affects fee structures and reporting. |
| 8 | Cleared | bit | NO | 0 | CODE-BACKED | AML/compliance clearance flag. Default=0. Set to 1 when the customer has passed AML checks. |
| 9 | Verified | bit | NO | 0 | CODE-BACKED | KYC verification flag. Default=0. Set to 1 when the customer's identity has been fully verified. |
| 10 | PreviousManagerID | int | YES | - | CODE-BACKED | The manager who was assigned to this customer before the current ManagerID. Used to track manager reassignment history. References BackOffice.Manager. |
| 11 | FXEligibilityDate | datetime | YES | - | CODE-BACKED | Date when this customer became eligible for FX trading. NULL = not yet eligible. Set based on regulation/verification requirements. |
| 12 | AffiliateManagerID | int | YES | - | CODE-BACKED | Manager ID for the affiliate who referred this customer. NULL for non-affiliate customers. References BackOffice.Manager. |
| 13 | CashoutFeeGroupID | int | YES | - | CODE-BACKED | Fee tier for withdrawal charges. FK to Dictionary.CashoutFeeGroup(CashoutFeeGroupID). NULL = default fee group. |
| 14 | AccountTypeID | tinyint | YES | - | CODE-BACKED | Customer account type. From _glossary.md: 1=Real, 2=Demo, 3=None, 5=VirtualCfd... (16 total values). The COLUMNSTORE index covers ValidFrom, ValidTo, CID, AccountTypeID for DWH aggregations. Also covered by separate nonclustered index on BackOffice.Customer. |
| 15 | MasterAccountCID | int | YES | - | CODE-BACKED | CID of the master/parent account if this is a sub-account. NULL for standalone accounts. Used in multi-account customer structures. |
| 16 | ManagerPermitID | int | NO | 1 | CODE-BACKED | Permission level of the assigned manager. Default=1 (standard permit). Controls what actions the manager can perform on this customer. |
| 17 | ThirdPartyManagerComment | varchar(255) | YES | - | CODE-BACKED | Free-text comment from a third-party manager (e.g., IB/introducer). Used when the customer was referred by an external partner. |
| 18 | GuruStatusID | int | YES | - | CODE-BACKED | Popular Investor / Guru status for CopyTrading. FK to Dictionary.GuruStatus. NULL = regular trader. Non-null = has guru/popular investor status at a specific level. |
| 19 | RiskClassificationID | int | NO | 0 | CODE-BACKED | Risk classification for regulatory purposes. FK to Dictionary.RiskClassification(RiskClassificationID). Default=0. Written by BackOffice.SetRiskClassificationNew and RiskCalculation procedures. |
| 20 | VerificationLevelID | int | YES | - | CODE-BACKED | KYC verification level. 0=Level 0 (unverified/basic). Higher values = more documents verified. References Dictionary.VerificationLevel. Covered by IX_HistoryBackOfficeCustomer (ValidFrom, includes CID, VerificationLevelID). |
| 21 | RegulationID | int | YES | - | CODE-BACKED | Primary regulatory jurisdiction. Known values: 1=Cyprus CySEC, 2=EU, 4=Australia ASIC, 5=UK FCA, 10=Global/Offshore, 11=US Apex. Determines product eligibility, leverage limits, and reporting requirements. Covered in Idx_History_BackOfficeCustomer_CID_ValidFrom_ValidTo INCLUDE. |
| 22 | RiskStatusID | int | YES | - | CODE-BACKED | Operational risk status (different from RiskClassificationID which is regulatory). Controls account restrictions, trading limits. References Dictionary.RiskStatus (if exists). |
| 23 | AcceptanceStatusID | int | YES | - | CODE-BACKED | KYC/compliance acceptance decision. 0=Pending, 1=Accepted, 2=Rejected, 3=Follow Up. References Dictionary.AcceptanceStatus. Set by compliance team after document review. |
| 24 | DocumentStatusID | int | YES | - | CODE-BACKED | Status of the customer's submitted identity documents. NULL = no documents submitted. References Dictionary.DocumentStatus. |
| 25 | PhoneVerifiedID | int | YES | - | CODE-BACKED | Phone number verification status. NULL = not verified. Non-null = verification method and status. |
| 26 | AcceptanceStatusChanginManagerID | int | YES | - | CODE-BACKED | Manager ID who changed the AcceptanceStatus. References BackOffice.Manager. Provides accountability for compliance decisions. Note: typo in column name ("Changin" instead of "Changing"). |
| 27 | GDCCheckID | int | YES | - | CODE-BACKED | Global Data Check (GDC) or sanctions screening result ID. AML-related check. References Dictionary or BackOffice check tables. |
| 28 | SuitabilityTestStatusID | int | YES | - | CODE-BACKED | Regulatory suitability/appropriateness test status. Required under MiFID II for professional categorization. References Dictionary.SuitabilityTestStatus. |
| 29 | EvMatchStatus | int | YES | - | CODE-BACKED | Electronic verification (eV) match status. Anti-fraud identity verification match result. |
| 30 | Lei | nvarchar(50) | YES | - | CODE-BACKED | Legal Entity Identifier (LEI) for institutional/corporate customers. 20-character ISO 17442 code. Required for MiFID II transaction reporting for legal entities. NULL for retail/individual accounts. |
| 31 | MifidCategorizationID | int | YES | - | CODE-BACKED | EU MiFID II client categorization. FK to Dictionary.MifidCategorization. 1=Retail, 2=Professional (per se), 3=Eligible Counterparty, 4=Not Applicable (non-EU), 5=Elected Professional. Determines leverage limits and protections under EU regulation. |
| 32 | DesignatedRegulationID | int | YES | - | CODE-BACKED | Override regulation for customers subject to a specific regulatory regime different from their primary RegulationID. NULL = follow primary RegulationID. |
| 33 | Trace | varchar(max) | YES | JSON DEFAULT | CODE-BACKED | Connection context JSON: {"HostName","AppName","SUserName","OriginalLogin","SPID","DBName","ObjectName"}. Automatically populated by the DEFAULT constraint at INSERT time. Enables tracing which application path (stored procedure, service, DBA tool) triggered each state change. |
| 34 | AMLComment | varchar(8000) | YES | - | CODE-BACKED | Anti-Money Laundering free-text comment. Written by compliance team. May contain investigation notes, screening results, or manual review findings. Up to 8000 characters. Covered in Idx_History_BackOfficeCustomer_CID_ValidFrom_ValidTo INCLUDE. |
| 35 | HasWallet | bit | YES | - | CODE-BACKED | Whether this customer has an eToro Money wallet. NULL/0=no wallet, 1=has wallet. Part of the eToro Money crypto wallet product. |
| 36 | SalesForceAccountID | nvarchar(18) | YES | - | CODE-BACKED | Salesforce CRM Account object ID (18-character Salesforce ID). Links this customer to their Salesforce record. NULL for customers not yet synced to Salesforce. |
| 37 | SalesForceContactID | nvarchar(18) | YES | - | CODE-BACKED | Salesforce CRM Contact object ID (18-character). The Contact record linked to this customer in Salesforce. NULL for unsynced customers. Written/read by Maintenance.JOB_SendCustomerXMLToCRM and SalesForce.GetBackOfficeCustomer. |
| 38 | AsicClassificationID | int | YES | - | CODE-BACKED | Australian ASIC client classification. NULL=not applicable (non-AU), 4=retail, other values=wholesale/sophisticated investor. Determines leverage limits under ASIC RG168. |
| 39 | SeychellesCategorizationID | int | YES | - | CODE-BACKED | Seychelles FSA (Financial Services Authority) client categorization. 0=retail, 1/2=other categories per the BackOffice.Customer computed TradingRiskStatusID formula. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | BackOffice.Customer | FK (FK_BCST_HBOC) | The customer whose state is archived. |
| ManagerID | BackOffice.Manager | FK (FK_BMNG_HBOC) | Assigned sales/account manager. |
| MifidCategorizationID | Dictionary.MifidCategorization | FK (FK_HBOC_MifidCategorizationID) | EU MiFID II client type. |
| CashoutFeeGroupID | Dictionary.CashoutFeeGroup | FK (FK_History_BackOfficeCustomer_Dictionary_CashoutFeeGroup) | Withdrawal fee tier. |
| GuruStatusID | Dictionary.GuruStatus | FK (HBOCGuruStatus) | Popular Investor / CopyTrading guru level. |
| RiskClassificationID | Dictionary.RiskClassification | FK (HBOCRiskClassification) | Regulatory risk classification. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetHistoryBackOfficeCustomer | - | Reader | Returns historical customer records by date range. |
| BackOffice.GetCustomerByCID | - | Reader | Current + historical customer lookup by CID. |
| BackOffice.AccountStatement_GetTaxReport (v1-v3) | - | Reader | Tax report generation using historical regulation/status. |
| DWH.V_BackOfficeCustomerHourly | - | Reader (view) | DWH hourly aggregation view using COLUMNSTORE index. |
| DWH.SP_Economic_Report | - | Reader | Economic reporting SP. |
| SalesForce.GetBackOfficeCustomer | - | Reader | Salesforce sync reads current customer state. |
| Maintenance.JOB_SendCustomerXMLToCRM | - | Reader | CRM sync job. |
| MIMOAlerts.FinancialDiscrepancies_GetWithdrawRequestDetails | - | Reader | Financial discrepancy investigation. |
| BackOffice.SetRiskClassificationNew | - | Writer | Updates RiskClassificationID, creating new history rows. |
| RiskCalculation.SetRiskClassificationForCySec | - | Writer | CySEC risk classification updates. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BackOfficeCustomer (table)
  - FK: BackOffice.Customer (CID)
  - FK: BackOffice.Manager (ManagerID)
  - FK: Dictionary.MifidCategorization
  - FK: Dictionary.CashoutFeeGroup
  - FK: Dictionary.GuruStatus
  - FK: Dictionary.RiskClassification
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | FK target - CID must exist |
| BackOffice.Manager | Table | FK target - ManagerID must exist |
| Dictionary.MifidCategorization | Table | FK target - MiFID II categorization |
| Dictionary.CashoutFeeGroup | Table | FK target - withdrawal fee tier |
| Dictionary.GuruStatus | Table | FK target - guru/popular investor level |
| Dictionary.RiskClassification | Table | FK target - regulatory risk class |

### 6.2 Objects That Depend On This

See Section 5.2 (22 procedures/views reference this table).

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HBOC | CLUSTERED PK (PAGE compressed) | CustomerHistoryID ASC | - | - | Active |
| IX_H_BackOfficeCustomer | NONCLUSTERED (PAGE compressed, FF90) | CID ASC, CustomerHistoryID ASC | ManagerID, ValidFrom, ValidTo | - | Active |
| IX_HistoryBackOfficeCustomer | NONCLUSTERED (PAGE compressed, FF95) | ValidFrom ASC | CID, VerificationLevelID | - | Active |
| Idx_History_BackOfficeCustomer_CID_ValidFrom_ValidTo | NONCLUSTERED (PAGE compressed, FF90) | CID ASC, ValidFrom ASC, ValidTo ASC | RegulationID, AMLComment | - | Active |
| inx_covering_dwh_nccs | NONCLUSTERED COLUMNSTORE | ValidFrom, ValidTo, CID, AccountTypeID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HBOC | PRIMARY KEY CLUSTERED | CustomerHistoryID - surrogate PK |
| HBOC_AFFILIATE | DEFAULT | IsAffiliate = 0 |
| HBOC_CLEARED | DEFAULT | Cleared = 0 |
| BCST_VERIFIED | DEFAULT | Verified = 0 |
| HBOC_ManagerPermitID | DEFAULT | ManagerPermitID = 1 |
| DF_HBOCRiskClassification | DEFAULT | RiskClassificationID = 0 |
| Df_History_BackOfficeCustomer_Trace | DEFAULT | Trace = JSON connection context string |
| FK_BCST_HBOC | FOREIGN KEY | CID -> BackOffice.Customer(CID) |
| FK_BMNG_HBOC | FOREIGN KEY | ManagerID -> BackOffice.Manager(ManagerID) |
| FK_HBOC_MifidCategorizationID | FOREIGN KEY | MifidCategorizationID -> Dictionary.MifidCategorization |
| FK_History_BackOfficeCustomer_Dictionary_CashoutFeeGroup | FOREIGN KEY | CashoutFeeGroupID -> Dictionary.CashoutFeeGroup |
| HBOCGuruStatus | FOREIGN KEY | GuruStatusID -> Dictionary.GuruStatus |
| HBOCRiskClassification | FOREIGN KEY | RiskClassificationID -> Dictionary.RiskClassification |

---

## 8. Sample Queries

### 8.1 Full history for a specific customer (SCD2 timeline)
```sql
SELECT
    CustomerHistoryID,
    ValidFrom,
    ValidTo,
    SalesStatusID,
    VerificationLevelID,
    AcceptanceStatusID,
    RegulationID,
    MifidCategorizationID,
    ManagerID,
    Verified
FROM History.BackOfficeCustomer WITH (NOLOCK)
WHERE CID = 25484479
ORDER BY ValidFrom ASC;
```

### 8.2 Point-in-time customer state lookup
```sql
SELECT
    CID,
    ValidFrom,
    ValidTo,
    RegulationID,
    VerificationLevelID,
    AcceptanceStatusID,
    AMLComment
FROM History.BackOfficeCustomer WITH (NOLOCK)
WHERE CID = @CustomerCID
  AND ValidFrom <= @AsOfDate
  AND ValidTo > @AsOfDate;
```

### 8.3 Count customers by AccountTypeID for a given date (uses COLUMNSTORE index)
```sql
SELECT
    AccountTypeID,
    COUNT(DISTINCT CID) AS UniqueCustomers
FROM History.BackOfficeCustomer WITH (NOLOCK)
WHERE ValidFrom <= '2025-12-31'
  AND ValidTo > '2025-12-31'
GROUP BY AccountTypeID
ORDER BY UniqueCustomers DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 34 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BackOfficeCustomer | Type: Table | Source: etoro/etoro/History/Tables/History.BackOfficeCustomer.sql*

# BI_DB_dbo.BI_DB_US_Apex_Rejected_Accounts

> 99.3K-row daily snapshot of US-designated (DesignatedRegulationID=8) fully verified customers whose Apex Clearing brokerage account is NOT in COMPLETE status — capturing validation errors, open support tickets, liabilities, and player status for compliance operations. Refreshed daily via SP_US_Apex_Rejected_Accounts with TRUNCATE+INSERT.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + USABroker Apex external tables (status/errors) + DWH_dbo.V_Liabilities + BI_DB_SF_Cases_Panel (ticket indicator) |
| **Refresh** | Daily (SP_US_Apex_Rejected_Accounts, TRUNCATE+INSERT, SB_Daily, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_US_Apex_Rejected_Accounts` is a 99.3K-row daily snapshot table listing all US-designated eToro customers whose Apex Clearing brokerage account is not in COMPLETE status. The table serves as an operational dashboard for the US compliance team to track rejected, restricted, suspended, and pending Apex accounts and understand why they failed validation.

The population is: customers with DesignatedRegulationID=8 (US), VerificationLevelID=3 (fully verified), IsValidCustomer=1, AND Apex StatusID <> 12 (not COMPLETE) or no Apex account at all. This captures ~99K customers daily who need attention for Apex onboarding or remediation.

Each row is enriched with:
- **Validation error**: The specific Apex validation failure (e.g., GeneralValidationError, CipCheckRejectedBySketch, UserIsNotPermanentResident)
- **Open ticket indicator**: Whether the customer has an active non-email support ticket in Salesforce (from BI_DB_SF_Cases_Panel)
- **Liabilities**: Current financial liabilities from V_Liabilities
- **Player status**: eToro account status (Normal, Blocked, Blocked Upon Request, etc.)
- **Pending closure status**: Whether the account is in a closure workflow

The table is TRUNCATE+INSERT daily — always reflects the current day's state, not historical.

---

## 2. Business Logic

### 2.1 Population Filter (US Designation + Not Approved)

**What**: Only US-designated, verified, valid customers with non-COMPLETE Apex status.
**Columns Involved**: `RegulationID`, `ApexStatus`
**Rules**:
- DesignatedRegulationID = 8 (NOT RegulationID — the comment in SP says `dc.RegulationID=8` is commented out)
- VerificationLevelID = 3 (fully verified KYC)
- IsValidCustomer = 1
- StatusID <> 12 (not COMPLETE) OR StatusID IS NULL (no Apex account)

### 2.2 Open Ticket Indicator

**What**: Flags customers with active support tickets from non-email channels.
**Columns Involved**: `TicketInd`
**Rules**:
- 'Yes' if customer's RealCID matches CID_Last in BI_DB_SF_Cases_Panel WHERE Source_AtOpen != 'Email' AND TicketStatus NOT IN ('Closed', 'Solved')
- 'No' otherwise
- Email-only tickets are excluded (always filtered out)

### 2.3 Apex Validation Errors

**What**: Specific reason why the customer's Apex account was rejected or restricted.
**Columns Involved**: `ValidationError`, `ErrortDate`
**Rules**:
- Top errors: GeneralValidationError (46%), CipCheckRejectedBySketch (14%), UserIsNotPermanentResident (10%), HomeAddressError (8%), WrongCombinationOfZipCityAndState (8%)
- ErrortDate is from External_USABroker_Apex_State.BeginTime (cast to date)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution, HEAP — full table scan for any query. For CID-specific lookups, filter by RealCID. Table is small (99K rows) so full scans are acceptable.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Count by Apex status | `GROUP BY ApexStatus` |
| Rejected accounts with open tickets | `WHERE ApexStatus = 'REJECTED' AND TicketInd = 'Yes'` |
| Customers with liabilities but blocked | `WHERE Liabilities > 0 AND PlayerStatus LIKE 'Block%'` |
| Validation error breakdown | `GROUP BY ValidationError ORDER BY COUNT(*) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID = Dim_Customer.RealCID | Full customer attributes |
| BI_DB_dbo.BI_DB_US_Apex_Address_Change | RealCID = CID | Correlate address changes with rejection status |

### 3.4 Gotchas

- **ApexID = 'No ApexAccount'**: String literal, not NULL — indicates customer has no Apex account at all (27K rows)
- **ErrortDate typo**: Column name has double 't' — `ErrortDate` not `ErrorDate`. This is in the DDL and cannot be renamed without ALTER
- **TRUNCATE daily**: This is a snapshot table — no history. Yesterday's data is gone. For historical trends, query audit logs or build a snapshot pipeline
- **DesignatedRegulationID vs RegulationID**: The SP filters on DesignatedRegulationID=8, not RegulationID. The RegulationID column in the output is the customer's primary regulation, which may differ

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data + context |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL infrastructure / standard metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | YES | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 2 | RealCID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 3 | RegulationID | int | YES | Customer's primary regulatory jurisdiction ID. FK to Dim_Regulation. Note: the population filter uses DesignatedRegulationID=8, not this field — so RegulationID may differ from 8. Passthrough from Dim_Customer. (Tier 2 — SP_US_Apex_Rejected_Accounts, Dim_Customer) |
| 4 | ApexID | varchar(50) | YES | Apex Clearing brokerage account identifier. 'No ApexAccount' (literal string) if customer has no Apex account. Format: alphanumeric (e.g., "3EX76442"). (Tier 2 — SP_US_Apex_Rejected_Accounts, External_USABroker_Apex_ApexData) |
| 5 | ApexStatus | varchar(100) | YES | Current Apex brokerage account status. RESTRICTED (56%), empty (28%), REJECTED (15%), SUSPENDED (1%), ACTION_REQUIRED, ERROR, BACK_OFFICE, ACCOUNT_SETUP. Empty string for customers with 'No ApexAccount'. (Tier 2 — SP_US_Apex_Rejected_Accounts, External_USABroker_Dictionary_ApexStatus) |
| 6 | ValidationError | nvarchar(max) | YES | Apex validation error description. GeneralValidationError (46%), CipCheckRejectedBySketch (14%), UserIsNotPermanentResident (10%), HomeAddressError (8%), WrongCombinationOfZipCityAndState (8%), AddressCouldNotBeVerified (4%), SsnCouldNotBeVerified (2%). From Dictionary_ApexValidationError. (Tier 2 — SP_US_Apex_Rejected_Accounts, External_USABroker_Dictionary_ApexValidationError) |
| 7 | ErrortDate | date | YES | Date the Apex validation error occurred. CAST(External_USABroker_Apex_State.BeginTime AS DATE). Note: column name has typo (double 't'). (Tier 2 — SP_US_Apex_Rejected_Accounts, External_USABroker_Apex_State) |
| 8 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_US_Apex_Rejected_Accounts (GETDATE()). (Tier 5 — SP_US_Apex_Rejected_Accounts) |
| 9 | TicketInd | varchar(50) | YES | Open support ticket indicator. 'Yes' if customer has an active non-email Salesforce ticket (from BI_DB_SF_Cases_Panel WHERE Source_AtOpen != 'Email' AND TicketStatus NOT IN ('Closed','Solved')). 'No' otherwise. (Tier 2 — SP_US_Apex_Rejected_Accounts, BI_DB_SF_Cases_Panel) |
| 10 | Liabilities | decimal(22,4) | YES | Customer's current financial liabilities. From V_Liabilities for @DateID. NULL if no liabilities record for this customer on this date. (Tier 2 — SP_US_Apex_Rejected_Accounts, V_Liabilities) |
| 11 | IsDepositor | varchar(50) | YES | Whether the customer has ever deposited. 'Yes' if Dim_Customer.IsDepositor=1, 'No' otherwise. Converted from bit to string. (Tier 2 — SP_US_Apex_Rejected_Accounts, Dim_Customer) |
| 12 | PendingClosureStatusName | varchar(50) | YES | Account pending closure status name. From Dim_PendingClosureStatus via PendingClosureStatusID. NULL if account is not in a closure workflow. (Tier 2 — SP_US_Apex_Rejected_Accounts, Dim_PendingClosureStatus) |
| 13 | PlayerStatus | varchar(50) | YES | eToro platform account status. Blocked (41%), Normal (36%), Blocked Upon Request (20%), Block Deposit & Trading (2%), Trade & MIMO Blocked, Warning, Deposit Blocked, Copy Block. From Dim_PlayerStatus.Name. (Tier 2 — SP_US_Apex_Rejected_Accounts, Dim_PlayerStatus) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| GCID | Dim_Customer | GCID | Passthrough |
| RealCID | Dim_Customer | RealCID | Passthrough |
| RegulationID | Dim_Customer | RegulationID | Passthrough |
| ApexID | External_USABroker_Apex_ApexData | ApexID | CASE NULL → 'No ApexAccount' |
| ApexStatus | External_USABroker_Dictionary_ApexStatus | Name | JOIN on StatusID |
| ValidationError | External_USABroker_Dictionary_ApexValidationError | Name | JOIN via UserValidationErrors |
| ErrortDate | External_USABroker_Apex_State | BeginTime | CAST to DATE |
| TicketInd | BI_DB_SF_Cases_Panel | CID_Last | EXISTS → 'Yes'/'No' |
| Liabilities | V_Liabilities | Liabilities | Passthrough for @DateID |
| IsDepositor | Dim_Customer | IsDepositor | CASE 1→'Yes', 0→'No' |
| PendingClosureStatusName | Dim_PendingClosureStatus | PendingClosureStatusName | JOIN |
| PlayerStatus | Dim_PlayerStatus | Name | JOIN on PlayerStatusID |
| UpdateDate | ETL | GETDATE() | Insert timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (customer identity + regulation + verification)
  |                                                                   |
  |  + External_USABroker_Apex_* (Apex account status/errors)          |
  |  + DWH_dbo.V_Liabilities (financial liabilities)                   |
  |  + DWH_dbo.Dim_PlayerStatus (platform status)                      |
  |  + DWH_dbo.Dim_PendingClosureStatus (closure workflow)             |
  |  + BI_DB_dbo.BI_DB_SF_Cases_Panel (open ticket check)              |
  |                                                                   |
  |-- SP_US_Apex_Rejected_Accounts @date (daily, TRUNCATE+INSERT) ----|
  v
BI_DB_dbo.BI_DB_US_Apex_Rejected_Accounts (99.3K rows, daily snapshot)
  |
  (UC: Not Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID / RealCID | DWH_dbo.Dim_Customer | Customer dimension |
| ApexID / ApexStatus | External_USABroker_Apex_ApexData | Apex brokerage account |
| TicketInd | BI_DB_dbo.BI_DB_SF_Cases_Panel | Salesforce case panel (open ticket check) |
| Liabilities | DWH_dbo.V_Liabilities | Customer liabilities view |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Player status dimension |

### 6.2 Referenced By (other objects point to this)

No known consumers in BI_DB_dbo or DWH_dbo SPs.

---

## 7. Sample Queries

### 7.1 Rejected Accounts with High Liabilities

```sql
SELECT
    RealCID, GCID, ApexID, ApexStatus,
    ValidationError, Liabilities, PlayerStatus
FROM BI_DB_dbo.BI_DB_US_Apex_Rejected_Accounts
WHERE Liabilities > 0
    AND ApexStatus = 'REJECTED'
ORDER BY Liabilities DESC
```

### 7.2 Validation Error Distribution

```sql
SELECT
    ValidationError,
    COUNT(*) AS CustomerCount,
    SUM(CASE WHEN TicketInd = 'Yes' THEN 1 ELSE 0 END) AS WithOpenTicket,
    SUM(CASE WHEN PlayerStatus LIKE 'Block%' THEN 1 ELSE 0 END) AS BlockedAccounts
FROM BI_DB_dbo.BI_DB_US_Apex_Rejected_Accounts
WHERE ValidationError IS NOT NULL
GROUP BY ValidationError
ORDER BY CustomerCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 2 T1, 10 T2, 0 T3, 0 T4, 1 T5 | Elements: 13/13, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_US_Apex_Rejected_Accounts | Type: Table | Production Source: Dim_Customer + USABroker Apex + V_Liabilities + SF_Cases_Panel*

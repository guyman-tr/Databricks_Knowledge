# BI_DB_dbo.BI_DB_US_Apex_Address_Change

> 12.2K-row US regulatory compliance table tracking address changes for FinCEN+FINRA-regulated (RegulationID=8) fully verified (VerificationLevelID=3) customers, with previous and current address/city/state and Apex brokerage account status, from September 2021 to present. Refreshed daily via SP_US_Apex_Address_Change with DELETE+INSERT by CID+ChangeDate.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer (address history via LAG) + DWH_dbo.Dim_Customer (name/GCID) + USABroker Apex external tables (brokerage status) |
| **Refresh** | Daily (SP_US_Apex_Address_Change, DELETE+INSERT by CID+ChangeDate, SB_Daily, Priority 0) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (CID ASC, ChangeDate ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_US_Apex_Address_Change` is a 12.2K-row compliance monitoring table that tracks residential address changes for US-regulated eToro customers who hold Apex Clearing brokerage accounts. Each row represents a detected address or city change for a fully verified (VerificationLevelID=3), FinCEN+FINRA-regulated (RegulationID=8) customer.

The SP uses LAG() window functions on DWH_dbo.Fact_SnapshotCustomer to detect when a customer's address or city changed between consecutive snapshots. Only rows where the address or city actually differ from the previous snapshot are included. The table captures both the previous and current values (address, city, state) to support compliance review of address change patterns.

Each row is enriched with the customer's Apex Clearing brokerage data: their Apex account ID, current status (91% COMPLETE, 2% SUSPENDED, etc.), and the approver who authorized their Apex account. This allows compliance teams to correlate address changes with brokerage account status — for example, flagging address changes on suspended or restricted accounts.

The table contains PII (FirstName, LastName, Address, City, State) and is intended for compliance/operations use only.

---

## 2. Business Logic

### 2.1 Address Change Detection via LAG()

**What**: Detects address or city changes by comparing consecutive customer snapshots.
**Columns Involved**: `Previous_Address`, `Address`, `PreviousCity`, `City`
**Rules**:
- LAG(Address, 1, NULL) OVER(PARTITION BY RealCID ORDER BY UpdateDate) computes previous address
- Same pattern for City and State
- Filter: WHERE (Previous_Address != Address AND Previous_Address IS NOT NULL) OR (PreviousCity != City AND PreviousCity IS NOT NULL)
- First-ever snapshot (Previous_Address IS NULL) is excluded — only actual changes tracked

### 2.2 US Regulatory Filter

**What**: Only US-regulated, fully verified customers are tracked.
**Columns Involved**: `RegulationAtChange`
**Rules**:
- WHERE VerificationLevelID = 3 (fully verified KYC)
- AND RegulationID = 8 (FinCEN+FINRA — US regulation)
- RegulationAtChange always shows "FinCEN+FINRA" (resolved from Dim_Regulation)

### 2.3 Apex Account Status Enrichment

**What**: Each customer's Apex Clearing brokerage status is attached.
**Columns Involved**: `ApexID`, `ApexStatus`, `ApproverName`, `ApprovedByDate`
**Rules**:
- LEFT JOIN to External_USABroker_Apex_ApexData on CID → ApexID, StatusID
- StatusID resolved to name via Dictionary_ApexStatus
- 10 status values: COMPLETE (91%), empty (6%), SUSPENDED (2%), ERROR, REJECTED, RESTRICTED, PENDING, ACTION_REQUIRED, BACK_OFFICE, INVESTIGATION_SUBMITTED

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) distribution — optimized for per-customer lookups. CLUSTERED INDEX on (CID, ChangeDate) supports efficient customer-level time-series queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Address changes for a specific CID | `WHERE CID = @cid ORDER BY ChangeDate` |
| Cross-state moves (compliance flag) | `WHERE PreviousState != State AND PreviousState IS NOT NULL` |
| Changes on suspended Apex accounts | `WHERE ApexStatus = 'SUSPENDED'` |
| Recent address changes | `WHERE ChangeDate >= DATEADD(DAY, -30, GETDATE())` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Additional customer attributes |
| BI_DB_dbo.BI_DB_US_Apex_Rejected_Accounts | CID | Correlate address changes with account rejections |

### 3.4 Gotchas

- **PII columns**: FirstName, LastName, Address, City, State, PreviousState, Previous_Address, PreviousCity are all PII — restrict access
- **ApexStatus empty string**: 6% of rows have empty string ApexStatus (not NULL) — customer may not have an Apex account yet
- **RegulationAtChange**: Always "FinCEN+FINRA" in current data (hardcoded filter). Column exists for historical/audit traceability
- **State vs PreviousState**: Both come from Dim_State_and_Province via RegionByIP_ID — may be NULL if RegionByIP_ID is 0 or unmatched

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
| 1 | CID | int | NOT NULL | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from Fact_SnapshotCustomer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 3 | FirstName | nvarchar(50) | YES | Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). PII. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 4 | LastName | nvarchar(50) | YES | Legal last name in Unicode. PII. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 5 | RegulationAtChange | varchar(20) | YES | Regulatory jurisdiction name at the time of the address change. Resolved from Dim_Regulation via RegulationID. Always "FinCEN+FINRA" in current data (filter: RegulationID=8). (Tier 2 — SP_US_Apex_Address_Change, Dim_Regulation) |
| 6 | ChangeDate | date | YES | Date the address change was first detected (MIN of Dim_Range.FromDateID converted to date). Range: 2021-09-30 to present. (Tier 2 — SP_US_Apex_Address_Change, Dim_Range) |
| 7 | DateID | int | YES | Integer date key (YYYYMMDD format) corresponding to ChangeDate. MIN per group from Dim_Range.FromDateID. (Tier 2 — SP_US_Apex_Address_Change, Dim_Range) |
| 8 | Previous_Address | varchar(100) | YES | Customer's address BEFORE the change. Computed via LAG(Address, 1, NULL) OVER(PARTITION BY RealCID ORDER BY UpdateDate) on Fact_SnapshotCustomer. NULL for first snapshot. PII. (Tier 2 — SP_US_Apex_Address_Change, Fact_SnapshotCustomer) |
| 9 | Address | varchar(100) | YES | Customer's address AFTER the change. Current snapshot value from Fact_SnapshotCustomer.Address. PII. (Tier 2 — SP_US_Apex_Address_Change, Fact_SnapshotCustomer) |
| 10 | PreviousCity | varchar(50) | YES | Customer's city BEFORE the change. Computed via LAG(City, 1, NULL) on Fact_SnapshotCustomer. NULL for first snapshot. PII. (Tier 2 — SP_US_Apex_Address_Change, Fact_SnapshotCustomer) |
| 11 | City | varchar(50) | YES | Customer's city AFTER the change. Current snapshot value from Fact_SnapshotCustomer.City. PII. (Tier 2 — SP_US_Apex_Address_Change, Fact_SnapshotCustomer) |
| 12 | PreviousState | varchar(50) | YES | Customer's US state BEFORE the change. Computed via LAG(Dim_State_and_Province.Name, 1, NULL). NULL if RegionByIP_ID unmatched. PII. (Tier 2 — SP_US_Apex_Address_Change, Dim_State_and_Province) |
| 13 | State | varchar(50) | YES | Customer's US state AFTER the change. From Dim_State_and_Province.Name via JOIN on RegionByIP_ID + CountryID. PII. (Tier 2 — SP_US_Apex_Address_Change, Dim_State_and_Province) |
| 14 | ApexID | varchar(50) | YES | Apex Clearing brokerage account identifier for this customer. From External_USABroker_Apex_ApexData via CID. NULL if customer has no Apex account. (Tier 2 — SP_US_Apex_Address_Change, External_USABroker_Apex_ApexData) |
| 15 | ApexStatus | varchar(100) | YES | Current Apex brokerage account status. COMPLETE (91%), empty (6%), SUSPENDED (2%), ERROR, REJECTED, RESTRICTED, PENDING, ACTION_REQUIRED, BACK_OFFICE, INVESTIGATION_SUBMITTED. From Dictionary_ApexStatus.Name. (Tier 2 — SP_US_Apex_Address_Change, External_USABroker_Dictionary_ApexStatus) |
| 16 | ApproverName | varchar(50) | YES | Name of the person who approved the Apex brokerage account. From External_USABroker_Apex_UserData. PII. (Tier 2 — SP_US_Apex_Address_Change, External_USABroker_Apex_UserData) |
| 17 | ApprovedByDate | date | YES | Date the Apex brokerage account was approved. From External_USABroker_Apex_UserData.ApprovedByDate. (Tier 2 — SP_US_Apex_Address_Change, External_USABroker_Apex_UserData) |
| 18 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_US_Apex_Address_Change (GETDATE()). (Tier 5 — SP_US_Apex_Address_Change) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| CID | Fact_SnapshotCustomer | RealCID | Rename |
| GCID | Dim_Customer | GCID | Passthrough |
| FirstName | Dim_Customer | FirstName | Passthrough |
| LastName | Dim_Customer | LastName | Passthrough |
| RegulationAtChange | Dim_Regulation | Name | JOIN on RegulationID |
| ChangeDate | Dim_Range | FromDateID | CONVERT to date, MIN per group |
| DateID | Dim_Range | FromDateID | MIN per group |
| Previous_Address | Fact_SnapshotCustomer | Address | LAG() window function |
| Address | Fact_SnapshotCustomer | Address | Passthrough |
| PreviousCity | Fact_SnapshotCustomer | City | LAG() window function |
| City | Fact_SnapshotCustomer | City | Passthrough |
| PreviousState | Dim_State_and_Province | Name | LAG() window function |
| State | Dim_State_and_Province | Name | JOIN on RegionByIP_ID + CountryID |
| ApexID | External_USABroker_Apex_ApexData | ApexID | Passthrough |
| ApexStatus | External_USABroker_Dictionary_ApexStatus | Name | JOIN on StatusID |
| ApproverName | External_USABroker_Apex_UserData | ApproverName | Passthrough |
| ApprovedByDate | External_USABroker_Apex_UserData | ApprovedByDate | Passthrough |
| UpdateDate | ETL | GETDATE() | Insert timestamp |

### 5.2 ETL Pipeline

```
Customer.CustomerStatic (production)
  |-- Generic Pipeline (Bronze) ---|
  v
DWH_staging → DWH_dbo.Dim_Customer (name, GCID)
                                    |
Ext_FSC (BackOffice/Customer)       |
  |-- SP_Fact_SnapshotCustomer -----|
  v                                 |
DWH_dbo.Fact_SnapshotCustomer (address/city/region snapshots)
  |                                                    |
  |  + DWH_dbo.Dim_Range (date conversion)             |
  |  + DWH_dbo.Dim_Regulation (regulation name)        |
  |  + DWH_dbo.Dim_State_and_Province (state name)     |
  |  + External_USABroker_Apex_* (Apex status)          |
  |                                                    |
  |-- SP_US_Apex_Address_Change @date (daily) ---------|
  v
BI_DB_dbo.BI_DB_US_Apex_Address_Change (12.2K rows)
  |
  (UC: Not Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer dimension |
| CID | DWH_dbo.Fact_SnapshotCustomer (RealCID) | Customer snapshot history |
| ApexID | External_USABroker_Apex_ApexData | Apex brokerage account |
| RegulationAtChange | DWH_dbo.Dim_Regulation | Regulation name lookup |
| State / PreviousState | DWH_dbo.Dim_State_and_Province | US state name |

### 6.2 Referenced By (other objects point to this)

No known consumers in BI_DB_dbo or DWH_dbo SPs.

---

## 7. Sample Queries

### 7.1 Recent Cross-State Address Changes

```sql
SELECT
    CID, FirstName, LastName,
    ChangeDate,
    PreviousState, State,
    Previous_Address, Address,
    ApexStatus
FROM BI_DB_dbo.BI_DB_US_Apex_Address_Change
WHERE PreviousState != State
    AND PreviousState IS NOT NULL
    AND ChangeDate >= DATEADD(MONTH, -3, GETDATE())
ORDER BY ChangeDate DESC
```

### 7.2 Address Changes on Non-Complete Apex Accounts

```sql
SELECT
    CID, ApexID, ApexStatus,
    ChangeDate,
    Previous_Address, Address,
    PreviousCity, City
FROM BI_DB_dbo.BI_DB_US_Apex_Address_Change
WHERE ApexStatus NOT IN ('COMPLETE', '')
ORDER BY ChangeDate DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 4 T1, 13 T2, 0 T3, 0 T4, 1 T5 | Elements: 18/18, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_US_Apex_Address_Change | Type: Table | Production Source: Fact_SnapshotCustomer + Dim_Customer + USABroker Apex*

# BackOffice.GetSetupAlertForHrcCountries

> Returns customers recently verified in High Risk Countries (HRC) who had a BackOffice profile change in the last 4 hours - used to trigger risk alerts for new account setups from HRC jurisdictions.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; returns Customer.CustomerStatic rows matching HRC + verification + recency criteria |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetSetupAlertForHrcCountries` identifies newly verified customers from High Risk Countries (HRC) whose accounts were recently updated in Back Office. It is a real-time monitoring procedure designed to alert risk operators about suspicious account setup activity: a customer registered from one of the designated HRC jurisdictions (hardcoded list of 34 CountryIDs), verified (VerificationLevelID > 0), registered after 2020-01-17, with a BackOffice profile change in the last 4 hours.

The 4-hour window is computed dynamically: `History.BackOfficeCustomer.ValidFrom > DATEADD(MINUTE, -240, GETDATE())`. The procedure was created for Jira story RD-20136 (Setup alert for HRC countries).

---

## 2. Business Logic

### 2.1 HRC Country Filter (Hardcoded)

**What**: Restricts output to customers whose registration country is on the High Risk Country list.

**Columns/Parameters Involved**: `Customer.CustomerStatic.CountryID`

**Rules**:
- Hardcoded list of 34 CountryIDs: 98, 104, 152, 38, 34, 140, 229, 18, 26, 111, 116, 215, 42, 68, 88, 89, 125, 187, 1, 25, 56, 90, 147, 31, 49, 2, 53, 141, 237, 193, 198, 210, 177, 157
- These correspond to jurisdictions classified as high risk for KYC/AML purposes (including but not limited to: Iran=98, Iraq=104, Libya=152, Afghanistan=38, Algeria=34, North Korea=140, Syria=229, etc.)
- No parameterization - list is static in DDL

### 2.2 Verification Requirement

**What**: Only returns customers who have passed at least the first level of identity verification.

**Columns/Parameters Involved**: `Customer.CustomerStatic.VerificationLevelID`

**Rules**:
- `VerificationLevelID > 0` - any verified state (excludes VerificationLevelID=0 = unverified/not started)
- Checked on both the outer query (BackOffice.Customer JOIN) and the inner subquery (CustomerStatic)
- The inner subquery also checks `VerificationLevelID > 0` to pre-filter before the outer CID IN check

### 2.3 Registration Cutoff Date

**What**: Excludes customers who registered before the HRC alert program began.

**Columns/Parameters Involved**: `Customer.CustomerStatic.Registered`

**Rules**:
- `Registered > '2020/01/17'` - only accounts registered after the alert program start date
- Accounts registered before this date are excluded regardless of HRC country or verification

### 2.4 Recent BackOffice Change (4-Hour Window)

**What**: Only returns customers with a BackOffice profile update in the last 4 hours.

**Columns/Parameters Involved**: `History.BackOfficeCustomer.ValidFrom`

**Rules**:
- `MAX(ValidFrom) > DATEADD(MINUTE, -240, GETDATE())` - the most recent BackOffice history record is within the past 4 hours
- Uses `GETDATE()` (local server time) - not `GETUTCDATE()` - which may cause timezone inconsistencies
- Subquery: `SELECT MAX(ValidFrom) FROM History.BackOfficeCustomer WHERE CID = bc.CID`
- This identifies accounts where BO staff just made a profile change, combined with HRC + verification criteria signals potential suspicious activity

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

None.

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID (Customer.CustomerStatic.CID). Primary customer identifier. |
| 2 | GCID | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Global Customer ID (Customer.CustomerStatic.GCID). Cross-system customer identifier. |
| 3 | Registered | DATETIME | NO | - | CODE-BACKED | Account registration timestamp (Customer.CustomerStatic.Registered). Always > 2020-01-17 for rows in this result. |
| 4 | VerificationLevelID | INT | NO | - | CODE-BACKED | Numeric KYC verification level (BackOffice.Customer.VerificationLevelID). Always > 0 for rows in this result. Not joined to Dictionary.VerificationLevel - raw ID is returned. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| bc.CID | BackOffice.Customer | Read (driving) | BO customer profile (verification level) |
| cc.CID | Customer.CustomerStatic | JOIN | Registration date, GCID, country, verification level |
| cc.CID (subquery) | Customer.CustomerStatic | Subquery | HRC country + verification filter |
| hb.CID | History.BackOfficeCustomer | Subquery (MAX ValidFrom) | Recent BO profile change detection |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Risk monitoring job/alert) | (scheduled call) | Application | Called by risk monitoring jobs or scheduled alerts to detect HRC setup activity |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetSetupAlertForHrcCountries (procedure)
├── BackOffice.Customer (table) - driving
├── Customer.CustomerStatic (table) - registration, country, GCID
└── History.BackOfficeCustomer (table) - recent change detection
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | Driving JOIN - VerificationLevelID |
| Customer.CustomerStatic | Table | JOIN and subquery - CountryID, Registered, CID, GCID |
| History.BackOfficeCustomer | Table | Subquery MAX(ValidFrom) - 4-hour recency check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by risk monitoring processes. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Hardcoded HRC country list | Implementation | 34 CountryIDs are hardcoded in the IN clause. Any change to the HRC list requires a DDL ALTER. |
| GETDATE() vs GETUTCDATE() | Implementation | Uses GETDATE() (server local time) for the 4-hour window, not GETUTCDATE(). Time zone-aware consumers should account for server TZ offset. |
| VerificationLevelID checked twice | Implementation | Once in outer query (BackOffice.Customer) and once in inner subquery (CustomerStatic). The subquery uses CustomerStatic.VerificationLevelID while the outer query uses BackOffice.Customer.VerificationLevelID - these may differ momentarily if not in sync. |
| Static registration cutoff | Data | '2020/01/17' is hardcoded - the alert program start date. Customers registered before this date are never returned. |

---

## 8. Sample Queries

### 8.1 Execute the alert check
```sql
EXEC [BackOffice].[GetSetupAlertForHrcCountries]
-- Returns all HRC customers with VerificationLevelID > 0, registered after 2020-01-17,
-- with a BO profile change in the last 4 hours.
```

### 8.2 Find HRC customers verified in the last 24 hours (extended window)
```sql
SELECT cc.CID, cc.GCID, cc.Registered, bc.VerificationLevelID
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Customer.CustomerStatic cc WITH (NOLOCK) ON bc.CID = cc.CID
WHERE cc.CountryID IN (98,104,152,38,34,140,229,18,26,111,116,215,42,68,88,89,125,187,1,25,56,90,147,31,49,2,53,141,237,193,198,210,177,157)
  AND bc.VerificationLevelID > 0
  AND cc.Registered > '2020/01/17'
  AND (SELECT MAX(ValidFrom) FROM History.BackOfficeCustomer hb WITH (NOLOCK) WHERE hb.CID = bc.CID) > DATEADD(HOUR, -24, GETDATE())
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| RD-20136 | Jira (DDL comment) | "Setup alert for HRC countries" - created Jan 2020 by Yulia Kramer |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira (RD-20136 from DDL comment only) | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetSetupAlertForHrcCountries | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetSetupAlertForHrcCountries.sql*

# BI_DB_dbo.BI_DB_KYC_DOBover85

> 3,137-row KYC compliance table listing fully verified customers who were aged 85 or older at registration. Filters: IsValidCustomer=1, PlayerStatusID=1 (Normal), VerificationLevelID=3 (fully verified), DATEDIFF(year, BirthDate, RegisteredReal)>=85. Includes electronic verification status and selfie/liveliness proof flag. Registration dates from Nov 2010 to Apr 2026, ages 85--126 (avg 97). Daily TRUNCATE+INSERT via SP_KYC_DOBover85.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (KYC Compliance -- Elderly Customer Watchlist) |
| **Production Source** | DWH_dbo.Dim_Customer + External BackOffice documents by SP_KYC_DOBover85 |
| **Refresh** | Daily TRUNCATE + INSERT (SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | -- |
| **UC Partitioned By** | -- |
| **UC Table Type** | -- |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |

---

## 1. Business Meaning

`BI_DB_KYC_DOBover85` is a **KYC compliance watchlist** identifying customers who were aged 85 or older at the time of registration. The table serves regulatory due diligence by flagging potentially suspicious registrations where the account holder's advanced age may indicate identity fraud, account misuse, or other compliance concerns.

The table holds 3,137 rows representing all active, fully verified customers meeting the age threshold. It is rebuilt daily via TRUNCATE+INSERT. The SP filters Dim_Customer for:
- `DATEDIFF(year, BirthDate, RegisteredReal) >= 85` -- age at registration was 85+
- `IsValidCustomer = 1` -- not a test/demo account
- `PlayerStatusID = 1` -- Normal (active) status
- `VerificationLevelID = 3` -- fully verified through KYC process

Each row is enriched with looked-up names (Regulation, Country, PlayerStatus, EvMatchStatusName) and a selfie/liveliness proof check from BackOffice document records.

### Key Statistics
- Age range: 85--126 years (average 97)
- Top regulations: CySEC (961), BVI (957), eToroUS (510), FCA (364)
- 79% have Verified electronic match status
- 54% have no first deposit (FTDDate = 1900-01-01 sentinel)
- 82% lack selfie/liveliness proof (IsSelfielivelinessProof = 1)

---

## 2. Business Logic

### 2.1 Age at Registration Filter

**What**: Identifies customers whose age at registration was 85+.
**Columns Involved**: BirthDate, Registered, AgeAtReg
**Rules**:
- `DATEDIFF(year, BirthDate, RegisteredReal) >= 85` applied in WHERE clause
- Age is recalculated at runtime: `DATEDIFF(year, BirthDate, GETDATE())` for current age
- AgeAtReg: `DATEDIFF(year, BirthDate, RegisteredReal)` frozen at registration time

### 2.2 Verification and Status Filters

**What**: Only fully verified, active customers are included.
**Columns Involved**: VerificationLevelID, PlayerStatus
**Rules**:
- VerificationLevelID = 3 (fully verified) -- all rows have this value
- PlayerStatusID = 1 (Normal) -- all rows show 'Normal' PlayerStatus
- IsValidCustomer = 1 (not test/demo)

### 2.3 Selfie/Liveliness Proof Flag

**What**: Checks whether the customer has submitted a selfie/liveliness document.
**Columns Involved**: IsSelfielivelinessProof
**Rules**:
- LEFT JOIN to External BackOffice CustomerDocument + DocumentToDocumentType
- DocumentTypeID = 18 (SelfieLiveliness)
- IsSelfielivelinessProof = 1 means proof is MISSING (customer NOT found in document table)
- IsSelfielivelinessProof = 0 means proof EXISTS
- **Inverted naming**: despite "Is...Proof" prefix, 1 = no proof, 0 = has proof

### 2.4 FTD Date Sentinel

**What**: First deposit date uses 1900-01-01 as sentinel for no deposit.
**Columns Involved**: FTDDate
**Rules**:
- 1900-01-01 = customer has never deposited (54% of rows)
- Other dates = actual first deposit date

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. Small table (3,137 rows). No index needed; full scans are instant.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customers aged 90+ without selfie proof | `WHERE Age >= 90 AND IsSelfielivelinessProof = 1` |
| Breakdown by regulation | `GROUP BY Regulation ORDER BY COUNT(*) DESC` |
| Recently registered elderly | `WHERE Registered >= '2025-01-01'` |
| Unverified electronic match | `WHERE EvMatchStatusName != 'Verified'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer profile |
| DWH_dbo.Dim_VerificationLevel | VerificationLevelID | Verification level name (always 3 here) |

### 3.4 Gotchas

- **IsSelfielivelinessProof naming is inverted**: 1 = proof MISSING, 0 = proof EXISTS. Do not confuse
- **FTDDate sentinel**: 1900-01-01 means no deposit, not Jan 1 1900
- **IsAddressProof/IsIDProof NULLs**: 2,109 NULLs (67%) -- primarily US regulation customers where these fields are not populated in Dim_Customer
- **Age 126**: Maximum age suggests possible data quality issues with BirthDate in source systems
- **DATEDIFF(year) is approximate**: Uses year boundary crossing, not exact age. A customer born Dec 31 1940 who registered Jan 1 2026 would show AgeAtReg=86 despite being 85 years and 1 day old

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki with documented production source |
| Tier 2 | Derived from SP code analysis with high confidence |
| Tier 3 | Inferred from data patterns and naming conventions |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer.RealCID. (Tier 1 -Customer.CustomerStatic) |
| 2 | BirthDate | datetime | YES | Customer date of birth. Used in KYC age verification. CAST to DATE from Dim_Customer.BirthDate. (Tier 1 -Customer.CustomerStatic) |
| 3 | Registered | datetime | YES | Account registration date. CAST to DATE from Dim_Customer.RegisteredReal. (Tier 1 -Customer.CustomerStatic) |
| 4 | Age | bigint | YES | Current age in years, recalculated daily. DATEDIFF(year, BirthDate, GETDATE()). Range: 85--126. Uses year-boundary crossing, not exact birthday. (Tier 2 -SP_KYC_DOBover85) |
| 5 | AgeAtReg | bigint | YES | Age at time of registration in years. DATEDIFF(year, BirthDate, RegisteredReal). This is the primary filter criterion (>=85). Frozen at registration time. (Tier 2 -SP_KYC_DOBover85) |
| 6 | VerificationLevelID | bigint | YES | KYC verification level. FK to Dictionary.VerificationLevel. 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Always 3 in this table (filter condition). (Tier 1 -BackOffice.Customer) |
| 7 | FTDDate | datetime | YES | Date of first deposit. CAST to DATE from Dim_Customer.FirstDepositDate. 1900-01-01 = no deposit (54% of rows). (Tier 2 -SP_Dim_Customer via Dim_Customer) |
| 8 | Regulation | nvarchar(max) | YES | Regulation name. JOIN lookup from Dim_Regulation.Name on Dim_Customer.RegulationID. Top values: CySEC, BVI, eToroUS, FCA, FinCEN+FINRA. (Tier 2 -SP_KYC_DOBover85 via Dim_Regulation) |
| 9 | Country | nvarchar(max) | YES | Country of registration. JOIN lookup from Dim_Country.Name on Dim_Customer.CountryID. (Tier 2 -SP_KYC_DOBover85 via Dim_Country) |
| 10 | PlayerStatus | nvarchar(max) | YES | Player status name. LEFT JOIN from Dim_PlayerStatus.Name on Dim_Customer.PlayerStatusID. Always 'Normal' in this table (filter: PlayerStatusID=1). (Tier 2 -SP_KYC_DOBover85 via Dim_PlayerStatus) |
| 11 | IsAddressProof | bigint | YES | Whether address proof document is on file (1/0). Passthrough from Dim_Customer. NULL for 67% of rows (primarily US regulation customers). (Tier 2 -SP_Dim_Customer via Dim_Customer) |
| 12 | IsIDProof | bigint | YES | Whether ID proof document is on file (1/0). Passthrough from Dim_Customer. NULL for 67% of rows (primarily US regulation customers). (Tier 2 -SP_Dim_Customer via Dim_Customer) |
| 13 | EvMatchStatusName | nvarchar(max) | YES | Electronic verification match status name. LEFT JOIN from Dim_EvMatchStatus on Dim_Customer.EvMatchStatus. Values: Verified (79%), None (16%), NotVerified (3%), PartiallyVerified (1%). (Tier 2 -SP_KYC_DOBover85 via Dim_EvMatchStatus) |
| 14 | IsSelfielivelinessProof | bigint | YES | Flag indicating whether selfie/liveliness proof document is MISSING. 1=no SelfieLiveliness document found (82%), 0=document exists (18%). Checked via LEFT JOIN to External_etoro_BackOffice_CustomerDocument + CustomerDocumentToDocumentType (DocumentTypeID=18). **Inverted naming**: 1 means proof is absent. (Tier 2 -SP_KYC_DOBover85) |
| 15 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_KYC_DOBover85. Set to GETDATE(). (Tier 5 -SP_KYC_DOBover85) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | Renamed passthrough |
| BirthDate | DWH_dbo.Dim_Customer | BirthDate | CAST to DATE |
| Registered | DWH_dbo.Dim_Customer | RegisteredReal | CAST to DATE, renamed |
| Age | Computed | BirthDate, GETDATE() | DATEDIFF(year) |
| AgeAtReg | Computed | BirthDate, RegisteredReal | DATEDIFF(year) |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough (always 3) |
| FTDDate | DWH_dbo.Dim_Customer | FirstDepositDate | CAST to DATE, renamed |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on RegulationID |
| Country | DWH_dbo.Dim_Country | Name | JOIN on CountryID |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN on PlayerStatusID |
| IsAddressProof | DWH_dbo.Dim_Customer | IsAddressProof | Passthrough |
| IsIDProof | DWH_dbo.Dim_Customer | IsIDProof | Passthrough |
| EvMatchStatusName | DWH_dbo.Dim_EvMatchStatus | EvMatchStatusName | LEFT JOIN on EvMatchStatus |
| IsSelfielivelinessProof | External BackOffice docs | DocumentTypeID=18 | CASE WHEN NOT found THEN 1 ELSE 0 |
| UpdateDate | GETDATE() | -- | ETL timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (customer demographics, KYC, verification)
  + DWH_dbo.Dim_PlayerStatus (status name lookup)
  + DWH_dbo.Dim_Regulation (regulation name lookup)
  + DWH_dbo.Dim_Country (country name lookup)
  + DWH_dbo.Dim_EvMatchStatus (EV match status name lookup)
    |-- SP_KYC_DOBover85 (daily, TRUNCATE + INSERT) ---|
    |   Step 1: #CIDS = Dim_Customer WHERE AgeAtReg>=85 |
    |           AND IsValidCustomer=1 AND PlayerStatusID=1|
    |           AND VerificationLevelID=3                  |
    |           + JOIN lookups for names                   |
    v
  + External_etoro_BackOffice_CustomerDocument
  + External_etoro_BackOffice_CustomerDocumentToDocumentType
    |   Step 2: #SELFIELIVELINESS = customers with        |
    |           DocumentTypeID=18 (SelfieLiveliness)       |
    |   Step 3: #FINAL = LEFT JOIN → flag missing proof    |
    v
BI_DB_dbo.BI_DB_KYC_DOBover85 (3,137 rows, daily TRUNCATE)
  (Not in Generic Pipeline -- _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Full customer profile |
| Regulation | DWH_dbo.Dim_Regulation | Regulation details |
| Country | DWH_dbo.Dim_Country | Country details |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Player status details |
| EvMatchStatusName | DWH_dbo.Dim_EvMatchStatus | EV match status details |
| VerificationLevelID | Dictionary.VerificationLevel | Verification level name |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Customers Aged 90+ Missing Selfie Proof

```sql
SELECT CID, Age, AgeAtReg, Regulation, Country, EvMatchStatusName
FROM [BI_DB_dbo].[BI_DB_KYC_DOBover85]
WHERE Age >= 90
  AND IsSelfielivelinessProof = 1
ORDER BY Age DESC
```

### 7.2 Breakdown by Regulation and EV Match Status

```sql
SELECT Regulation,
       EvMatchStatusName,
       COUNT(*) AS customer_count,
       AVG(Age) AS avg_age
FROM [BI_DB_dbo].[BI_DB_KYC_DOBover85]
GROUP BY Regulation, EvMatchStatusName
ORDER BY customer_count DESC
```

### 7.3 Recently Registered Elderly Customers Without Deposit

```sql
SELECT CID, Age, AgeAtReg, Registered, Regulation, Country
FROM [BI_DB_dbo].[BI_DB_KYC_DOBover85]
WHERE FTDDate = '1900-01-01'
  AND Registered >= '2025-01-01'
ORDER BY Age DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 3 T1, 11 T2, 0 T3, 0 T4, 1 T5 | Elements: 15/15, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_KYC_DOBover85 | Type: Table | Production Source: Dim_Customer + External BackOffice docs*

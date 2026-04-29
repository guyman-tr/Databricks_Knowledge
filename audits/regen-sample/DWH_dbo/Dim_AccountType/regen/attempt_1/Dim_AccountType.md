# DWH_dbo.Dim_AccountType

> 19-row replicated dimension table classifying eToro accounts by ownership type and purpose (Private, Corporate, IB, Fund, Employee, etc.). Sourced from `etoro.Dictionary.AccountType` via `SP_Dictionaries_DL_To_Synapse` with daily full refresh (TRUNCATE + INSERT). Includes sentinel row 0=N/A.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.Dictionary.AccountType` via `SP_Dictionaries_DL_To_Synapse` |
| **Refresh** | Daily full refresh (TRUNCATE + INSERT), ~02:11 UTC |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override, daily, parquet) |

---

## 1. Business Meaning

Dim_AccountType is a small lookup table (19 rows) that classifies every eToro customer account into one of 17 categories based on ownership structure and operational purpose, plus a sentinel row (0=N/A). The classification drives which platform features are available, what regulatory rules apply, how fees are calculated, and how accounts are monitored for compliance.

Account types naturally cluster into five functional groups: Retail (Private, Joint, SMSF, Administrated), Corporate (Corporate, Affiliate Corporate), Partner (IB Account, White Label, Affiliate Private, White List), Internal (Employee, eToro Group, News, Analyst, Funded Employee), and Managed (Custodian, Fund).

The table is loaded daily by `SP_Dictionaries_DL_To_Synapse`, which truncates and reloads from `DWH_staging.etoro_Dictionary_AccountType` (sourced from production `etoro.Dictionary.AccountType` via Generic Pipeline Bronze export). After the main INSERT, a sentinel row (AccountTypeID=0, Name='N/A') is appended for FK safety. All StatusID values are hardcoded to 1.

---

## 2. Business Logic

### 2.1 Account Category Groups

**What**: Account types cluster into functional groups that determine system behavior across trading, compliance, billing, and reporting.
**Columns Involved**: AccountTypeID, Name
**Rules**:
- **Retail** (1=Private, 4=Joint Account, 14=SMSF, 16=Administrated Account): Standard users subject to full retail regulation
- **Corporate** (2=Corporate, 15=Affiliate Corporate Account): Business entities with enhanced KYC and reporting
- **Partner** (3=IB Account, 5=White Label, 6=Affiliate Private Account, 12=White List): Revenue-sharing arrangements with special fee/commission structures
- **Internal** (7=Employee Account, 10=eToro Group Account, 11=News, 13=Analyst, 17=Funded Employee Account): eToro-operated accounts with enhanced compliance monitoring
- **Managed** (8=Custodian, 9=Fund): Third-party managed accounts with fiduciary requirements
- **Sentinel** (0=N/A): Default/unknown, used for FK safety in DWH joins

### 2.2 Sentinel Row

**What**: SP inserts a hardcoded sentinel row after the main load.
**Columns Involved**: All columns
**Rules**:
- AccountTypeID=0, Name='N/A', DWHAccountTypeID=0, StatusID=1
- Ensures DWH fact tables can always resolve an AccountTypeID FK, even when the value is missing or unknown

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distribution — the full 19-row table is cached on every compute node. No movement cost on any JOIN. HEAP storage (no clustered index) — appropriate for this tiny table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What account types exist? | `SELECT * FROM DWH_dbo.Dim_AccountType WHERE AccountTypeID > 0 ORDER BY AccountTypeID` |
| Resolve a customer's account type | `JOIN DWH_dbo.Dim_AccountType dat ON c.AccountTypeID = dat.AccountTypeID` |
| Count customers by type | `GROUP BY dat.Name` after joining to Dim_Customer |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `Dim_Customer.AccountTypeID = Dim_AccountType.AccountTypeID` | Resolve customer's account classification |
| DWH_dbo.Fact_* tables | `Fact_X.AccountTypeID = Dim_AccountType.AccountTypeID` | Enrich facts with account type name |

### 3.4 Gotchas

- **Sentinel row**: AccountTypeID=0 ('N/A') is injected by the ETL — it does not exist in production `etoro.Dictionary.AccountType`. Exclude it (`WHERE AccountTypeID > 0`) when counting real account types.
- **DWHAccountTypeID always equals AccountTypeID**: The surrogate key column carries no additional information; it is a copy of the PK.
- **StatusID is always 1**: Hardcoded by the SP — not sourced from production. Do not filter on it expecting meaningful status logic.
- **Name column rename**: Production column is `AccountTypeName`; DWH renames it to `Name`.
- **18=Trust**: AccountTypeID 18 (Trust) appears in live data but is not in the upstream wiki's documented set (1-17). This may be a recently added type.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description inherited verbatim from upstream production wiki |
| Tier 2 | Description grounded in ETL stored procedure code |
| Tier 3 | No upstream or SP source; requires human review |
| Tier 4 | Inferred from column name only (banned unless no other evidence) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountTypeID | int | NO | Primary key identifying the account classification. 0=N/A (DWH sentinel), 1=Private, 2=Corporate, 3=IB Account, 4=Joint, 5=White Label, 6=Affiliate Private, 7=Employee, 8=Custodian, 9=Fund, 10=eToro Group, 11=News, 12=White List, 13=Analyst, 14=SMSF, 15=Affiliate Corporate, 16=Administrated, 17=Funded Employee, 18=Trust. Controls feature access, regulatory treatment, fee structures, and compliance monitoring level. (Tier 1 — Dictionary.AccountType) |
| 2 | Name | varchar(50) | YES | Human-readable label for the account type. Used in BackOffice UI, compliance reporting, and DWH exports. Renamed from `AccountTypeName` in production. (Tier 1 — Dictionary.AccountType) |
| 3 | DWHAccountTypeID | int | NO | DWH surrogate key. ETL-computed: always equals AccountTypeID (`[AccountTypeID] AS [DWHAccountTypeID]`). Carries no additional information beyond the PK. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | ETL status flag. Hardcoded to 1 for all rows by SP_Dictionaries_DL_To_Synapse. Not sourced from production. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp. Set to `GETDATE()` at each daily refresh. Reflects when the SP last ran, not when the source data changed. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | ETL insert timestamp. Set to `GETDATE()` at each daily refresh. Identical to UpdateDate because the SP does TRUNCATE + INSERT (no upsert logic). (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| AccountTypeID | etoro.Dictionary.AccountType | AccountTypeID | Passthrough. Sentinel 0=N/A added by SP. |
| Name | etoro.Dictionary.AccountType | AccountTypeName | Rename: AccountTypeName → Name |
| DWHAccountTypeID | (ETL-computed) | AccountTypeID | Copy of PK |
| StatusID | (ETL-computed) | — | Hardcoded 1 |
| UpdateDate | (ETL-computed) | — | GETDATE() |
| InsertDate | (ETL-computed) | — | GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.AccountType (production, etoroDB-REAL)
  |-- Generic Pipeline (Bronze export, Override, daily) ---|
  v
Bronze/etoro/Dictionary/AccountType/ (parquet, Data Lake)
  |-- External table / COPY INTO ---|
  v
DWH_staging.etoro_Dictionary_AccountType (staging)
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT + sentinel row) ---|
  v
DWH_dbo.Dim_AccountType (19 rows, REPLICATE)
  |-- Generic Pipeline (Gold export, Override, daily) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype (Unity Catalog, delta)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

This object has no outgoing references (it is a root lookup table).

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DWH_dbo.Dim_Customer | AccountTypeID | Implicit FK | Customer's account type classification |
| Various Fact_* tables | AccountTypeID | Implicit FK | Account type dimension for reporting |

---

## 7. Sample Queries

### 7.1 List all account types (excluding sentinel)

```sql
SELECT AccountTypeID, Name
FROM DWH_dbo.Dim_AccountType
WHERE AccountTypeID > 0
ORDER BY AccountTypeID;
```

### 7.2 Count customers per account type

```sql
SELECT dat.Name AS AccountType, COUNT(*) AS CustomerCount
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_AccountType dat ON dc.AccountTypeID = dat.AccountTypeID
WHERE dat.AccountTypeID > 0
GROUP BY dat.Name
ORDER BY CustomerCount DESC;
```

### 7.3 Identify all fund and custodian accounts

```sql
SELECT dc.RealCID, dc.UserName, dat.Name AS AccountType
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_AccountType dat ON dc.AccountTypeID = dat.AccountTypeID
WHERE dat.AccountTypeID IN (8, 9)
ORDER BY dc.RealCID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-27 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 8/10)*
*Tiers: 2 T1, 4 T2, 0 T3, 0 T4 | Elements: 6/6, Logic: 8/10, Relationships: 6/10, Sources: 8/10*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: DWH_dbo.Dim_AccountType | Type: Table | Production Source: etoro.Dictionary.AccountType via SP_Dictionaries_DL_To_Synapse*

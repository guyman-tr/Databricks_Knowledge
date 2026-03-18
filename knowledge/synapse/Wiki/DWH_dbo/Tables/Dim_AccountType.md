# DWH_dbo.Dim_AccountType

> Lookup table classifying eToro accounts by ownership type and purpose — Private, Corporate, IB, Fund, Employee, etc.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.AccountType |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, truncate-and-reload) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Dim_AccountType classifies every eToro account into one of 18 categories (17 real + 1 placeholder) based on ownership structure and operational purpose. This classification drives which platform features are available, what regulatory rules apply, how fees are calculated, and how the account is monitored for compliance.

The production source is `etoro.Dictionary.AccountType` on the etoroDB-REAL server. Data flows through the Generic Pipeline (daily, parquet, Override) into the data lake at `Bronze/etoro/Dictionary/AccountType/`, then into `DWH_staging.etoro_Dictionary_AccountType`, and finally into this table via SP_Dictionaries_DL_To_Synapse.

SP_Dictionaries_DL_To_Synapse TRUNCATEs and reloads daily. It renames `AccountTypeName` to `Name`, copies `AccountTypeID` as `DWHAccountTypeID` (redundant surrogate), hardcodes `StatusID=1`, and sets `UpdateDate/InsertDate` to GETDATE(). After the main INSERT, an ID=0 "N/A" placeholder row is added. Full production documentation: see upstream wiki `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountType.md`.

---

## 2. Business Logic

### 2.1 Account Category Groups

**What**: Account types cluster into functional groups that determine system behavior.

**Columns Involved**: `AccountTypeID`, `Name`

**Rules**:
- **Retail accounts** (1=Private, 4=Joint, 14=SMSF, 16=Administrated, 18=Trust): Standard users subject to full retail regulation
- **Corporate accounts** (2=Corporate, 15=Affiliate Corporate): Business entities with enhanced KYC and reporting
- **Partner accounts** (3=IB, 5=White Label, 6=Affiliate Private, 12=White List): Revenue-sharing arrangements with special fee/commission structures
- **Internal accounts** (7=Employee, 10=eToro Group, 11=News, 13=Analyst, 17=Funded Employee): eToro-operated accounts with enhanced compliance monitoring
- **Managed accounts** (8=Custodian, 9=Fund): Third-party managed accounts with fiduciary requirements

**Diagram**:
```
Dim_AccountType
├── Retail (standard users)
│   ├── 1: Private
│   ├── 4: Joint Account
│   ├── 14: SMSF
│   ├── 16: Administrated
│   └── 18: Trust
├── Corporate (business entities)
│   ├── 2: Corporate
│   └── 15: Affiliate Corporate
├── Partner (revenue-sharing)
│   ├── 3: IB Account
│   ├── 5: White Label
│   ├── 6: Affiliate Private Account
│   └── 12: White List
├── Internal (eToro-operated)
│   ├── 7: Employee Account
│   ├── 10: eToro Group Account
│   ├── 11: News
│   ├── 13: Analyst
│   └── 17: Funded Employee Account
└── Managed (third-party managed)
    ├── 8: Custodian
    └── 9: Fund
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a HEAP storage. With only 19 rows, it is cached on every compute node — JOINs are always local and extremely fast. PK constraint on AccountTypeID is declared but NOT ENFORCED (Synapse limitation).

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Count customers by account type | JOIN Dim_Customer on AccountTypeID, GROUP BY Name |
| Filter to retail accounts only | WHERE AccountTypeID IN (1, 4, 14, 16, 18) |
| Find fund/custodian managed accounts | WHERE AccountTypeID IN (8, 9) |
| Exclude internal/employee accounts | WHERE AccountTypeID NOT IN (7, 10, 11, 13, 17) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON Dim_Customer.AccountTypeID = Dim_AccountType.AccountTypeID | Resolve account type for customer records |
| DWH_dbo.Fact_SnapshotCustomer | ON Fact_SnapshotCustomer.AccountTypeID = Dim_AccountType.AccountTypeID | Resolve account type in daily customer snapshots |

### 3.4 Gotchas

- **Name vs AccountTypeName**: Production uses `AccountTypeName`; DWH renames it to `Name`. Queries expecting `AccountTypeName` will fail.
- **DWHAccountTypeID** always equals AccountTypeID — it is a redundant DWH surrogate with no independent value. Use AccountTypeID for JOINs.
- AccountTypeID=0 ("N/A") is a DWH-only placeholder. It does not exist in production. Exclude it when counting real types.
- StatusID is always 1 — ETL metadata, not a business column.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★★★ (4) | Tier 1 | Upstream wiki verbatim — expert-reviewed production documentation |
| ★★★ (3) | Tier 2 | Synapse SP code — verified from ETL procedure logic |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountTypeID | int | NO | Primary key identifying the account classification. 1=Private, 2=Corporate, 3=IB Account, 4=Joint, 5=White Label, 6=Affiliate Private, 7=Employee, 8=Custodian, 9=Fund, 10=eToro Group, 11=News, 12=White List, 13=Analyst, 14=SMSF, 15=Affiliate Corporate, 16=Administrated, 17=Funded Employee, 18=Trust. Controls feature access, regulatory treatment, fee structures, and compliance monitoring level. DWH note: widened from tinyint to int; includes ID=0 "N/A" placeholder. (Tier 1 — upstream wiki, Dictionary.AccountType) |
| 2 | Name | varchar(50) | YES | Human-readable label for the account type. Used in BackOffice UI, compliance reporting, and DWH exports. DWH note: renamed from `AccountTypeName` in production source. (Tier 1 — upstream wiki, Dictionary.AccountType) |
| 3 | DWHAccountTypeID | int | NO | DWH surrogate key — always equals AccountTypeID. Assigned by SP_Dictionaries as `[AccountTypeID] as [DWHAccountTypeID]`. Redundant column with no independent business value. (Tier 2 — Synapse SP code, SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | ETL metadata: hardcoded to 1 by SP_Dictionaries_DL_To_Synapse. Always equals 1 for all rows. Not a business column. (Tier 2 — Synapse SP code, SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last refreshed by the ETL pipeline. Set to GETDATE() on every SP_Dictionaries run. (Tier 2 — Synapse SP code, SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | ETL metadata: timestamp when this row was inserted by the ETL pipeline. Set to GETDATE() on every SP_Dictionaries run. Because the table is truncated daily, this always equals UpdateDate. (Tier 2 — Synapse SP code, SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| AccountTypeID | Dictionary.AccountType | AccountTypeID | None (passthrough) |
| Name | Dictionary.AccountType | AccountTypeName | Renamed: AccountTypeName → Name |
| DWHAccountTypeID | Dictionary.AccountType | AccountTypeID | Copy: AccountTypeID as DWHAccountTypeID |
| StatusID | — | — | Hardcoded to 1 by SP_Dictionaries_DL_To_Synapse |
| UpdateDate | — | — | GETDATE() by SP_Dictionaries_DL_To_Synapse |
| InsertDate | — | — | GETDATE() by SP_Dictionaries_DL_To_Synapse |

Full production documentation: see upstream wiki `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountType.md`.

### 5.2 ETL Pipeline

```
etoro.Dictionary.AccountType → Generic Pipeline (daily, parquet) → DWH_staging.etoro_Dictionary_AccountType → SP_Dictionaries_DL_To_Synapse → DWH_dbo.Dim_AccountType
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.AccountType | Production account type lookup on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/AccountType/ | Daily parquet export via Generic Pipeline (Override) |
| Staging | DWH_staging.etoro_Dictionary_AccountType | Raw import into Synapse staging schema |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; renames AccountTypeName→Name, adds DWHAccountTypeID=AccountTypeID, StatusID=1, GETDATE() timestamps, ID=0 placeholder |
| Target | DWH_dbo.Dim_AccountType | Final DWH dimension table |

---

## 6. Relationships

### 6.1 References To (this object points to)

This object has no outgoing references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | AccountTypeID | Stores the account type for each customer — primary DWH consumer |
| DWH_dbo.Fact_SnapshotCustomer | AccountTypeID | Daily customer snapshot includes account type |

---

## 7. Sample Queries

### 7.1 List all account types
```sql
SELECT  AccountTypeID,
        Name AS AccountTypeName
FROM    [DWH_dbo].[Dim_AccountType]
WHERE   AccountTypeID > 0
ORDER BY AccountTypeID;
```

### 7.2 Count customers by account type group
```sql
SELECT  dat.Name AS AccountType,
        COUNT(*) AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_AccountType] dat
        ON dc.AccountTypeID = dat.AccountTypeID
WHERE   dat.AccountTypeID > 0
GROUP BY dat.Name
ORDER BY CustomerCount DESC;
```

### 7.3 Find all internal/employee accounts
```sql
SELECT  dc.CID,
        dc.UserName,
        dat.Name AS AccountType
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_AccountType] dat
        ON dc.AccountTypeID = dat.AccountTypeID
WHERE   dat.AccountTypeID IN (7, 10, 11, 13, 17)
ORDER BY dat.Name, dc.CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from upstream wiki and ETL code analysis.

---

*Generated: 2026-03-18 | Quality: 8.2/10 (★★★★☆) | Phases: 7/14*
*Tiers: 2 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_AccountType | Type: Table | Production Source: etoro/Dictionary/AccountType*

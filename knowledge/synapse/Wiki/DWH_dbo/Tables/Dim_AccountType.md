# DWH_dbo.Dim_AccountType

> Lookup dimension classifying eToro accounts by ownership type and purpose. Controls feature access, regulatory treatment, fee structures, and compliance monitoring. Sourced daily from etoro.Dictionary.AccountType via SP_Dictionaries_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.AccountType |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_AccountType is the DWH version of etoro.Dictionary.AccountType. It classifies every eToro account into one of 18 categories based on ownership structure and operational purpose. This classification drives which platform features are available, what regulatory rules apply, how fees are calculated, and how accounts are monitored for compliance.

Source: etoro.Dictionary.AccountType on etoroDB-REAL. The production table is exported daily to Bronze/etoro/Dictionary/AccountType/ and staged into DWH_staging.etoro_Dictionary_AccountType. SP_Dictionaries_DL_To_Synapse loads from that staging table using a TRUNCATE + INSERT pattern.

The DWH table has 19 rows: IDs 0-18. ID=0 (N/A) is a DWH placeholder row from the production source itself (no separate placeholder insert in the SP). DWHAccountTypeID is set equal to AccountTypeID by the ETL and carries no additional information. StatusID is hardcoded to 1. UpdateDate and InsertDate are both set to GETDATE() at load time.

Account types are assigned at customer registration and stored in Customer.CustomerStatic. They are read across BackOffice, Trade, Hedge, Billing, and Compliance systems. The account type rarely changes after initial assignment.

---

## 2. Business Logic

### 2.1 Account Category Groups

**What**: Account types cluster into functional groups that determine system behavior, regulatory treatment, and fee structures.

**Columns Involved**: `AccountTypeID`, `Name`

**Rules**:
- Retail accounts (1=Private, 4=Joint, 14=SMSF, 16=Administrated): Standard users subject to full retail regulation
- Corporate accounts (2=Corporate, 15=Affiliate Corporate): Business entities with enhanced KYC and reporting
- Partner accounts (3=IB, 5=White Label, 6=Affiliate Private, 12=White List): Revenue-sharing arrangements with special fee/commission structures
- Internal accounts (7=Employee, 10=eToro Group, 11=News, 13=Analyst, 17=Funded Employee): eToro-operated accounts with enhanced compliance monitoring
- Managed accounts (8=Custodian, 9=Fund): Third-party managed accounts with fiduciary requirements
- 18=Trust: Registered after the upstream wiki was generated; classification consistent with retail/managed category
- AccountTypeID=0 (N/A): DWH placeholder for NULL-safe JOINs

**Value Map** (19 rows in DWH):

| AccountTypeID | Name | Category |
|---|---|---|
| 0 | N/A | DWH placeholder |
| 1 | Private | Retail |
| 2 | Corporate | Corporate |
| 3 | IB Account | Partner |
| 4 | Joint Account | Retail |
| 5 | White Label | Partner |
| 6 | Affiliate Private Account | Partner |
| 7 | Employee Account | Internal |
| 8 | Custodian | Managed |
| 9 | Fund | Managed |
| 10 | eToro Group Account | Internal |
| 11 | News | Internal |
| 12 | White List | Partner |
| 13 | Analyst | Internal |
| 14 | SMSF | Retail |
| 15 | Affiliate Corporate Account | Corporate |
| 16 | Administrated Account | Retail |
| 17 | Funded Employee Account | Internal |
| 18 | Trust | Retail/Managed |

### 2.2 Fund and Copy Trading Routing

**What**: AccountTypeID=9 (Fund) receives special handling in copy trading and fund management.

**Columns Involved**: `AccountTypeID`

**Rules**:
- AccountTypeID=9 (Fund) accounts have special copy-trading settlement restrictions
- Fund allocation procedures route based on account type
- Hedge procedures use account type to route to correct liquidity accounts

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE distributed with a HEAP index. REPLICATE is correct for a 19-row lookup -- every distribution node holds a local copy, eliminating data movement on JOINs with fact tables. HEAP is appropriate for a table this small with no range queries.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, no partitioning needed for a 19-row reference table. Expected as a MANAGED Delta table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All retail (Private) customers | JOIN Dim_Customer ON AccountTypeID, filter AccountTypeID = 1 |
| Fund accounts and their performance | JOIN fact tables on CID, filter AccountTypeID = 9 |
| Internal vs external account split | CASE WHEN AccountTypeID IN (7,10,11,13,17) THEN 'Internal' ELSE 'External' END |
| Resolve type ID to name | JOIN Dim_AccountType ON AccountTypeID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON Dim_Customer.AccountTypeID = Dim_AccountType.AccountTypeID | Resolve account type for each customer |

### 3.4 Gotchas

- **DWHAccountTypeID = AccountTypeID**: This column is always equal to AccountTypeID. It is an ETL artifact with no additional information -- do not use it as a join key when AccountTypeID is available.
- **Name, not AccountTypeName**: The DWH column is called `Name` (not `AccountTypeName` like the production source). When joining or comparing to upstream wikis, note the rename.
- **ID=0 from production source**: Unlike other DWH Dim_ tables, the ID=0 (N/A) placeholder row comes from the production Dictionary.AccountType table itself, not from an explicit DWH SP insert.
- **18=Trust not in upstream wiki**: Type 18 (Trust) appears in the DWH live data but was added after the upstream Dictionary.AccountType wiki was generated.
- **StatusID always 1**: Hardcoded by ETL convention, carries no business meaning.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.AccountType) |
| 3 stars | Tier 2 - SP ETL code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountTypeID | int | NOT NULL | Primary key identifying the account classification. 0=N/A (DWH placeholder), 1=Private, 2=Corporate, 3=IB Account, 4=Joint Account, 5=White Label, 6=Affiliate Private, 7=Employee, 8=Custodian, 9=Fund, 10=eToro Group, 11=News, 12=White List, 13=Analyst, 14=SMSF, 15=Affiliate Corporate, 16=Administrated, 17=Funded Employee, 18=Trust. Controls feature access, regulatory treatment, fee structures, and compliance monitoring level. Referenced by Dim_Customer.AccountTypeID. (Tier 1 - upstream wiki, Dictionary.AccountType) |
| 2 | Name | varchar(50) | NOT NULL | Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification. (Tier 1 - upstream wiki, Dictionary.AccountType) |
| 3 | DWHAccountTypeID | int | NOT NULL | ETL surrogate key. Set equal to AccountTypeID by SP_Dictionaries_DL_To_Synapse (SELECT AccountTypeID AS DWHAccountTypeID). Carries no additional information beyond AccountTypeID. Present for DWH schema consistency with other Dim_ tables. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | NOT NULL | ETL-internal active-row indicator. Hardcoded to 1 by SP_Dictionaries_DL_To_Synapse for all rows. Not from the production source; carries no business meaning. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect when the production value changed. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | NOT NULL | ETL load timestamp for row (re-)insertion. Set to GETDATE() on every reload (TRUNCATE + INSERT pattern). Always equals UpdateDate on this table. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| AccountTypeID | etoro.Dictionary.AccountType | AccountTypeID | Passthrough |
| Name | etoro.Dictionary.AccountType | AccountTypeName | Passthrough (renamed) |
| DWHAccountTypeID | etoro.Dictionary.AccountType | AccountTypeID | ETL-computed: SELECT AccountTypeID AS DWHAccountTypeID |
| StatusID | - | - | ETL-computed: hardcoded to 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() at load time |
| InsertDate | - | - | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
etoro.Dictionary.AccountType -> Generic Pipeline (daily, Override) -> Bronze/etoro/Dictionary/AccountType/ -> DWH_staging.etoro_Dictionary_AccountType -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_AccountType
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.AccountType | 19-row production lookup (etoroDB-REAL) |
| Lake | Bronze/etoro/Dictionary/AccountType/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Dictionary_AccountType | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; DWHAccountTypeID=AccountTypeID; StatusID=1; UpdateDate/InsertDate=GETDATE() |
| Target | DWH_dbo.Dim_AccountType | 19 rows (ID=0 through ID=18) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AccountTypeID | etoro.Dictionary.AccountType | Production source (upstream reference) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | AccountTypeID | Customer account type lookup (primary consumer in DWH) |

---

## 7. Sample Queries

### 7.1 List all account types

```sql
SELECT AccountTypeID, Name
FROM [DWH_dbo].[Dim_AccountType]
ORDER BY AccountTypeID
-- Returns: 0=N/A, 1=Private, 2=Corporate ... 18=Trust
```

### 7.2 Count customers by account type

```sql
SELECT
    dat.Name AS AccountTypeName,
    COUNT(*) AS CustomerCount
FROM [DWH_dbo].[Dim_Customer] dc
JOIN [DWH_dbo].[Dim_AccountType] dat
    ON dc.AccountTypeID = dat.AccountTypeID
WHERE dat.AccountTypeID > 0
GROUP BY dat.Name
ORDER BY CustomerCount DESC
```

### 7.3 Internal vs external account breakdown

```sql
SELECT
    CASE
        WHEN AccountTypeID IN (7, 10, 11, 13, 17) THEN 'Internal'
        WHEN AccountTypeID = 0 THEN 'Placeholder'
        ELSE 'External'
    END AS AccountCategory,
    COUNT(*) AS CustomerCount
FROM [DWH_dbo].[Dim_Customer]
GROUP BY
    CASE
        WHEN AccountTypeID IN (7, 10, 11, 13, 17) THEN 'Internal'
        WHEN AccountTypeID = 0 THEN 'Placeholder'
        ELSE 'External'
    END
ORDER BY CustomerCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-18 | Quality: 8.0/10 (4 stars) | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 2 T1, 4 T2, 0 T3, 0 T4-Inferred, 0 T5 | Elements: 10.0/10, Logic: 8.0/10, Relationships: 5.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_AccountType | Type: Table | Production Source: etoro.Dictionary.AccountType*

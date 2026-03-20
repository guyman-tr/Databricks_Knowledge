# DWH_dbo.Dim_BonusType

> Lookup dimension classifying customer credit adjustments (bonuses) by type, covering Sales, Marketing, Retention, Accounting, R&D, and operational categories. Sourced daily from etoro.BackOffice.BonusType via SP_Dictionaries_DL_To_Synapse. 66 rows (IDs 0-71 with gaps).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.BackOffice.BonusType |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (BonusTypeID) |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_BonusType is a simplified DWH version of etoro.BackOffice.BonusType -- the master catalog of bonus categories. Every credit adjustment (bonus) issued to a customer references a BonusTypeID to classify what kind of promotion or operational adjustment it represents. Types span sales-driven first-deposit promotions, retention loyalty programs, accounting/ops fee adjustments, R&D technical credits, and MT4 platform fund transfers.

Source: etoro.BackOffice.BonusType on etoroDB-REAL. Exported daily to Bronze/etoro/BackOffice/BonusType/ and staged into DWH_staging.etoro_BackOffice_BonusType. SP_Dictionaries_DL_To_Synapse loads using a TRUNCATE + INSERT pattern.

**Important**: The DWH loads only 4 of 9 production columns. Excluded: ParentID (departmental hierarchy), DisplayName (customer-facing label), IsDepositRelated, HideFromAffwiz, Configuration. Analysts cannot reconstruct the bonus type hierarchy in DWH without the ParentID column.

66 rows: IDs 0-71 with gaps at 60-65. All IsWithdrawable=False. IsActive=False for IDs 0, 17 (Refill-Negative Balance), and 23 (Championship Winner Demo). DWHBonusTypeID always equals BonusTypeID. StatusID hardcoded to 1.

---

## 2. Business Logic

### 2.1 Bonus Type Categories

**What**: Bonus types organize credit adjustments by the department or system that issues them.

**Columns Involved**: `BonusTypeID`, `Name`

**Rules**:
- Root category nodes (9 roots in production, identified by their ParentID) are NOT preserved in DWH -- DWH has a flat list only
- Functional groups present in the live data:

| BonusTypeID | Category | Examples |
|-------------|----------|---------|
| 3, 59 | Custom / ad-hoc | Custom, Share and Copy Bonus |
| 8, 13, 14, 17, 20, 38, 50, 66, 67, 68 | Accounting / Ops | Satisfaction Bonus, Dormant Fee, Foreclosure, Cashout Fee Reimbursment |
| 9 | R&D | R&D (technical credits) |
| 10, 5, 24, 30, 41, 71 | Retention | Retention Deposit Bonus, Club Bonus, Rebate |
| 26, 1, 2, 7, 11, 28, 29, 45, 46, 47 | Sales / Marketing | First Registration Bonus, Inviting Friend, Marketing Deposit Bonus |
| 34, 35, 36, 51 | ACT platform | ACT, Transfer to/from ACT |
| 44, 6, 12, 56 | Marketing / IB | Marketing Affiliate, Lot Count Bonus |
| 52, 53, 54, 55 | MT4 platform | MT4, Transfer to/from MT4 |
| 57, 58 | Employee programs | Employees Trading Program, Guru Second Income |

### 2.2 IsActive Flag

**What**: Flags whether a bonus type is still in active use.

**Columns Involved**: `BonusTypeID`, `IsActive`

**Rules**:
- IsActive=False: BonusTypeID 0 (N/A placeholder), 17 (Refill-Negative Balance), 23 (Championship Winner Demo under old Retention category)
- All other 63 types are IsActive=True
- When filtering for usable bonus types in analysis, exclude IsActive=False rows

### 2.3 IsWithdrawable Flag

**What**: Whether the bonus amount can be withdrawn by the customer.

**Columns Involved**: `IsWithdrawable`

**Rules**:
- All 66 rows (including ID=0) have IsWithdrawable=False
- This flag is either a planned feature never activated, or bonus withdrawability is managed elsewhere in the bonus lifecycle (not via this flag in DWH)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE distributed with a CLUSTERED INDEX on BonusTypeID. REPLICATE is correct for 66 rows. The clustered index on BonusTypeID optimizes point lookups from bonus fact tables.

**Type note**: BonusTypeID and DWHBonusTypeID are smallint in DWH (vs int IDENTITY in production). Maximum safe value is 32,767.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, no partitioning needed for 66 rows. Expected as a MANAGED Delta table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All active bonus types | WHERE IsActive = 1 |
| Bonus activity by type | JOIN fact bonus table ON BonusTypeID |
| Resolve BonusTypeID to Name | JOIN Dim_BonusType ON BonusTypeID |

### 3.3 Gotchas

- **Hierarchy not in DWH**: The production table has a ParentID column creating a 2-level departmental hierarchy (9 root categories, 61 child types). This hierarchy is NOT loaded into DWH. All 66 rows appear as a flat list.
- **DisplayName excluded**: Production has both Name (internal) and DisplayName (customer-facing statement label). DWH only has Name (internal). The DWH Name column is the BackOffice internal name, NOT what customers see.
- **IsDepositRelated excluded**: The flag indicating whether a bonus type was issued in connection with a deposit event is not in DWH. Deposit-related bonus analysis requires joining to production source or fact tables.
- **DWHBonusTypeID = BonusTypeID**: Always equal. ETL artifact with no additional information.
- **BonusTypeID is smallint** (not int): Type difference from production (int IDENTITY). Current max ID=71 is well within smallint range.
- **All IsWithdrawable=False**: This flag carries no useful information in the current data.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, BackOffice.BonusType) |
| 3 stars | Tier 2 - SP ETL code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | BonusTypeID | smallint | YES | Primary key identifying the bonus category. 0=N/A (DWH placeholder), 1=First Registration Bonus, 2=Sales First Deposit Bonus, 3=Custom, ... 71=Credit Line. 66 rows, IDs 0-71 with gaps 60-65. Smallint in DWH vs int IDENTITY in production. (Tier 1 - upstream wiki, BackOffice.BonusType) |
| 2 | Name | varchar(50) | NOT NULL | Internal BackOffice name for the bonus type. Used by BackOffice staff for reporting and operational routing. This is NOT the customer-facing label -- production also has a DisplayName column (excluded from DWH). Note: some names contain typos from production (e.g., "Cashout Fee Reimbursment" - misspelling of "Reimbursement"). (Tier 1 - upstream wiki, BackOffice.BonusType) |
| 3 | IsWithdrawable | bit | NOT NULL | Whether the bonus amount can be withdrawn by the customer. False (0) for ALL 66 rows in the DWH -- this field is either a planned feature not yet activated or withdrawability is controlled elsewhere in the bonus lifecycle. (Tier 1 - upstream wiki, BackOffice.BonusType) |
| 4 | IsActive | bit | NOT NULL | Whether this bonus type is still in active use. False for IDs 0 (N/A placeholder), 17 (Refill-Negative Balance), and 23 (Championship Winner Demo). True for all other 63 types. (Tier 1 - upstream wiki, BackOffice.BonusType) |
| 5 | DWHBonusTypeID | smallint | NOT NULL | ETL surrogate key. Set equal to BonusTypeID by SP_Dictionaries_DL_To_Synapse (SELECT BonusTypeID AS DWHBonusTypeID). Always equals BonusTypeID; carries no additional information. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | StatusID | int | YES | ETL-internal active-row indicator. Hardcoded to 1 for all rows by SP_Dictionaries_DL_To_Synapse. Not from the production source; carries no business meaning. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 7 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() on each daily reload. Monitor for freshness -- live data shows last load 2026-03-11. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 8 | InsertDate | datetime | YES | ETL load timestamp for row (re-)insertion. Set to GETDATE() on every reload (TRUNCATE + INSERT). Always equals UpdateDate on this table. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| BonusTypeID | etoro.BackOffice.BonusType | BonusTypeID | Passthrough (smallint cast from int) |
| Name | etoro.BackOffice.BonusType | Name | Passthrough |
| IsWithdrawable | etoro.BackOffice.BonusType | IsWithdrawable | Passthrough |
| IsActive | etoro.BackOffice.BonusType | IsActive | Passthrough |
| DWHBonusTypeID | etoro.BackOffice.BonusType | BonusTypeID | ETL-computed: SELECT BonusTypeID AS DWHBonusTypeID |
| StatusID | - | - | ETL-computed: hardcoded to 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() at load time |
| InsertDate | - | - | ETL-computed: GETDATE() at load time |
| *(not in DWH)* | etoro.BackOffice.BonusType | ParentID | Excluded -- departmental hierarchy not loaded |
| *(not in DWH)* | etoro.BackOffice.BonusType | DisplayName | Excluded -- customer-facing label not loaded |
| *(not in DWH)* | etoro.BackOffice.BonusType | IsDepositRelated | Excluded |
| *(not in DWH)* | etoro.BackOffice.BonusType | HideFromAffwiz | Excluded |
| *(not in DWH)* | etoro.BackOffice.BonusType | Configuration | Excluded (xml) |

### 5.2 ETL Pipeline

```
etoro.BackOffice.BonusType -> Generic Pipeline (daily, Override) -> Bronze/etoro/BackOffice/BonusType/ -> DWH_staging.etoro_BackOffice_BonusType -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_BonusType
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.BackOffice.BonusType | 66-row bonus category catalog (etoroDB-REAL) |
| Lake | Bronze/etoro/BackOffice/BonusType/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_BackOffice_BonusType | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; 4 of 9 columns loaded; DWHBonusTypeID=BonusTypeID; StatusID=1; UpdateDate/InsertDate=GETDATE() |
| Target | DWH_dbo.Dim_BonusType | 66 rows (ID=0 through ID=71 with gaps) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| BonusTypeID | etoro.BackOffice.BonusType | Production source (upstream reference) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Fact bonus tables | BonusTypeID | Resolve bonus type for each customer credit adjustment |

---

## 7. Sample Queries

### 7.1 List all active bonus types

```sql
SELECT BonusTypeID, Name, IsWithdrawable, IsActive
FROM [DWH_dbo].[Dim_BonusType]
WHERE IsActive = 1
ORDER BY BonusTypeID
```

### 7.2 Count bonuses by type (illustrative - replace fact table reference)

```sql
SELECT
    dbt.Name AS BonusTypeName,
    COUNT(*) AS BonusCount
FROM [DWH_dbo].[Fact_Bonus] fb    -- adjust to actual fact table name
JOIN [DWH_dbo].[Dim_BonusType] dbt ON fb.BonusTypeID = dbt.BonusTypeID
WHERE dbt.IsActive = 1
GROUP BY dbt.Name
ORDER BY BonusCount DESC
```

### 7.3 ETL freshness check

```sql
SELECT MAX(UpdateDate) AS LastLoad, COUNT(*) AS RowCount
FROM [DWH_dbo].[Dim_BonusType]
-- UpdateDate should equal today's date if ETL ran successfully
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-18 | Quality: 7.8/10 (4 stars) | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 4 T1, 4 T2, 0 T3, 0 T4-Inferred, 0 T5 | Elements: 9.0/10, Logic: 7.0/10, Relationships: 4.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_BonusType | Type: Table | Production Source: etoro.BackOffice.BonusType*

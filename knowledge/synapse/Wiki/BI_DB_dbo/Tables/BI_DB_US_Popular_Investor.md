# BI_DB_dbo.BI_DB_US_Popular_Investor

> 3.2K-row US Popular Investor eligibility assessment table. Identifies US customers passing ALL qualification gates: VL3, depositor, 35/35 days active, position activity in 30 days, max risk score, equity >= $100, privacy policy, recent login. Daily TRUNCATE+INSERT via SP_US_Popular_Investor (no @Date parameter — uses yesterday internally).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + V_Liabilities + Fact_CustomerAction + BI_DB_CIDFirstDates + BI_DB_CID_DailyPanel_FullData via `SP_US_Popular_Investor` |
| **Refresh** | Daily (TRUNCATE+INSERT, no date parameter) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (RealCID) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | — |
| **Row Count** | ~3,151 (as of 2026-04-27) |

---

## 1. Business Meaning

`BI_DB_US_Popular_Investor` is a daily eligibility snapshot for the US Popular Investor program. It contains only US customers (CountryID=219) who pass every qualification gate in a multi-step pipeline:

1. **Base population**: US depositors with PrivacyPolicyID=1, IsValidCustomer=1, IsDepositor=1, FirstPosOpenDate NOT NULL, VL3Date NOT NULL, LastLoggedIn within 30 days
2. **Activity gate**: Must be active ALL 35 of the last 35 days (SUM(Active)=35 from BI_DB_CID_DailyPanel_FullData)
3. **Position gate**: Must have opened/closed positions in last 30 days (ActionTypeID IN 1,2,3,4,5,6,28)
4. **Risk gate**: Max risk score over past 2 months from V_Liabilities.StandardDeviation, mapped to 1-10 scale
5. **Equity gate**: Equity (Liabilities + ActualNWA) >= $100

All gates are AND conditions (INNER JOIN). Copy data, copy block status, and AboutMe length are LEFT JOINed as supplemental fields.

As of 2026-04-27: 3,151 qualifying US customers. The AllowDisplayFullName column exists in DDL but is never populated by the SP (always NULL).

---

## 2. Business Logic

### 2.1 Multi-Step Qualification Pipeline

**What**: Five sequential filters that must ALL be passed.
**Columns Involved**: All — the table only contains customers who pass every gate.
**Rules**:
- Step 1 (#pop): US depositors from Dim_Customer JOIN BI_DB_CIDFirstDates. CountryID=219, PrivacyPolicyID=1, IsValidCustomer=1, IsDepositor=1, FirstPosOpenDate NOT NULL, VL3Date NOT NULL, LastLoggedIn within 30 days
- Step 2 (#Active): SUM(Active) = 35 from BI_DB_CID_DailyPanel_FullData (all 35 of last 35 days)
- Step 3 (#Position): COUNT from Fact_CustomerAction WHERE ActionTypeID IN (1,2,3,4,5,6,28) in last 30 days
- Step 4 (#Risk): MAX risk score mapped from V_Liabilities.StandardDeviation via threshold brackets (1-10 scale)
- Step 5 (#Equity): Equity = Liabilities + ActualNWA >= $100 from V_Liabilities
- Final: INNER JOIN all temp tables — must pass every gate

### 2.2 Risk Score Mapping

**What**: StandardDeviation from V_Liabilities is mapped to a 1-10 integer risk score.
**Columns Involved**: `MaxRiskScorePast2Months`
**Rules**:
- MAX of the mapped score over the past 2 months
- Mapping uses CASE WHEN threshold brackets on StandardDeviation
- Score range: 1 (lowest risk) to 10 (highest risk)

### 2.3 Supplemental Fields (LEFT JOIN)

**What**: Copy and profile data appended after qualification.
**Columns Involved**: `CopyAUM`, `NumOfCopiers`, `Is_Copy_Blocked`, `Number_of_characters_AboutMe`
**Rules**:
- CopyAUM and NumOfCopiers from BI_DB_CopyDailyData (ISNULL to 0)
- Is_Copy_Blocked: 1/0 from External_etoro_Customer_BlockedCustomerOperations WHERE OperationTypeID=2
- Number_of_characters_AboutMe: LEN(AboutMe) from External_UserApiDB_dbo_Publications

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on RealCID — efficient for single-customer lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Check if a customer qualifies for PI | `WHERE RealCID = X` (presence in table = qualified) |
| High-risk candidates | `WHERE MaxRiskScorePast2Months >= 7` |
| Candidates with copiers | `WHERE NumOfCopiers > 0` |
| Copy-blocked candidates | `WHERE Is_Copy_Blocked = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `RealCID = RealCID` | Full customer profile |
| BI_DB_dbo.BI_DB_CopyDailyData | `RealCID = CID` | Extended copy metrics |

### 3.4 Gotchas

- **Presence = qualified**: Only customers who pass ALL gates appear. Absence means disqualified at some step
- **AllowDisplayFullName always NULL**: Column exists in DDL but the SP INSERT does not populate it
- **No @Date parameter**: SP always processes yesterday internally
- **35/35 activity requirement**: Very strict — one inactive day in 35 disqualifies the customer
- **TRUNCATE+INSERT**: Full refresh daily — no history preserved

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 4 | Unverified / placeholder |
| Tier 5 | ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer identifier. FK to Dim_Customer.RealCID. Clustered index key. Only US customers (CountryID=219) who pass all qualification gates. (Tier 1 — Customer.CustomerStatic) |
| 2 | UserName | varchar(20) | YES | Username for the eToro social trading platform. Unique public identifier. From Dim_Customer.UserName. (Tier 1 — Customer.CustomerStatic) |
| 3 | DaysOfTrading | int | YES | Days since customer's first trading action. DATEDIFF(DAY, BI_DB_First5Actions.FirstActionDate, GETDATE()). (Tier 2 — SP_US_Popular_Investor) |
| 4 | Equity | decimal(13,0) | YES | Customer equity in USD. Calculated as V_Liabilities.Liabilities + ActualNWA. Must be >= $100 to qualify. (Tier 2 — SP_US_Popular_Investor) |
| 5 | PositionsOpenedClosedLast30Days | int | YES | Count of positions opened or closed in the last 30 days. From Fact_CustomerAction WHERE ActionTypeID IN (1,2,3,4,5,6,28). (Tier 2 — SP_US_Popular_Investor) |
| 6 | MaxRiskScorePast2Months | int | YES | Maximum risk score over the past 2 months. StandardDeviation from V_Liabilities mapped to 1-10 scale via threshold brackets. (Tier 2 — SP_US_Popular_Investor) |
| 7 | Is_Copy_Blocked | int | YES | Whether the customer is blocked from being copied. 1 = blocked (OperationTypeID=2 exists in External_etoro_Customer_BlockedCustomerOperations), 0 = not blocked. (Tier 2 — SP_US_Popular_Investor) |
| 8 | UpdateDate | date | YES | ETL execution date. GETDATE() at SP execution time. (Tier 5 — ETL metadata) |
| 9 | HasAvatar | int | YES | Whether the customer has a profile avatar. From Dim_Customer.HasAvatar with ISNULL conversion. (Tier 2 — SP_US_Popular_Investor) |
| 10 | CopyAUM | int | YES | Assets under management from copy trading. From BI_DB_CopyDailyData.CopyAUM, ISNULL to 0. (Tier 2 — SP_US_Popular_Investor) |
| 11 | NumOfCopiers | int | YES | Number of users currently copying this customer. From BI_DB_CopyDailyData.NumOfCopiers, ISNULL to 0. (Tier 2 — SP_US_Popular_Investor) |
| 12 | Number_of_characters_AboutMe | int | YES | Character count of the customer's AboutMe profile text. LEN(External_UserApiDB_dbo_Publications.AboutMe). (Tier 2 — SP_US_Popular_Investor) |
| 13 | AllowDisplayFullName | int | YES | Not populated by the SP INSERT — always NULL. Column exists in DDL but is not part of the ETL pipeline. (Tier 4 — column exists in DDL but not populated) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | Customer.CustomerStatic | CID | passthrough via Dim_Customer |
| UserName | Customer.CustomerStatic | UserName | passthrough via Dim_Customer |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (US depositors, VL3, privacy, valid, recent login)
  + BI_DB_dbo.BI_DB_CIDFirstDates (FirstPosOpenDate, VL3Date NOT NULL)
  + BI_DB_dbo.BI_DB_CID_DailyPanel_FullData (35/35 active days)
  + DWH_dbo.Fact_CustomerAction (position open/close in 30 days)
  + DWH_dbo.V_Liabilities (risk score + equity >= $100)
  + BI_DB_dbo.BI_DB_First5Actions (FirstActionDate for DaysOfTrading)
  + BI_DB_dbo.BI_DB_CopyDailyData (CopyAUM, NumOfCopiers — LEFT JOIN)
  + External_etoro_Customer_BlockedCustomerOperations (copy block — LEFT JOIN)
  + External_UserApiDB_dbo_Publications (AboutMe length — LEFT JOIN)
  |
  |-- SP_US_Popular_Investor (TRUNCATE+INSERT, no date param)
  |   Step 1: US depositors with VL3, privacy, valid, recent login
  |   Step 2: 35/35 active days filter
  |   Step 3: Position activity in last 30 days
  |   Step 4: Risk score mapping from V_Liabilities.StandardDeviation
  |   Step 5: Equity >= $100
  |   Final: INNER JOIN all gates + LEFT JOIN supplemental
  v
BI_DB_dbo.BI_DB_US_Popular_Investor (3.2K rows, ROUND_ROBIN CI(RealCID))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer (RealCID) | Customer dimension |
| DaysOfTrading | BI_DB_dbo.BI_DB_First5Actions (FirstActionDate) | First action date source |
| CopyAUM, NumOfCopiers | BI_DB_dbo.BI_DB_CopyDailyData | Copy trading metrics |
| PositionsOpenedClosedLast30Days | DWH_dbo.Fact_CustomerAction | Position activity source |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 High-Value PI Candidates

```sql
SELECT RealCID, UserName, Equity, NumOfCopiers, CopyAUM, MaxRiskScorePast2Months
FROM BI_DB_dbo.BI_DB_US_Popular_Investor
WHERE NumOfCopiers > 0
ORDER BY Equity DESC
```

### 7.2 Candidates at Risk of Copy Block

```sql
SELECT RealCID, UserName, Is_Copy_Blocked, NumOfCopiers, CopyAUM
FROM BI_DB_dbo.BI_DB_US_Popular_Investor
WHERE Is_Copy_Blocked = 1 AND NumOfCopiers > 0
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 2 T1, 9 T2, 0 T3, 1 T4, 1 T5 | Elements: 13/13, Logic: 8/10, Lineage: 7/10*
*Object: BI_DB_dbo.BI_DB_US_Popular_Investor | Type: Table | Production Source: Dim_Customer + V_Liabilities + Fact_CustomerAction via SP_US_Popular_Investor*

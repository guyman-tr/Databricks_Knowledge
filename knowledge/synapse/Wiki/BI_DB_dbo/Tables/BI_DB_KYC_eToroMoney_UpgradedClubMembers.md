# BI_DB_dbo.BI_DB_KYC_eToroMoney_UpgradedClubMembers

> 146,580-row daily UK-only KYC feed for eToroMoney club members upgraded from Bronze to a higher tier (Silver/Gold/Platinum/Platinum Plus/Diamond), covering 2022-02-13 to 2026-04-12 (1,467 distinct dates). Contains identity and residential address details for UK customers requiring enhanced KYC upon club tier upgrade. Excludes Card program members (IBANO only + no eMoney account). Written by SP_KYC_eToroMoney_UpgradedClubMembers (SB_Daily, Priority 20). DELETE WHERE DateID + INSERT.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + Dim_Country + BI_DB_CID_DailyPanel_Club + Dim_PlayerLevel + eMoney_dbo.eMoney_Account_Mappings via SP_KYC_eToroMoney_UpgradedClubMembers |
| **Refresh** | Daily (SB_Daily, Priority 20) — DELETE WHERE DateID=@DateID + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

BI_DB_KYC_eToroMoney_UpgradedClubMembers is a daily compliance/KYC feed identifying UK customers who have been upgraded from the Bronze club tier to a higher tier on a given date. The table is designed to support UK regulatory requirements (FCA jurisdiction) that mandate enhanced KYC when customers reach higher investment thresholds.

**Why this table exists**: Under FCA/eToroMoney regulations, UK customers who progress beyond Bronze club membership (indicating increased investment/trading activity) must undergo additional identity and address verification. This table provides the list of such customers with their residential address details, enabling the KYC team to initiate verification workflows.

**Population criteria** (all must be true):
1. Country: UK only (`DWH_dbo.Dim_Customer.CountryID = 218`)
2. Club upgrade event on the run date: `BI_DB_CID_DailyPanel_Club.IsUpgrade = 1`
3. Previous tier was Bronze: `LastTier = 1` (PlayerLevelID=1)
4. eToroMoney account: NOT in Card program — either IBANO (AccountProgramID=2) or no eMoney account at all (NULL, LEFT JOIN miss)

**Club upgrade distribution** (all-time): Bronze→Silver 66.4%, Bronze→Platinum 17.3%, Bronze→Gold 14.3%, Bronze→Platinum Plus 1.9%, Bronze→Diamond 0.1%.

**Program distribution**: IBANO (67.2%), no eMoney account (32.8%).

The table appends rows incrementally — each date's upgrades are stored permanently (DELETE WHERE DateID replaces the specific date but does not purge history). As of April 2026, the table contains 146,580 rows spanning 1,467 dates (~100 rows/date average).

**Identity data sensitivity**: This table contains PII — address fields (BuildingNumber, Address, City, Zip) are sourced from `Dim_Customer` which has PII masking in the production masked UC copy. Access must be governed appropriately.

---

## 2. Business Logic

### 2.1 Population Filter — UK Bronze Upgrades Excluding Card

**What**: Only UK-resident customers who were Bronze and got upgraded that day, excluding those in the Card eToroMoney program.

**Columns Involved**: Country_Abbreviation (always GB), OldClub_Name (always Bronze), NewClub_Name (Silver/Gold/Platinum/Platinum Plus/Diamond), Program

**Rules**:
- `DWH_dbo.Dim_Customer.CountryID = 218` — hardcoded UK filter
- `BI_DB_CID_DailyPanel_Club.IsUpgrade = 1` — upgrade event must have occurred on DateID
- `BI_DB_CID_DailyPanel_Club.LastTier = 1` — previous tier was Bronze (PlayerLevelID=1)
- `a.GCID IS NULL OR a.AccountProgramID = 2` — no eMoney account (GCID not in eMoney_Account_Mappings) OR IBANO program; EXCLUDES Card program (AccountProgramID=1)
- Implication: every row has Country_Abbreviation='GB' and OldClub_Name='Bronze'

### 2.2 IDENTITY Gaps and Date-Keyed ID

**What**: The ID column uses IDENTITY(1,1) and has large sequential gaps between date batches.

**Columns Involved**: ID, DateID

**Rules**:
- ID is auto-assigned by SQL Server/Synapse on each INSERT — it does NOT reset on DELETE+re-INSERT
- Gaps of 60 between consecutive IDs within the same date batch correspond to how many rows were deleted and re-inserted (counter does not rewind)
- The ID column is not a business key — use (CID, DateID) as a logical identifier for any given upgrade event
- Do NOT use ID for ordering rows in a business sense

### 2.3 Program Classification

**What**: The Program column classifies whether the customer has an eToroMoney IBANO account.

**Columns Involved**: Program

**Rules**:
- `IBANO` — customer has an eToroMoney account in the IBANO program (AccountProgramID=2)
- Empty/NULL — customer does NOT have an eToroMoney account (LEFT JOIN on GCID returns NULL)
- `Card` — this value never appears (SP filter `NOT a.AccountProgramID=1` excludes these customers from the table)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP — no clustered index. All queries are full-scans. Add a DateID filter first to minimise data movement. For UK-specific KYC work, this table is the correct starting point (no need to filter DIM tables).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Today's Bronze upgrades requiring KYC | `WHERE DateID=@ddINT ORDER BY NewClub_Name, GCID` |
| Breakdown by upgrade destination this week | `WHERE DateID BETWEEN @weekStart AND @weekEnd GROUP BY NewClub_Name ORDER BY COUNT(*) DESC` |
| IBANO-enrolled upgrades vs. non-enrolled | `WHERE DateID=@ddINT GROUP BY PROGRAM` |
| History for a specific CID | `WHERE CID=@cid ORDER BY DateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON CID = dc.RealCID` | Get additional KYC fields (email, phone, DocsOK, VerificationLevelID) |
| DWH_dbo.Dim_PlayerLevel | `ON NewClub_Name = dpl.Name` | Get PlayerLevelID for the new tier |
| BI_DB_dbo.BI_DB_CID_DailyPanel_Club | `ON CID = cp.CID AND DateID = cp.DateID` | Confirm current tier and portfolio balance at upgrade date |

### 3.4 Gotchas

- **Country_Abbreviation is always 'GB'**: The SP hardcodes `CountryID=218` (UK). Do not expect other countries in this table.
- **OldClub_Name is always 'Bronze'**: The SP hardcodes `LastTier=1`. The column is not useful for filtering.
- **Program=NULL vs. empty string**: A NULL Program means no eToroMoney account; use `WHERE Program IS NULL OR Program = ''` to find these.
- **No Card program members**: Customers in the Card program (AccountProgramID=1) are excluded. The table cannot be used to audit Card program upgrades.
- **IDENTITY gaps**: ID counter does not reset — daily DELETE+re-INSERT creates large gaps. Sort by ID only for insertion-order reference.
- **Historical rows preserved**: Unlike TRUNCATE+INSERT, this table uses DELETE WHERE DateID — prior dates remain. The table accumulates all UK Bronze upgrades since Feb 2022.
- **PII sensitivity**: Address columns (BuildingNumber, Address, City, Zip) are PII. Ensure appropriate access controls before querying or exporting.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Inferred from DWH metadata; limited production confidence |
| Tier 4 | Best-available estimate; requires business confirmation |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NOT NULL | IDENTITY(1,1) auto-assigned row identifier. Does NOT reset on DELETE+re-INSERT; large sequential gaps exist between date batches. Not a business key. (Tier 2 — SP_KYC_eToroMoney_UpgradedClubMembers) |
| 2 | DateID | int | YES | ETL integer date key (YYYYMMDD) from SP @Date parameter. Marks the club upgrade event date. Used as the DELETE key (DELETE WHERE DateID=@DateID). (Tier 2 — SP_KYC_eToroMoney_UpgradedClubMembers) |
| 3 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Maps to DWH_dbo.Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 4 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 5 | OldClub_Name | varchar(max) | YES | Club tier name before the upgrade event. Always `Bronze` — SP filter `LastTier=1` (PlayerLevelID=1 = Bronze) hardcodes this. From DWH_dbo.Dim_PlayerLevel.Name. (Tier 2 — SP_KYC_eToroMoney_UpgradedClubMembers) |
| 6 | NewClub_Name | varchar(max) | YES | Club tier name after the upgrade event. Values: `Silver` (66%), `Platinum` (17%), `Gold` (14%), `Platinum Plus` (2%), `Diamond` (<1%). From DWH_dbo.Dim_PlayerLevel.Name WHERE PlayerLevelID=BI_DB_CID_DailyPanel_Club.CurrentTier. (Tier 2 — SP_KYC_eToroMoney_UpgradedClubMembers) |
| 7 | BuildingNumber | nvarchar(30) | YES | Building/apartment number. Separate from Address for structured address storage. **PII**. (Tier 1 — Customer.CustomerStatic) |
| 8 | Address | nvarchar(100) | YES | Street address in Unicode. **PII**. (Tier 1 — Customer.CustomerStatic) |
| 9 | City | nvarchar(50) | YES | City in Unicode. **PII**. (Tier 1 — Customer.CustomerStatic) |
| 10 | Zip | nvarchar(50) | YES | Postal code. Used in LinkedAccountHash1. **PII**. (Tier 1 — Customer.CustomerStatic) |
| 11 | Country_Abbreviation | char(2) | YES | ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE"). Unique per row. Used in UI display, API parameters, and geolocation matching. Trimmed on use (char type has trailing spaces). Always `GB` in this table (SP hardcodes CountryID=218 = UK). (Tier 1 — Dictionary.Country upstream wiki) |
| 12 | MarketingRegionManualName | varchar(50) | YES | Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. Always `UK` in this table (UK-only population). (Tier 3 — Ext_Dim_Country live data) |
| 13 | Program | varchar(50) | YES | eToroMoney program type for the customer. Values: `IBANO` (AccountProgramID=2, 67% of rows) or empty/NULL (no eMoney account, 33% of rows). Card program customers (AccountProgramID=1) are excluded by the SP filter. (Tier 2 — SP_KYC_eToroMoney_UpgradedClubMembers) |
| 14 | UpdateDate | datetime | YES | ETL execution timestamp — GETDATE() at SP run time. Indicates when this batch was inserted. (Tier 2 — SP_KYC_eToroMoney_UpgradedClubMembers) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | Passthrough via Dim_Customer.RealCID; renamed to CID |
| GCID | Customer.CustomerStatic | GCID | Passthrough via Dim_Customer.GCID |
| BuildingNumber | Customer.CustomerStatic | BuildingNumber | Passthrough via Dim_Customer.BuildingNumber |
| Address | Customer.CustomerStatic | Address | Passthrough via Dim_Customer.Address |
| City | Customer.CustomerStatic | City | Passthrough via Dim_Customer.City |
| Zip | Customer.CustomerStatic | Zip | Passthrough via Dim_Customer.Zip |
| Country_Abbreviation | Dictionary.Country | Abbreviation | Passthrough via Dim_Country.Abbreviation JOIN on CountryID |
| MarketingRegionManualName | Ext_Dim_Country | MarketingRegionManualName | Passthrough via Dim_Country.MarketingRegionManualName |
| OldClub_Name | Customer.PlayerLevel (dict) | Name | Passthrough via Dim_PlayerLevel WHERE LastTier=1; always Bronze |
| NewClub_Name | Customer.PlayerLevel (dict) | Name | Passthrough via Dim_PlayerLevel WHERE CurrentTier |
| Program | eMoney_dbo.eMoney_Account_Mappings | AccountProgramID | CASE 2→'IBANO', 1→'Card'; NULL if no mapping |
| UpdateDate | ETL | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (CountryID=218 → UK only; RealCID, GCID, address fields)
DWH_dbo.Dim_Country (Abbreviation='GB', MarketingRegionManualName='UK')
BI_DB_dbo.BI_DB_CID_DailyPanel_Club (IsUpgrade=1, LastTier=1, DateID=@DateID)
DWH_dbo.Dim_PlayerLevel ×2 (OldClub_Name + NewClub_Name)
eMoney_dbo.eMoney_Account_Mappings (Program: IBANO/Card/NULL; Card excluded)
  |-- SP_KYC_eToroMoney_UpgradedClubMembers @Date (SB_Daily, P20) ---|
  |   Dependency: SP_CID_DailyPanel_Club → BI_DB_CID_DailyPanel_Club |
  |   Filter: UK Bronze upgraders NOT in Card program              |
  |   DELETE WHERE DateID=@DateID + INSERT (append-accumulate)     |
  ↓
BI_DB_dbo.BI_DB_KYC_eToroMoney_UpgradedClubMembers
(ROUND_ROBIN, HEAP, IDENTITY — 146,580 rows, Feb 2022 to Apr 2026)
  |-- UC: Not Migrated ---|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer identity lookup |
| GCID | DWH_dbo.Dim_Customer.GCID | Cross-product identity key |
| Country_Abbreviation | DWH_dbo.Dim_Country.Abbreviation | Always GB (UK) |
| MarketingRegionManualName | DWH_dbo.Dim_Country.MarketingRegionManualName | Always UK |
| OldClub_Name / NewClub_Name | DWH_dbo.Dim_PlayerLevel.Name | Club tier name lookup |
| Program | eMoney_dbo.eMoney_Account_Mappings.AccountProgramID | eToroMoney program classification |

### 6.2 Referenced By

| Object | Relationship |
|--------|-------------|
| (No documented downstream consumers in current batch context) | — |

---

## 7. Sample Queries

### Today's Bronze upgrades — UK KYC list

```sql
SELECT DateID, CID, GCID, OldClub_Name, NewClub_Name, BuildingNumber, Address, City, Zip, Country_Abbreviation, Program
FROM [BI_DB_dbo].[BI_DB_KYC_eToroMoney_UpgradedClubMembers]
WHERE DateID = 20260410
ORDER BY NewClub_Name, CID;
```

### Weekly upgrade summary by destination tier

```sql
SELECT NewClub_Name, Program, COUNT(*) AS upgrades
FROM [BI_DB_dbo].[BI_DB_KYC_eToroMoney_UpgradedClubMembers]
WHERE DateID BETWEEN 20260404 AND 20260410
GROUP BY NewClub_Name, Program
ORDER BY upgrades DESC;
```

### Monthly trend of upgrade volume

```sql
SELECT LEFT(CAST(DateID AS varchar(8)), 6) AS YearMonth, COUNT(*) AS daily_upgrades
FROM [BI_DB_dbo].[BI_DB_KYC_eToroMoney_UpgradedClubMembers]
WHERE DateID >= 20260101
GROUP BY LEFT(CAST(DateID AS varchar(8)), 6)
ORDER BY YearMonth;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for BI_DB_KYC_eToroMoney_UpgradedClubMembers.

---

*Generated: 2026-04-22 | Quality: 8.8/10 | Phases: 12/14*
*Tiers: 7 T1, 5 T2, 1 T3, 0 T4, 0 T5 | Elements: 14/14, Logic: 8/10, ETL: 9/10*
*Object: BI_DB_dbo.BI_DB_KYC_eToroMoney_UpgradedClubMembers | Type: Table | Production Source: Customer.CustomerStatic + eMoney_dbo.eMoney_Account_Mappings via SP_KYC_eToroMoney_UpgradedClubMembers*

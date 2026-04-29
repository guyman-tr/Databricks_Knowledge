# BI_DB_dbo.BI_DB_OPS_MultipleAccounts

> 41.4K-row operations table identifying customers who share the same first name, last name, country, birth date, and gender — flagging potential duplicate/linked accounts among verified depositors. Daily TRUNCATE+INSERT from Dim_Customer + 8 dim lookups + V_Liabilities + EXW wallet balances + CIDFirstDates + BackOffice master-sub relationships. Registrations span 2008 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer (primary) via `SP_OPS_MultipleAccounts` |
| **Refresh** | Daily (TRUNCATE+INSERT, @Date parameter) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Pavlina Masoura (2025-04-28) |
| **Row Count** | ~41,403 (as of 2026-04-13) |

---

## 1. Business Meaning

`BI_DB_OPS_MultipleAccounts` is an operations compliance table that identifies customers suspected of holding multiple accounts on the eToro platform. Each row represents one customer account that shares PII (first name + last name + country + birth date + gender) with at least one other verified depositor account.

The table targets a specific population: only customers who are fully verified (VerificationLevelID=3), have deposited (IsDepositor=1), are valid (IsValidCustomer=1), are not internal employees (PlayerLevelID<>4), are not pending closure ("Suggested for Closure" / "Approved for Closure" excluded), and are not Blocked or Blocked Upon Request (PlayerStatusID NOT IN 2,4).

The SP groups accounts by a concatenated PII key (`LOWER(FirstName) + LOWER(LastName) + Country + BirthDate + Gender`), then retains only groups with 2+ distinct CIDs. Each group receives a shared `ID` (via DENSE_RANK) and each member gets a `Rank` based on equity and recent login activity. The `Keep Y/N` column implements a retention heuristic: Club-tier members keep the top 5 by equity/login; non-Club members keep only the top 1.

As of 2026-04-13: 41,403 accounts in ~20,700 PII groups. 86% male, 98% Normal status. Top countries: UK (8.2K), Germany (7.0K), France (6.0K), Italy (5.9K). Regulations: CySEC (64%), FCA (26%). NoOfRelations ranges from 1 to 52 (avg 1.2). TotalEquity ranges from -$6.5K to $6.8M.

---

## 2. Business Logic

### 2.1 PII-Based Duplicate Detection

**What**: Customers are grouped by a concatenated key of lowercased first name, lowercased last name, country name, birth date, and gender. Only groups with 2+ distinct CIDs are flagged.
**Columns Involved**: `FN_LN_Country_BirthDate_Gender`, `NoOfRelations`, `ID`
**Rules**:
- Key = `CONCAT(LOWER(FirstName), LOWER(LastName), Country, BirthDate, Gender)`
- Only groups where `COUNT(DISTINCT CID) > 1` are included
- `NoOfRelations` = count of other accounts in the same group (total - 1)
- `ID` = DENSE_RANK() ordered by the PII key descending — shared across all accounts in a group

### 2.2 Within-Group Ranking and Keep Logic

**What**: Each account within a PII group is ranked by financial activity to determine which accounts to retain.
**Columns Involved**: `Rank`, `ClubNonClubPhysicalPerson`, `Keep Y/N`, `TP_and_Wallet_Equity`, `LastLoggedIn`
**Rules**:
- `Rank` = ROW_NUMBER() PARTITION BY ID, ordered by: (1) equity > 0 first, then (2) equity descending, then (3) last login descending
- `ClubNonClubPhysicalPerson` = 'Club' if any account in the group has a PlayerLevel above Bronze; 'Not Club' otherwise
- `Keep Y/N`:
  - Club groups: keep top 5 (Rank < 6) = 'Yes', rest = 'No'
  - Non-Club groups: keep top 1 (Rank < 2) = 'Yes', rest = 'No'
- 63% of accounts are marked 'Yes' (26.1K), 37% 'No' (15.3K)

### 2.3 Account Type Classification (Master-Sub)

**What**: Identifies master/sub account relationships from BackOffice.
**Columns Involved**: `MasterAccountCID`, `AccountType`
**Rules**:
- MasterAccountCID from External_etoro_BackOffice_Customer
- `AccountType`: 'Null' (no master link, 95%), 'SubAccount' (linked to a master, 5%), 'Master' (is a master — 0% in current data, all masters filtered out by WHERE conditions or lack of self-referencing rows)

### 2.4 Population Filters

**What**: Strict eligibility criteria limit the population to verified depositors.
**Columns Involved**: (filter logic, not stored columns)
**Rules**:
- `IsValidCustomer = 1` (valid customer flag)
- `IsDepositor = 1` (has made at least one deposit)
- `VerificationLevelID = 3` (fully verified)
- `PlayerLevelID <> 4` (not Internal)
- `PendingClosureStatusName NOT IN ('Suggested for Closure', 'Approved for Closure') OR NULL`
- `PlayerStatusID NOT IN (2, 4)` (not Blocked, not Blocked Upon Request)
- Employees excluded (2025-11-05 change)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no preferred join key. For JOINs to Dim_Customer use `CID = RealCID`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many duplicate groups exist? | `SELECT COUNT(DISTINCT ID) FROM BI_DB_OPS_MultipleAccounts` |
| Which groups have the most accounts? | `SELECT ID, MAX(NoOfRelations)+1 AS group_size FROM ... GROUP BY ID ORDER BY group_size DESC` |
| Which accounts should be closed? | `WHERE [Keep Y/N] = 'No'` |
| Club members with duplicates | `WHERE ClubNonClubPhysicalPerson = 'Club'` |
| High-equity duplicate groups | `WHERE TP_and_Wallet_Equity > 10000 ORDER BY ID, Rank` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `CID = RealCID` | Full customer profile |
| BI_DB_dbo.BI_DB_CIDFirstDates | `CID = CID` | Additional milestone dates |

### 3.4 Gotchas

- **Column with space**: `[Keep Y/N]` requires square brackets in queries
- **VerificationLevelID is always 3**: The WHERE filter restricts to VL3 only — this column is informational but constant
- **Names are lowercased**: FirstName and LastName are LOWER()-transformed; do not compare case-sensitively to source data
- **FN_LN_Country_BirthDate_Gender concatenation format**: Includes date in locale format (e.g., "Jul 31 1990 12:00AM") due to implicit CONVERT — not a clean key for external matching
- **NoOfRelations = 0 is impossible**: Minimum is 1 (at least one other account in the group)
- **MasterAccountCID can be NULL**: 95% of accounts have no master link (AccountType='Null' as string, not SQL NULL)
- **WalletBalanceUSD NULLs**: NULL when customer has no EXW wallet balance; TP_and_Wallet_Equity handles via ISNULL

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge, limited confidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | YES | Group identifier for accounts sharing the same PII key. DENSE_RANK() over FN+LN+Country+BirthDate+Gender descending. All accounts in the same duplicate group share the same ID. (Tier 2 — SP_OPS_MultipleAccounts) |
| 2 | CID | bigint | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Mapped from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 3 | FirstName | nvarchar(max) | YES | Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). DWH note: LOWER() applied by SP_OPS_MultipleAccounts for case-insensitive PII grouping. (Tier 1 — Customer.CustomerStatic) |
| 4 | LastName | nvarchar(max) | YES | Legal last name in Unicode. DWH note: LOWER() applied by SP_OPS_MultipleAccounts for case-insensitive PII grouping. (Tier 1 — Customer.CustomerStatic) |
| 5 | BirthDate | date | YES | Customer date of birth. Used in the PII duplicate detection key and in KYC age verification. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 6 | Gender | nvarchar(10) | YES | Gender: M, F, or U (Unknown). Used in the PII duplicate detection key. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 7 | Country | nvarchar(100) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 8 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Always 3 (fully verified) in this table due to WHERE filter. Passthrough from Dim_Customer. (Tier 1 — BackOffice.Customer) |
| 9 | NoOfRelations | int | YES | Number of other accounts sharing the same PII key. Computed as COUNT(DISTINCT CID) - 1 per group. Range: 1-52, average 1.2. (Tier 2 — SP_OPS_MultipleAccounts) |
| 10 | PlayerStatus | nvarchar(max) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Values: Normal, Block Deposit & Trading, Trade & MIMO Blocked, Copy Block, Deposit Blocked, Warning. Passthrough from Dim_PlayerStatus. (Tier 1 — Dictionary.PlayerStatus) |
| 11 | PlayerLevel | nvarchar(max) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel. (Tier 1 — Dictionary.PlayerLevel) |
| 12 | Regulation | nvarchar(max) | YES | Short code for the regulation. Values: CySEC, FCA, FSA Seychelles, ASIC & GAML, FSRA, ASIC, FinCEN+FINRA, FinCEN, MAS. Passthrough from Dim_Regulation. (Tier 1 — Dictionary.Regulation) |
| 13 | FN_LN_Country_BirthDate_Gender | nvarchar(max) | YES | Concatenated PII deduplication key: LOWER(FirstName) + LOWER(LastName) + Country + BirthDate (locale-formatted) + Gender. Used for grouping accounts suspected of being duplicates. (Tier 2 — SP_OPS_MultipleAccounts) |
| 14 | TotalEquity | money | YES | Customer total equity from V_Liabilities: Liabilities + ActualNWA for the @Date parameter. NULL if no liabilities record exists. (Tier 2 — SP_OPS_MultipleAccounts, V_Liabilities) |
| 15 | WalletBalanceUSD | money | YES | Sum of eToro Money wallet balances in USD from EXW_FinanceReportsBalancesNew. Only includes positive balances (Balance > 0). NULL if no wallet balance. (Tier 2 — SP_OPS_MultipleAccounts, EXW_FinanceReportsBalancesNew) |
| 16 | TP_and_Wallet_Equity | money | YES | Combined trading platform equity and wallet balance: ISNULL(TotalEquity, 0) + ISNULL(WalletBalanceUSD, 0). Used as the primary ranking factor within duplicate groups. (Tier 2 — SP_OPS_MultipleAccounts) |
| 17 | LastLoggedIn | datetime | YES | Last platform login date. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID=14. Passthrough from BI_DB_CIDFirstDates. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 18 | PendingClosureStatusName | nvarchar(max) | YES | Human-readable label for the closure state. 1=No, 2=Suggested for Closure, 3=Approved for Closure. Note: accounts with 'Suggested for Closure' or 'Approved for Closure' are excluded by the WHERE filter — only 'No' or NULL appear. Passthrough from Dim_PendingClosureStatus. (Tier 1 — Dictionary.PendingClosureStatus) |
| 19 | GuruStatusName | nvarchar(max) | YES | Human-readable PI tier name. Values: No, Cadet, Champion, Elite, Elite Pro. 'Certified', 'Rising Star', 'Removed', 'Rejected' are theoretically possible but not observed. Passthrough from Dim_GuruStatus. (Tier 1 — Dictionary.GuruStatus) |
| 20 | HasOpenTrades | int | YES | 1 if the customer has any open position (CloseDateID=0) in Dim_Position; 0 otherwise. Computed via MAX(CASE) aggregate. (Tier 2 — SP_OPS_MultipleAccounts, Dim_Position) |
| 21 | PlayerStatusReason | nvarchar(max) | YES | Human-readable reason label. Key values: None, Failed Verification, Chargeback, AML-Account Closed, HRC, AML, AML review, WCH match, Right to be forgotten, Self-Service, eToro Money Restriction, Abusive Trading, Hacked Account, Tax. Passthrough from Dim_PlayerStatusReasons. (Tier 1 — Dictionary.PlayerStatusReasons) |
| 22 | PlayerStatusSubReasonName | nvarchar(max) | YES | Granular sub-reason beneath the primary status reason. 83 distinct values covering KYC failures, chargeback types, AML sub-categories, compliance actions. Passthrough from Dim_PlayerStatusSubReasons. (Tier 1 — Dictionary.PlayerStatusSubReasons) |
| 23 | Club | nvarchar(max) | YES | Tier display name from Dim_PlayerLevel (same source as PlayerLevel). Used in the Club/Not Club classification and Keep Y/N retention logic. Passthrough from Dim_PlayerLevel. (Tier 1 — Dictionary.PlayerLevel) |
| 24 | VerificationLevel3Date | date | YES | First date customer reached verification level 3 (fully verified). MIN(FromDateID) WHERE VerificationLevelID=3. Backfills levels 1 and 2 if not already set. Passthrough from BI_DB_CIDFirstDates. (Tier 2 — SP_CIDFirstDates, Fact_SnapshotCustomer) |
| 25 | HasOpenRealCryptoPosition | int | YES | 1 if the customer has an open settled crypto position (InstrumentTypeID=10, CloseDateID=0, IsSettled=1); 0 otherwise. Computed via CASE on join to Dim_Position + Dim_Instrument. (Tier 2 — SP_OPS_MultipleAccounts, Dim_Position) |
| 26 | Rank | int | YES | Within-group priority rank. ROW_NUMBER() PARTITION BY ID, ordered by: (1) positive equity first, (2) equity descending, (3) last login descending. Rank 1 = highest equity / most recent login in the group. (Tier 2 — SP_OPS_MultipleAccounts) |
| 27 | ClubNonClubPhysicalPerson | nvarchar(max) | YES | 'Club' if any account in the PII group has a PlayerLevel above Bronze (Silver, Gold, Platinum, etc.); 'Not Club' otherwise. Drives differential Keep Y/N thresholds. (Tier 2 — SP_OPS_MultipleAccounts) |
| 28 | Keep Y/N | nvarchar(max) | YES | Retention recommendation: 'Yes' = keep this account, 'No' = candidate for closure. Club groups keep top 5 by rank (Rank < 6); Non-Club groups keep only top 1 (Rank < 2). (Tier 2 — SP_OPS_MultipleAccounts) |
| 29 | RegisteredReal | datetime | YES | Account registration date (renamed from Registered). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 30 | HasWallet | int | YES | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. Passthrough from Dim_Customer. (Tier 1 — BackOffice.Customer) |
| 31 | HaseMoney | int | YES | 1 if the customer has an eMoney account (exists in eMoney_Dim_Account); 0 otherwise. Computed via LEFT JOIN existence check. (Tier 2 — SP_OPS_MultipleAccounts, eMoney_Dim_Account) |
| 32 | MasterAccountCID | bigint | YES | CID of the master account if this is a sub-account. From External_etoro_BackOffice_Customer. NULL (displayed as 'Null' in AccountType) for 95% of accounts with no master-sub relationship. (Tier 2 — SP_OPS_MultipleAccounts, BackOffice.Customer) |
| 33 | AccountType | nvarchar(max) | YES | Account relationship type: 'Null'=no master-sub link, 'Master'=is a master account (CID=MasterAccountCID), 'SubAccount'=linked to a master. Computed from MasterAccountCID. (Tier 2 — SP_OPS_MultipleAccounts) |
| 34 | GCID | bigint | YES | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 35 | UpdateDate | datetime | YES | ETL execution timestamp. GETDATE() at SP execution time. All rows share the same value per daily run. (Tier 2 — SP_OPS_MultipleAccounts) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | rename (RealCID → CID) via Dim_Customer |
| FirstName | Customer.CustomerStatic | FirstName | LOWER() via Dim_Customer |
| LastName | Customer.CustomerStatic | LastName | LOWER() via Dim_Customer |
| BirthDate | Customer.CustomerStatic | BirthDate | passthrough via Dim_Customer |
| Gender | Customer.CustomerStatic | Gender | passthrough via Dim_Customer |
| Country | Dictionary.Country | Name | dim-lookup via Dim_Country |
| VerificationLevelID | BackOffice.Customer | VerificationLevelID | passthrough via Dim_Customer |
| PlayerStatus | Dictionary.PlayerStatus | Name | dim-lookup via Dim_PlayerStatus |
| PlayerLevel | Dictionary.PlayerLevel | Name | dim-lookup via Dim_PlayerLevel |
| Regulation | Dictionary.Regulation | Name | dim-lookup via Dim_Regulation |
| PendingClosureStatusName | Dictionary.PendingClosureStatus | PendingClosureStatusName | dim-lookup via Dim_PendingClosureStatus |
| GuruStatusName | Dictionary.GuruStatus | GuruStatusName | dim-lookup via Dim_GuruStatus |
| PlayerStatusReason | Dictionary.PlayerStatusReasons | Name | dim-lookup via Dim_PlayerStatusReasons |
| PlayerStatusSubReasonName | Dictionary.PlayerStatusSubReasons | Name | dim-lookup via Dim_PlayerStatusSubReasons (rename: Name → PlayerStatusSubReasonName) |
| RegisteredReal | Customer.CustomerStatic | Registered | rename via Dim_Customer |
| HasWallet | BackOffice.Customer | HasWallet | passthrough via Dim_Customer |
| GCID | Customer.CustomerStatic | GCID | passthrough via Dim_Customer |
| Club | Dictionary.PlayerLevel | Name | dim-lookup via Dim_PlayerLevel (same source as PlayerLevel) |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (primary, HASH(RealCID))
DWH_dbo.Dim_Country (REPLICATE)
DWH_dbo.Dim_PlayerStatus (REPLICATE)
DWH_dbo.Dim_PlayerLevel (REPLICATE)
DWH_dbo.Dim_Regulation (REPLICATE)
DWH_dbo.Dim_GuruStatus (REPLICATE)
DWH_dbo.Dim_PendingClosureStatus (REPLICATE)
DWH_dbo.Dim_PlayerStatusReasons (REPLICATE)
DWH_dbo.Dim_PlayerStatusSubReasons (REPLICATE)
DWH_dbo.V_Liabilities (equity calculation)
EXW_dbo.EXW_FinanceReportsBalancesNew (wallet balances)
BI_DB_dbo.BI_DB_CIDFirstDates (login/VL3 dates)
DWH_dbo.Dim_Position + Dim_Instrument (open trades/crypto)
eMoney_dbo.eMoney_Dim_Account (eMoney flag)
BI_DB_dbo.External_etoro_BackOffice_Customer (master-sub)
  |
  |-- SP_OPS_MultipleAccounts @Date (daily TRUNCATE+INSERT)
  |   Step 1: Build #LIABILITIES from V_Liabilities
  |   Step 2: Build #wallet from EXW_FinanceReportsBalancesNew
  |   Step 3: Build #List_Init — Dim_Customer + 7 dim JOINs + CIDFirstDates
  |   Step 4: Build #group — PII grouping, HAVING COUNT(DISTINCT CID) > 1
  |   Step 5: Build #IDS — DENSE_RANK + dim re-JOINs + open position checks
  |   Step 6: Build #RANK — ROW_NUMBER by equity/login within group
  |   Step 7: Build #CLUB — groups with non-Bronze members
  |   Step 8: Build #finaltable — combine all + eMoney + BackOffice + Keep Y/N
  |   Step 9: TRUNCATE + INSERT into target
  v
BI_DB_dbo.BI_DB_OPS_MultipleAccounts (41.4K rows, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Primary customer dimension |
| Country | DWH_dbo.Dim_Country (Name) | Country dimension lookup |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus (Name) | Account restriction status |
| PlayerLevel / Club | DWH_dbo.Dim_PlayerLevel (Name) | Loyalty tier |
| Regulation | DWH_dbo.Dim_Regulation (Name) | Regulatory authority |
| GuruStatusName | DWH_dbo.Dim_GuruStatus (GuruStatusName) | Popular Investor tier |
| PendingClosureStatusName | DWH_dbo.Dim_PendingClosureStatus | Closure workflow state |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons (Name) | Status change reason |
| PlayerStatusSubReasonName | DWH_dbo.Dim_PlayerStatusSubReasons | Status sub-reason |
| TotalEquity | DWH_dbo.V_Liabilities | Trading platform equity |
| WalletBalanceUSD | EXW_dbo.EXW_FinanceReportsBalancesNew | eToro Money wallet balance |
| LastLoggedIn, VerificationLevel3Date | BI_DB_dbo.BI_DB_CIDFirstDates | Customer milestone dates |
| HasOpenTrades, HasOpenRealCryptoPosition | DWH_dbo.Dim_Position | Open position checks |
| HaseMoney | eMoney_dbo.eMoney_Dim_Account | eMoney account flag |
| MasterAccountCID | BI_DB_dbo.External_etoro_BackOffice_Customer | Master-sub account link |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 Find Largest Duplicate Groups

```sql
SELECT TOP 20
    ID,
    MAX(NoOfRelations) + 1 AS group_size,
    MAX(FN_LN_Country_BirthDate_Gender) AS pii_key,
    SUM(TP_and_Wallet_Equity) AS total_group_equity
FROM BI_DB_dbo.BI_DB_OPS_MultipleAccounts
GROUP BY ID
ORDER BY group_size DESC
```

### 7.2 Accounts Recommended for Closure with Positive Equity

```sql
SELECT CID, FirstName, LastName, Country, TP_and_Wallet_Equity, [Rank], ClubNonClubPhysicalPerson
FROM BI_DB_dbo.BI_DB_OPS_MultipleAccounts
WHERE [Keep Y/N] = 'No'
  AND TP_and_Wallet_Equity > 0
ORDER BY TP_and_Wallet_Equity DESC
```

### 7.3 Club Members with Multiple Accounts and Open Crypto

```sql
SELECT CID, FirstName, LastName, Country, Club, GuruStatusName,
       HasOpenRealCryptoPosition, TP_and_Wallet_Equity
FROM BI_DB_dbo.BI_DB_OPS_MultipleAccounts
WHERE ClubNonClubPhysicalPerson = 'Club'
  AND HasOpenRealCryptoPosition = 1
ORDER BY ID, [Rank]
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable due to permissions).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 18 T1, 17 T2, 0 T3, 0 T4, 0 T5 | Elements: 35/35, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_OPS_MultipleAccounts | Type: Table | Production Source: DWH_dbo.Dim_Customer via SP_OPS_MultipleAccounts*

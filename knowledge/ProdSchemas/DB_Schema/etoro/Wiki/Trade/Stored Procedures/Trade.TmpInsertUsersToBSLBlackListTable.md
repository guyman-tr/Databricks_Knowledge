# Trade.TmpInsertUsersToBSLBlackListTable

> Maintenance procedure that inserts first-time depositors with open positions into the BSL (Broker/System Liquidity) blacklist table, with capacity guard and multiple eligibility filters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @dt DATETIME, @MaxNumbersOfUsers INT (BSL blacklist population, FTD + open positions filter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure populates `Trade.BSLBlackList` with real customers who have made their first deposit (FTD) and have open trading positions. The BSL blacklist is used by the BSL (Broker/System Liquidity) service to identify accounts for special handling - customers who have real skin in the game (deposited AND have open positions) but may need monitoring or routing treatment.

The "Tmp" prefix indicates this is a maintenance/batch procedure rather than a real-time operational one. It was created to handle a specific need (possibly a migration or initial population) identified in FB 45530 (June 2017), where the original fund check was changed from Trade.Fund to BackOffice.Customer.

Key eligibility criteria:
1. First-time depositor (IsFTD=1) after the cutoff date @dt
2. Not already in BSLBlackList
3. Has at least one open position (exists in Trade.PositionTbl)
4. Not CountryID=250 (Palestine - regulatory exclusion)
5. Not PlayerLevelID=4 (internal/test/staff)
6. BackOffice.Customer.AccountTypeID <> 9 (excludes specific account types)

The procedure respects a capacity limit (@MaxNumbersOfUsers): if the table already has that many users, it returns immediately. If capacity remains, it inserts up to the remaining slots.

---

## 2. Business Logic

### 2.1 Capacity Guard

```sql
SELECT @Top = @MaxNumbersOfUsers - COUNT(*) FROM Trade.BSLBlackList
IF @Top <= 0 RETURN
```
- Computes remaining capacity and exits immediately if at limit
- Only inserts up to the remaining capacity (TOP @Top)

### 2.2 Customer Eligibility Pipeline

**Step 1**: Load first-time depositors into #Deposits
```sql
SELECT BD.CID, DepositID INTO #Deposits
FROM Billing.Deposit BD INNER JOIN BackOffice.Customer BC ON BC.CID = BD.CID
WHERE IsFTD = 1 AND PaymentDate >= @dt AND BD.CID >= @CID
  AND BC.AccountTypeID <> 9
```
- `IsFTD = 1`: first-time deposit flag from Billing.Deposit
- `@CID = MIN(CID) WHERE Registered > @dt`: only checks customers registered after @dt
- `AccountTypeID <> 9`: excludes fund/managed account types

**Step 2**: Remove depositors without open positions
```sql
DELETE #Deposits WHERE CID NOT IN (SELECT CID FROM Trade.PositionTbl)
```

**Step 3**: Remove already-blacklisted users
```sql
DELETE #Deposits WHERE CID IN (SELECT CID FROM Trade.BSLBlackList)
```

**Step 4**: Insert into BSLBlackList
```sql
INSERT INTO Trade.BSLBlackList (CID, ProcName, DepositID)
SELECT DISTINCT TOP (@Top) CUST.CID,
    CONCAT(OBJECT_SCHEMA_NAME(@@PROCID),'.', OBJECT_NAME(@@PROCID)),  -- 'Trade.TmpInsertUsersToBSLBlackListTable'
    D.DepositID
FROM #Deposits D
INNER JOIN Customer.CustomerStatic CUST ON D.CID = CUST.CID
INNER JOIN Trade.PositionTbl TPOS ON CUST.CID = TPOS.CID
WHERE CUST.CountryID <> 250 AND CUST.PlayerLevelID <> 4
OPTION(RECOMPILE)
```
- ProcName stored as-is for audit trail
- CountryID<>250: Palestine exclusion (likely regulatory)
- PlayerLevelID<>4: exclude internal accounts

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @dt | DATETIME | YES | '20170507' | CODE-BACKED | Cutoff date: only processes customers registered after this date and FTD deposits on or after this date. Default is the system's Go-Live date for this blacklist feature. |
| 2 | @MaxNumbersOfUsers | INT | NO | - | CODE-BACKED | Maximum allowed entries in Trade.BSLBlackList. Procedure exits if table already has this many rows; otherwise inserts up to the remaining capacity. |

### Output

No result sets returned. Side effect: rows inserted into `Trade.BSLBlackList`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Trade.BSLBlackList | WRITE + Lookup (READ) | Target table; read for capacity check and duplicate elimination; written to. |
| CID, MirrorID, StatusID | Trade.PositionTbl | Lookup (READ) | Eligibility filter: CID must have at least one position in PositionTbl. |
| CID, IsFTD, PaymentDate, DepositID | Billing.Deposit | Lookup (READ) | Source of first-time depositors (IsFTD=1) after the cutoff date. |
| CID, AccountTypeID | BackOffice.Customer | Lookup (READ) | AccountTypeID<>9 filter on depositors. |
| CID, CountryID, PlayerLevelID | Customer.CustomerStatic | Lookup (READ) | Country filter (CountryID<>250) and staff filter (PlayerLevelID<>4). |

### 5.2 Referenced By

Not analyzed. Called as a maintenance/batch job, not a real-time operational procedure.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TmpInsertUsersToBSLBlackListTable (procedure)
+-- Trade.BSLBlackList (table) - target + capacity check
+-- Trade.PositionTbl (table) - eligibility filter
+-- Billing.Deposit (table - cross-schema) - FTD source
+-- BackOffice.Customer (table - cross-schema) - account type filter
+-- Customer.CustomerStatic (table - cross-schema) - country + staff filter
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.BSLBlackList | Table | Target for insert; read for capacity count and duplicate check. |
| Trade.PositionTbl | Table | Eligibility filter: customer must have open positions. |
| Billing.Deposit | Table | Source of first-time depositors (IsFTD=1, PaymentDate>=@dt). |
| BackOffice.Customer | Table | AccountTypeID<>9 filter on depositors. |
| Customer.CustomerStatic | Table | CountryID<>250 and PlayerLevelID<>4 filters on final INSERT. |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Capacity guard | Business Rule | @MaxNumbersOfUsers limits BSLBlackList size. Procedure returns without error if at capacity. |
| CountryID=250 exclusion | Business Rule | Palestine accounts excluded from blacklist. Likely regulatory requirement. |
| AccountTypeID<>9 | Business Rule | Specific account type excluded from FTD lookup (likely fund/managed accounts). |
| OPTION(RECOMPILE) | Performance | On final INSERT to handle parameter sensitivity for the large join. |

---

## 8. Sample Queries

### 8.1 Check BSLBlackList capacity before running

```sql
SELECT COUNT(*) AS CurrentCount FROM Trade.BSLBlackList WITH (NOLOCK)
-- If < @MaxNumbersOfUsers, the procedure will insert additional rows
```

### 8.2 Run the blacklist population

```sql
EXEC Trade.TmpInsertUsersToBSLBlackListTable
    @dt = '20170507',
    @MaxNumbersOfUsers = 10000
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TmpInsertUsersToBSLBlackListTable | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TmpInsertUsersToBSLBlackListTable.sql*

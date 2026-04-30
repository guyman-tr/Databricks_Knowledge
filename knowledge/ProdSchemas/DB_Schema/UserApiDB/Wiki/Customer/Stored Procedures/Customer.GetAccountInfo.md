# Customer.GetAccountInfo

> Returns account-level configuration for a user by joining AccountUserInfo with BasicUserInfo (for Registered date).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetAccountInfo retrieves the full account configuration for a user including: affiliate/serial ID, label, trade level, currency, account status, closure status, account type, master account link, manager, guru status, KYC state, and registration date. It joins Customer.AccountUserInfo with Customer.BasicUserInfo to get the Registered timestamp.

---

## 2. Business Logic

No complex business logic. SELECT with JOIN on GCID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | Global Customer ID to retrieve account info for. |

Output columns: GCID, OriginalCID, AffiliateID (aliased SerialID), WhiteLabelID (aliased LabelID), AccountTypeID, CreatedOn (aliased Registered), TradeLevelID, CurrencyID, PendingClosureStatusID, AccountStatusID, MasterAccountCID, ManagerID, SubSerialID, GuruStatusID, KycState, FunnelFromID.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.AccountUserInfo | SELECT FROM | Account configuration data |
| - | Customer.BasicUserInfo | JOIN | Registration date |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetAccountInfo (procedure)
  +-- Customer.AccountUserInfo (table) [done]
  +-- Customer.BasicUserInfo (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.AccountUserInfo | Table | SELECT FROM |
| Customer.BasicUserInfo | Table | JOIN for Registered date |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get account info
```sql
EXEC Customer.GetAccountInfo @gcid = 12345
```

### 8.2 Capture into temp table
```sql
CREATE TABLE #AcctInfo (GCID INT, OriginalCID INT, AffiliateID INT, WhiteLabelID INT, AccountTypeID TINYINT, CreatedOn DATETIME, TradeLevelID INT, CurrencyID INT, PendingClosureStatusID TINYINT, AccountStatusID TINYINT, MasterAccountCID INT, ManagerID INT, SubSerialID VARCHAR(1024), GuruStatusID INT, KycState INT, FunnelFromID INT)
INSERT INTO #AcctInfo EXEC Customer.GetAccountInfo @gcid = 12345
SELECT * FROM #AcctInfo
DROP TABLE #AcctInfo
```

### 8.3 Compare with direct query
```sql
SELECT a.*, b.Registered FROM Customer.AccountUserInfo a WITH (NOLOCK) JOIN Customer.BasicUserInfo b WITH (NOLOCK) ON a.GCID = b.GCID WHERE a.GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetAccountInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetAccountInfo.sql*

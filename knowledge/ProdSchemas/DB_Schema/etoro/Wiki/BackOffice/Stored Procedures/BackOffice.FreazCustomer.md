# BackOffice.FreazCustomer

> Freezes (blocks) a customer account by setting PlayerStatusID=9, sends a blocked-account notification message, and returns the assigned manager's name as an OUTPUT parameter.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer to freeze |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.FreazCustomer (note: intentional typo preserved from original code - "Freaz" not "Freeze") is the BackOffice entry point for blocking a customer account. It sets `Customer.Customer.PlayerStatusID = 9` (Blocked/Frozen) and sends the customer a blocked-account notification via `Customer.SendMessage`. It then retrieves and returns the customer's assigned manager's name via an OUTPUT parameter, allowing the caller to display "Frozen by manager X" in the BackOffice UI.

The procedure was extended in July 2015 (Case 28292, Varchar2NVarchar). A `@ChangeRiskStatus` block that would have called `BackOffice.CustomerSetRiskStatus` is fully commented out - risk status changes on freeze have been decoupled.

Note: The `@Comment` parameter is accepted but never used in the active code. The commented-out `Maintenance.SendMail` and risk status update blocks suggest originally richer freeze logic that has been stripped back over time.

---

## 2. Business Logic

### 2.1 Pre-Freeze Data Fetch

**What**: Loads customer context needed for the blocked notification message.

**Columns/Parameters Involved**: `@CID`, `Customer.Customer.IsReal`, `Customer.Customer.Email`, `Customer.Customer.FirstName`, `Customer.Customer.LastName`

**Rules**:
- SELECT @IsReal, @Email, @FullName (LTRIM/RTRIM ISNULL concat of FirstName + ' ' + LastName) FROM Customer.Customer WHERE CID = @CID.
- @XML = FOR XML PATH(''), Root('Root') of @FullName - used for the (now commented-out) mail step.
- If CID not found, @IsReal/@Email/@FullName remain NULL; the procedure does not guard against this.

### 2.2 Account Freeze

**What**: Marks the customer account as blocked.

**Columns/Parameters Involved**: `@CID`, `Customer.Customer.PlayerStatusID`

**Rules**:
- UPDATE Customer.Customer SET PlayerStatusID = 9 WHERE CID = @CID.
- PlayerStatusID = 9 = Blocked/Frozen (from Dictionary.PlayerStatus).
- Wrapped in BEGIN TRAN FreazCustomer inside TRY/CATCH.
- No @@ROWCOUNT check - silently no-ops if CID not found.

### 2.3 Blocked Notification

**What**: Sends a blocked-account message to the customer.

**Columns/Parameters Involved**: `@CID`, `Customer.SendMessage`

**Rules**:
- EXEC @Ret = Customer.SendMessage @CID, 11, 'http://www.etoro.com/messages/blocked/index.html;300;300'.
- MessageTypeID = 11 (blocked account notification).
- URL points to eToro's legacy blocked account page with 300x300 popup dimensions.
- IF @Ret <> 0: RAISERROR('An error occurred while trying to activate procedure Customer.SendMessage in procedure BackOffice.FreazCustomer', 16, 1) - triggers CATCH.
- COMMIT TRAN FreazCustomer on success.

### 2.4 Manager Name Output

**What**: Returns the customer's assigned manager name to the caller.

**Columns/Parameters Involved**: `@Manager (OUTPUT)`, `BackOffice.Customer.ManagerID`, `BackOffice.Manager`

**Rules**:
- SELECT @Manager = LTRIM(RTRIM(ISNULL(M.FirstName,'') + ' ' + ISNULL(M.LastName,''))) FROM BackOffice.Customer C INNER JOIN BackOffice.Manager M ON C.ManagerID = M.ManagerID WHERE C.CID = @CID.
- Executed AFTER COMMIT (outside the transaction).
- If CID has no manager assigned, @Manager remains NULL.

### 2.5 Commented-Out Code

**What**: Two blocks have been removed from active code:
- `--EXEC Maintenance.SendMail @CID, @IsReal, @Email, 1036, 1, @XML` - legacy email notification, decommissioned.
- Risk status block: `--IF @ChangeRiskStatus = 1 / EXEC BackOffice.CustomerSetRiskStatus ...` - decoupled from freeze flow. @ChangeRiskStatus and @RiskStatusID parameters remain in the signature but are unused.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer to freeze. Used to UPDATE Customer.Customer.PlayerStatusID=9 and lookup manager. No existence guard - silently no-ops if CID not found. |
| 2 | @Comment | VARCHAR(100) | NO | - | CODE-BACKED | Freeze comment/reason. Accepted as parameter but NOT USED in any active code path. Likely intended for audit trail but never implemented. |
| 3 | @ChangeRiskStatus | BIT | NO | - | CODE-BACKED | Whether to also update risk status. Parameter is accepted but the code block using it is fully commented out. Always a no-op. |
| 4 | @RiskStatusID | INT | NO | - | CODE-BACKED | Risk status to set if @ChangeRiskStatus=1. Parameter is accepted but the code block using it is fully commented out. Always a no-op. |
| 5 | @Manager | NVARCHAR(50) | YES | - | CODE-BACKED | OUTPUT: Full name of the customer's assigned BackOffice manager (ISNULL FirstName + ' ' + LastName). NULL if customer has no manager. Retrieved from BackOffice.Manager after freeze commits. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Modifier | UPDATE PlayerStatusID=9 (freeze). Also SELECT for pre-fetch context. |
| @CID | Customer.SendMessage | Caller | EXEC - sends blocked-account notification (MessageTypeID=11). |
| @CID | BackOffice.Customer | Reader | SELECT ManagerID for OUTPUT param resolution. |
| ManagerID | BackOffice.Manager | Lookup | JOIN to resolve ManagerID -> manager full name for @Manager OUTPUT. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice freeze/block workflow | EXEC | Caller | Called by BackOffice agents when freezing a customer account. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.FreazCustomer (procedure)
├── Customer.Customer (table) - UPDATE PlayerStatusID=9 + SELECT pre-fetch
├── Customer.SendMessage (procedure) - EXEC blocked notification
├── BackOffice.Customer (table) - SELECT ManagerID for OUTPUT
└── BackOffice.Manager (table) - JOIN for manager name OUTPUT
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | UPDATE PlayerStatusID=9; SELECT IsReal, Email, FullName |
| Customer.SendMessage | Procedure | EXEC - send blocked notification (MessageTypeID=11) |
| BackOffice.Customer | Table | SELECT ManagerID WHERE CID = @CID |
| BackOffice.Manager | Table | JOIN to resolve manager name for OUTPUT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice agent tooling | External | EXEC - freeze customer flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Typo in procedure name | Legacy | "FreazCustomer" not "FreezeCustomer". Preserved from original (Case 28292, 2015). |
| @Comment unused | Bug/Incomplete | Parameter accepted but never written to any table. No audit trail of freeze reason. |
| @ChangeRiskStatus / @RiskStatusID unused | Decommissioned | Risk status change block is fully commented out. Both parameters are dead. |
| No CID existence guard | Risk | UPDATE and SELECT silently no-op if CID does not exist. No error raised for invalid CID. |
| CATCH: @@TRANCOUNT=1 ROLLBACK, >1 COMMIT | Pattern | Standard nested-transaction-safe error handling. Uncomments THROW to re-raise. |
| Manager fetch outside transaction | Behavior | @Manager OUTPUT SELECT runs after COMMIT - outside the freeze transaction. |
| @XML built but conditionally used | Legacy | FOR XML PATH built for commented-out Maintenance.SendMail. Still executes on every call despite being unused. |

---

## 8. Sample Queries

### 8.1 Freeze a customer
```sql
DECLARE @ManagerName NVARCHAR(50)
EXEC BackOffice.FreazCustomer
    @CID = 12345,
    @Comment = 'Suspicious activity - account frozen pending review',
    @ChangeRiskStatus = 0,
    @RiskStatusID = 0,
    @Manager = @ManagerName OUTPUT
SELECT @ManagerName AS AssignedManager
```

### 8.2 Check if a customer is frozen
```sql
SELECT CID, PlayerStatusID, Username, Email
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345
-- PlayerStatusID = 9 means Blocked/Frozen
```

### 8.3 Count currently frozen customers
```sql
SELECT COUNT(*) AS FrozenCount
FROM Customer.Customer WITH (NOLOCK)
WHERE PlayerStatusID = 9
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.FreazCustomer | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.FreazCustomer.sql*

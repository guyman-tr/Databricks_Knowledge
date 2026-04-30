# BackOffice.CustomerSetAccountType

> Updates a customer's AccountTypeID on BackOffice.Customer and notifies the Customer Dynamics CRM via Service Broker. Validates AccountTypeID against Dictionary.AccountType.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure sets the account type classification for a customer, which determines the nature of their trading account (e.g., real money account, demo account, professional account, institutional). After updating `BackOffice.Customer.AccountTypeID`, it sends an XML message to the Customer Dynamics CRM system via SQL Server Service Broker to keep the CRM in sync.

`AccountTypeID` is a fundamental account classification field. Different account types may have different regulatory treatment, trading capabilities, leverage limits, and fee structures.

The Service Broker integration with `svcDynamics` is notable: unlike sibling procedures (`CustomerFXEligibilityUpdate`, `CustomerSetCashoutFeeGroup`) where the Service Broker was removed, this procedure retains active Dynamics integration. When AccountTypeID changes, the CRM must be notified to update the customer record in Microsoft Dynamics.

The XML payload contains: CID, @OriginalProviderID (with complex legacy calculation from pre-2007 data), OriginalCID, ProviderID, AccountTypeID, and IsReal flag.

---

## 2. Business Logic

### 2.1 AccountTypeID Validation and Update

**What**: Validates AccountTypeID exists before updating, then checks the CID exists.

**Rules**:
- IF NOT EXISTS (SELECT * FROM Dictionary.AccountType WHERE AccountTypeID=@AccountTypeID): RAISERROR(60000), RETURN 60000
- UPDATE BackOffice.Customer SET AccountTypeID=@AccountTypeID WHERE CID=@CID
- IF @@ROWCOUNT=0: RAISERROR(60000), RETURN 60000 (CID not in BackOffice.Customer)

### 2.2 Customer Dynamics CRM Notification via Service Broker

**What**: After the DB update, builds an XML payload and sends it to svcDynamics via Service Broker.

**Rules**:
- Reads Customer.Customer for CID: @OriginalCID, @ProviderID, @IsReal, and a complex @OriginalProviderID calculation
- @OriginalProviderID logic:
  - If OriginalProviderID > 1: use OriginalProviderID as-is
  - Else if OriginalCID = CID (own account): use IsReal
  - Else if Registered < '2007-10-02': use IsReal (pre-2007 account legacy rule)
  - Else: use OriginalProviderID
- Builds XML via FOR XML RAW('Customer'): Action='Update', CID, OriginalProviderID, OriginalCID, ProviderID, AccountTypeID, IsReal
- BEGIN DIALOG CONVERSATION to svcDynamics on 'CURRENT DATABASE' using ctrAnyXMLData contract
- SEND ON CONVERSATION with the XML message
- CATCH: ROLLBACK if outermost tran (@@TRANCOUNT=1), COMMIT if nested; delegates error handling to Internal.CallRaiseError; RETURN error_num

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Must exist in BackOffice.Customer (@@ROWCOUNT check after UPDATE). Also read from Customer.Customer for Dynamics payload. |
| 2 | @AccountTypeID | TINYINT | NO | - | CODE-BACKED | New account type. Must exist in Dictionary.AccountType (validation check 1). Written to BackOffice.Customer.AccountTypeID and included in Dynamics XML payload. |

**Return Values:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 3 | RETURN 0 | INT | Success: DB updated and Service Broker message sent. |
| 4 | RETURN 60000 | INT | Failure: AccountTypeID not in dictionary, or CID not in BackOffice.Customer. |
| 5 | RETURN error_num | INT | CATCH path: error from Internal.CallRaiseError. |

**Unused Variables (legacy artifacts - partial holdovers from removed integrations):**

| Variable | Type | Note |
|----------|------|------|
| @error_num | INT | Used - captures return from Internal.CallRaiseError |
| @OriginalCID through @IsReal | Various | ALL actively used for Dynamics payload construction |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AccountTypeID | Dictionary.AccountType | SELECT (validation) | Validates account type exists before update |
| @CID | BackOffice.Customer | UPDATE | Sets AccountTypeID |
| @CID | Customer.Customer | SELECT (NOLOCK) | Reads OriginalCID, ProviderID, OriginalProviderID, IsReal for Dynamics payload |
| @Handle | svcDynamics (Service Broker) | SEND | Sends account type change notification to Customer Dynamics CRM |
| (CATCH) | Internal.CallRaiseError | EXEC | Delegates CATCH error handling to shared error procedure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice account management | External | Direct call | Called when account type classification changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetAccountType (procedure)
|- Dictionary.AccountType (table) [SELECT: validation]
|- BackOffice.Customer (table) [UPDATE: AccountTypeID]
|- Customer.Customer (table) [SELECT NOLOCK: Dynamics payload fields]
|- svcDynamics (Service Broker service) [SEND: CRM notification]
|- Internal.CallRaiseError (procedure) [EXEC: CATCH error handler]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AccountType | Table | Validation: AccountTypeID must exist |
| BackOffice.Customer | Table | UPDATE: AccountTypeID |
| Customer.Customer | Table | SELECT: OriginalCID, ProviderID, OriginalProviderID, IsReal for Dynamics payload |
| svcDynamics | Service Broker Service | SEND: XML notification to Customer Dynamics |
| Internal.CallRaiseError | Stored Procedure | Error handler in CATCH block |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice account management pipeline | External | Account type assignment and classification |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dictionary.AccountType validation | Application | AccountTypeID must exist before UPDATE |
| CID existence validation | Application | @@ROWCOUNT=0 raises 60000 |
| Active Service Broker | Design | Unlike CustomerFXEligibilityUpdate, this SP still sends to svcDynamics |
| OriginalProviderID legacy logic | Design | Complex 3-branch calculation for pre-2007 accounts |
| TRY/CATCH nested transaction safety | Design | @@TRANCOUNT=1 -> ROLLBACK, >1 -> COMMIT |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Set account type for a customer

```sql
EXEC BackOffice.CustomerSetAccountType
    @CID = 12345,
    @AccountTypeID = 2;
-- RETURN 0 = success (DB updated + Dynamics notified)
-- RETURN 60000 = validation error or CID not found
```

### 8.2 Check valid account types

```sql
SELECT AccountTypeID, Name
FROM Dictionary.AccountType WITH (NOLOCK)
ORDER BY AccountTypeID;
```

### 8.3 Verify update

```sql
SELECT CID, AccountTypeID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerSetAccountType | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetAccountType.sql*

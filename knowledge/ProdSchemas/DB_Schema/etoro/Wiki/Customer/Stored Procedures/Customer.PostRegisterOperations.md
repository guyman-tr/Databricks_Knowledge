# Customer.PostRegisterOperations

> Post-registration orchestrator for dual-environment provisioning: deserializes registration parameters from XML, then conditionally calls Customer.RegisterDemo to create a demo account paired to the real account; controlled by @PartsToDo bit flags and deduplicated against DemoCustomers.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Params XML - serialized registration parameters; @PartsToDo INT - bit flags |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.PostRegisterOperations` is the asynchronous post-registration step that provisions the demo account counterpart for a newly registered real customer. eToro maintains paired real/demo accounts for each customer - the real account is created first (by `Customer.RegisterReal`), and this procedure is then called to create the corresponding demo account in the demo environment.

The procedure accepts all registration parameters serialized as XML (`@Params`), deserializes them, and executes the applicable operations based on the `@PartsToDo` bit mask:
- Bit 0 (value 1): Register the demo environment counterpart.

A deduplication check against `DemoCustomers` (cross-DB table) prevents re-creating a demo account if one already exists for the GCID. This makes the procedure safe to retry on failure.

The `@RetVal` accumulator pattern means partial failures are tracked: if the demo registration fails, `@RetVal` is incremented but the procedure does not re-throw, allowing the caller to see a non-zero return while continuing.

---

## 2. Business Logic

### 2.1 XML Parameter Deserialization

**What**: Extracts all registration parameters from the XML @Params envelope.

**Rules**:
- Uses `.value('(Root/{Field}/@Value)[1]', '{Type}')` XQuery pattern.
- Fields extracted: CIDReal, CIDDemo, CreditDemo, ExternalID, RealProviderID, ChangePasswordDemo, ActionType, LoginID, GameType, SendEmail, AccountTypeID, ChangePassword, RegulationID, RiskStatusID, AffiliateStatusID, WasOrigCIDZero.
- If XML parse fails: @RetVal = -1, RETURN immediately.

### 2.2 Demo Account Provisioning (Bit 0)

**What**: Creates the demo environment account for a real customer.

**Rules**:
- Condition: `@PartsToDo = 0 OR @PartsToDo & 1 = 1` - runs if all parts or specifically bit 0.
- Reads real customer data from `Customer.Customer WHERE CID = @CIDReal`.
- Dedup: IF NOT EXISTS in `DemoCustomers WHERE GCID = @GCID`: EXEC RegisterDemo.
- RegisterDemo called with: AccountExpirationDate='9999-12-31 23:59:59.997', Password='', ExpirationDate=NULL.
- @RetVal incremented (+1) if demo registration fails (CATCH block, no re-throw).

```
Parse @Params XML -> registration fields
IF @PartsToDo = 0 OR bit 0 set:
  Read real customer: CID=@CIDReal
  IF DemoCustomers WHERE GCID != exists:
    EXEC Customer.RegisterDemo (using real customer's fields)
RETURN @RetVal (0=success, >0=partial failure)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Params | XML | NO | - | CODE-BACKED | Serialized registration parameters. Root element with child attributes: Root/CIDReal/@Value, Root/CIDDemo/@Value, Root/CreditDemo/@Value, Root/ExternalID/@Value, etc. |
| 2 | @PartsToDo | INT | NO | - | CODE-BACKED | Bit mask controlling which post-registration operations to execute. Bit 0 (value 1) = create demo account. 0 = execute all parts. |
| 3 | @ID | INT | NO | - | CODE-BACKED | Identifier for the post-registration job instance (used for tracking in History.AsyncFailedSteps per code comment). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CIDReal | Customer.Customer | READ | Gets real customer's registration data to pass to RegisterDemo |
| (dedup) | DemoCustomers | READ (cross-DB) | Checks if demo account already exists for @GCID |
| (demo reg) | Customer.RegisterDemo | EXEC | Creates the demo account counterpart |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Registration API / async job | External | Caller | Called after RegisterReal to complete dual-account provisioning |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.PostRegisterOperations (procedure)
├── Customer.Customer (view) [READ - real customer data]
├── DemoCustomers (cross-DB table) [READ - dedup check]
└── Customer.RegisterDemo (procedure) [EXEC - demo account creation]
      ├── Customer.Customer [INSERT]
      ├── Customer.CustomerMoney [INSERT]
      ├── BackOffice.Customer [INSERT]
      └── Billing.AmountAdd [EXEC]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | READ - loads @CIDReal's registration fields |
| DemoCustomers | Cross-DB Table | READ - GCID deduplication check |
| Customer.RegisterDemo | Procedure | EXEC - creates paired demo account |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Registration API / async job | External | Calls after real registration to provision demo |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| GCID deduplication | Application | IF NOT EXISTS DemoCustomers WHERE GCID - prevents duplicate demo creation on retry |
| @PartsToDo bit mask | Application | 0=all, 1=demo only; extensible for future additional post-register steps |
| Non-throwing CATCH | Application | Demo registration failure increments @RetVal but does not re-throw; partial success pattern |
| XML deserialization failure | Application | Returns -1 immediately if XML parse fails in TRY block |

---

## 8. Sample Queries

### 8.1 Check customers with real account but no demo account

```sql
SELECT cs.CID, cs.GCID, cs.UserName
FROM Customer.CustomerStatic cs WITH (NOLOCK)
WHERE cs.IsReal = 1
  AND NOT EXISTS (
    SELECT 1 FROM DemoCustomers dc
    WHERE dc.GCID = cs.GCID
  )
ORDER BY cs.Registered DESC
```

### 8.2 Example @Params XML format

```xml
<Root>
  <CIDReal Value="12345"/>
  <CIDDemo Value="67890"/>
  <CreditDemo Value="10000000"/>
  <ExternalID Value="123456789012345678"/>
  <RealProviderID Value="1"/>
  <ChangePasswordDemo Value="0"/>
  <ActionType Value="1"/>
  <WasOrigCIDZero Value="1"/>
</Root>
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 8.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.PostRegisterOperations | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.PostRegisterOperations.sql*

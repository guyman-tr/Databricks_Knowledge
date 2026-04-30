# Billing.ProtocolEdit

> Upserts a payment protocol record - creates a new protocol if none exists or updates an existing one, based on whether @ProtocolID is 0 (insert) or non-zero (update).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProtocolID (0 = insert new, >0 = update existing) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Payment protocols are the named gateway configurations that route deposits and withdrawals through a specific payment service and direction. Each protocol has a class key (used by the application layer to instantiate the correct processor) and a human-readable name. `Billing.ProtocolEdit` is the administrative write entry point for this configuration table - used by the back-office to add new payment methods or update the routing details of existing ones.

Without this procedure, changes to payment routing configuration would require direct DML on the `Billing.Protocol` table. This procedure provides a single controlled upsert path with validation to prevent partial or malformed records being inserted.

Data flows from a back-office administration panel or configuration tool through this procedure into `Billing.Protocol`. The zero-vs-nonzero ProtocolID pattern is a classic "save-or-create" idiom: the caller does not need to know whether the protocol already exists - it passes 0 to create, or the known ID to update.

---

## 2. Business Logic

### 2.1 Upsert Pattern (Insert vs Update)

**What**: The procedure acts as a single entry point for both creating new protocols and editing existing ones.

**Columns/Parameters Involved**: `@ProtocolID`, `@PaymentServiceID`, `@ProtocolDirectionID`, `@Name`, `@ClassKey`

**Rules**:
- When `@ProtocolID = 0`: a new row is INSERTed into `Billing.Protocol` with the provided values.
- When `@ProtocolID > 0`: the existing row with that ID is UPDATEd.
- When `@ProtocolID = -1`: the guard clause (`@ProtocolID <> -1`) fails and nothing is written - acts as a "no-op sentinel."
- The procedure returns `@@ROWCOUNT` (1 if a row was written, 0 if validation failed).

**Diagram**:
```
Caller passes @ProtocolID
      |
      v
  [Validation Guard]
  @ProtocolID <> -1
  @Name <> ''
  @PaymentServiceID <> -1
  @ProtocolDirectionID <> 0
  @ClassKey <> ''
      |
      +-- ANY fails --> no DML, RETURN 0
      |
      +-- ALL pass --> @ProtocolID = 0? --> INSERT INTO Billing.Protocol
                                          --> @ProtocolID > 0? --> UPDATE Billing.Protocol WHERE ProtocolID = @ProtocolID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProtocolID | INTEGER | NO | - | CODE-BACKED | Protocol to operate on. 0 = create a new protocol (INSERT path). Any positive integer = update that specific protocol (UPDATE WHERE ProtocolID = @ProtocolID). -1 = sentinel/no-op (validation guard fails). |
| 2 | @PaymentServiceID | INTEGER | NO | - | CODE-BACKED | Foreign key to Billing.PaymentService. Identifies which payment service provider (e.g., PayPal, Neteller, Visa) this protocol belongs to. Validated: must be non -1. |
| 3 | @ProtocolDirectionID | INTEGER | NO | - | CODE-BACKED | Direction of money flow for this protocol. Validated: must be non-zero. Typical values: 1 = Deposit, 2 = Withdrawal (from Billing.ProtocolDirection lookup). |
| 4 | @Name | VARCHAR(50) | NO | - | CODE-BACKED | Human-readable display name for this protocol (e.g., "Visa Deposit EU", "PayPal Withdrawal"). Validated: must be non-empty. Used in back-office and reporting. |
| 5 | @ClassKey | VARCHAR(50) | NO | - | CODE-BACKED | Application-level class identifier that the payment service layer uses to instantiate the correct processor for this protocol (e.g., a .NET type name or key string). Validated: must be non-empty. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProtocolID | Billing.Protocol | Direct write | This procedure is the upsert gateway for Billing.Protocol rows. |
| @PaymentServiceID | Billing.PaymentService | Lookup | Identifies the payment service provider for the protocol. |
| @ProtocolDirectionID | Billing.ProtocolDirection | Lookup | Identifies whether the protocol handles deposits or withdrawals. |

### 5.2 Referenced By (other objects point to this)

No SQL procedure callers found. Called directly by the back-office application layer for protocol configuration management.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ProtocolEdit (procedure)
└── Billing.Protocol (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Protocol | Table | Target of INSERT (new protocol) and UPDATE (edit existing protocol) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application (back-office) | External caller | Called by the payment configuration admin panel to create/edit protocol entries. No SQL-layer callers found. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Validation guard | Application-level (IF block) | All parameters must be non-empty and non-sentinel before any DML is executed. @ProtocolID must be != -1, @Name and @ClassKey must be non-empty strings, @PaymentServiceID must be != -1, @ProtocolDirectionID must be != 0. |

---

## 8. Sample Queries

### 8.1 Create a new protocol

```sql
EXEC Billing.ProtocolEdit
    @ProtocolID = 0,              -- 0 = INSERT new
    @PaymentServiceID = 5,
    @ProtocolDirectionID = 1,     -- 1 = Deposit
    @Name = 'Visa Deposit EU',
    @ClassKey = 'VisaDepositEU'
```

### 8.2 Update an existing protocol's name and class key

```sql
EXEC Billing.ProtocolEdit
    @ProtocolID = 42,             -- Update protocol 42
    @PaymentServiceID = 5,
    @ProtocolDirectionID = 1,
    @Name = 'Visa Deposit EU v2',
    @ClassKey = 'VisaDepositEUv2'
```

### 8.3 View current protocols with service and direction names

```sql
SELECT p.ProtocolID, p.Name, ps.Name AS ServiceName, pd.Name AS Direction, p.ClassKey
FROM Billing.Protocol p WITH (NOLOCK)
JOIN Billing.PaymentService ps WITH (NOLOCK) ON ps.PaymentServiceID = p.PaymentServiceID
JOIN Billing.ProtocolDirection pd WITH (NOLOCK) ON pd.ProtocolDirectionID = p.ProtocolDirectionID
ORDER BY ps.Name, pd.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: skipped | Corrections: 0 applied*
*Object: Billing.ProtocolEdit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ProtocolEdit.sql*

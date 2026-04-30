# Billing.FraudEmailSent_NogaJunk210725

> One-time operational tracking table created on 2021-07-25 by developer "Noga" to prevent duplicate fraud-related emails being sent to customers; currently holds 61 rows from a 2023 RAF compensation run.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | CID - PK CLUSTERED |
| **Partition** | N/A - PRIMARY filegroup |
| **Indexes** | 1 (PK on CID) |

---

## 1. Business Meaning

`Billing.FraudEmailSent_NogaJunk210725` is a one-time operational tracking table. The naming convention "_NogaJunk210725" follows an eToro pattern for personal/temporary tables: `{description}_{developer}Junk{DDMMYY}`. This was created by developer "Noga" on 25 July 2021 ("210725") to track which customers had already received a fraud-related email, preventing duplicate sends.

Despite the "Junk" label, the table has 61 rows - all inserted on 2023-06-05 by the `RAFCompensationProcess` procedure (RAF = Refer a Friend) running as ETORO_ADMIN. The PK on CID ensures each customer appears only once - effectively a deduplication guard: "if this CID is in the table, don't send them another email."

The table is completely inactive now (last insertion 2023-06-05). No stored procedures in the Billing schema reference it directly - `RAFCompensationProcess` was likely a one-time compensation run not preserved in the SSDT repo.

---

## 2. Business Logic

### 2.1 Email Deduplication Guard

**What**: CID-as-PK ensures each customer can have at most one row - insert fails if duplicate attempted.

**Columns/Parameters Involved**: `CID`, `SentAt`, `ProcName`, `InsertedBy`

**Rules**:
```
Pattern: "Idempotent email send tracking"
  INSERT INTO Billing.FraudEmailSent_NogaJunk210725 (CID)
    -> Succeeds: CID not yet in table -> email is new, can be sent
    -> Fails (PK violation): CID already in table -> email was already sent, skip

  SentAt: auto-populated via DEFAULT (GETUTCDATE()) - records when email was sent
  ProcName: auto-populated via DEFAULT (OBJECT_NAME(@@PROCID)) - records which proc sent it
  InsertedBy: auto-populated via DEFAULT (SUSER_SNAME()) - records which SQL login sent it
```

### 2.2 RAF Compensation Context

**What**: All 61 rows were inserted by `RAFCompensationProcess` - indicating this deduplication guard was used during a Refer-a-Friend compensation run in June 2023 where fraud-flagged customers needed to receive a one-time notification email.

**Rules**:
```
2023-06-05 batch: 61 customers processed
  ProcName = "RAFCompensationProcess"
  InsertedBy = "ETORO_ADMIN"
  SentAt range: ~11:18:52 UTC (all within milliseconds = bulk run)
```

---

## 3. Data Overview

| CID | SentAt | ProcName | InsertedBy | Meaning |
|-----|--------|----------|------------|---------|
| 10921579 | 2023-06-05 11:18:52 | RAFCompensationProcess | ETORO_ADMIN | Customer received RAF fraud compensation email |
| 10908891 | 2023-06-05 11:18:52 | RAFCompensationProcess | ETORO_ADMIN | Same batch, ~23ms apart (bulk insert) |
| (59 more) | 2023-06-05 | RAFCompensationProcess | ETORO_ADMIN | All 61 rows from same batch run |

Total: 61 rows. Last insert: 2023-06-05. Table is now dormant.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer who received the fraud-related email. PK - enforces one-email-per-customer deduplication. Implicit FK to Customer.CustomerStatic(CID). |
| 2 | SentAt | datetime | NO | GETUTCDATE() | VERIFIED | UTC timestamp when the email was sent. Auto-populated via DEFAULT to the current UTC time at insertion. All 61 rows have SentAt on 2023-06-05. |
| 3 | ProcName | varchar(50) | YES | OBJECT_NAME(@@PROCID) | VERIFIED | Name of the stored procedure that inserted this row. Auto-populated via DEFAULT to the name of the executing proc. All 61 rows show "RAFCompensationProcess". NULL if inserted ad-hoc outside a named procedure. |
| 4 | InsertedBy | varchar(50) | NO | SUSER_SNAME() | VERIFIED | SQL login that inserted this row. Auto-populated via DEFAULT to the current SQL login name. All 61 rows show "ETORO_ADMIN". |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | Customer who received the email |

### 5.2 Referenced By (other objects point to this)

No stored procedures in the current SSDT repo reference this table. The RAFCompensationProcess that wrote it was likely a one-time script or procedure not preserved in the repo.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FraudEmailSent_NogaJunk210725 (table)
  (no FK constraints in DDL - all relationships implicit)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingFraudEmailSent | CLUSTERED PK | CID ASC | - | - | Active (FILLFACTOR 95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingFraudEmailSent | PRIMARY KEY CLUSTERED | CID - one row per customer (deduplication guarantee) |
| DF_BillingFraudEmailSent_SentAt | DEFAULT | SentAt = GETUTCDATE() at insert time |
| DF_BillingFraudEmailSent_ProcName | DEFAULT | ProcName = OBJECT_NAME(@@PROCID) - auto-captures calling procedure name |
| DF_BillingFraudEmailSent_InsertedBy | DEFAULT | InsertedBy = SUSER_SNAME() - auto-captures SQL login |

---

## 8. Sample Queries

### 8.1 Check if a customer already received the fraud email
```sql
SELECT CID, SentAt, ProcName, InsertedBy
FROM   Billing.FraudEmailSent_NogaJunk210725 WITH (NOLOCK)
WHERE  CID = 10921579;
-- Returns row -> email was sent; no rows -> not yet sent
```

### 8.2 View all 61 records
```sql
SELECT CID, SentAt, ProcName, InsertedBy
FROM   Billing.FraudEmailSent_NogaJunk210725 WITH (NOLOCK)
ORDER BY SentAt DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FraudEmailSent_NogaJunk210725 | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.FraudEmailSent_NogaJunk210725.sql*

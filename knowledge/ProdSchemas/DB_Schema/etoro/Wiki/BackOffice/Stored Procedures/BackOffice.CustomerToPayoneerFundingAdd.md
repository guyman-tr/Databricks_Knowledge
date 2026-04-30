# BackOffice.CustomerToPayoneerFundingAdd

> Registers a customer's Payoneer card for payout, inserting a row into BackOffice.CustomerToPayoneerFunding only if one does not already exist for that customer.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - internal customer identifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CustomerToPayoneerFundingAdd links a customer to their Payoneer prepaid card in the `BackOffice.CustomerToPayoneerFunding` table. Payoneer is a cross-border mass-payout platform; this registration enables eToro to credit the customer's Payoneer card as a withdrawal/payout channel. The procedure enforces a one-per-customer rule: if the customer already has a Payoneer card registered, the INSERT is skipped silently (no error, no update).

As documented in BackOffice.CustomerToPayoneerFunding, the table has minimal data in production (1 test row), indicating Payoneer is either in early deployment or a legacy/inactive payout channel. The `CardNumber` field is protected by SQL Server dynamic data masking.

---

## 2. Business Logic

### 2.1 Guard-Protected Insert (One-Per-Customer)

**What**: Prevents duplicate Payoneer card registrations for the same customer.

**Columns/Parameters Involved**: `@CID`, `@CardNumber`, `@FundingID`, `BackOffice.CustomerToPayoneerFunding.*`

**Rules**:
- IF NOT EXISTS (SELECT 1 FROM BackOffice.CustomerToPayoneerFunding WHERE CID = @CID): INSERT.
- IF EXISTS: no INSERT, no error, no update - the call is a silent no-op.
- No UPDATE path: to change a customer's Payoneer card, use CustomerToPayoneerFundingDelete then CustomerToPayoneerFundingAdd.
- No transaction wrapping - single INSERT in an IF block.

**Diagram**:
```
CID already in CustomerToPayoneerFunding?
  YES -> silent no-op (0 rows affected)
  NO  -> INSERT (CID, CardNumber, FundingID)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Internal Customer ID. Both the existence-check key and the PK for the inserted row in BackOffice.CustomerToPayoneerFunding. |
| 2 | @CardNumber | VARCHAR(50) | NO | - | CODE-BACKED | Payoneer prepaid card number for this customer. Stored in BackOffice.CustomerToPayoneerFunding.CardNumber which is masked with dynamic data masking (default mask = empty string for users without UNMASK privilege). PCI-sensitive. |
| 3 | @FundingID | INT | NO | - | CODE-BACKED | Links to a Billing.Funding record representing the corresponding payment method on eToro's side. Can be NULL in practice (per table data). Enables reconciliation between the Payoneer card and eToro's funding instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.CustomerToPayoneerFunding | Writer | INSERT target - creates the customer-to-Payoneer-card registration row. |
| @FundingID | Billing.Funding | Implicit FK | Links to the eToro funding record for this Payoneer payment method. Nullable - not enforced by DB constraint. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice Payoneer registration workflow | EXEC | Caller | Called when registering a customer's Payoneer card for payout. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerToPayoneerFundingAdd (procedure)
└── BackOffice.CustomerToPayoneerFunding (table) - INSERT target (guard-protected)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerToPayoneerFunding | Table | EXISTS check + conditional INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice Payoneer workflow | External | EXEC - registers customer Payoneer card for payout channel |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| One-per-customer guard | Logic | IF NOT EXISTS check prevents duplicate registration; idempotent on repeated calls. |
| No error on duplicate | Behavior | If CID already exists, returns 0 rows affected silently - caller cannot distinguish between "inserted" and "skipped". |

---

## 8. Sample Queries

### 8.1 Register a Payoneer card for a customer
```sql
EXEC BackOffice.CustomerToPayoneerFundingAdd
    @CID = 12345678,
    @CardNumber = '4444333322221111',
    @FundingID = 567
```

### 8.2 Check if a customer has a Payoneer card registered
```sql
SELECT CID, FundingID
FROM BackOffice.CustomerToPayoneerFunding WITH (NOLOCK)
WHERE CID = 12345678
```

### 8.3 List all registered Payoneer customers
```sql
SELECT
    pf.CID,
    cs.UserName,
    pf.FundingID
FROM BackOffice.CustomerToPayoneerFunding pf WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = pf.CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerToPayoneerFundingAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerToPayoneerFundingAdd.sql*

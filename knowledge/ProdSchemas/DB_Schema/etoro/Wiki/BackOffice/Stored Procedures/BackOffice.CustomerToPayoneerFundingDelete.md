# BackOffice.CustomerToPayoneerFundingDelete

> Removes a customer's Payoneer card registration from BackOffice.CustomerToPayoneerFunding by CID.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - internal customer identifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CustomerToPayoneerFundingDelete removes the link between a customer and their registered Payoneer card in `BackOffice.CustomerToPayoneerFunding`. This is called when a Payoneer payout channel is revoked for a customer - for example, when the card expires, the customer requests removal, or the channel is deactivated for compliance reasons. It is the counterpart to `BackOffice.CustomerToPayoneerFundingAdd`.

No UPDATE procedure exists for Payoneer card data - changing a card requires calling Delete then Add in sequence.

---

## 2. Business Logic

### 2.1 Delete-by-CID

**What**: Removes the customer's single Payoneer card registration unconditionally.

**Columns/Parameters Involved**: `@CID`, `BackOffice.CustomerToPayoneerFunding.CID`

**Rules**:
- DELETE WHERE CID = @CID. Since CID is the PK, at most one row is deleted.
- If no row exists for the CID, affects 0 rows - silent no-op, no error.
- No validation or confirmation before deletion.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Internal Customer ID. The PK of BackOffice.CustomerToPayoneerFunding. Identifies which customer's Payoneer card registration to remove. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.CustomerToPayoneerFunding | Deleter | DELETE target - removes the customer's Payoneer card registration by CID (PK). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice Payoneer deregistration workflow | EXEC | Caller | Called to remove a Payoneer channel. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerToPayoneerFundingDelete (procedure)
└── BackOffice.CustomerToPayoneerFunding (table) - DELETE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerToPayoneerFunding | Table | DELETE WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice Payoneer workflow | External | EXEC - removes Payoneer card registration, paired with CustomerToPayoneerFundingAdd for card change |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Silent no-op | Behavior | DELETE on missing CID returns 0 rows affected without error. |

---

## 8. Sample Queries

### 8.1 Remove a customer's Payoneer registration
```sql
EXEC BackOffice.CustomerToPayoneerFundingDelete @CID = 12345678
```

### 8.2 Verify the registration was removed
```sql
SELECT COUNT(*) AS RowsRemaining
FROM BackOffice.CustomerToPayoneerFunding WITH (NOLOCK)
WHERE CID = 12345678
```

### 8.3 View all current Payoneer registrations
```sql
SELECT pf.CID, cs.UserName, pf.FundingID
FROM BackOffice.CustomerToPayoneerFunding pf WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = pf.CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerToPayoneerFundingDelete | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerToPayoneerFundingDelete.sql*

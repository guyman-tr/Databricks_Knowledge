# BackOffice.CustomerToThirdPartyFundingsAdd

> Records an approved third-party funding relationship, linking a FundingID to a customer CID in the AML/fraud review registry.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingID + @CID - matches composite PK of BackOffice.CustomerToThirdPartyFundings |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CustomerToThirdPartyFundingsAdd inserts a (FundingID, CID) pair into `BackOffice.CustomerToThirdPartyFundings`, recording that BackOffice has reviewed and documented a third-party funding relationship. This is called when an agent confirms that a customer (CID) used a payment method (FundingID) that is also linked to another customer - a situation flagged by the system as potential straw-man funding, card sharing, or family funding.

Presence of the pair in the table suppresses duplicate fraud alerts for the same relationship. The procedure performs a plain INSERT with no existence guard - duplicate CID+FundingID insertions will fail with a PK violation (the table has a clustered composite PK on (FundingID, CID)). Callers must verify the pair does not already exist before calling.

Note the INSERT VALUES order matches the table's column definition: `@FundingID` first, then `@CID` - despite the parameters being declared `@CID, @FundingID` in that order.

---

## 2. Business Logic

### 2.1 Plain Insert - No Existence Guard

**What**: Directly inserts the third-party funding pair without checking for duplicates.

**Columns/Parameters Involved**: `@CID`, `@FundingID`, `BackOffice.CustomerToThirdPartyFundings.*`

**Rules**:
- INSERT INTO BackOffice.CustomerToThirdPartyFundings VALUES(@FundingID, @CID) - column order is (FundingID, CID) matching the table PK definition.
- No IF NOT EXISTS guard - duplicate (FundingID, CID) calls will raise a PK violation error.
- Caller is responsible for ensuring the pair is not already registered.
- Counterpart: CustomerToThirdPartyFundingsDelete removes the relationship by CID + FundingID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Internal Customer ID. Identifies the customer who used a third-party payment method. Inserted as second column (after @FundingID) per table column order. |
| 2 | @FundingID | INT | NO | - | CODE-BACKED | The funding method (Billing.Funding) that the customer used but is also associated with another customer. This is the payment instrument that triggered the third-party flag. Inserted as first column per the (FundingID, CID) composite PK order. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID + @CID | BackOffice.CustomerToThirdPartyFundings | Writer | INSERT target - records the reviewed third-party funding relationship. |
| @FundingID | Billing.Funding | Implicit FK | Identifies the shared payment instrument. Not enforced by DB FK. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice fraud/AML review workflow | EXEC | Caller | Called when an agent approves and documents a third-party funding relationship after review. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerToThirdPartyFundingsAdd (procedure)
└── BackOffice.CustomerToThirdPartyFundings (table) - INSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerToThirdPartyFundings | Table | INSERT - records the approved third-party funding pair |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice AML workflow | External | EXEC - records approved third-party funding after fraud review |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No duplicate guard | Risk | No IF NOT EXISTS check - PK violation on duplicate (FundingID, CID) call. Caller must pre-check. |
| INSERT column order | Behavior | VALUES(@FundingID, @CID) - FundingID goes first, matching the (FundingID, CID) composite PK column order despite the parameter declaration order being @CID, @FundingID. |

---

## 8. Sample Queries

### 8.1 Record an approved third-party funding relationship
```sql
EXEC BackOffice.CustomerToThirdPartyFundingsAdd @CID = 12345678, @FundingID = 98765
```

### 8.2 Check if a pair already exists before inserting
```sql
SELECT 1
FROM BackOffice.CustomerToThirdPartyFundings WITH (NOLOCK)
WHERE CID = 12345678 AND FundingID = 98765
```

### 8.3 List all third-party funding relationships for a customer
```sql
SELECT tpf.CID, tpf.FundingID, cs.UserName
FROM BackOffice.CustomerToThirdPartyFundings tpf WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = tpf.CID
WHERE tpf.CID = 12345678
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerToThirdPartyFundingsAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerToThirdPartyFundingsAdd.sql*

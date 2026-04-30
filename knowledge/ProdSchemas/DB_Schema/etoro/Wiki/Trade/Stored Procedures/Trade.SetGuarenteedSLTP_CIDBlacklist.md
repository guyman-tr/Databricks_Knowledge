# Trade.SetGuarenteedSLTP_CIDBlacklist

> Upserts a CID into the Guaranteed SL/TP blacklist: inserts the CID if not present, or sets GuarenteedSLTP=0 (disabled) if already in the table.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT - the customer to add to or update in the blacklist |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Guaranteed Stop Loss/Take Profit (GSLTP) is a premium feature allowing customers to set a stop-loss or take-profit that is guaranteed to execute at exactly the specified price, even during gaps. Customers on the `Trade.GuarenteedSLTP_CIDBlacklist` are excluded from this feature.

This procedure adds a customer to the blacklist or disables their GSLTP entitlement if they are already on the list. The MERGE pattern ensures idempotency:
- First call for a CID: inserts a new row (GuarenteedSLTP defaults to 0 per table default, or explicitly set)
- Subsequent calls: sets GuarenteedSLTP=0 (explicitly disables, in case it was re-enabled manually)

Note: The INSERT branch only inserts the CID column - the GuarenteedSLTP column is not explicitly set in the INSERT, relying on the column default. The MATCH branch explicitly sets GuarenteedSLTP=0. The name contains the typo "Guarenteed" (should be "Guaranteed") - preserved from the original schema.

---

## 2. Business Logic

### 2.1 Blacklist Upsert

**What**: Ensures a CID is on the GSLTP blacklist with GuarenteedSLTP=0.

**Columns/Parameters Involved**: `Trade.GuarenteedSLTP_CIDBlacklist.CID`, `Trade.GuarenteedSLTP_CIDBlacklist.GuarenteedSLTP`

**Rules**:
- MERGE target: Trade.GuarenteedSLTP_CIDBlacklist, match on CID
- WHEN MATCHED: UPDATE SET GuarenteedSLTP=0 (explicit disable)
- WHEN NOT MATCHED: INSERT(CID) VALUES(@CID) - only CID; GuarenteedSLTP uses column default

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | The customer to blacklist from Guaranteed SL/TP. If not on the list, inserted. If already present, GuarenteedSLTP is set to 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MERGE target | Trade.GuarenteedSLTP_CIDBlacklist | Modifier | Upserts the CID: inserts new or disables GSLTP for existing |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - called by operations tools when disabling GSLTP for a customer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetGuarenteedSLTP_CIDBlacklist (procedure)
|- Trade.GuarenteedSLTP_CIDBlacklist (table - upsert target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GuarenteedSLTP_CIDBlacklist | Table | MERGE target - CID blacklist for Guaranteed SL/TP feature |

### 6.2 Objects That Depend On This

No dependents found - called by ops/compliance tools for customer GSLTP management.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Idempotent | Logic | MERGE is idempotent - safe to call multiple times |
| INSERT default | Logic | INSERT only specifies CID; GuarenteedSLTP relies on column default (likely 0) |
| Schema typo | Note | "Guarenteed" (misspelled) is preserved throughout the schema - consistent but incorrect spelling |

---

## 8. Sample Queries

### 8.1 Blacklist a customer from Guaranteed SL/TP

```sql
EXEC Trade.SetGuarenteedSLTP_CIDBlacklist @CID = 12345
```

### 8.2 Check if a customer is blacklisted

```sql
SELECT CID, GuarenteedSLTP
FROM Trade.GuarenteedSLTP_CIDBlacklist WITH (NOLOCK)
WHERE CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetGuarenteedSLTP_CIDBlacklist | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetGuarenteedSLTP_CIDBlacklist.sql*

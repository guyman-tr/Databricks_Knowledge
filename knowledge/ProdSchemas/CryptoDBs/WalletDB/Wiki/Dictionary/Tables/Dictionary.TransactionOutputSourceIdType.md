# Dictionary.TransactionOutputSourceIdType

> Lookup table defining the source identifier type for sent transaction outputs, tracking what entity the output references.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint IDENTITY(0,1), PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table identifies what type of entity a sent transaction output's SourceId refers to. When a blockchain transaction has multiple outputs (e.g., Bitcoin UTXO model), each output may reference a different source entity. Currently only one type exists - PositionId - indicating that the output is linked to a trading position.

No direct references found in the Wallet schema SSDT, suggesting it is consumed by application-layer code.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single-value lookup currently mapping outputs to position IDs.

---

## 3. Data Overview

| Id | Description | Meaning |
|---|---|---|
| 0 | PositionId | The transaction output's SourceId column contains a trading position identifier. Links the blockchain transaction output back to the eToro trading position that originated the crypto movement. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | IDENTITY(0,1) | CODE-BACKED | Unique identifier starting from 0. Currently: 0=PositionId. Maps output source IDs to their entity type. |
| 2 | Description | nvarchar(100) | NO | - | CODE-BACKED | Description of the source entity type. Uses nvarchar (Unicode). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct references found in the Wallet schema SSDT.

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No direct dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TransactionOutputSourceIdType_Id | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all source ID types
```sql
SELECT Id, Description FROM Dictionary.TransactionOutputSourceIdType WITH (NOLOCK) ORDER BY Id
```

### 8.2 Resolve source type for a transaction output
```sql
SELECT Description FROM Dictionary.TransactionOutputSourceIdType WITH (NOLOCK) WHERE Id = 0
```

### 8.3 All types with their meaning
```sql
SELECT Id, Description, 'Links output to a trading position' AS BusinessContext
FROM Dictionary.TransactionOutputSourceIdType WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 3.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.TransactionOutputSourceIdType | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.TransactionOutputSourceIdType.sql*

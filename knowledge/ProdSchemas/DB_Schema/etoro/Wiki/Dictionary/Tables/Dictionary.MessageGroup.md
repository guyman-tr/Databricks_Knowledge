# Dictionary.MessageGroup

> Defines alphabetic group codes used to categorize and route payment status messages in the billing subsystem.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MessageGroupID (int, IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 1 unique NC on MessageGroupName |

---

## 1. Business Meaning

Dictionary.MessageGroup assigns alphabetic group codes (A through AZ, plus special codes like CA, GP) to categorize payment status messages. These groups are used by the billing system to organize and route payment notifications — each message from a payment provider is tagged with a message group that determines how it's processed and displayed.

Without this table, the billing system could not categorize incoming PSP messages or map them to appropriate processing workflows. The group codes act as routing keys for the Billing.PaymentStatusMessageGroup mapping, which links payment statuses to their message categories.

Referenced by Billing.PaymentStatusMessageGroup (MessageGroupID FK) and read by Billing.GetMessageGroup procedure. The sequential alphabetic naming (A, B, C... AA, AB...) suggests these groups were created incrementally as new payment flows were added.

---

## 2. Business Logic

### 2.1 Alphabetic Group Coding System

**What**: Sequential alphabetic codes for billing message categorization.

**Columns/Parameters Involved**: `MessageGroupID`, `MessageGroupName`

**Rules**:
- Groups 1-26 use single letters A through Z
- Groups 27-52 use double letters AA through AZ
- Groups 53+ use special codes (CA, BA, CC, GP) — likely added for specific payment flows
- Group names are unique (enforced by DMRG_U_Key constraint)
- Identity column auto-generates IDs — IDENTITY(1,1)

---

## 3. Data Overview

| MessageGroupID | MessageGroupName | Meaning |
|---|---|---|
| 1 | A | First message group — used for the primary/default payment status message category |
| 26 | Z | Last single-letter group — the 26th message routing category |
| 27 | AA | First double-letter group — extended categories added when single letters were exhausted |
| 53 | CA | Special group code, likely for a specific payment flow (e.g., card-related messages) |
| 58 | GP | Special group code, possibly for gateway/provider-specific messages |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MessageGroupID | int (IDENTITY) | NO | - | CODE-BACKED | Auto-incrementing primary key. Values 1-58 (with gaps at 56-57). Referenced by Billing.PaymentStatusMessageGroup as the message category identifier. |
| 2 | MessageGroupName | varchar(40) | NO | - | CODE-BACKED | Alphabetic group code (A-Z, AA-AZ, CA, BA, CC, GP). Enforced unique by DMRG_U_Key constraint. Used as routing keys in the billing message processing pipeline. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.PaymentStatusMessageGroup | MessageGroupID | Implicit | Maps payment statuses to message groups for routing |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PaymentStatusMessageGroup | Table | MessageGroupID FK |
| Billing.GetMessageGroup | Stored Procedure | Reads message groups |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DMRG | CLUSTERED PK | MessageGroupID | - | - | Active |
| DMRG_U_Key | NC UNIQUE | MessageGroupName | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DMRG_U_Key | UNIQUE | Ensures each message group has a unique alphabetic code |

---

## 8. Sample Queries

### 8.1 List all message groups
```sql
SELECT  MessageGroupID,
        MessageGroupName
FROM    [Dictionary].[MessageGroup] WITH (NOLOCK)
ORDER BY MessageGroupID;
```

### 8.2 Find payment statuses for a specific message group
```sql
SELECT  psmg.*,
        mg.MessageGroupName
FROM    [Billing].[PaymentStatusMessageGroup] psmg WITH (NOLOCK)
JOIN    [Dictionary].[MessageGroup] mg WITH (NOLOCK)
        ON psmg.MessageGroupID = mg.MessageGroupID
WHERE   mg.MessageGroupName = 'A';
```

### 8.3 Count payment status mappings per group
```sql
SELECT  mg.MessageGroupName,
        COUNT(*) AS StatusCount
FROM    [Billing].[PaymentStatusMessageGroup] psmg WITH (NOLOCK)
JOIN    [Dictionary].[MessageGroup] mg WITH (NOLOCK)
        ON psmg.MessageGroupID = mg.MessageGroupID
GROUP BY mg.MessageGroupName
ORDER BY mg.MessageGroupName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MessageGroup | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MessageGroup.sql*

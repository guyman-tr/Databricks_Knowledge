# BackOffice.FundingDocumentRequiredUpdate

> Sets the DocumentRequired flag on a specific customer payment instrument, indicating whether supporting documentation is needed for transactions on that funding method.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingID - targets a single Billing.Funding row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.FundingDocumentRequiredUpdate` is a targeted administrative procedure that toggles the `DocumentRequired` compliance flag on a single customer payment instrument (Billing.Funding row). When this flag is set to 1, the system requires the customer to provide supporting documentation before transactions can be processed against that payment method - a key compliance and KYC enforcement mechanism.

This procedure exists to give BackOffice operations staff a controlled, single-purpose write path into the compliance state of payment instruments. Rather than allowing direct table updates, the procedure encapsulates the operation with named, typed parameters.

The procedure is called when a compliance officer or operations manager determines that a particular payment method needs additional scrutiny. Setting `DocumentRequired=1` triggers downstream document collection flows; setting it back to 0 clears the requirement. The flag defaults to 0 (not required) at registration time.

---

## 2. Business Logic

### 2.1 Document Requirement Toggle

**What**: Flips the compliance documentation flag for a specific registered payment instrument.

**Columns/Parameters Involved**: `@FundingID`, `@DocumentRequired`

**Rules**:
- A value of 1 means the customer must provide supporting documents before this payment method can be used for deposits or withdrawals.
- A value of 0 clears the requirement (default state at Billing.Funding creation).
- The update is unconditional - there is no status check or guard; the caller is responsible for validating whether the state change is appropriate.
- Only one record is updated per call (WHERE FundingID = @FundingID is a PK lookup - always exactly one row or zero if FundingID does not exist).

**Diagram**:
```
BackOffice Staff                    Database
     |                                  |
     |--[FundingID, DocumentRequired]--->|
     |                                  |
     |                    Billing.Funding PK lookup
     |                    SET DocumentRequired = @DocumentRequired
     |                                  |
     |<-----------[implicit OK]---------|
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INT | NO | - | CODE-BACKED | Primary key of the Billing.Funding record to update. Identifies the exact customer payment instrument (credit card, bank account, e-wallet, etc.) whose DocumentRequired flag will be changed. Must match an existing FundingID; no error is raised if the ID does not exist (0 rows affected). |
| 2 | @DocumentRequired | BIT | NO | - | CODE-BACKED | New value for the DocumentRequired compliance flag on the payment instrument. 1=Documentation required (customer must submit supporting docs before using this payment method); 0=Not required (default state, transactions allowed without additional docs). Inherited from Billing.Funding.DocumentRequired. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID | Billing.Funding | Lookup / UPDATE target | Updates the DocumentRequired column on the matching payment instrument row. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No callers found via Grep across the SQL repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.FundingDocumentRequiredUpdate (procedure)
└── Billing.Funding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | Single-row UPDATE by PK (FundingID) to set DocumentRequired column. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | No procedures in the repository call this procedure. Invoked externally (application or BackOffice UI). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. The procedure has no internal guards or validations beyond parameter typing. The underlying Billing.Funding.DocumentRequired column has DEFAULT((0)) and is NOT NULL.

---

## 8. Sample Queries

### 8.1 Set document requirement for a funding instrument
```sql
-- Flag a payment instrument as requiring documentation (compliance hold)
EXEC BackOffice.FundingDocumentRequiredUpdate
    @FundingID = 1045321,
    @DocumentRequired = 1;
```

### 8.2 Clear document requirement for a funding instrument
```sql
-- Remove documentation requirement after documents have been received and verified
EXEC BackOffice.FundingDocumentRequiredUpdate
    @FundingID = 1045321,
    @DocumentRequired = 0;
```

### 8.3 Verify current state before and after update
```sql
-- Check current DocumentRequired state for a funding record
SELECT
    FundingID,
    FundingTypeID,
    DocumentRequired,
    DateCreated
FROM Billing.Funding WITH (NOLOCK)
WHERE FundingID = 1045321;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.FundingDocumentRequiredUpdate | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.FundingDocumentRequiredUpdate.sql*

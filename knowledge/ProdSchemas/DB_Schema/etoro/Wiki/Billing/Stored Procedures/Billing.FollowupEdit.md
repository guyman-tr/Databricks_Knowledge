# Billing.FollowupEdit

> Updates the follow-up tracking fields on a withdraw rejection record - the back-office case management SP for withdrawal dispute/follow-up workflows.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Billing.WithdrawRejects (CaseDate, FollowupDate, Comment, CaseNumber) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FollowupEdit` updates case management fields on a `Billing.WithdrawRejects` record. When a withdrawal is rejected, back-office agents manage the follow-up process: scheduling follow-up dates, recording case numbers (external reference in a CRM/ticketing system), and logging comments. This SP is the write interface for those follow-up management fields.

---

## 2. Business Logic

**Rules**: `UPDATE Billing.WithdrawRejects SET CaseDate=@CaseDate, FollowupDate=@FollowupDate, Comment=@Comment, CaseNumber=@CaseNumber WHERE WithdrawID=@WithdrawID`. No validation, no audit trail, no transaction.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INT | NO | - | CODE-BACKED | PK of the withdraw rejection record. FK to Billing.WithdrawRejects.WithdrawID. No existence check. |
| 2 | @CaseDate | DATETIME | NO | - | CODE-BACKED | Date the rejection case was opened or last actioned. Written to Billing.WithdrawRejects.CaseDate. |
| 3 | @FollowupDate | DATETIME | NO | - | CODE-BACKED | Scheduled follow-up date for this case. Written to Billing.WithdrawRejects.FollowupDate. |
| 4 | @Comment | NVARCHAR(MAX) | NO | - | CODE-BACKED | Agent notes or comments about the rejection case. Written to Billing.WithdrawRejects.Comment. |
| 5 | @CaseNumber | INT | NO | - | CODE-BACKED | External case/ticket number (CRM or support system reference). Written to Billing.WithdrawRejects.CaseNumber. |

---

## 5. Relationships

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.WithdrawRejects | MODIFIER (UPDATE) | Updates case management fields. |

---

## 6. Dependencies

```
Billing.FollowupEdit (procedure)
+-- Billing.WithdrawRejects (table)
```

---

## 7. Technical Details

No transaction, no audit, no validation.

---

## 8. Sample Queries

```sql
EXEC [Billing].[FollowupEdit]
    @WithdrawID = 5678,
    @CaseDate = '2026-03-18 09:00:00',
    @FollowupDate = '2026-03-25 09:00:00',
    @Comment = N'Customer contacted, awaiting additional verification documents.',
    @CaseNumber = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FollowupEdit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FollowupEdit.sql*

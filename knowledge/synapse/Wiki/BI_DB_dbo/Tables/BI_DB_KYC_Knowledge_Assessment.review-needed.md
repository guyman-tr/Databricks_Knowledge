# BI_DB_dbo.BI_DB_KYC_Knowledge_Assessment — Review Needed

## Tier 4 Items

None.

## Reviewer Questions

1. **Answer correctness mapping**: The SP scores answers 142 and 144 as +2 (correct), while 143, 145, 146 are scored as -2 (incorrect). Are these the actual correct/incorrect answers for the Trading Knowledge Assessment, or has the scoring logic changed?
2. **101-104 version**: Only AnswerID 102 is considered correct. What do the other answers (101, 103, 104, 127) represent?
3. **Q23_AnswerText and Q23_AnswerID**: These columns appear to be legacy/unused (all 'N/A' and -1). Are they still needed or could they be deprecated?
4. **Multiple versions per customer**: Can a customer have results for both 142-146 and 101-104 versions? If so, which version's pass result takes precedence?

## Cross-Object Consistency

- GCID matches the convention used across the KYC Panel family (BI_DB_KYC_Panel, BI_DB_KYC_Questions_Answers_Row_Data).
- This table is a component of the larger KYC Panel system (SP_KYC_Panel is the parent SP).

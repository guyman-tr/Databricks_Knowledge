with cases as (
SELECT 
c.CaseNumber,c.CreatedDate,c.CaseOwnerTitle,c.OwnerSubRole,c.Sub_Type,c.Sub_Type_2,c.Status,ch.CreatedDate AS ChangeDate,c.CaseID,

case when ch.OldValue='00G1p000001xqrLEAQ' then 'OPS CS World Check' 
when ch.OldValue='00G08000002gROzEAM' then 'AML USA'
when ch.OldValue='00G1p000002OIXVEA4' then 'AML Cyprus'
when ch.OldValue='00G08000002ALq1EAG' then 'APU Check Ups'
when ch.OldValue='00G080000038nqjEAA' then 'AML Seychelles'
when ch.OldValue='00G08000002gMZfEAM' then 'OPS CS AML'
when ch.OldValue='00G08000002gyOGEAY' then 'Fallback Case'
when ch.OldValue='00G08000002AWd3EAG' then 'AML Closures'
when ch.OldValue='00G08000002DLKAEA4' then 'AML UK'
when ch.OldValue='00G08000002ARPGEA4' then 'Account Closures'
when ch.OldValue='0050800000FCToKAAX' then 'Bot eToro'
when ch.OldValue='00G08000002gROuEAM' then 'AML Australia'
when ch.OldValue='00G08000003DAPQEA4' then 'AML ADGM'
when ch.OldValue='00G08000002cMI0EAM' then 'AML - Non Responsive Closures'
when ch.OldValue='00G08000003DAPQEA4' then 'AML ADGM'
when ch.OldValue='00G1p000002WPP2EAO' then 'AML/OPS'
when ch.OldValue='00G1p000002WWktEAG' then 'OPS CS Verification'
when ch.OldValue='00G080000038pVdEAI' then 'OPS Teams Escalation'
when ch.OldValue='00G08000002DGbXEAW' then 'Risk eToro Money'
when ch.OldValue='00G08000003GzVZEA0' then 'eToro Money FinCrime'
when ch.OldValue='00G08000002gPOuEAM' then 'Escalation Team'
when ch.OldValue='00G08000002DYBvEAO' then 'OPS CS Cashouts'
when ch.OldValue='00G08000002DOFIEA4' then 'Lost wire COs / Returned wire COs'
when ch.OldValue='00G08000002DKr3EAG' then 'Operations Money'
when ch.OldValue='00G08000002hDGFEA2' then 'eToro X AML'
when ch.OldValue='00G1p000001ZLXJEA4' then 'Compliance CY'
when ch.OldValue='00G08000002DOFDEA4' then 'Lost credit card COs'
when ch.OldValue='00G08000002hBnEEAU' then 'OPS CS AML Escalation'
when ch.OldValue='00GJ6000000y9ZxMAI' then 'FCMU - EDD project escalations'
else A.SubRole  END as OldOwner,
 concat(A.FirstName,' ',A.LastName) as previousAgent,
ch.OldValue,
case when ch.NewValue='00G1p000001xqrLEAQ' then 'OPS CS World Check' 
when ch.NewValue='00G08000002gROzEAM' then 'AML USA'
when ch.NewValue='00G1p000002OIXVEA4' then 'AML Cyprus'
when ch.NewValue='00G08000002ALq1EAG' then 'APU Check Ups'
when ch.NewValue='00G080000038nqjEAA' then 'AML Seychelles'
when ch.NewValue='00G08000002gMZfEAM' then 'OPS CS AML'
when ch.NewValue='00G08000002gyOGEAY' then 'Fallback Case'
when ch.NewValue='00G08000002AWd3EAG' then 'AML Closures'
when ch.NewValue='00G08000002DLKAEA4' then 'AML UK'
when ch.NewValue='00G08000002ARPGEA4' then 'Account Closures'
when ch.NewValue='0050800000FCToKAAX' then 'Bot eToro'
when ch.NewValue='00G08000002gROuEAM' then 'AML Australia'
when ch.NewValue='00G08000002cMI0EAM' then 'AML - Non Responsive Closures'
when ch.NewValue='00G08000003DAPQEA4' then 'AML ADGM'
when ch.NewValue='00G1p000002WPP2EAO' then 'AML/OPS'
when ch.NewValue='00G1p000002WWktEAG' then 'OPS CS Verification'
when ch.NewValue='00G080000038pVdEAI' then 'OPS Teams Escalation'
when ch.NewValue='00G08000002DGbXEAW' then 'Risk eToro Money'
when ch.NewValue='00G08000003GzVZEA0' then 'eToro Money FinCrime'
when ch.NewValue='00G08000002gPOuEAM' then 'Escalation Team'
when ch.NewValue='00G08000002DYBvEAO' then 'OPS CS Cashouts'
when ch.NewValue='00G08000002DOFIEA4' then 'Lost wire COs / Returned wire COs'
when ch.NewValue='00G08000002DKr3EAG' then 'Operations Money'
when ch.NewValue='00G08000002hDGFEA2' then 'eToro X AML'
when ch.NewValue='00G1p000001ZLXJEA4' then 'Compliance CY'
when ch.NewValue='00G08000002DOFDEA4' then 'Lost credit card COs'
when ch.NewValue='00G08000002hBnEEAU' then 'OPS CS AML Escalation'
when ch.NewValue='00GJ6000000y9ZxMAI' then 'FCMU - EDD project escalations'
ELSE A2.SubRole end AS NewOwner,
 concat(A2.FirstName," ",A2.LastName) as newagent,ch.NewValue
from 
    bi_output.bi_output_customer_customer_support_case c
   left  join crm.silver_casehistory ch on ch.CaseId=c.CaseID and ch.Field='Owner'
    and ch.DataType='EntityId'
   LEFT JOIN bi_output.bi_output_customer_customer_support_agent_user A ON A.ID=ch.OldValue and ((cast(ch.CreatedDate AS DATE) BETWEEN CAST(A.FromDate AS DATE) AND  CAST(A.ToDate AS DATE)) or (cast(ch.CreatedDate AS DATE) <(CAST(A.ToDate AS DATE))))
LEFT JOIN bi_output.bi_output_customer_customer_support_agent_user A2 ON A2.ID=ch.NewValue and ((cast(ch.CreatedDate AS DATE) BETWEEN CAST(A2.FromDate AS DATE) AND  CAST(A2.ToDate AS DATE)) or (cast(ch.CreatedDate AS DATE) <(CAST(A2.ToDate AS DATE))))
where c.Sub_Type='Screening'
AND c.Sub_Type_2='Perfect Match'
and c.CreatedDate >='2024-01-01'
order by c.CaseNumber,ChangeDate asc),

enhanced_cases AS (
    SELECT *,
           LAG(ChangeDate) OVER (PARTITION BY CaseNumber ORDER BY ChangeDate) AS PrevChangeDate,
           MIN(CreatedDate) OVER (PARTITION BY CaseNumber) AS CaseCreatedDate
    FROM cases
)
SELECT *,
       CASE 
           WHEN NewOwner IS NOT NULL THEN NewOwner 
           ELSE newagent 
       END AS New_Owner,
       CASE 
           WHEN OldOwner IS NOT NULL THEN OldOwner 
           ELSE previousAgent 
       END AS Previous_Owner,

       -- Fractional hours
       TIMESTAMPDIFF(SECOND, 
           COALESCE(PrevChangeDate, CaseCreatedDate), 
           ChangeDate) / 3600.0 AS Hours_Since_Last_Change,

       -- Fractional days
       TIMESTAMPDIFF(SECOND, 
           COALESCE(PrevChangeDate, CaseCreatedDate), 
           ChangeDate) / 86400.0 AS Days_Since_Last_Change

FROM enhanced_cases
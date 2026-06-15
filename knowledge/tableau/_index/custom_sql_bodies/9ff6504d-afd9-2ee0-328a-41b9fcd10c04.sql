select 
CaseNumber as DuplicateCaseNumber,
Cast(ClosedDate as Date) AS DuplicateClosedDate,
OwnerId AS DuplicateOwner
from main.bi_output.bi_output_customer_customer_support_case
where Duplicate='true'
and Origin='Chat' 
and Status='Closed'
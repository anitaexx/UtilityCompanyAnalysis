Business Case Question: 

**Flag customers who are marked as Residential in DimCustomer but whose accounts are Commercial or Small Commercial in DimAccount (data inconsistency).

**Inactive accounts with recent activity
List accounts marked as AccountStatus = 'Inactive' but still having usage transactions.

**Same customer, multiple accounts
Find customers (Residential + Small Comm) who have more than 1 account under their name 

** Find all customers with the same service address linked to multiple accounts

**Refund abuse
Find customers where the total Refund amount > total Payment amount, in a month
Detect cases where a Refund was issued to a customer who never received a Bill.

**High outstanding balances
For each customer, calculate total Billed – total Payments – total Refunds + total Late Fees, and return those with balances > $1000.

**Create an aging report 30 days 60days 90days 90+days

**Critical Care with late fees
Critical Care customers should ideally not have service interruptions. Find all Critical Care Residential customers who were ever charged a Late Fee.

**Critical Care total TDU charges month by month for reimbursement 



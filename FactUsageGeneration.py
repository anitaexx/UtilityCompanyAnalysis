import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

dim_customers = pd.read_csv("DimCustomer.csv", parse_dates=['CreateDate', 'DOB'])
dim_accounts = pd.read_csv("DimAccounts.csv", parse_dates=['CreateDate'])


# Keep only active accounts
dim_accounts = dim_accounts[dim_accounts['AccountStatus'] == 'Active']


# Merge accounts with customer info like a join
accounts = dim_accounts.merge(dim_customers[['CustomerID', 'customer_type']], on='CustomerID', how='left')


start_year = 2025
months = range(1, 10)  # Jan–Sep

payment_prob = {'Residential': 0.95, 'Small Commercial': 0.85, 'Commercial': 0.85}
refund_prob = 0.05
late_fee_days = 30


# Usage ranges (kWh)
usage_ranges = {
    'Residential': (50, 300),
    'Small Commercial': (500, 2500),
    'Commercial': (1000, 5000)
}


# Price per kWh (USD)
price_per_kwh = {
    'Residential': (0.12, 0.18),
    'Small Commercial': (0.10, 0.15),
    'Commercial': (0.08, 0.12)
}


# TDU % range
tdu_percent_range = (0.10, 0.25)


# Transaction types
transaction_types = {1:'Bill',2:'Payment',3:'Refund',4:'Late Fee'}


transactions = []
transaction_id = 1

for _, account in accounts.iterrows():
    cust_id = account['CustomerID']
    acct_number = account['AccountNumber']
    cust_type = account['customer_type']

    for month in months:
        # Bill transaction
        usage = random.randint(*usage_ranges[cust_type])
        amount = round(usage * random.uniform(*price_per_kwh[cust_type]), 2)
        tdu_amount = round(amount * random.uniform(*tdu_percent_range), 2)
        bill_date = datetime(start_year, month, random.randint(1,28))

        transactions.append({
            'TransactionID': transaction_id,
            'CustomerID': cust_id,
            'AccountNumber': acct_number,
            'TransactionTypeID': 1,
            'TransactionAmount': amount,
            'UsageQuantity': usage,
            'TDUAmount': tdu_amount,
            'CreatedDate': bill_date
        })
        transaction_id += 1

        # Payment transaction (random)
        if random.random() < payment_prob[cust_type]:
            pay_date = bill_date + timedelta(days=random.randint(1,15))
            transactions.append({
                'TransactionID': transaction_id,
                'CustomerID': cust_id,
                'AccountNumber': acct_number,
                'TransactionTypeID': 2,
                'TransactionAmount': amount,
                'UsageQuantity': usage,
                'TDUAmount': tdu_amount,
                'CreatedDate': pay_date
            })
            transaction_id += 1

            # Refund transaction (~5%)
            if random.random() < refund_prob:
                refund_date = pay_date + timedelta(days=random.randint(1,10))
                refund_amount = round(amount * random.uniform(0.1,0.5),2)
                transactions.append({
                    'TransactionID': transaction_id,
                    'CustomerID': cust_id,
                    'AccountNumber': acct_number,
                    'TransactionTypeID': 3,
                    'TransactionAmount': refund_amount,
                    'UsageQuantity': usage,
                    'TDUAmount': tdu_amount,
                    'CreatedDate': refund_date
                })
                transaction_id += 1
        else:
            # Late Fee if unpaid
            late_fee_date = bill_date + timedelta(days=late_fee_days + random.randint(1,10))
            late_fee_amount = round(amount * random.uniform(0.05,0.1),2)
            transactions.append({
                'TransactionID': transaction_id,
                'CustomerID': cust_id,
                'AccountNumber': acct_number,
                'TransactionTypeID': 4,
                'TransactionAmount': late_fee_amount,
                'UsageQuantity': 0,
                'TDUAmount': 0,
                'CreatedDate': late_fee_date
            })
            transaction_id += 1

# -------------------------
# Export to CSV
# -------------------------
df_transactions = pd.DataFrame(transactions)
df_transactions.to_csv("FactTransactions.csv", index=False)
print(f"Generated {len(df_transactions)} transactions for {len(accounts)} active accounts.")


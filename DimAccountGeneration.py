import pandas as pd
from random import choice, randint
from datetime import datetime, timedelta


service_types = ["Electric"] * 6 + ["Gas"] * 3 + ["Water"] * 1  # weighted distribution
rate_plans = ["fixed-rate", "variable-rate", "time-of-use"]
account_statuses = ["Active"] * 70 + ["Inactive"] * 15 + ["Suspended"] * 10 + ["Closed"] * 5


def random_date(start, end):
    """Generate a random datetime between start and end dates."""
    delta = end - start
    random_days = randint(0, delta.days)
    return start + timedelta(days=random_days)


customers = pd.read_csv("DimCustomer.csv") 


output = []
account_id_counter = 100001
start_date = datetime(2019, 1, 1)
end_date = datetime.today()

for _, row in customers.iterrows():
    cust_id = row["CustomerID"]
    cust_type = str(row["customer_type"]).strip().lower()

    # Build full customer address
    full_address = f"{row['Address']}, {row['City']}, {row['State']}, {row['Country']}"

    if cust_type in ["residential", "small commercial"]:
        # Always exactly ONE account
        prefix = "RESI-" if cust_type == "residential" else "SMALLCOMM-"
        account_number = f"{prefix}{account_id_counter}"
        account_id_counter += 1

        output.append({
            "CreateDate": random_date(start_date, end_date).strftime("%Y-%m-%d"),
            "CustomerID": cust_id,
            "CustomerType": cust_type.title(),
            "AccountNumber": account_number,
            "BillingAddress": full_address,
            "ServiceAddress": full_address,  # must match for these types
            "ServiceType": choice(service_types),
            "RatePlan": choice(rate_plans),
            "AccountStatus": choice(account_statuses)
        })

    elif cust_type == "commercial":
        # Between 1 and 3 accounts
        num_accounts = randint(1, 3)
        for i in range(num_accounts):
            account_number = f"COMM-{account_id_counter}"
            account_id_counter += 1

            # ServiceAddress varies (Unit numbers or suffixes)
            service_address = full_address if i == 0 else full_address + f" (Unit {i+1})"

            output.append({
                "CreateDate": random_date(start_date, end_date).strftime("%Y-%m-%d"),
                "CustomerID": cust_id,
                "CustomerType": cust_type.title(),
                "AccountNumber": account_number,
                "BillingAddress": full_address,   # fixed per customer
                "ServiceAddress": service_address, # can vary
                "ServiceType": choice(service_types),
                "RatePlan": choice(rate_plans),
                "AccountStatus": choice(account_statuses)
            })

# -----------------------------
# 5. Add exactly 150 Fraud Cases
# -----------------------------
residential_customers = customers[customers["customer_type"].str.lower() == "residential"]

# Randomly sample with replacement to reach exactly 150 rows
fraud_targets = residential_customers.sample(n=150, replace=True, random_state=42)

for idx, row in fraud_targets.iterrows():
    cust_id = row["CustomerID"]
    full_address = f"{row['Address']}, {row['City']}, {row['State']}, {row['Country']}"

    account_number = f"RESI-{account_id_counter}"
    account_id_counter += 1

    output.append({
        "CreateDate": random_date(start_date, end_date).strftime("%Y-%m-%d"),
        "CustomerID": cust_id,
        "CustomerType": "Residential",
        "AccountNumber": account_number,
        "BillingAddress": full_address,
        "ServiceAddress": full_address,
        "ServiceType": choice(service_types),
        "RatePlan": choice(rate_plans),
        "AccountStatus": "Active",
        "Notes": f"Fraud case - fake email{idx+1}@example.com"
    })


# Convert only the last 150 rows in output to a DataFrame
accounts_df = pd.DataFrame(output)
accounts_df.to_csv("Accounts.csv", index=False)

print("Accounts.csv created successfully!")






def model(dbt, session):
    
    bronze_users = dbt.ref("silver_users")

    return bronze_users
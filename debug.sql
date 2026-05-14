create or replace temporary view `silver_users__dbt_tmp` as
      
    
    with snapshot_query as (

        with __dbt__cte__silver_users as (
            select 
                user_id_sk,
                user_id,
                coalesce(email, "Unknown") as email,
                name,
                country,
                user_type,
                created_at,
                is_business,
                coalesce(company_name, "Unknown") as company_name,
                elt_load_time    
            from `wander_analytics`.`bronze`.`bronze_users`
        ) select * from __dbt__cte__silver_users
    ),

    snapshotted_data as (

        select *, 
    
        user_id_sk as dbt_unique_key
    

        from `wander_analytics`.`silver`.`silver_users`
        where
            
                end_date is null
            

    ),

    insertions_source_data as (

        select *, 
    
        user_id_sk as dbt_unique_key
    
,
            
    current_timestamp()
 as updated_at,
            
    current_timestamp()
 as start_date,
            
  
  coalesce(nullif(
    current_timestamp()
, 
    current_timestamp()
), null)
  as end_date
,
            md5(coalesce(cast(user_id_sk as string ), '')
         || '|' || coalesce(cast(
    current_timestamp()
 as string ), '')
        ) as scd_id

        from snapshot_query
    ),

    updates_source_data as (

        select *, 
    
        user_id_sk as dbt_unique_key
    
,
            
    current_timestamp()
 as updated_at,
            
    current_timestamp()
 as start_date,
            
    current_timestamp()
 as end_date

        from snapshot_query
    ),

    deletes_source_data as (

        select *, 
    
        user_id_sk as dbt_unique_key
    

        from snapshot_query
    ),
    

    insertions as (

        select
            'insert' as dbt_change_type,
            source_data.*

        from insertions_source_data as source_data
        left outer join snapshotted_data
            on 
    
        snapshotted_data.dbt_unique_key = source_data.dbt_unique_key
    

            where 
    
        snapshotted_data.dbt_unique_key is null
    

            or (
    
        snapshotted_data.dbt_unique_key is not null
    
 and (
               (snapshotted_data.`name` != source_data.`name`
        or
        (
            ((snapshotted_data.`name` is null) and not (source_data.`name` is null))
            or
            ((not snapshotted_data.`name` is null) and (source_data.`name` is null))
        ) or snapshotted_data.`country` != source_data.`country`
        or
        (
            ((snapshotted_data.`country` is null) and not (source_data.`country` is null))
            or
            ((not snapshotted_data.`country` is null) and (source_data.`country` is null))
        ) or snapshotted_data.`user_type` != source_data.`user_type`
        or
        (
            ((snapshotted_data.`user_type` is null) and not (source_data.`user_type` is null))
            or
            ((not snapshotted_data.`user_type` is null) and (source_data.`user_type` is null))
        ) or snapshotted_data.`is_business` != source_data.`is_business`
        or
        (
            ((snapshotted_data.`is_business` is null) and not (source_data.`is_business` is null))
            or
            ((not snapshotted_data.`is_business` is null) and (source_data.`is_business` is null))
        ) or snapshotted_data.`company_name` != source_data.`company_name`
        or
        (
            ((snapshotted_data.`company_name` is null) and not (source_data.`company_name` is null))
            or
            ((not snapshotted_data.`company_name` is null) and (source_data.`company_name` is null))
        ) or snapshotted_data.`email` != source_data.`email`
        or
        (
            ((snapshotted_data.`email` is null) and not (source_data.`email` is null))
            or
            ((not snapshotted_data.`email` is null) and (source_data.`email` is null))
        ))
            )

        )

    ),

    updates as (

        select
            'update' as dbt_change_type,
            source_data.*,
            snapshotted_data.scd_id

        from updates_source_data as source_data
        join snapshotted_data
            on 
    
        snapshotted_data.dbt_unique_key = source_data.dbt_unique_key
    

        where (
            (snapshotted_data.`name` != source_data.`name`
        or
        (
            ((snapshotted_data.`name` is null) and not (source_data.`name` is null))
            or
            ((not snapshotted_data.`name` is null) and (source_data.`name` is null))
        ) or snapshotted_data.`country` != source_data.`country`
        or
        (
            ((snapshotted_data.`country` is null) and not (source_data.`country` is null))
            or
            ((not snapshotted_data.`country` is null) and (source_data.`country` is null))
        ) or snapshotted_data.`user_type` != source_data.`user_type`
        or
        (
            ((snapshotted_data.`user_type` is null) and not (source_data.`user_type` is null))
            or
            ((not snapshotted_data.`user_type` is null) and (source_data.`user_type` is null))
        ) or snapshotted_data.`is_business` != source_data.`is_business`
        or
        (
            ((snapshotted_data.`is_business` is null) and not (source_data.`is_business` is null))
            or
            ((not snapshotted_data.`is_business` is null) and (source_data.`is_business` is null))
        ) or snapshotted_data.`company_name` != source_data.`company_name`
        or
        (
            ((snapshotted_data.`company_name` is null) and not (source_data.`company_name` is null))
            or
            ((not snapshotted_data.`company_name` is null) and (source_data.`company_name` is null))
        ) or snapshotted_data.`email` != source_data.`email`
        or
        (
            ((snapshotted_data.`email` is null) and not (source_data.`email` is null))
            or
            ((not snapshotted_data.`email` is null) and (source_data.`email` is null))
        ))
        )
    )
    ,
    deletes as (

        select
            'delete' as dbt_change_type,
            source_data.*,
            
    current_timestamp()
 as start_date,
            
    current_timestamp()
 as updated_at,
            
    current_timestamp()
 as end_date,
            snapshotted_data.scd_id
        from snapshotted_data
        left join deletes_source_data as source_data
            on 
    
        snapshotted_data.dbt_unique_key = source_data.dbt_unique_key
    

            where 
    
        source_data.dbt_unique_key is null
    

    )

    select * from insertions
    union all
    select * from updates
    union all
    select * from deletes

  
run dbt deps to install packages
check the sources.yml out first, check for the database config, run source freshness
Create staging layers models, .yml file as well
check out the seeds then run dbt seeds
check the macros, understand what they Do
after confirming the staging, intermediate, marts layer. Do dbt test and dbt run for each folders. 
check the compile for any query that has macros embedded
After check out the analyses folder
run the dbt test for the test folders, 
Check out the snapshot
Check out the incremental 
check out exposures


check out the unique values in traffic source column under  stg_thelook__users and then add an accepted values for the test.
check out the unique values in the order status column and include it in the macro valid_order_statuses
check out the unique values in the event type in stg_thelook__events and and then add an accepted values for the test.



you can also overide your model level config in the dbt_project.yml rather than the in-file level config
find out where to get my target.schema. In my case it is dbt_n3zzar
importance of confugring +groups
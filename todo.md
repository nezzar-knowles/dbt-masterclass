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


I need to add tags, 
Get the ERD
Understand loop.last, loop.first and loop.index. How to clear trailing gaps.


Module 1
Explain the dataset, talk about how it changes, the ERD, the tables
Run dbt init to show them all the folders that makes up a dbt project and how to create folders and subfolders
Show them the dbt_project.yml, explain the default is showing and then set some materialization and schema.
Show them the dag of the from_scratch, where the source and ref functions plays a role
Show them how to navigate based on selector_method, graph_operator
Try the few dbt commands
Version control (Github sync)

Module 2
Create sources.yml and define the necessary variables
Show them the hardcoded syntax and the one written off defined sources. Show them what happens when you compile the latter
Define freshness on the important tables, not on the source level. Explains what it will do.
Run generic test on your columns
Write a seed.csv. Show them what qualifies it as a seed.
Document for the seeds via .yml file. Perform data test for the columns and describe each tables.
Define column types, schema in the dbt_project.yml
Do csv preview in your interface
Run dbt seed and show them how/where it materialize in the warehouse.
Build a snapshot table
Explain why we used the users table, check strategy
Multi line description using >
Run dbt snapshot
Show how it added new columns and where it materialized in the warehouse

Module 3
Install packages. Show them where they can get it from.
Practice the right naming convention (model naming and column naming)
Build staging models with source function. Document (model description and column description). Write generic and singular tests. Do dbt run.
Do the same for intermediate and marts with ref function. Preview it. Show them how it is a jinja expression syntax that wraps around the ref and source function
Add a jinja comment in any of your query and show them how it dissapeared when compiling unlike sql comments.
Do dbt test, add with selectors too.
Write a test that will output error. Run dbt tests. Show them how store_failures can show you the rows that fail. Show how you can set it on a column level or global level.
Then overide it with severity (show error and correct with severity). Practice with the error_if and warn_if thresholds, usually with dbt_utils.accepted_range.
Practicalize the the typical transformation expected of the different folders
Show them the DDL result when you compile it
Experiment with config block. Add tags and explain how the model_level config block is supposed to override the folder_level defaults in the dbt_project.yml
Do dbt run and show them the different icons each materializations show in bigquery
Look for repeated sql syntax that could be converted into a macro and define one with a jinja statement saved as an sql file within your macros folder, then call it in any model.
Run dbt compile within such model and show what it will produce.
Write a for loop and if statement macro and explain what they do (dynamic sql)
Show them how the generate_schema_name macro works
Write a doc block and reference it in description of any YAML file.
Do dbt docs generate.
Do dbt contract on yor marts models. Show them the consequence of not doing without it.
Define your exposure.yml





Show them how we test for every primary key
Best case practices ( description to all models, and columns, define all sources
Use tags
Reference the seeds in staging model, and source 

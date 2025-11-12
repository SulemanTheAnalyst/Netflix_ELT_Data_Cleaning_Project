# Netflix_ELT_Data_Cleaning_Project
ELT data pipeline using Python and MySQL — extracted Netflix dataset via API, loaded to MySQL, and transformed using SQL.
# Project Overview
This project demonstrates an ELT (Extract → Load → Transform) process using Python and MySQL.
The goal was to extract raw Netflix data from the Kaggle API, load it into MySQL, and perform SQL-based cleaning and transformation to prepare it for further analysis and dashboarding.
# Objectives
Extract the dataset programmatically using Kaggle API and Python.
Load the raw data into a structured MySQL database.
Transform the data using SQL queries — handling missing values, duplicates, inconsistent formats, and schema standardization.
Prepare a clean, analysis-ready dataset suitable for Power BI, Tableau, or Python-based analytics.
# Tools & Technologies
Programming Language: Python (Kaggle API, Pandas)
Database: MySQL (Workbench 8.0)
Libraries Used: pandas, mysql.connector, os, dotenv
Data Source: Netflix Titles Dataset on Kaggle
# ELT Workflow Summary
1. Extract
Used Kaggle API to download the netflix_titles.csv file programmatically.
Verified dataset structure and inspected columns in Python.
2. Load
Established a MySQL connection using mysql.connector.
Created a database schema and imported raw CSV data into MySQL tables.
3. Transform
Performed data cleaning and transformation within MySQL:
Removed duplicates and handled NULL values.
Standardized date, text, and categorical fields.
Split and normalized the duration column.
Defined primary keys, ensured data integrity, and optimized column types.
# Example Sql Transformations 
-- group by title, type and director then it will give the exact duplicate which actually matters for removal

select t1.* from netflix_titles t1
join ( select title,type,director from netflix_titles 
group by title,type,director having count(*) >1 ) t2 
on t1.title = t2.title
order by t1.title;

-- here we will find duplicates and also mysql doesnot allow to delete directly using cte 
with removeduplicate as(
select *,
row_number() over(partition by title, type, director order by show_id) as rn 
from netflix_titles 
) 
Select * from removeduplicate 
where rn > 1;

-- now we will remove duplicates permanently 
set SQL_Safe_updates = 0;

delete from netflix_titles
where show_id in (
select show_id from(
select show_id,
row_number() over(partition by type, title, director order by show_id) as rn
from netflix_titles ) del_dup
where rn >1 );

set SQL_Safe_updates = 1;

# Key Learnings
Gained hands-on experience in ELT workflows integrating Python and SQL.
Strengthened data cleaning, schema design, and SQL transformation skills.
Learned to validate data quality and ensure referential integrity in structured databases.
# Future Enhancements
Build Power BI dashboard for visual storytelling.
Automate the pipeline using Airflow or scheduling scripts.
Integrate Python-based analysis for trend insights.
# Let's Connect!

If you're a recruiter or someone interested in collaborating, feel free to reach out or connect with me on [LinkedIn](https://www.linkedin.com/in/sulemantheanalyst).


use Netflix_project;
show tables ;
select * from netflix_titles
order by title;
-- We handled the foreign characters by changig data type and assigning the correct number of chahracters used for each column
show columns from netflix_titles;
desc netflix_titles;
Select * 
from netflix_titles
where show_id = 's5023';
-- Now for data security and best practice we will create a new table and insert the data of the original table and then drop the original table
Create table netflix_titles_backup as
select * from netflix_titles;
Drop table netflix_titles;
Rename table netflix_titles_backup to netflix_titles;
-- Now we will remove duplicates 
select * from netflix_titles;
select show_id, count(*) from netflix_titles
group by show_id 
having count(*) >1;
-- No duplicates found in show_id so i make it primary key using alter through settings
-- Now look for duplicates titles and others
select * from netflix_titles;
select * from netflix_titles
where title in (
select title 
from netflix_titles 
group by title 
having count(*) >1)
order by title;
-- This query took a lot time to run i will optimise it for quick execution 
select t1.* from netflix_titles t1
join ( select title from netflix_titles 
group by title having count(*) >1 ) t2 
on t1.title = t2.title
order by t1.title;
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
-- Now trim the extra characters in title column 
select * from netflix_titles
where title like "#%"
order by title;
select * from netflix_titles
order by title;
-- ¡Ay, mi madre!, '76, (T)ERROR, (Un)Well, #Alive these are the real characters so keep it and donot delete or remove it from title section 
-- Now check for null value where it needs to be filled or useless to be deleted or removed 
Select count(*) as total_rows,
sum(type is null ) as type_nulls,
sum(title is null ) as title_nulls,
sum(director is null) as director_nulls,
sum(cast is null) as cast_nulls,
sum(country is null) as country_nulls,
sum(date_added is null) as date_nulls,
sum(release_year is null) as release_year_nulls,
sum(rating is null) as rating__nulls,
sum(duration is null) as duration_nulls,
sum(listed_in is null) as listed_in_nulls,
sum(description is null) as description_nulls
from netflix_titles;
select show_id,director, cast, country from netflix_titles
where director is null or cast is null or country is null;
select count(*) as total_null 
from netflix_titles
where director is null 
and cast is null and 
country is null;
-- Now lets find the total percent of combined director, cast and country 
select count(*) as total_rows,
sum(case when director is null 
and cast is null and 
country is null then 1 else 0 end) as total_null_combined,
Round((sum(case when director is null and cast is null and 
country is null then 1 else 0 end) * 100.0) / count(*),2) as percent_null_combined
from netflix_titles;
-- as we can see combined null values are less then 5% of total values so we can delete them now 
set SQL_Safe_updates = 0;
delete from netflix_titles
where country is null and cast is null and director is null;
set SQL_Safe_updates = 1;
select count(*) from netflix_titles 
where director is null and cast is null and country is null ;
select * from netflix_titles;
-- Now replace NULL to 'Unknown' for text/categorical columns only but not numeric and date column 
select director, cast, country ,rating,duration 
from netflix_titles 
where director is null or cast is null or country is null or rating is null or duration is null;
-- Preview before updating just ot make sure everything is right 
with preview as(
select show_id,title,
    coalesce(director, 'Unknown') AS director_preview,
    coalesce(cast, 'Unknown') AS cast_preview,
    coalesce(country, 'Unknown') AS country_preview,
    coalesce(rating, 'Unknown') AS rating_preview,
    coalesce(duration, 'Unknown') AS duration_preview
from netflix_titles
)
select * from preview
where director_preview = 'Unknown' 
or cast_preview = 'Unknown'
or country_preview = 'Unknown'
or rating_preview = 'Unknown'
or duration_preview = 'Unknown' ;
-- Now we will safely update everything 
set SQL_Safe_updates = 0;
update netflix_titles
set director = coalesce(director, "Unknown"),
cast = coalesce(cast, "Unknown"),
country = coalesce(country, "Unknown"),
rating = coalesce(rating, "Unknown"),
duration = coalesce(duration, "Unknown");
set SQL_Safe_updates = 1;
select * from netflix_titles;
-- Change the column name to make it specific to Netflix 
Alter table netflix_titles
rename column date_added to netflix_release_date;
-- Standardized the date format
desc netflix_titles;
Alter table netflix_titles
Modify netflix_release_date Date;
-- we cannot modify or change data type of this column directly because it is text formatted dates,
-- so we will add temporary column to it and then convert it with date formated column and populate the data 
Alter table netflix_titles
Add column netflix_release_date_fixed Date;
-- check it before converting 
select netflix_release_date,
str_to_date(netflix_release_date, '%M %d, %Y') as converted
from netflix_titles
limit 10;
-- Now convert and populate the data inside that new column 
set sql_safe_updates = 0;
Update netflix_titles
set netflix_release_date_fixed = str_to_date(netflix_release_date, '%M %d, %Y');
set sql_safe_updates = 1;
select * from netflix_titles;
-- now replace the old column 
Alter table netflix_titles 
drop column netflix_release_date;
Alter table netflix_titles
change netflix_release_date_fixed netflix_release_date Date;
-- if you want u can change the position of the column as i do 
Alter table netflix_titles
Modify netflix_release_date Date after country;
select * from netflix_titles;
-- Now spilt duration into duration_value and duration_type for better visualisation and analyzation in python or BI tools
Alter table netflix_titles
Add column duration_value Int,
Add column duration_type varchar(20);
-- before updating preview it
Select duration, 
Cast(substring_index(duration, ' ',1) as Unsigned),
substring_index(duration, ' ', -1)
from netflix_titles
where duration not like '%Unknown%' and duration is not null and duration != '';
-- Now update after confirmation 
Set sql_safe_updates = 0;
Update netflix_titles
Set duration_value = Cast(substring_index(duration, ' ',1) as Unsigned),
duration_type = substring_index(duration, ' ', -1);
Set sql_safe_updates = 1;
-- above query contains 'Unknown' which i added in place of null for better analysis that is why this query didnot work here 
-- so this query handled everything in which i used where clause to handle unknown or null values 
Set sql_safe_updates = 0;
Update netflix_titles
Set duration_value = Cast(substring_index(duration, ' ',1) as Unsigned),
duration_type = substring_index(duration, ' ', -1)
where duration not like '%Unknown%' and duration is not null and duration != '';
Set sql_safe_updates = 1;
select * from netflix_titles;
-- Now Double-check your new columns
select duration,duration_value,duration_type
from netflix_titles
limit 20;
-- now delete the duration column which contains mixed type of data 
Alter table netflix_titles
drop column duration;
-- Now rearrange the positon of the duration column as they were before 
Alter table netflix_titles
Modify duration_value int after rating,
modify duration_type varchar(20) after duration_value;

select distinct listed_in, cast 
from netflix_titles;



 

 











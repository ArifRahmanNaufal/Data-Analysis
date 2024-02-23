-- This project use 4 tables and contain 10 request to analysis
 -- 1. agent
 -- 2. productivity
 -- 3. qa
 -- 4. rating

-- Change date_type in all tables
ALTER TABLE cs.qa ALTER COLUMN "date" TYPE date USING to_date(date, 'MM-DD-YYYY')
ALTER TABLE cs.rating ALTER COLUMN "date" TYPE date USING to_date(date, 'DD Month YYYY')
ALTER TABLE cs.agent ALTER COLUMN "DoB" TYPE date USING to_date("DoB", 'MM-DD-YYYY')
ALTER TABLE cs.agent ALTER COLUMN join_date TYPE date USING to_date(join_date, 'MM-DD-YYYY')
ALTER TABLE cs.productivity  ALTER COLUMN "date" TYPE date USING to_date(date, 'DD Month YYYY')

-- Identify agents with consistently high QA scores across different parameters.
select 
	agent,
	avg(qa_score) avg_score
from qa q 
group by agent
order by avg_score desc

-- Compare average ratings by channel and sub-channel.
select 
	channel,
	sub_channel, 
	avg(rating) as avg_rating
from rating r 	
group by channel, sub_channel 

-- Analyze agent productivity by channel and identify areas for improvement.
select
	agent,
	channel,
	sum(total_call) as total_call,
	avg("AHT") as avg_aht,
	avg(abandoned_call) as avg_abandon
from productivity p 
group by agent, channel 
order by channel

-- Find agents with the highest number of critical errors in QA assessments.
select 
	agent,
	channel,
	sub_channel, 
	sum(case when critical_error = 'Failed' then 1 else 0 end) as total_ce
from qa
group by agent,channel,sub_channel
order by total_ce desc

-- Correlate agent tenure with QA scores and identify trends.
select 
	agent,
	a."Tenure",
	avg(qa_score) as avg_score
from qa as q
	left join agent as a on q.agent = a.full_name
group by agent, a."Tenure"

-- Discover agents with high call volumes and low abandoned call rates.
select 
	agent,
	sum(total_call) as total_call,
	sum(abandoned_call) as total_abandoned_call
from productivity p 
group by agent
order by total_call desc, total_abandoned_call asc

-- Track agent performance changes over time based on QA scores and ratings.
select
	q2.agent,
	extract (month from q2.date) as months,
	round(avg(qa_score),2),
	round(avg(rating),2)
from qa q2
	left join rating r on 
		q2.agent = r.agent and 
		extract (month from q2.date) = extract (month from r.date) 
group by q2.agent, months

-- Identify agents who excel in specific communication skills (e.g., empathy, grammar).
select
	agent,
	round(avg(case when "opening/closing" = 'Passed' then 1 else 0 end)*(100),2) as "opening/closing Passed%",
	round(avg(case when "empathy/sympathy" = 'Passed' then 1 else 0 end)*(100),2) as "empathy/sympathy Passed%",
	round(avg(case when "spelling/grammar" = 'Passed' then 1 else 0 end)*(100),2) as "spelling/grammar Passed%",
	round(avg(case when handling_skill = 'Passed' then 1 else 0 end)*(100),2) as "handling_skill Passed%",
	round(avg(case when critical_error = 'Passed' then 1 else 0 end)*(100),2) as "critical_error Passed%",
	round(avg(qa_score),2) as avg_score
from qa
group by agent
order by avg_score desc

-- Compare agent performance across different channels and sub-channels.
select
	q2.agent,
	q2.channel,
	q2.sub_channel,
	round(avg(qa_score),2) as avg_score,
	round(avg(rating),2) as avg_rating
from qa q2
	left join rating r on 
		q2.agent = r.agent and 
		extract (month from q2.date) = extract (month from r.date) 
group by q2.agent, q2.channel, q2.sub_channel
order by channel asc, sub_channel asc

-- Analyze the relationship between agent demographics (e.g., gender, age) and performance metrics.
select
	a."Gender",
	case when 2024 - extract (year from a."DoB") < 23 
		then 'Under_23' else 'Over_23' end as age_category,
	round(avg(qa_score),2) as avg_score,
	round(avg(rating),2) as avg_rating
from qa q2
	left join rating r on 
		q2.agent = r.agent and 
		extract (month from q2.date) = extract (month from r.date)
	left join agent a on
		q2.agent = a.full_name
group by a."Gender", age_category
	
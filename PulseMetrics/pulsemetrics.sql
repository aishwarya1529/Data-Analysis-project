-- CREATE DATABASE pulsemetrics;
USE pulsemetrics;

-- SCHEMA VALIDATION
DESCRIBE users;
DESCRIBE sessions;
DESCRIBE events;
DESCRIBE featureusage;
DESCRIBE subscriptions;

/*
DATA TYPE CONVERSION (Run only once)
UPDATE users
SET SignupDate = STR_TO_DATE(SignupDate,'%d-%m-%Y');

ALTER TABLE users
MODIFY SignupDate DATE;


UPDATE featureusage
SET UsageDate = STR_TO_DATE(UsageDate,'%d-%m-%Y');

ALTER TABLE featureusage
MODIFY UsageDate DATE;

UPDATE subscriptions
SET SubscriptionDate = STR_TO_DATE(SubscriptionDate,'%d-%m-%Y');

UPDATE subscriptions
SET RenewalDate = STR_TO_DATE(RenewalDate,'%d-%m-%Y');

ALTER TABLE subscriptions
MODIFY SubscriptionDate DATE,
MODIFY RenewalDate DATE;
*/

-- DATA VALIDATION

SELECT 'Users' AS Table_Name, COUNT(*) AS Total_Rows FROM users
UNION ALL
SELECT 'Sessions', COUNT(*) FROM sessions
UNION ALL
SELECT 'Events', COUNT(*) FROM events
UNION ALL
SELECT 'FeatureUsage', COUNT(*) FROM featureusage
UNION ALL
SELECT 'Subscriptions', COUNT(*) FROM subscriptions;

SELECT UserID,
COUNT(*) AS Duplicate_Count
FROM users
GROUP BY UserID
HAVING COUNT(*) > 1;

select count(*) as missing_age
from users
where age IS NULL;

select count(*) as missing_gender
from users
where gender IS NULL;

select COUNT(*) AS Missing_Browser
from sessions
where Browser IS NULL OR Browser='';

select COUNT(*) AS Missing_TimeSpent
from events
where TimeSpent IS NULL;

select COUNT(*) AS Negative_Session_Duration
from sessions
where SessionDuration < 0;

select
MIN(SessionStart),
MAX(SessionStart),
MIN(SessionEnd),
MAX(SessionEnd)
from sessions;

select COUNT(*) AS Orphan_Users
from sessions s
LEFT JOIN users u
ON s.UserID = u.UserID
where u.UserID IS NULL;

select COUNT(*) AS Orphan_Sessions
from events e
LEFT JOIN sessions s
ON e.SessionID = s.SessionID
where s.SessionID IS NULL;


-- DATA CLEANING

DROP TABLE IF EXISTS users_clean;
CREATE TABLE users_clean AS
SELECT DISTINCT *
FROM users;

ALTER TABLE users_clean
MODIFY UserID VARCHAR(20);

ALTER TABLE users_clean
ADD PRIMARY KEY (UserID);

-- =========================
-- BUSINESS ANALYSIS
-- =========================

-- How many users does PulseMetrics have
select count(*) as total_users
from users_clean;

-- How many sessions occurred?
select count(*) as total_sessions
from sessions;

-- How has monthly user activity changed?
select date_format(sessionstart,'%Y-%m') as Month,
count(distinct userID) as monthly_active_users
from sessions
group by Month
order by Month;

-- Average sessions per user
select
round(count(*)/count(distinct userID), 2) AS avg_session_per_user
from sessions;

-- Average session duration
select
round(avg(sessionduration),2) AS Avg_Session_Duration_Minutes
from sessions
where sessionduration>=0;

-- Which countries have the most users
select country, count(*) as Total_Users
from users_clean
group by country
order by Total_users desc;

-- Which acquisition channels bring the most users
select AcquisitionChannel, count(*) as Total_Users
from users_clean
group by AcquisitionChannel
order by Total_Users desc;

-- Which user segments bring the most users
select UserSegment,count(*) AS total_users
from users_clean
group by UserSegment
order by total_users desc;

-- Which user segments have the most Premium users
select UserSegment,count(*) AS Premium_users
from users_clean
where PlanType='Premium'
group by UserSegment
order by Premium_users desc;

-- Which devices do users prefer
select DeviceType, count(*) as Total_users
from Users_clean
group by DeviceType
order by Total_users desc;

-- Which Operating Systems generate the most sessions
select OperatingSystem, count(*) as Total_sessions
from Sessions
group by OperatingSystem
order by Total_sessions desc;

-- Which features are used the most
select FeatureName,count(*) as Total_num
from Featureusage
group by FeatureName
order by total_num desc;

-- Which feature categories are used the most
select FeatureCategory,count(*) as Total_num
from Featureusage
group by FeatureCategory
order by total_num desc;

-- Which screens are visited the most
select ScreenName, count(*) AS total_num
from events
group by ScreenName
order by total_num desc;

-- Which event types occur the most
select EventType, count(*) AS total_num
from events
group by EventType
order by total_num desc;

-- MAU trend with month-over-month % change
WITH mau AS
(select date_format( SessionStart, '%Y-%m') AS Month,
count(DISTINCT userID) as MAU
from sessions
group by Month)
select Month, MAU,
Lag(MAU) over(order by Month) AS previous_month_MAU,
Round((MAU-Lag(MAU) over(order by month))/ Lag(MAU) over(order by Month)*100,2) AS MoM_change_pct
from MAU
order by Month;

-- Premium conversion rate by signup cohort, with trend
SELECT
    DATE_FORMAT(SignupDate,'%Y-%m') AS SignupMonth,
    COUNT(*) AS Total_Signups,
SUM(CASE
    WHEN PlanType='Premium' THEN 1
    ELSE 0
    END) AS Premium_Users,
ROUND(SUM(CASE
          WHEN PlanType='Premium' THEN 1
          ELSE 0
          END)*100.0/COUNT(*),2) AS Conversion_Rate_Pct
FROM users_clean
GROUP BY SignupMonth
ORDER BY SignupMonth;

-- 30-day retention by signup cohort (classic cohort analysis)
WITH activity AS (
    SELECT u.UserID, u.SignupDate,
           DATE_FORMAT(u.SignupDate, '%Y-%m') AS SignupMonth,
           MAX(s.SessionStart) AS LastSession
    FROM users_clean u
    LEFT JOIN sessions s ON u.UserID = s.UserID
    GROUP BY u.UserID, u.SignupDate)
SELECT SignupMonth,
       COUNT(*) AS CohortSize,
       SUM(CASE WHEN DATEDIFF(LastSession, SignupDate) >= 30 THEN 1 ELSE 0 END) AS RetainedPast30Days,
       ROUND(SUM(CASE WHEN DATEDIFF(LastSession, SignupDate) >= 30 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS Retention_Rate_Pct
FROM activity
GROUP BY SignupMonth
ORDER BY SignupMonth;

-- Which acquisition channels bring the highest number of users, and which bring the highest-quality (Premium-converting) users(volume Vs Quality)
-- Comparing user acquisition volume with Premium conversion rate.

SELECT AcquisitionChannel,
COUNT(*) AS Signups,
SUM(CASE
	WHEN PlanType = 'Premium' THEN 1
	ELSE 0
	END) AS Premium_Users,
ROUND(SUM(CASE
		  WHEN PlanType = 'Premium' THEN 1
		  ELSE 0
		  END) * 100.0 / COUNT(*),2) AS Conversion_Rate_Pct,
          
RANK() OVER (ORDER BY COUNT(*) DESC) AS Rank_By_Volume,
RANK() OVER (ORDER BY ROUND(SUM(CASE
                                WHEN PlanType='Premium' THEN 1
							    ELSE 0
                                END) * 100.0 / COUNT(*),2) DESC) AS Rank_By_Quality
FROM users_clean
GROUP BY AcquisitionChannel
ORDER BY Signups DESC;

-- How does user engagement differ between users who experienced crashes and those who didn't

WITH crash_flag AS (
    SELECT UserID, MAX(CASE WHEN CrashOccurred='Yes' THEN 1 ELSE 0 END) AS EverCrashed
    FROM sessions
    GROUP BY UserID
),
user_activity AS (
    SELECT UserID, COUNT(*) AS TotalSessions, MAX(SessionStart) AS LastSession
    FROM sessions
    GROUP BY UserID
)
SELECT cf.EverCrashed,
       COUNT(*) AS Users,
       ROUND(AVG(ua.TotalSessions), 2) AS Avg_Sessions_Per_User,
       ROUND(AVG(DATEDIFF('2025-12-31', ua.LastSession)), 1) AS Avg_Days_Inactive_Since_Last_Session
FROM crash_flag cf
JOIN user_activity ua ON cf.UserID = ua.UserID
GROUP BY cf.EverCrashed;

-- How have monthly revenue and average discount changed over time

SELECT DATE_FORMAT(SubscriptionDate, '%Y-%m') AS Month,
       SUM(Revenue) AS Total_Revenue,
       ROUND(AVG(DiscountPercent), 2) AS Avg_Discount_Pct,
       COUNT(*) AS Subscription_Periods
FROM subscriptions
GROUP BY Month
ORDER BY Month;

-- Renewal rate trend & cancellation reasons

SELECT DATE_FORMAT(RenewalDate, '%Y-%m') AS Month,
       COUNT(*) AS Periods_Due,
       SUM(CASE WHEN Status='Renewed' THEN 1 ELSE 0 END) AS Renewed,
       SUM(CASE WHEN Status='Cancelled' THEN 1 ELSE 0 END) AS Cancelled,
       ROUND(SUM(CASE WHEN Status='Renewed' THEN 1 ELSE 0 END)/COUNT(*)*100, 2) AS Renewal_Rate_Pct
FROM subscriptions
WHERE Status IN ('Renewed','Cancelled')
GROUP BY Month
ORDER BY Month;
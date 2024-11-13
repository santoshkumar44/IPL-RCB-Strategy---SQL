use ipl;


-- objective 2 : What is the total number of run scored in 1st season by RCB (bonus : also include the extra runs using the extra runs table)

WITH match_detail AS 
(SELECT Match_Id , Team_1 , Team_2 , Toss_Winner , Toss_Decide ,
	   CASE WHEN Toss_Winner = 2 AND Toss_Decide = 1 THEN 2 
	        WHEN Toss_Winner = 2 AND Toss_Decide = 2 THEN 1 
			WHEN Toss_Winner !=2 AND Toss_Decide = 1 THEN 1 
			WHEN Toss_Winner !=2 AND Toss_Decide = 2 THEN 2 END AS Innings
FROM matches
WHERE Season_Id = 1 AND (Team_1 = 2 OR Team_2 = 2))
,
Runs_from_bat AS 
(SELECT SUM(bs.Runs_Scored) AS total
FROM batsman_scored bs 
JOIN match_detail md 
ON md.Match_Id = bs.Match_Id AND bs.Innings_No = md.Innings)
,
Runs_from_extra AS 
(SELECT sum(er.Extra_Runs) total
FROM extra_runs er 
JOIN match_detail md 
ON er.Match_Id = md.Match_Id AND er.Innings_No = md.Innings)


SELECT SUM(runs.total) Total_runs_by_RCB_in_Season_1
FROM
(SELECT total FROM Runs_from_bat rb 
UNION ALL
SELECT total FROM Runs_from_extra re) runs;

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- objective:3 How many players were more than age of 25 during season 2 ?

WITH cte1 AS (SELECT player_id,(2009-year(dob)) AS age FROM player),
cte2 AS ( SELECT * FROM player_match)

SELECT count(distinct cte1.player_id) AS player_count FROM cte1
JOIN cte2
ON cte1.player_id=cte2.player_id
WHERE age>25;

-- ----------------------------------------------------------------------------------------------------------------------------------
-- objective:4 How many matches did RCB win in season 1 ? 

SELECT Count(Match_Winner) Matches_win_by_RCB_in_Season1
FROM matches
WHERE Season_Id = 1 AND Match_Winner = 2;

-- --------------------------------------------------------------------------------------------------------------------------------------
-- objective:5 List top 10 players according to their strike rate in last 4 seasons

with total_details as 
( select bb.
Striker,count(bb.Ball_Id) balls, sum(bs.Runs_Scored) runs, 
sum(bs.Runs_Scored)/count(bb.Ball_Id) * 100  strike_Rate
from ball_by_ball bb
join batsman_scored bs on bb.Match_Id = bs.Match_Id and bb.Over_Id = bs.Over_Id and bb.Ball_Id = bs.Ball_Id 
join player p on bb.Striker = p.Player_Id
where bb.Match_Id in (select m.Match_Id from matches m
					  where  m.Season_Id in(6,7,8,9))
group by bb.Striker)

select p.Player_Name, ds.Striker,ds.runs,ds.balls,ds.strike_Rate
from total_details ds
join player p on p.Player_Id = ds.Striker
where ds.balls > 100
order by ds.strike_Rate desc
limit 10;
-- -------------------------------------------------------------------------------------------------------------------------------
-- objective:6 What is the average runs scored by each batsman considering all the seasons?

with total_details as
(select  p.Player_Name, count(distinct bs.Match_Id) match_played , sum(bs.Runs_Scored) runs,
sum(bs.Runs_Scored)/count(distinct bs.Match_Id) avg_batting 
from  ball_by_ball bb 
join batsman_scored bs on bb.Match_Id = bs.Match_Id and bb.Over_Id =bs.Over_Id and bb.Ball_Id = bs.Ball_Id
join player p on bb.Striker = p.Player_Id
group by p.Player_Name)

select td.Player_Name,td.match_played,td.runs,td.avg_batting
from total_details td
order by td.avg_batting desc;



-- -----------------------------------------------------------------------------------------------------------------------------------------------
-- objective:7 What are the average wickets taken by each bowler considering all the seasons?

with match_by_bowler as (
select bb.Bowler, count( distinct bb.Match_Id)  match_played
from ball_by_ball bb
join batsman_scored bs on bb.Match_Id = bs.Match_Id and bb.Over_Id= bs.Over_Id and bb.Ball_Id = bs.Ball_Id 
and bb.Innings_No = bs.Innings_No
group by bb.Bowler),

average_taken_wickets as (
select  bb.Bowler, count(wt.Kind_Out) wickets
from ball_by_ball bb
join wicket_taken wt on bb.Match_Id = wt.Match_Id and bb.Over_Id = wt.Over_Id and bb.Ball_Id = wt.Ball_Id
and bb.Innings_No = wt.Innings_No
group by bb.Bowler)

select mbb.Bowler,p.Player_Name,aw.wickets,mbb.match_played,aw.wickets/mbb.match_played wickets_average
from match_by_bowler mbb 
join average_taken_wickets aw on mbb.Bowler = aw.Bowler
join player p on p.Player_Id = mbb.Bowler
order by aw.wickets desc;

-- ------------------------------------------------------------------------------------------------------------------------------------

-- objective:8 List all the players who have average runs scored greater than overall average and who have taken wickets greater than overall average

--  i) /*average runs scored greater than overall average */:

with total_details as (
select p.Player_Name,count(distinct bs.Match_Id) match_played, sum(bs.Runs_Scored) runs,
sum(bs.Runs_Scored)/count(distinct bs.Match_Id) avg_runs_scored
from ball_by_ball bb
join batsman_scored bs 
on bb.Match_Id = bs.Match_Id and bb.Over_Id= bs.Over_Id and bb.Ball_Id = bs.Ball_Id 
join player p
on p.Player_Id = bb.Striker
group by p.Player_Name)

select td.Player_Name,td.match_played,td.runs,td.avg_runs_scored batting_average
from total_details td 
where td.avg_runs_scored > ( select sum(td.runs)/sum(td.match_played) overall_batting_avg
								from total_details td)
order by td.avg_runs_scored desc;
 
--  ii) /*average wickets taken greater than overall average */:

with match_by_bowler as (
select bb.Bowler, count( distinct bb.Match_Id)  match_played
from ball_by_ball bb
join batsman_scored bs on bb.Match_Id = bs.Match_Id and bb.Over_Id= bs.Over_Id and bb.Ball_Id = bs.Ball_Id 
and bb.Innings_No = bs.Innings_No
group by bb.Bowler),

average_taken_wickets as (
select  bb.Bowler, count(wt.Kind_Out) wickets
from ball_by_ball bb
join wicket_taken wt on bb.Match_Id = wt.Match_Id and bb.Over_Id = wt.Over_Id and bb.Ball_Id = wt.Ball_Id
and bb.Innings_No = wt.Innings_No
group by bb.Bowler)

select mbb.Bowler, p.Player_Name,mbb.match_played,aw.wickets,aw.wickets/mbb.match_played as avg_wickets_taken
from match_by_bowler mbb 
join average_taken_wickets aw on mbb.Bowler = aw.Bowler
join player p on p.Player_Id = mbb.Bowler
where aw.wickets/mbb.match_played > (select sum(aw.wickets)/sum(mbb.match_played) as overall_average
										from match_by_bowler mbb
                                        join average_taken_wickets aw
                                        on mbb.Bowler = aw.Bowler
                                        join player p 
                                        on p.Player_Id = mbb.Bowler
                                        order by aw.wickets desc)
order by aw.wickets desc;
                                        
-- --------------------------------------------------------------------------------------------------------------------------------

-- objective:9 Create a table rcb_record table that shows wins and losses of RCB in an individual venue.

SELECT 
    v.Venue_Name,
    COUNT(DISTINCT m.Match_Id) matches_played,
    COUNT(CASE
        WHEN m.Match_Winner = 2 THEN 1
        ELSE NULL
    END) AS matches_won,
    COUNT(CASE
        WHEN m.Match_Winner != 2 THEN 1
        ELSE NULL
    END) AS matches_loss
FROM
    venue v
        JOIN
    matches m ON v.Venue_Id = m.Venue_Id
WHERE
    m.team_1 = 2 OR m.team_2 = 2
GROUP BY v.Venue_Name
ORDER BY matches_won DESC;

-- ----------------------------------------------------------------------------------------------------------------------------------------

-- objective:10 What is the impact of bowling style on wickets taken

SELECT 
    bs.Bowling_skill, COUNT(wt.Kind_Out) wickets_taken
FROM
    bowling_style bs
        JOIN
    player p ON bs.Bowling_Id = p.Bowling_skill
        JOIN
    ball_by_ball bb ON bb.Bowler = p.Player_Id
        JOIN
    wicket_taken wt ON bb.Match_Id = wt.Match_Id
        AND bb.Over_Id = wt.Over_Id
        AND bb.Ball_Id = wt.Ball_Id
GROUP BY bs.Bowling_skill
ORDER BY wickets_taken DESC;

-- ------------------------------------------------------------------------------------------------------------------------------------

-- objective:11 Write the sql query to provide a status of whether the performance of the team better than the previous year performance on the basis of number of runs scored by the team in the season and number of wickets taken 

WITH Runs_Per_Season AS 
(SELECT s.Season_Year, SUM(b.Runs_Scored) AS Total_Runs
FROM Season s
JOIN Matches m ON s.Season_Id = m.Season_Id
JOIN Batsman_Scored b ON m.Match_Id = b.Match_Id
WHERE (m.Team_1 = 2 AND b.Innings_No = 1) OR (m.Team_2 = 2 AND b.Innings_No = 2)
GROUP BY s.Season_Year)
,
Wickets_Per_Season AS 
(SELECT s.Season_Year, COUNT(w.Player_Out) AS Total_Wickets
FROM Season s
JOIN Matches m ON s.Season_Id = m.Season_Id
JOIN Wicket_Taken w ON m.Match_Id = w.Match_Id
WHERE (m.Team_1 = 2 AND w.Innings_No = 2) OR (m.Team_2 = 2 AND w.Innings_No = 1)
GROUP BY s.Season_Year)
,
Performance AS 
(SELECT r.Season_Year, r.Total_Runs, w.Total_Wickets,
        LAG(r.Total_Runs) OVER (ORDER BY r.Season_Year) AS Prev_Season_Runs,
        LAG(w.Total_Wickets) OVER (ORDER BY w.Season_Year) AS Prev_Season_Wickets
FROM Runs_Per_Season r
JOIN Wickets_Per_Season w ON r.Season_Year = w.Season_Year
)

SELECT Season_Year, Total_Runs, Total_Wickets, Prev_Season_Runs,Prev_Season_Wickets,
       CASE WHEN Total_Runs > Prev_Season_Runs AND Total_Wickets > Prev_Season_Wickets 
       THEN 'Better' ELSE 'Worse' END AS Performance_Status
FROM Performance;     
-- --------------------------------------------------------------------------------------------------------------------------
-- objective12: Can you derive more KPIs for the team strategy if possible?
     
--  Batting
WITH match_detail AS 
(SELECT Match_Id , Team_1 , Team_2 , Toss_Winner , Toss_Decide ,
	   CASE WHEN Toss_Winner = 2 AND Toss_Decide = 1 THEN 2 
	        WHEN Toss_Winner = 2 AND Toss_Decide = 2 THEN 1 
			WHEN Toss_Winner !=2 AND Toss_Decide = 1 THEN 1 
			WHEN Toss_Winner !=2 AND Toss_Decide = 2 THEN 2 END AS Innings
FROM matches
WHERE Team_1 = 2 OR Team_2 = 2)
,
Runs_from_bat AS 
(SELECT SUM(bs.Runs_Scored) AS total
FROM batsman_scored bs 
JOIN match_detail md 
ON md.Match_Id = bs.Match_Id AND bs.Innings_No = md.Innings)
where 
bs.Over_Id BETWEEN 7 and 15
-- bs.Over_Id < 6  
-- bs.Over_Id > 15
,
Runs_from_extra AS 
(SELECT sum(er.Extra_Runs) total
FROM extra_runs er 
JOIN match_detail md 
ON er.Match_Id = md.Match_Id AND er.Innings_No = md.Innings)
-- bs.Over_Id BETWEEN 7 and 15
-- bs.Over_Id < 6  
-- bs.Over_Id > 15

SELECT SUM(runs.total) Total_runs_by_RCB_in_Season_1
FROM
(SELECT total FROM Runs_from_bat rb 
UNION ALL
SELECT total FROM Runs_from_extra re) runs;


-- Bowling


WITH match_detail AS 
(SELECT Match_Id , Team_1 , Team_2 , Toss_Winner , Toss_Decide ,
	   CASE WHEN Toss_Winner = 2 AND Toss_Decide = 1 THEN 2 
	        WHEN Toss_Winner = 2 AND Toss_Decide = 2 THEN 1 
			WHEN Toss_Winner !=2 AND Toss_Decide = 1 THEN 1 
			WHEN Toss_Winner !=2 AND Toss_Decide = 2 THEN 2 END AS Innings
FROM matches
WHERE (Team_1 = 2 OR Team_2 = 2))

SELECT COUNT(wt.Kind_Out) 
FROM wicket_taken wt 
JOIN match_detail md 
ON wt.Match_Id = md.Match_Id  AND wt.Innings_No = md.Innings
-- WHERE wt.Over_Id < 7 
-- WHERE wt.Over_Id between 7 and 15 
-- WHERE wt.Over_Id > 15 
     
-- ------------------------------------------------------------------------------------------------------------------------------
     
-- objective:13 Using SQL, write a query to find out average wickets taken by each bowler in each venue. Also rank the gender according to the average value.

WITH runs_consided AS 
(SELECT v.Venue_Id , bb.Bowler , SUM(bs.Runs_Scored) runs_given
FROM matches m 
JOIN venue v ON v.Venue_Id = m.Venue_Id
JOIN ball_by_ball bb ON m.Match_Id = bb.Match_Id
JOIN batsman_scored bs ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id AND bb.Innings_No = bs.Innings_No
GROUP BY v.Venue_Id , bb.Bowler
ORDER BY v.Venue_Id)
,
wickets_taken AS 
(SELECT v.Venue_Id , bb.Bowler , COUNT(wt.Kind_Out) wickets
FROM matches m 
JOIN venue v ON v.Venue_Id = m.Venue_Id
JOIN ball_by_ball bb ON m.Match_Id = bb.Match_Id
JOIN wicket_taken wt ON  bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id AND bb.Ball_Id = wt.Ball_Id AND bb.Innings_No = wt.Innings_No
GROUP BY v.Venue_Id , bb.Bowler
ORDER BY v.Venue_Id)

SELECT rc.Venue_Id , v.Venue_Name , rc.Bowler , p.Player_Name , rc.runs_given , wt.wickets , rc.runs_given/wt.wickets AS Bowling_AVG,
       dense_rank() OVER (ORDER BY rc.runs_given/wt.wickets) AS Ranks_by_avg_in_venue
FROM runs_consided rc 
JOIN wickets_taken wt 
ON rc.Venue_Id = wt.Venue_Id AND rc.Bowler = wt.Bowler
JOIN player p 
ON p.Player_Id = rc.Bowler
JOIN venue v 
ON v.Venue_Id = rc.Venue_Id;

-- -----------------------------------------------------------------------------------------------------------------------------

-- objective:14 Which of the given players have consistently performed well in past seasons? (will you use any visualisation to solve the problem)

-- consistence batter's
with details as (
select p.Player_Name,m.Season_Id,count(distinct bs.Match_Id) matches_played , sum(bs.Runs_Scored) runs,
sum(bs.Runs_Scored)/count(distinct bs.Match_Id) avg_runs
from ball_by_ball bb
join batsman_scored bs 
on bb.Match_Id = bs.Match_Id and bb.Over_Id = bs.Over_Id and bb.Ball_Id = bs.Ball_Id
join player p 
on p.Player_Id = bb.Striker
join matches m 
on m.Match_Id = bb.Match_Id
group by p.Player_Name,m.Season_Id)

select Player_Name, count(*) consistence
from 
(select d.player_name,d.Season_Id,d.matches_played,d.runs,d.avg_runs batting_average
from details d
where d.runs >= 700) me 
group by Player_Name
having count(*) >= 4;

-- consistence Bowler's

with runs_given_details as (
select bb.Bowler,m.Season_Id,sum(bs.Runs_Scored) runs_given
from ball_by_ball bb
join batsman_scored bs
on bb.Match_Id = bs.Match_Id and bb.Over_Id = bs.Over_Id and bb.Ball_Id = bs.Ball_Id and bb.Innings_No = bs.Innings_No
join matches m
on m.Match_Id = bb.Match_Id
group by  bb.Bowler,m.Season_Id),

wickets_taken_details as (
select bb.Bowler,m.Season_Id,count(wt.Kind_Out) wickets_taken
from ball_by_ball bb
join wicket_taken wt 
on bb.Match_Id = wt.Match_Id and bb.Over_Id = wt.Over_Id and bb.Ball_Id = wt.Ball_Id and bb.Innings_No = wt.Innings_No
join matches m
on m.Match_Id = bb.Match_Id
group by  bb.Bowler,m.Season_Id)

select Player_Name, count(*) consistence
from 
(select p.player_name,rd.Season_Id,rd.runs_given,wd.wickets_taken,rd.runs_given/wd.wickets_taken as bowling_average
from runs_given_details rd 
join wickets_taken_details wd 
on rd.Bowler = wd.Bowler and rd.Season_Id = wd.Season_Id
join player p 
on p.Player_Id = rd.Bowler
where wd.wickets_taken >= 15) me 
group by Player_Name
having count(*) >= 4;

-- all rounder consistence:
-- bat
with detail as 
(select  p.Player_Name , m.Season_Id, count(distinct bs.Match_Id) Matches_played , sum(bs.Runs_Scored) runs,
	    sum(bs.Runs_Scored)/count(distinct bs.Match_Id) average_runs
from ball_by_ball bb
join batsman_scored bs 
on bb.Match_Id = bs.Match_Id and bb.Over_Id = bs.Over_Id and bb.Ball_Id = bs.Ball_Id
join player p 
on p.Player_Id = bb.Striker
join matches m 
on m.Match_Id = bb.Match_Id
group by p.Player_Name,m.Season_Id)

select Player_Name , count(*) consistence
from 
(select d.Player_Name ,d.Season_Id , d.Matches_played , d.runs , d.average_runs batting_average
from detail d 
where d.runs >= 400) me 
group by Player_Name
having count(*) >= 4;

-- bowl

with runs_consided as 
(select bb.Bowler , m.Season_Id ,sum(bs.Runs_Scored) runs_given
from ball_by_ball bb 
join batsman_scored bs 
on bb.Match_Id = bs.Match_Id and bb.Over_Id = bs.Over_Id and bb.Ball_Id = bs.Ball_Id and bb.Innings_No = bs.Innings_No
join matches m 
on m.Match_Id = bb.Match_Id
group by bb.Bowler , m.Season_Id)
,
wickets_taken as 
(select bb.Bowler , m.Season_Id  ,COUNT(wt.Kind_Out) wickets
from ball_by_ball bb 
join wicket_taken wt
on  bb.Match_Id = wt.Match_Id and bb.Over_Id = wt.Over_Id and bb.Ball_Id = wt.Ball_Id and bb.Innings_No = wt.Innings_No
join matches m 
on m.Match_Id= bb.Match_Id
group by bb.Bowler , m.Season_Id)


select Player_Name , count(*) consistance
from
(select p.Player_Name,rc.Season_Id ,rc.runs_given , wt.wickets , rc.runs_given / wt.wickets AS bowling_average
from runs_consided rc 
join wickets_taken wt 
on rc.Bowler = wt.Bowler and rc.Season_Id = wt.Season_Id
join player p 
on p.Player_Id = rc.Bowler
where wt.wickets >= 8) me 
group by Player_Name
having count(*) >= 4;

-- -------------------------------------------------------------------------------------------------------------------------------------
-- objective:15 Are there players whose performance is more suited to specific venues or conditions? (how would you present this using charts?) 

-- bat

WITH detail AS 
(SELECT m.Venue_Id , p.Player_Name , COUNT(DISTINCT bs.Match_Id) Matches_played ,
		SUM(bs.Runs_Scored) runs, SUM(bs.Runs_Scored)/COUNT(DISTINCT bs.Match_Id) batting_avg 
FROM ball_by_ball bb
JOIN batsman_scored bs 
ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id
JOIN matches m 
ON m.Match_Id = bb.Match_Id
JOIN player p 
ON p.Player_Id = bb.Striker
GROUP BY   m.Venue_Id , p.Player_Name)
,
detail_by_rank AS
(SELECT d.Venue_Id , d.Player_Name , d.Matches_played , d.runs , d.batting_avg , 
        dense_rank() OVER (partition by d.Venue_Id ORDER BY d.runs DESC , d.batting_avg) as Ranks
FROM detail d)

SELECT v.Venue_Name , dr.* 
FROM detail_by_rank dr 
JOIN venue v 
ON dr.Venue_Id = v.Venue_Id
WHERE dr.Ranks <= 3;

-- Bowl

WITH runs_consided AS 
(select m.Venue_Id , bb.Bowler , SUM(bs.Runs_Scored) runs_given
FROM ball_by_ball bb 
JOIN batsman_scored bs 
ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id AND bb.Innings_No = bs.Innings_No
JOIN matches m 
ON m.Match_Id= bb.Match_Id 
GROUP BY m.Venue_Id , bb.Bowler)
,
wickets_taken AS 
(select m.Venue_Id, bb.Bowler , COUNT(wt.Kind_Out) wickets
FROM ball_by_ball bb 
JOIN wicket_taken wt
ON  bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id AND bb.Ball_Id = wt.Ball_Id AND bb.Innings_No = wt.Innings_No
JOIN matches m 
ON m.Match_Id= bb.Match_Id 
GROUP BY m.Venue_Id , bb.Bowler)
,
Details_by_Rank AS 
(SELECT rc.Venue_Id , rc.Bowler ,p.Player_Name ,  rc.runs_given , wt.wickets , rc.runs_given / wt.wickets AS bowling_average , 
       dense_rank() OVER (partition by rc.Venue_Id ORDER BY wt.wickets DESC , rc.runs_given / wt.wickets ASC ) Ranks
FROM runs_consided rc 
JOIN wickets_taken wt 
ON rc.Venue_Id = wt.Venue_Id AND rc.Bowler = wt.Bowler
JOIN player p 
ON p.Player_Id = rc.Bowler)

SELECT v.Venue_Name , dr.* 
FROM Details_by_Rank dr 
JOIN venue v 
ON v.Venue_Id = dr.Venue_Id
WHERE dr.Ranks <= 3;



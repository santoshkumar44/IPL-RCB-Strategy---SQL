use ipl;
-- subjective:1	How does toss decision have affected the result of the match ? (which visualisations could be used to better present your answer) And is the impact limited to only specific venues?

-- total number of matches
SELECT count(Match_Id) total_matches 
FROM matches;

-- Number of matches won afer wining the toss
SELECT COUNT(*) Matches_and_toss_won
FROM matches
WHERE Toss_Winner = Match_Winner AND Win_Type in (1,2,4);

-- Matches won after tos winning as per venue
SELECT v.Venue_Name , COUNT(m.Match_Id) matches , COUNT(CASE WHEN m.Toss_Winner = m.Match_Winner THEN 1 else NULL END ) AS toss_win_and_match_win,
COUNT(CASE WHEN m.Toss_Winner = m.Match_Winner THEN 1 else NULL END )/COUNT(m.Match_Id)*100  winning_percentage
FROM matches m 
JOIN venue v 
ON m.Venue_Id = v.Venue_Id
WHERE Win_Type in (1,2,4)
GROUP BY v.Venue_Name

-- -----------------------------------------------------------------------------------------------------------------------------------------
-- subjective:4 Which players offer versatility in their skills and can contribute effectively with both bat and ball? (can you visualize the data for the same)

with details_runs as (
select p.Player_Name,count(distinct bs.Match_Id) matches , sum(bs.Runs_Scored) runs,
sum(bs.Runs_Scored)/count(distinct bs.Match_Id) avg_runs
from ball_by_ball bb
join batsman_scored bs 
on bb.Match_Id = bs.Match_Id and bb.Over_Id = bs.Over_Id and bb.Ball_Id = bs.Ball_Id
join player p 
on p.Player_Id = bb.Striker
join matches m 
on m.Match_Id = bb.Match_Id
group by p.Player_Name),

wickets_details_wickets as(
select bb.Bowler,p.Player_Name,count(distinct wt.Match_Id) matches,
COUNT(wt.Kind_Out) wickets,count(wt.Kind_Out)/count(distinct wt.Match_Id) avg_wickets
from ball_by_ball bb
join wicket_taken wt
on bb.Match_Id = wt.Match_Id and bb.Over_Id = wt.Over_Id and bb.Ball_Id = wt.Ball_Id and bb.Innings_No = wt.Innings_No
join player p
on p.Player_Id =bb.Bowler
group by bb.Bowler,p.Player_Name)


select wd.Player_Name,ds.matches,ds.runs,wd.wickets,ds.avg_runs batting_average,wd.avg_wickets bowling_average
from details_runs ds
join wickets_details_wickets wd
on ds.Player_Name = wd.Player_Name
where ds.runs >1000 and wd.wickets >30;

-- ------------------------------------------------------------------------------------------------------------------------------------
-- subjective:5 Are there players whose presence positively influences the morale and performance of the team? (justify your answer using visualisation)

WITH Details AS 
(SELECT p.Player_Id,COUNT(DISTINCT m.Match_Id) Matches_played , COUNT(CASE WHEN t.Team_Id = m.Match_Winner then 1 else NULL end) AS wins,
				   COUNT(CASE WHEN t.Team_Id = m.Match_Winner then 1 else NULL end)/COUNT(DISTINCT m.Match_Id) * 100  AS win_percentage
FROM player p 
JOIN player_match pm 
ON p.Player_Id = pm.Player_Id
JOIN team t 
ON t.Team_Id = pm.Team_Id
JOIN matches m 
ON m.Match_Id = pm.Match_Id
GROUP BY 1)

SELECT p.Player_Name , d.Matches_played , d.wins , d.win_percentage 
FROM Details d 
JOIN player p 
ON p.Player_Id = d.player_Id
WHERE d.Matches_played > 40
ORDER BY d.win_percentage DESC
LIMIT 20;

-- ---------------------------------------------------------------------------------------------------------------------------------------
-- subjective8: Analyze the impact of home ground advantage on team performance and identify strategies to maximize this advantage for RCB.

SELECT COUNT(*) RCB_Home_Match , COUNT( CASE WHEN Match_Winner = 2 THEN 1 else NULL END ) AS RCB_WIN ,
                  COUNT(CASE WHEN Match_Winner != 2 THEN 1 ELSE NULL END ) AS RCB_LOSS , 
                  COUNT(*) - COUNT(Match_Winner) No_result , 
                  COUNT( CASE WHEN Match_Winner = 2 THEN 1 else NULL END )/COUNT(*) * 100 AS win_percentage
FROM matches
WHERE Venue_Id = 1 AND (Team_1 = 2 or Team_2 =2);

-- RCB Away Match

SELECT COUNT(*) RCB_away_Match , COUNT( CASE WHEN Match_Winner = 2 THEN 1 else NULL END ) AS RCB_WIN ,
                  COUNT(CASE WHEN Match_Winner != 2 THEN 1 ELSE NULL END ) AS RCB_LOSS , 
                  COUNT(*) - COUNT(Match_Winner) No_result , 
                  COUNT( CASE WHEN Match_Winner = 2 THEN 1 else NULL END )/COUNT(*) * 100 AS win_percentage
FROM matches
WHERE Venue_Id != 1 AND (Team_1 = 2 or Team_2 =2);

-- ---------------------------------------------------------------------------------------------------------------------------------------
-- subjective9: Come up with a visual and analytical analysis with the RCB past seasons performance and potential reasons for them not winning a trophy.

-- Sesson vise record

SELECT Season_Id , Count(Match_Id) Matches_Played , COUNT(CASE WHEN Match_Winner = 2 THEN 1 else NULL end) AS won ,
                   COUNT(CASE WHEN Match_Winner != 2 THEN 1 else NULL end) AS loss , 
                   COUNT(CASE WHEN Match_Winner = 2 THEN 1 else NULL end) / Count(Match_Id) * 100  AS win_percentage
                   
FROM matches
WHERE Team_1 = 2 or Team_2 = 2
GROUP BY Season_Id;

-- Overall Record 

WITH Detail AS 
(SELECT Season_Id , Count(Match_Id) Matches_Played , COUNT(CASE WHEN Match_Winner = 2 THEN 1 else NULL end) AS won ,
                   COUNT(CASE WHEN Match_Winner != 2 THEN 1 else NULL end) AS loss , 
                   COUNT(CASE WHEN Match_Winner = 2 THEN 1 else NULL end) / Count(Match_Id) * 100  AS win_percentage
FROM matches
WHERE Team_1 = 2 or Team_2 = 2
GROUP BY Season_Id)

select SUM(matches_played) Total_matches , SUM(won) Wins , SUM(loss) loss, 
       AVG(win_percentage) overall_win_percentage , SUM(won) - SUM(loss) AS No_result
FROM Detail;


-- Runs and Wickets

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

SELECT Season_Year, Total_Runs, Total_Wickets
FROM Performance;

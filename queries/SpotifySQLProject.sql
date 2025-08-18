-- ==========================
-- EASY QUERIES
-- ==========================

--Question 2: 
--For each album, calculate the average tempo and total number of tracks. 
--Return the top 10 albums with the highest average tempo and at least 3 tracks.
select album, avg(tempo) as avg_tempo, count(track) as track_count
from spotify
group by album
having count(track) >= 3
order by avg_tempo desc
limit 10;

--Question 3: 
--Which tracks have a duration longer than the global average track duration 
--and also have above-average danceability?
select track
from spotify
where duration_min >= 
(select avg(duration_min) from spotify)
and 
danceability >= (select avg(danceability) from spotify);

-- Question 5 Part A: 
--For each artist, return their top 3 most-viewed tracks based on the number of YouTube views. 
--Use a window function to rank tracks and return only the top 3 per artist.
select most.artist, most.track, most.viewed_tracks
from (
	select artist, track, row_number() over(partition by artist order by views desc) as viewed_tracks
	from spotify
) as most
where most.viewed_tracks <= 3;

-- Question 6: 
--Which artist has the highest average stream count per track?
WITH max_count AS (
  SELECT artist, SUM(stream) AS max_streams, COUNT(track) AS num_tracks
  FROM spotify
  GROUP BY artist
)
SELECT artist,
       ROUND((max_streams * 1.0 / num_tracks), 2) AS highest_avg_stream
FROM max_count
ORDER BY highest_avg_stream DESC;

-- Question 7: What are the total streams and views per artist and their most played platform?
SELECT totals.artist, totals.total_streams, totals.total_views, totals.most_played_on
FROM (
  SELECT artist, SUM(stream) AS total_streams, SUM(views) AS total_views, most_played_on
  FROM spotify
  GROUP BY artist, most_played_on
) AS totals
ORDER BY totals.total_streams DESC, totals.total_views DESC;

-- Question 9: 
--Rank artists based on their total Spotify streams
with total_streams as (
	select artist, sum(stream) as total_stream
	from spotify
	group by artist
)

select artist, total_stream, rank() over(order by total_stream desc) as rank_order
from total_streams
order by total_stream desc;

-- Question 10: 
--Write a query to find tracks where the liveness score is above the average 
with avg_track_liveness as(	
	select track, liveness, 
	(select round((sum(liveness) * 1.0 / count(track))::numeric, 2) from spotify) as avg_liveness
	from spotify
)

select track, liveness
from avg_track_liveness
where liveness > avg_liveness;

-- Bonus: Question 16: 
--Find all the tracks, streams, and views where Olivia Rodrigo is the artist
-- List the streaming and viewing numbers from greatest to least
select artist, track, stream, views
from spotify
where artist = 'Olivia Rodrigo'
order by stream desc, views desc;

-- ==========================
-- MEDIUM QUERIES
-- ==========================
--Question 4:
--Which 5 artists have the highest consistency between their top 3 
--most-streamed tracks and top 3 most-viewed tracks, based on overlap in track titles?
with stream_rank as (
	select artist, track,
	row_number() over(partition by artist order by stream desc) as rn_stream
	from spotify	
),

views_rank as (
	select artist, track,
	row_number() over(partition by artist order by views desc) as rn_views
	from spotify 
)

select sr.artist, sr.track, vr.track 
from stream_rank as sr
inner join views_rank as vr on sr.artist = vr.artist and sr.track = vr.track
where rn_stream <= 3 and rn_views <= 3;

-- Question 5 Part B:
--Order the result from Part A by the sum of views across each artist’s top 3 tracks, from highest to lowest total.
with ranked_tracks as (
	select artist, views, track, 
	       row_number() over(partition by artist order by views desc) as track_rank
	from spotify
),
top_tracks as (
	select artist, views, track, track_rank
	from ranked_tracks
	where track_rank <= 3
),
artist_totals as (
	select artist, views, track, track_rank, 
	       sum(views) over(partition by artist) as total_views
	from top_tracks
)

select artist, track, track_rank
from artist_totals
order by total_views;


-- Question 8 Part A: 
--For each artist, what is their dominant platform (Spotify or YouTube), 
--and how do they rank in total engagement within that platform?
WITH artist_platform_metrics AS (
    SELECT 
        artist, 
        CASE 
            WHEN stream > views THEN 'Spotify' 
            ELSE 'YouTube' 
        END AS dominant_platform,
        SUM(stream + views) AS total_engagement
    FROM spotify
    GROUP BY artist, 
             CASE 
                 WHEN stream > views THEN 'Spotify' 
                 ELSE 'YouTube' 
             END
)
SELECT 
    artist, 
    dominant_platform, 
    total_engagement,
    ROW_NUMBER() OVER (
        PARTITION BY dominant_platform 
        ORDER BY total_engagement DESC
    ) AS rank_in_total_engagement
FROM artist_platform_metrics;

-- Question 8 Part B: 
--For each artist, count how many times they had higher streams vs. higher views, 					  
--determine dominant platform, and rank them by total engagement.
WITH artist_platform_metrics AS (
  SELECT artist, SUM(stream + views) AS total_engagement,
         COUNT(CASE WHEN stream > views THEN 1 END) AS spotify_count, 
         COUNT(CASE WHEN views > stream THEN 1 END) AS youtube_count
  FROM spotify
  GROUP BY artist
)
SELECT artist,
       CASE 
         WHEN spotify_count > youtube_count THEN 'Spotify'
         WHEN youtube_count > spotify_count THEN 'YouTube'
         ELSE 'Tie'
       END AS dominant_platform,
       total_engagement,
       ROW_NUMBER() OVER (
         PARTITION BY 
           CASE 
             WHEN spotify_count > youtube_count THEN 'Spotify'
             WHEN youtube_count > spotify_count THEN 'YouTube'
             ELSE 'Tie'
           END
         ORDER BY total_engagement DESC
       ) AS rank_in_total_engagement
FROM artist_platform_metrics;

-- Question 11: 
--Use a WITH clause to calculate the difference between 
--the highest and lowest energy values for tracks in each album.
with album_energy_diff as (
	select artist, album, round((max(energy)::numeric *1.0 - min(energy)::numeric),2) as energy_track_diff, count(track) as track_per_album
	from spotify
	group by artist, album
	having count(track) > 1
)
select album, energy_track_diff
from album_energy_diff
order by energy_track_diff desc;

--Question 12: 
--Which artists have a higher-than-average likes-to-views 
--ratio across all their tracks and have at least 5 official music videos?
with like_view_ratio as (
select artist, round(sum(likes)::numeric *1.0 / sum(views)::numeric *1.0,4) as artist_avg_ratio, 
	   count(official_video) as video_count
from spotify
where views != 0 
group by artist
having count(official_video) >= 5
)

select artist, artist_avg_ratio
from like_view_ratio
where artist_avg_ratio > (
select round(sum(likes)::numeric *1.0 / sum(views)::numeric *1.0, 4)
from spotify 
where views!= 0
)
order by artist_avg_ratio desc;

-- Question 13 Part A: 
--For each artist, calculate the standard deviation of streams per track. 
--Return the 10 artists with the lowest standard deviation.
select artist, round(stddev(stream),2) as stream_stddev, count(track) as track_count
from spotify
where stream is not null and stream > 0
group by artist
having count(track) >= 1
order by stream_stddev
limit 10;

--Question 13 Part B: 
--Identify the most consistent artists by streams per track using 
--Coefficient of Variation (CV). Return the 10 artists with the lowest CV (stddev / avg), 
-- only considering artists with at least 5 tracks and a meaningful total stream count.
with consistent_artist as (
	select artist, sum(stream) as total_streams, stddev(stream) as std_dev, avg(stream) as avg_stream,
	count(track) as track_count
	from spotify
	where stream is not null and stream > 0
	group by artist
	having count(track) >= 5
)

select artist, round(((std_dev) / (avg_stream)),4) as cv
from consistent_artist
where total_streams > 100000
order by cv
limit 10;


-- ==========================
-- ADVANCED QUERIES
-- ==========================

--Question 1:
--Which artists would be the best headliners for an end-of-summer festival—artists who not 
--only rank in the top 15% for total engagement (streams + views) but also have the right 
--musical attributes to keep the crowd moving all night? Return the top 8 artists ordered 
--descending by their Festival Vibe Score.

with totals as (
	select artist, (sum(stream) + sum(views)) as total_engagement, 
	avg(tempo) as avg_tempo, avg(danceability) as avg_dance,
	avg(liveness) as avg_live, avg(energy) as avg_energy, avg(energy_liveness) as avg_el
	from spotify
	group by artist
),

percentiles as (
	select artist, total_engagement,
	(1 - percent_rank() over(order by avg_tempo desc)) as rnt,
	(1 - percent_rank() over(order by avg_dance desc )) as rnd,
	(1 - percent_rank() over(order by avg_live desc)) as rnl,
	(1 - percent_rank() over(order by avg_energy desc)) as rne,
	(1 - percent_rank() over(order by avg_el desc)) as rnel
	from totals
),

percent_sums as (
	select artist, total_engagement, ((rnt + rnd + rnl + rne + rnel) / 5) as vibe_score
	from percentiles
),

thresholds as ( 
	select percentile_cont(0.85) within group (order by total_engagement desc) as p85
	from totals
)


select ps.artist, round(ps.vibe_score::numeric,4) as festival_vibe_score
from percent_sums as ps
cross join thresholds as t
where ps.total_engagement >= t.p85
order by ps.vibe_score desc
limit 8;

--Question 14:
--Identify the top 5 artists whose Spotify–YouTube track performance is most balanced, 
--measured by the smallest average absolute difference between streams and views per track. Only consider artists with:
	--A total engagement (streams + views) above the 25th percentile across all artists, and
	--A catalog size at or above the dataset-wide average track count.
with abs_diff AS (
    SELECT 
        artist, 
		track,
        ABS(COALESCE(stream,0) - COALESCE(views,0)) AS track_abs_diff, 
        ABS(COALESCE(stream,0) + COALESCE(views,0)) AS track_engagement
    FROM spotify
	where stream > 0 and views > 0
),

artist_totals AS (
    SELECT 
        artist,
		count(track) as total_track,
        avg(track_abs_diff) AS avg_diff,
		sum(track_abs_diff) as total_abs_diff,
        sum(track_engagement) AS total_engagement,
		sum(track_abs_diff)::numeric / nullif(sum(track_engagement),0) AS real_diff
    FROM abs_diff
    GROUP BY artist
	
),

percentile_threshold AS (
    SELECT 
	percentile_cont(0.25) within group (order by total_engagement) as p25,
	avg(total_track) as avg_track_count
    FROM artist_totals as at 
)

SELECT 
    at.artist,
	round(at.real_diff::numeric, 2) as rounded_real_diff,
    at.avg_diff,
    at.total_engagement
FROM artist_totals at
CROSS JOIN percentile_threshold pt
WHERE at.total_engagement >= pt.p25 and at.total_track >= pt.avg_track_count
ORDER BY rounded_real_diff desc, at.avg_diff
LIMIT 5;

-- Question 15: 
--Which 5 artists offer the strongest cross-platform engagement 
--balance and should be prioritized for dual-format (video + audio) promotion?
with cross_check as (
	select artist, sum(stream) as total_streams, sum(views) as total_views, 
	round((sum(likes)::numeric *1.0 / sum(views)::numeric *1.0),4) as like_view_ratio, 
	sum(case 
		when official_video = TRUE then 1  else 0 end) as vid_count
from spotify
where views <> 0
group by artist
),

fair_balance as (
	select artist, greatest(max(stream), max(views)) as max_hit, least(min(stream), min(views)) as min_tail
	from spotify
	where stream > 0 and views > 0
	group by artist
	
),

percent_ranking as (
	select cc.artist, cc.total_streams, cc.total_views, cc.like_view_ratio, cc.vid_count,
	round((least(total_streams, total_views)::numeric / greatest(total_streams, total_views))::numeric,4) as balance,
	ntile(4) over(order by max_hit desc) as max_hit_quart,
	ntile(4) over (order by min_tail desc) as flop_song_quart,
	(1 - percent_rank() over(order by total_streams desc)) as stream_rank,
	(1 - percent_rank() over(order by total_views desc)) as view_rank,
	(1 - percent_rank() over(order by like_view_ratio desc)) as lv_ratio_rank,
	(1 - percent_rank() over(order by vid_count desc)) as vid_rank
	
from cross_check as cc
inner join fair_balance as fb on cc.artist = fb.artist
),

scored as (
	select pr.artist, pr.total_streams, pr.total_views, pr.like_view_ratio, pr.vid_count, max_hit_quart, flop_song_quart,
	round(((stream_rank + view_rank + lv_ratio_rank + vid_rank + 2*balance)::numeric / 6), 4) as base_rank,
	case when pr.max_hit_quart = 1 then 1.5
		 when pr.max_hit_quart = 2 then 1
		 when pr.max_hit_quart = 3 then 0.5 else 0 end as hit_ranking,
	case when pr.flop_song_quart = 1 then 0
		 when pr.flop_song_quart = 2 then 0.5
		 when pr.flop_song_quart = 3 then 1 else 1.5 end as flop_ranking
	from percent_ranking as pr
)

select artist, total_streams, total_views, base_rank, (base_rank + 0.1*hit_ranking - 0.05*flop_ranking) as balance_rank
from scored
order by balance_rank desc
limit 5;






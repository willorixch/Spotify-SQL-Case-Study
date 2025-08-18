# Spotify Cross-Platform SQL Analysis Case Study

<img width="800" height="450" alt="image" src="https://github.com/user-attachments/assets/c3c30071-2b5b-45cc-a6e4-894577826ccd" />


## Overview
This repository contains a unique Spotify SQL analysis case study blending data exploration with  multifaceted lens of creativity.
This dataset captures various attributes about tracks, albums, and artists enabling a deep dive into cross-platform engagement between Spotify and YouTube.

This project ensures a full pipline process from gathering and cleaning data, preforming queries, to visualizing results into meaningful insights like charts and dashboards.
The primary goal was to write efficient and effective queries varying in complexity levels (easy, medium, advanced) to provide a distinctive perspective on how data shapes decision making in a fast paced music industry.

## Project Structure
### 1. Data Exploration

#### Links To Datasets
  * [Cleaned Dataset](https://drive.google.com/file/d/19TOqTvBW5sfkrlMA3n1pSkACuwGtplDJ/view?usp=drive_link)
  * [Orginal Dataset](https://www.kaggle.com/datasets/sanjanchaudhari/spotify-dataset)

The cleaned dataset was used to create a SQL table called spotify. Each column represents a different attribute of a record/track; think of them like parts of a body like hands or feet that together form the "whole" song. 
```sql
-- Table Creation (Spotify)
DROP TABLE IF EXISTS spotify;
CREATE TABLE spotify (
    artist VARCHAR(255),
    track VARCHAR(255),
    album VARCHAR(255),
    album_type VARCHAR(50),
    danceability FLOAT,
    energy FLOAT,
    loudness FLOAT,
    speechiness FLOAT,
    acousticness FLOAT,
    instrumentalness FLOAT,
    liveness FLOAT,
    valence FLOAT,
    tempo FLOAT,
    duration_min FLOAT,
    title VARCHAR(255),
    channel VARCHAR(255),
    views FLOAT,
    likes BIGINT,
    comments BIGINT,
    licensed BOOLEAN,
    official_video BOOLEAN,
    stream BIGINT,
    energy_liveness FLOAT,
    most_played_on VARCHAR(50)
);
```

#### Column Descriptions
 * Artist - The name of the singer, songwriter, or group who performed the song.
 * Track - The title of the song.
 * Album - The album where the track was released.
 * Album_Type - Indicates if the release was an album, single, or compilation (EP).
 * Danceability - A score (0.0 - 1.0) describing how suitable the track is for dancing.
 * Energy - A measure of intensity and activity in the track (higher = more energetic).
 * Loudness - Overall loudness of the track in decibels (dB).
 * Speechiness - Degree to which track contains spoken words.
 * Acousticness - Measures how much of a song is comprised of natural, organic sounds.
 * Instrumentalness - Shows how much of a song contains more instruments over vocals (closer to 1.0 = more instrumental).
 * Liveness - Presence of a live audience within a track.
 * Valence - Describes the musical positivity of a track (0.0 = ballad, 1.0 = upbeat).
 * Tempo - Indicates the pacing or speed of the track measured in beats per minute (BPM).
 * Duration_Min - The length of the track in minutes.
 * Title - The title of the track shown on YouTube.
 * Channel - The YouTube channel that uploaded the video.
 * Views - Total number of individuals who viewed the offical track/video on YouTube.
 * Likes - Number of likes on the YouTube video.
 * Comments - Number of comments on the YouTube video
 * Licensed - Boolean (True or False) showing if the video is licensed.
 * Offical_Video - Boolean (True or False) showing if the video is the official release.
 * Stream - Total Number of streams for track on Spotify.
 * Energy_Liveness - A combined metric (experimental) of energy and liveness.
 * Most_Played_On - Indicates where the track has the most engagement (Spotify vs YouTube)

### Preview of Cleaned Dataset

Below is a sample of 10 rows (2 songs per artist) to provide a glimpse of the dataset:

| Artist         | Track                 | Streams      | Views       | Most Played On |
|----------------|-----------------------|--------------|-------------|----------------|
| Taylor Swift   | Anti-Hero             | 530,534,722  | 101,169,702 | Spotify        |
| Taylor Swift   | Lavender Haze         | 263,032,419  | 14,004,124  | Spotify        |
| Billie Eilish  | lovely (with Khalid)  | 2,110,573,779| 1,721,400,523| Spotify       |
| Billie Eilish  | TV                    | 188,946,951  | 21,545,835  | Spotify        |
| Olivia Rodrigo | good 4 u              | 1,732,870,361| 419,252,572 | Spotify        |
| Olivia Rodrigo | traitor               | 1,070,224,502| 87,390,538  | Spotify        |
| Clairo         | Sofia                 | 518,264,885  | 524,064     | Spotify        |
| Clairo         | Bubble Gum            | 332,692,745  | 123,012     | Spotify        |
| Beabadoobee    | Cofeee                | 114,905,173  | 5,648,813   | Spotify        |
| Beabadoobee    | the perfect pair      | 52,377,086   | 2,580,366   | Spotify        |

### 2. Query Analysis
After inserting the data, various queries can be run to filter, group, and ultimately extract meaningful insights. In this project, I categorized each question into three levels of complexity: Easy, Medium, and Advanced.

 * [Full Document Questions](https://docs.google.com/document/d/120jG-nItwBXqaJy3dEA_N6Pd0_0VdrB9afqscWvncdo/edit?usp=sharing)
 * [SQL Queries](https://github.com/willorixch/Spotify-SQL-Case-Study/blob/main/queries/SpotifySQLProject.sql)

#### Easy Queries
 * Simple retrieval and aggregations
 * Examples:
   * Calculate the average tempo and total tracks per album, returning the top 10.
   * Find tracks with duration longer than the global average and above-average danceability.
   * Rank artists based on their total Spotify streams.

```sql
select artist, track, stream, views
from spotify
where artist = 'Olivia Rodrigo'
order by stream desc, views desc;
```
#### Medium Queries
 * Intermediate joins, window functions, and ratios.
 * Examples:
   * Identify the 5 artists with the highest overlap between their top 3 streamed and top 3 viewed tracks.
   * Calculate the standard deviation of streams per track for each artist.
   * Find artists with above-average likes-to-views ratios and at least 5 official videos.

```sql
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
```
#### Advanced Queries
* Complex business-like case studies and ranking metrics.
* Examples:
  * Determine the best potential headliners for a festival, factoring in both engagement and “Festival Vibe Score”.
  * Identify the top 5 artists whose Spotify–YouTube performance is most balanced, based on absolute differences.
  * Pinpoint artists that should be prioritized for dual-format (video + audio) promotion.

```sql
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
```

### 3. Results - Outputs and Visualizations from Queries

### 4. Case Study Document

### 5. Query Optimization (Coming Soon...)

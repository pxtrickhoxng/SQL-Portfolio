----------------------------------------------
# 1. Which video game genre had the most publications from 2010 onwards? And which genre had the most publications before 2010?

SELECT genres,
    COUNT(CASE WHEN YEAR(release_date) >= 2010 THEN 1 END) AS count_2010_and_later,
    COUNT(CASE WHEN YEAR(release_date) < 2010 THEN 1 END) AS count_earlier_than_2010
FROM steam
GROUP BY genres
ORDER BY count_2010_and_later DESC;

# Summarized findings: 
-- Action is undeniably the most popular genre both after and before 2010.
----------------------------------------------
# 2. Which developer has the highest net rating (positive rating minus negative) of all time?

# This CTE calculates the net rating for each developer.
WITH cte1 AS (
    SELECT developer, (positive_ratings - negative_ratings) AS net_rating
    FROM steam
)

# The main query combines the CTE with the steam table and groups each developer's net rating into a single row.
SELECT s.developer, SUM(c.net_rating) AS total_net_rating
FROM steam AS s
JOIN cte1 AS c ON s.developer = c.developer
GROUP BY s.developer
ORDER BY total_net_rating DESC;

# Summarized findings: 
-- Valve is the top-performing developer, securing both the first and second positions in terms of net rating.
----------------------------------------------
# 3. What is the average price of games released between 2014 and 2019, separated by genres?

# The query shows the average price per genre & genre combination.
SELECT genres, CONCAT("$", ROUND(AVG(price), 2)) AS average_price
FROM steam
WHERE YEAR(release_date) BETWEEN 2014 AND 2019
GROUP BY genres
ORDER BY AVG(price) DESC;

# Summarized findings: 
-- Utilities (tools, not video games) are the most expensive genre, with animation and modeling utilities appearing to be the priciest.
----------------------------------------------
# 4. How many games were released each year, and what were the average number of positive ratings for those games?

SELECT year(release_date), COUNT(*) AS num_games_released, AVG(positive_ratings)
FROM steam
GROUP BY year(release_date)
ORDER BY AVG(positive_ratings) DESC;

SELECT * FROM STEAM WHERE YEAR(release_date) = 2000;

# Summarized findings: 
-- Although Steam launched in 2003, 2000 had the highest average positive ratings with only two releases: Counter-Strike and Ricochet. The second query filters the dataset to show only the games from 2000, revealing these two titles.
-- Apart from that, 2018 had the highest total positive ratings.
----------------------------------------------
# 5. Which year had the highest number of game releases, and what platforms did they support?

# The CTE identifies the year with the highest number of game releases.
WITH top_year AS (
    SELECT YEAR(release_date) AS yr
    FROM steam
    GROUP BY YEAR(release_date)
    ORDER BY COUNT(*) DESC
    LIMIT 1
)

# The main query breaks down the year with highest num of releases by their platforms. 
SELECT YEAR(s.release_date) AS yr, 
    COUNT(*) AS num_of_games,
    COUNT(CASE WHEN platforms LIKE '%Windows%' THEN 1 END) AS Windows,
    COUNT(CASE WHEN platforms LIKE '%Mac%' THEN 1 END) AS Mac,
    COUNT(CASE WHEN platforms LIKE '%Linux%' THEN 1 END) AS Linux
FROM steam s
JOIN top_year t ON YEAR(s.release_date) = t.yr
GROUP BY YEAR(s.release_date);

# Summarized findings: 
-- 2013 had the most games, with Windows being the dominant OS.
----------------------------------------------
# 6. What is the relationship between price range and the number of positive ratings, and what is the estimated profit per price range?

# This CTE groups prices in $5 intervals AND gathers the middle price per price range
WITH price_groups AS (
SELECT 
	CASE 
		WHEN price < 5 THEN 'Under $5'
		WHEN price BETWEEN 5 AND 9.99 THEN '$5 - $9.99'
		WHEN price BETWEEN 10 AND 14.99 THEN '$10 - $14.99'
		WHEN price BETWEEN 15 AND 19.99 THEN '$15 - $19.99'
		WHEN price BETWEEN 20 AND 24.99 THEN '$20 - $24.99'
		WHEN price BETWEEN 25 AND 29.99 THEN '$25 - $29.99'
		WHEN price BETWEEN 30 AND 34.99 THEN '$30 - $34.99'
		ELSE '$35 and above'
	END AS price_range,
	CASE 
		WHEN price < 5 THEN 2.50
		WHEN price BETWEEN 5 AND 9.99 THEN 7.50
		WHEN price BETWEEN 10 AND 14.99 THEN 12.50
		WHEN price BETWEEN 15 AND 19.99 THEN 17.50
		WHEN price BETWEEN 20 AND 24.99 THEN 22.50
		WHEN price BETWEEN 25 AND 29.99 THEN 27.50
		WHEN price BETWEEN 30 AND 34.99 THEN 32.50
		ELSE 40.00
	END AS median_price,
        positive_ratings
    FROM steam
)

SELECT price_range, SUM(positive_ratings) AS total_positive_ratings, AVG(median_price) AS median_price, SUM(positive_ratings) * AVG(median_price) AS estimated_profit
FROM price_groups
GROUP BY price_range
ORDER BY price_range;

# Summarized findings: 
-- As expected, price and positive ratings have a negative correlation. The lower the price, the higher the positive ratings because more people are able to play and review the game.
-- However, higher positive ratings don’t always mean higher profits. Games in the $10 - $14.99 range seem to strike the best balance between affordability and revenue, generating the highest estimated profits.
----------------------------------------------
# 7. What is the average price for games with over 80% positive ratings? What about those with under 20% positive ratings?

SELECT 
CONCAT("$", ROUND(AVG(CASE WHEN (positive_ratings / (positive_ratings + negative_ratings)) > 0.80 THEN price END), 2)) AS avg_price_highly_rated,
CONCAT("$", ROUND(AVG(CASE WHEN (positive_ratings / (positive_ratings + negative_ratings)) < 0.20 THEN price END), 2)) AS avg_price_lowly_rated
FROM steam;

# Summarized findings: 
-- The games with over 80% positive ratings have an average price of $8.91, while games with under 20% positive ratings have an average price of $6.84.
-- This suggests that price may be less influential than overall game quality. As the price increases, buyers tend to have higher expectations, pushing developers to create higher-quality games to justify the cost.
-- We may also need to consider the Price-Quality Effect in our findings.
----------------------------------------------
# 8. What genre contains the most games that have a higher number of negative ratings than positive ratings?

SELECT genres, COUNT(*) AS games_with_more_negative_ratings
FROM steam
WHERE negative_ratings > positive_ratings
GROUP BY genres
ORDER BY games_with_more_negative_ratings DESC;

# The query counts games with more negative than positive ratings per genre, orders them by the highest count, and returns only the genre with the most negatively-rated games.

# Summarized findings: 
-- Strategy has the highest number of games with more negative ratings than positive ratings.
-- This suggests that strategy gamers may be more critical/dissatisfied with these games, or that developers in this genre struggle to meet the expectations of their playerbase.
----------------------------------------------
# 9. What is the average rating of games in different genres? To ensure accurate sampling, only include genres with more than 20 games.

SELECT genres, ROUND(AVG(positive_ratings / (positive_ratings + negative_ratings)), 2) AS average_rating_percentage
FROM steam
GROUP BY genres	
HAVING COUNT(*) >= 20
ORDER BY average_rating_percentage DESC;

# The query calculates the average positive rating percentage for each genre, filters out genres with fewer than 20 games, and orders the results by the highest average rating.

# Summarized findings:
-- Action has the highest average positive rating. When combining the results of this query with query #1, it becomes clear that Action is not only the most popular genre but also the most highly praised.
----------------------------------------------
# 10. Find the top 5 developers who have released the most games on Steam, along with their highest-rated game (based on positive/negative ratings ratio), 
# the average price of their games, and the total number of achievements across all their games. Exclude games that are not in English, and sort the results by the total number of achievements in descending order

# This CTE reveals the top 5 developers in regards to number of published games
WITH top_devs AS(
SELECT developer, COUNT(*) AS num_games
FROM steam
GROUP BY developer
ORDER BY num_games DESC
LIMIT 5
),

# This CTE ranks each developer's game by positive ratings
highest_rated_games AS (
SELECT developer, `name` AS highest_rated_game,
positive_ratings / (positive_ratings + negative_ratings) AS percent_positive,
RANK() OVER (PARTITION BY developer ORDER BY positive_ratings / (positive_ratings + negative_ratings) DESC) AS game_rnk
FROM steam
WHERE developer IN (SELECT developer FROM top_devs)
)

# This query joins all CTEs, calculates the developer's average game price, total achievements, and ensures the game is in English and the top seller.
SELECT td.developer, td.num_games, hrg.highest_rated_game, ROUND(AVG(price), 2) AS "Average Developer's Game Price", SUM(achievements) AS total_achievements
FROM steam AS s
JOIN top_devs AS td
ON td.developer = s.developer
JOIN highest_rated_games AS hrg
ON hrg.developer = s.developer
WHERE s.english = 1 AND hrg.game_rnk = 1
GROUP BY td.developer, hrg.highest_rated_game
ORDER BY total_achievements DESC



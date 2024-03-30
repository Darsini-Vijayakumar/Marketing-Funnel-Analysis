
-- First Query: Retrieve a limited set of data for initial analysis
SELECT * FROM `Data_for_analysis` LIMIT 5;

---- 1. Identifying Channel performance across Marketing Funnel Phases

-- This query provides a comprehensive analysis of marketing performance by program detailing total leads, sold, and start metrics alongside their respective percentages of the total.

SELECT
CHANNEL,
SUM(LEADS) AS TOTAL_LEADS,
SUM(SOLD) AS TOTAL_SOLD,
SUM(START) AS TOTAL_START,
ROUND((SUM(LEADS) * 100.0) / SUM(SUM(LEADS)) OVER(), 2) AS LEADS_PERCENT,
ROUND((SUM(SOLD) * 100.0) / SUM(SUM(SOLD)) OVER(), 2) AS SOLD_PERCENT,
ROUND((SUM(START) * 100.0) / SUM(SUM(START)) OVER(), 2) AS START_PERCENT
FROM `Data_for_analysis`
GROUP BY CHANNEL
ORDER BY TOTAL_LEADS DESC, TOTAL_SOLD DESC, TOTAL_START DESC;


/**
Findings : Digital Acquisition Channel followed by Traditional phone drive more conversion in all three marketing phases compared to other channels
**/


---- 2. Identifying the efficiency of each channel in converting leads through the funnel stages

-- This query calculates the rates of conversion from leads to sold (LEADS_RATE), from sold to start (START_RATE) and overall conversion from leads to start (CONVERSION) as percentages

WITH DATA AS 
(
SELECT CHANNEL,
SUM(LEADS) as TOTAL_LEADS, 
SUM(SOLD) as TOTAL_SOLD, 
SUM(START) as TOTAL_START, 
SUM(START_AMT) as TOTAL_START_AMT
FROM `Data_for_analysis`
GROUP BY 1
)
SELECT CHANNEL, 
ROUND(100 * TOTAL_SOLD / NULLIF(TOTAL_LEADS, 0), 0) AS LEADS_RATE,
ROUND(100 * TOTAL_START / NULLIF(TOTAL_SOLD, 0), 0) AS START_RATE,
ROUND(100 * TOTAL_START / NULLIF(TOTAL_LEADS, 0), 0) AS CONVERSION
FROM DATA
GROUP BY 1,2,3,4
ORDER BY LEADS_RATE DESC;

/**
Findings : Creative followed by traditional phone are effective channels in converting leads through the funnel stages
**/

-- 3. Which is the best Channel in terms of volume of business ?

-- Transactional Volume

WITH DATA AS 
(
SELECT CHANNEL,
SUM(LEADS) as TOTAL_LEADS, 
SUM(SOLD) as TOTAL_SOLD, 
SUM(START) as TOTAL_START, 
SUM(START_AMT) as TOTAL_START_AMT
FROM `Data_for_analysis`
GROUP BY 1
)
SELECT CHANNEL, TOTAL_START,
ROUND((SUM(TOTAL_START) / (SELECT SUM(START) FROM `Data_for_analysis`)) * 100, 2) AS PERCENTAGE,
ROUND(100 * TOTAL_START / NULLIF(TOTAL_LEADS, 0), 0) AS CONVERSION
FROM DATA
GROUP BY 1,2,4
ORDER BY CONVERSION DESC;

/**
Findings : Though Digital Acquisition brings in 46% of the total starts, Creative channel drives highest conversion of 86% followed by 40% through Traditional phone
**/

-- Monetary Volume

WITH DATA AS 
(
SELECT CHANNEL,
SUM(LEADS) as TOTAL_LEADS, 
SUM(SOLD) as TOTAL_SOLD, 
SUM(START) as TOTAL_START, 
SUM(START_AMT) as TOTAL_START_AMT
FROM `Data_for_analysis`
GROUP BY 1
)
SELECT CHANNEL, TOTAL_START_AMT,
ROUND((SUM(TOTAL_START_AMT) / (SELECT SUM(START_AMT) FROM `Data_for_analysis`)) * 100, 2) AS PERCENTAGE,
ROUND((SUM(TOTAL_START_AMT) / SUM(TOTAL_START)), 2) AS AVG_START_AMOUNT_PER_CONTRACT
FROM DATA
GROUP BY 1,2
ORDER BY AVG_START_AMOUNT_PER_CONTRACT DESC;

/**
Findings : Though ‘Other’ brings only 2% of total revenue, its average cost per contract is almost equal to Digital acquisition channel
**/

---- 4. Trend Analysis by Sub-Channel

-- This query provides a detailed breakdown of starts for various marketing sub-channels by quarter for each year.

SELECT YR,
CASE
WHEN MONTH IN (1, 2, 3) THEN 'Q1'
WHEN MONTH IN (4, 5, 6) THEN 'Q2'
WHEN MONTH IN (7, 8, 9) THEN 'Q3'
WHEN MONTH IN (10, 11, 12) THEN 'Q4'
END AS QUARTER,
  SUM(CASE WHEN SUB_CHANNEL = 'Creative' THEN START ELSE 0 END) AS Creative,
  SUM(CASE WHEN SUB_CHANNEL = 'IYP' THEN START ELSE 0 END) AS IYP,
  SUM(CASE WHEN SUB_CHANNEL = 'Natural Search' THEN START ELSE 0 END) AS Natural_Search,
  SUM(CASE WHEN SUB_CHANNEL = 'Abc.com' THEN START ELSE 0 END) AS Website,
  SUM(CASE WHEN SUB_CHANNEL = 'Other' THEN START ELSE 0 END) AS Other,
  SUM(CASE WHEN SUB_CHANNEL = 'Other Digital' THEN START ELSE 0 END) AS Other_Digital,
  SUM(CASE WHEN SUB_CHANNEL = 'Paid Search' THEN START ELSE 0 END) AS Paid_Search,
  SUM(CASE WHEN SUB_CHANNEL = 'Traditional Phone' THEN START ELSE 0 END) AS Traditional_Phone
FROM `Data_for_analysis`
GROUP BY 1,2
ORDER BY YR, QUARTER;

/**
Findings : 
- Starts face increases from Q1 to Q3 and gradually decreases towards Q4, is trend is similar across all sub programs
- Although Traditional phone has been significant contributor, Paid and natural search has remained consistent over the years
**/ 

---- 5. Identifying cost effective marketing channels

-- This query calculates the return on investment (ROI) for different marketing sub-channels by first assuming the lead acquisition cost as below

WITH DATA AS 
(
SELECT CHANNEL,
SUB_CHANNEL,
SUM(LEADS) AS TOTAL_LEADS,
SUM(START) AS TOTAL_START,
SUM(START_AMT) AS TOTAL_START_AMT,
(CASE
WHEN SUB_CHANNEL = 'Paid Search' THEN SUM(LEADS) * 1.32
WHEN SUB_CHANNEL = 'Traditional Phone' THEN SUM(LEADS) * 0.75
WHEN SUB_CHANNEL = 'IYP' THEN SUM(LEADS) * 1.02
ELSE SUM(LEADS) * 0.5
END) AS LEAD_ACQUISTION_COST
FROM `Data_for_analysis`
GROUP BY CHANNEL, SUB_CHANNEL
ORDER BY LEAD_ACQUISTION_COST DESC
);


/**
Findings : 
- Creative and Abc.com can be beneficial to increase investment and maximize returns
- Re-evaluate IYP, its essential to understand why ROI is lower
**/
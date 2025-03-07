# COVID-19-Data-Analysis-Visualization

## Overview
This project provides an in-depth analysis of COVID-19 trends using SQL and Tableau. It examines infection rates, mortality trends, vaccination progress, and the role of healthcare infrastructure, leveraging data from Our World in Data.

## Dataset

The dataset includes:

* Daily COVID-19 cases and death counts

* Vaccination statistics

* Healthcare infrastructure (hospital beds per thousand)

* Economic indicators (GDP per capita, Human Development Index)

## Steps Performed

### 1. SQL-Based Exploratory Data Analysis (EDA)

Data Cleaning & Processing: Standardized column names, handled missing values, and structured data for efficient analysis.

Key Queries:

1. Maximum Percentage of Rolling People Vaccinated in Each Country
   
-- Insight: Determines the maximum vaccination percentage achieved in each country.

WITH PopvsVac AS (
    SELECT death.iso_code, death.location, death.population, vac.new_vaccinations, vac.people_vaccinated, 
           vac.total_vaccinations, vac.date,
           SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY death.location ORDER BY death.date) AS RollingPeopleVaccinated
    FROM Covid_Portfolio_db.dbo.CovidDeaths death
    JOIN Covid_Portfolio_db.dbo.CovidVaccinations vac
       ON death.iso_code = vac.iso_code
       AND death.date = vac.date
    WHERE death.continent IS NOT NULL
) 
SELECT location, 
       MAX((RollingPeopleVaccinated / population) * 100) AS Percentage_RollingPeopleVaccinated
FROM PopvsVac
GROUP BY location
ORDER BY location;

2. GDP vs. COVID-19 Death Rate:
   
-- Insight: Examines the relationship between GDP per capita and COVID-19 death rates.

SELECT location, gdp_per_capita, 
       SUM(CAST(total_deaths AS FLOAT)) AS TotalDeaths, 
       SUM(CAST(total_cases AS FLOAT)) AS TotalCases,
       (SUM(CAST(total_deaths AS FLOAT)) / NULLIF(SUM(CAST(total_cases AS FLOAT)), 0)) * 100 AS DeathRate
FROM Covid_Portfolio_db.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, gdp_per_capita
ORDER BY gdp_per_capita DESC;

3. Hospital Beds vs. COVID-19 Mortality Rate:
   
-- Insight: Analyzes whether countries with more hospital beds per thousand had lower COVID-19 death rates.

SELECT location, hospital_beds_per_thousand, 
       SUM(CAST(total_deaths AS FLOAT)) AS TotalDeaths, 
       SUM(CAST(total_cases AS FLOAT)) AS TotalCases,
       (SUM(CAST(total_deaths AS FLOAT)) / NULLIF(SUM(CAST(total_cases AS FLOAT)), 0)) * 100 AS DeathRate
FROM Covid_Portfolio_db.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, hospital_beds_per_thousand
ORDER BY DeathRate DESC;

### 2. Tableau Visualization

Developed an interactive Tableau dashboard with:

* SQL as Data Source: Connected directly to a SQL database and used multiple views for efficient querying.

* Data Blending & Views: Integrated various SQL views in Tableau to facilitate advanced analysis.

* Forecasting in "Percent Population Infected" Sheet: Applied Tableau's built-in forecasting techniques to predict future infection trends.

* Window Functions in "Mortality Rate vs. Healthcare Facilities" Sheet: Used window functions to analyze the correlation between healthcare capacity and COVID-19 mortality rates.

### 3. Key Dashboards Created:

* Dual-Axis Line Chart: Tracks the relationship between vaccination rates and infection rates over time.

* Scatter Plot: Shows Mortality Rate vs. Healthcare Facilities (hospital beds per 1,000 people, GDP per capita as bubble size).

* Geographical Heatmap: Displays COVID-19 impact per country.

* Monthly Trends of Cases & Deaths: Uses Moving Averages to smooth fluctuations.

* Parameterized Bar Chart: Allows users to dynamically switch between Total Cases, Deaths, and Death Percentage.

## Key Insights

✅ Higher vaccination rates correlated with lower infection growth over time.
✅ Countries with better healthcare infrastructure (more hospital beds) had lower mortality rates.
✅ GDP per capita influenced access to vaccinations and healthcare infrastructure.
✅ Forecasting provided a clearer picture of future COVID-19 trends.

## Technologies Used

* SQL (SSMS) for data extraction and transformation

* Tableau for visualization and dashboarding

* Data Blending & Window Functions for advanced analytics

* Forecasting and Moving Averages for trend analysis

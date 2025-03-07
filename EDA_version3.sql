/* 
   COVID-19 Data Exploration and Analysis 
   --------------------------------------
   This project analyzes COVID-19 cases, deaths, infections, and vaccinations using SQL.
   It provides insights into death percentages, infection rates, vaccination progress, and continent-wise analysis. 
*/

/* ---------------------- 1. Death Analysis ---------------------- */

/* Death Percentage in the United States - Total Cases vs Total Deaths */
-- Insight: This query calculates the percentage of deaths relative to total cases in the United States over time.
SELECT location, date, total_cases, total_deaths, 
       ((total_deaths / total_cases) * 100) AS Death_Percentage
FROM Covid_Portfolio_db.dbo.CovidDeaths
WHERE location LIKE '%States'
ORDER BY location, date; 

/* Percentage of Population Infected - Total Cases vs Population */
-- Insight: This query determines the proportion of the population infected with COVID-19.
SELECT location, date, population, total_cases, total_deaths, 
       ((total_cases / population) * 100) AS Covid_Population_Percentage
FROM Covid_Portfolio_db.dbo.CovidDeaths
WHERE location LIKE '%States'
ORDER BY location, date; 

/* Countries with the Highest Infection Rate Compared to Population */
-- Insight: Identifies the countries where the highest percentage of the population was infected.
SELECT location, population, 
       MAX(total_cases) AS HighestInfectionCount,  
       MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM Covid_Portfolio_db.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC; 

/* Countries with the Highest Death Count per Population */
-- Insight: Finds the countries with the highest death toll per population.
SELECT location, population,  
       MAX(CAST(total_deaths AS FLOAT)) AS HighestDeathCount,  
       MAX((total_deaths / population) * 100) AS PercentPopulationDied
FROM Covid_Portfolio_db.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationDied DESC; 

/* ---------------------- 2. Continent-Wise Analysis ---------------------- */

/* Continents with the Highest Death Count per Population */
-- Insight: This query evaluates which continent had the highest death rate relative to its population.
SELECT location, population,  
       MAX(CAST(total_deaths AS FLOAT)) AS HighestDeathCount,  
       MAX((total_deaths / population) * 100) AS PercentPopulationDied
FROM Covid_Portfolio_db.dbo.CovidDeaths
WHERE continent IS NULL  -- This filters only continent-level data
GROUP BY location, population
ORDER BY PercentPopulationDied DESC; 

/* ---------------------- 3. Vaccination Analysis ---------------------- */

/* Total Population vs Vaccinations */
-- Insight: Tracks the cumulative number of people vaccinated in each country over time.
SELECT death.iso_code, death.location, death.population, vac.new_vaccinations, 
       vac.people_vaccinated, vac.total_vaccinations, vac.date,
       SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY death.location ORDER BY death.date) AS RollingPeopleVaccinated
FROM Covid_Portfolio_db.dbo.CovidDeaths death
JOIN Covid_Portfolio_db.dbo.CovidVaccinations vac
   ON death.iso_code = vac.iso_code
   AND death.date = vac.date
WHERE death.continent IS NOT NULL;

/* Using CTE to Find the Maximum Percentage of Rolling People Vaccinated in Each Country */
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

/* ---------------------- 4. Temporary Table for Vaccination Analysis ---------------------- */

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(FLOAT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM Covid_Portfolio_db..CovidDeaths dea
JOIN Covid_Portfolio_db..CovidVaccinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

/* ---------------------- 5. GDP, Healthcare, and Development Factors ---------------------- */

/* GDP vs. COVID-19 Death Rate */
-- Insight: Examines the relationship between GDP per capita and COVID-19 death rates.
SELECT location, gdp_per_capita, 
       SUM(CAST(total_deaths AS FLOAT)) AS TotalDeaths, 
       SUM(CAST(total_cases AS FLOAT)) AS TotalCases,
       (SUM(CAST(total_deaths AS FLOAT)) / NULLIF(SUM(CAST(total_cases AS FLOAT)), 0)) * 100 AS DeathRate
FROM Covid_Portfolio_db.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, gdp_per_capita
ORDER BY gdp_per_capita DESC;

/* Hospital Beds vs. COVID-19 Deaths */
-- Insight: Analyzes whether countries with more hospital beds per thousand had lower COVID-19 death rates.
SELECT location, hospital_beds_per_thousand, 
       SUM(CAST(total_deaths AS FLOAT)) AS TotalDeaths, 
       SUM(CAST(total_cases AS FLOAT)) AS TotalCases,
       (SUM(CAST(total_deaths AS FLOAT)) / NULLIF(SUM(CAST(total_cases AS FLOAT)), 0)) * 100 AS DeathRate
FROM Covid_Portfolio_db.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, hospital_beds_per_thousand
ORDER BY DeathRate DESC;

/* Human Development Index (HDI) vs. Infection Rate */
-- Insight: Evaluates whether countries with a higher HDI had lower infection rates.
SELECT location, human_development_index, 
       population, 
       MAX(total_cases) AS HighestInfectionCount,
       (MAX(total_cases) / NULLIF(population, 0)) * 100 AS InfectionRate
FROM Covid_Portfolio_db.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, human_development_index, population
ORDER BY human_development_index DESC;

/* ---------------------- 6. Views for Tableau Project ---------------------- */

/* Creating a View for Percent Population Vaccinated */
CREATE VIEW PercentPopulationVaccinated_V AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(FLOAT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM Covid_Portfolio_db..CovidDeaths dea
JOIN Covid_Portfolio_db..CovidVaccinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

/* Creating a View for Total Cases and Death Percentage */
CREATE VIEW TotalCounts_V AS
SELECT SUM(new_cases) AS TotalCases, 
       SUM(CAST(new_deaths AS FLOAT)) AS TotalDeaths, 
       (SUM(CAST(new_deaths AS FLOAT)) / SUM(New_Cases)) * 100 AS DeathPercentage
FROM Covid_Portfolio_db..CovidDeaths
WHERE continent IS NOT NULL;

/* Creating a View for Continent-wise Death Counts */
CREATE VIEW ContinentDeathCounts_V AS
SELECT location, 
       SUM(CAST(new_deaths AS FLOAT)) AS TotalDeathCount
FROM Covid_Portfolio_db..CovidDeaths
WHERE continent IS NULL 
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location;

/* Creating a View for Location-wise Infection Statistics */
CREATE VIEW LocationInfectionStats_V AS
SELECT location, 
       COALESCE(population, 0) AS population, 
       MAX(COALESCE(total_cases, 0)) AS HighestInfectionCount,  
       MAX(COALESCE(total_cases, 0) * 100.0 / NULLIF(population, 0)) AS PercentPopulationInfected
FROM Covid_Portfolio_db..CovidDeaths
GROUP BY location, population;

/* Creating a View for Daily Infection Statistics */
CREATE VIEW DailyInfectionStats AS
SELECT location, 
       COALESCE(population, 0) AS population, 
       date, 
       MAX(COALESCE(total_cases, 0)) AS HighestInfectionCount,  
       MAX(COALESCE(total_cases, 0) * 100.0 / NULLIF(COALESCE(population, 0), 0)) AS PercentPopulationInfected
FROM Covid_Portfolio_db..CovidDeaths
GROUP BY location, COALESCE(population, 0), date;

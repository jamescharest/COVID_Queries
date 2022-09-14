-- NOTE: When data set uploaded to MySQL, did not register NULL values, hence some wonky queries below

-- SELECT data we are going to look at

SELECT 
	location, date, total_cases, new_cases, total_deaths, population
FROM 
	COVID.deaths
Order by 1, 2;

-- Looking at Total Cases vs Total Deaths

SELECT 
	location, date, total_cases, total_deaths,  (total_deaths/total_cases) *100 AS Death_Percentage
FROM 
	COVID.deaths
WHERE continent not like ''
Order by 1, 2;

-- Look only at United States, most recent date
-- Shows the likelihood of dying of COVID

SELECT 
	location, date, total_cases, total_deaths,  (total_deaths/total_cases) *100 AS Death_Percentage
FROM 
	COVID.deaths
WHERE 
	location = 'United States'
    AND continent not like ''
ORDER BY 2 DESC;

-- Look at the rolling new cases and rolling new deaths in US

SELECT
	location,
    date,
    new_cases,
    SUM(new_cases) OVER (PARTITION BY location ORDER BY location, date) AS total_cases,
    CAST(new_deaths AS UNSIGNED) AS new_deaths,
    SUM(CAST(new_deaths AS UNSIGNED)) OVER (PARTITION BY location ORDER BY location, date) AS total_deaths
FROM COVID.deaths
WHERE
	location = 'United States'
    AND continent not like ''
ORDER BY 2;

-- Looking at the Total Cases vs the Population
-- Shows what percentage of the population has gotten COVID

SELECT 
	location, date, population, total_cases, (total_cases/population) *100 AS Percentage_Infected
FROM 
	COVID.deaths
WHERE 
	location = 'United States'
	AND continent not like ''
ORDER BY 2 DESC;


-- Looking at countries with highest infection rate compared to population

SELECT 
	location, 
    population, 
    MAX(total_cases) AS Highest_Infection_Count,  
    MAX((total_cases/population)) *100 AS Percentage_Infected
FROM 
	COVID.deaths
WHERE
	continent not like ''
GROUP BY location, population
ORDER BY Percentage_Infected DESC;


-- Showing Countries with highest death count

SELECT 
	location, 
    MAX(total_deaths) AS Total_Death_Count
FROM 
	COVID.deaths
GROUP BY location
ORDER BY Total_Death_Count DESC;

-- Previous query revealed that total_deaths is text string, not integer, need to CAST 
-- Data set did not import blank values as NULL, only as ''; applied to previous queries

SELECT 
	location, 
    MAX(CAST(total_deaths AS UNSIGNED)) AS Total_Death_Count
FROM 
	COVID.deaths
WHERE continent not like ''
GROUP BY location
ORDER BY Total_Death_Count DESC;

-- Breaking things down by continent

SELECT 
	continent, 
    CAST(total_deaths AS UNSIGNED) AS total_deaths
FROM 
	COVID.deaths
WHERE continent not like ''
ORDER BY total_deaths DESC;

SELECT 
	continent, 
    MAX(CAST(total_deaths AS UNSIGNED)) AS Total_Death_Count
FROM 
	COVID.deaths
WHERE continent not like ''
GROUP BY continent
ORDER BY Total_Death_Count DESC;

-- Provides innacurrate data, because countries are connected to Continent, so this actually pulls the max death count countries with highest death count in continent
-- Reexamining data shows accurate data for Continents in location

SELECT 
	location, 
    MAX(CAST(total_deaths AS UNSIGNED)) AS Total_Death_Count
FROM 
	COVID.deaths
WHERE continent = ''
	AND location not like "High Income"
	AND location not like "International"
	AND location not like "Low Income"
GROUP BY location
ORDER BY Total_Death_Count DESC;


-- Can also just look at most recent data based on most recent date

SELECT *
FROM Covid.deaths
Order by date DESC;

-- Most recent data is 9/6/22
-- Show most recent total numbers for each country

SELECT
	location,
    continent,
    population,
    total_cases,
    CAST(total_deaths AS UNSIGNED) AS total_deaths
FROM
	Covid.deaths
WHERE date = '2022-09-06'
	AND continent not like ''
Order by 1;

-- Global Numbers with CTE

WITH CountryCases (location, continent, population, total_cases, total_deaths)
AS
(
SELECT
	location,
    continent,
    population,
    total_cases,
    CAST(total_deaths AS UNSIGNED) AS total_deaths
FROM
	Covid.deaths
WHERE date = '2022-09-06'
	AND continent not like ''
-- Order by 1
)	
SELECT
	SUM(total_cases) AS global_cases,
    SUM(total_deaths) AS global_deaths,
    SUM(total_deaths) / SUM(total_cases) * 100 AS global_death_percentage
FROM CountryCases;

-- By Continent with CTE

WITH CountryCases (location, continent, population, total_cases, total_deaths)
AS
(
SELECT
	location,
    continent,
    population,
    total_cases,
    CAST(total_deaths AS UNSIGNED) AS total_deaths
FROM
	Covid.deaths
WHERE date = '2022-09-06'
	AND continent not like ''
-- Order by 1
)	
SELECT
	continent,
    SUM(population) AS population,
    SUM(total_cases) AS total_cases,
    SUM(total_deaths) AS total_deaths, 
    SUM(total_deaths)/SUM(total_cases) * 100 AS death_percentage
FROM COUNTRYCASES
GROUP BY continent;

-- Joining tables to see total population vs. vaccinations
-- Shows percentage of population who has received at least one shot

SELECT
	dea.continent,
    dea.location,
    dea.population,
    MAX(CAST(vac.people_vaccinated as UNSIGNED)) as total_vaccinated,
    MAX(CAST(vac.people_vaccinated as UNSIGNED))/ dea.population * 100 AS percent_vaccinated
FROM COVID.deaths as dea
JOIN COVID.vaccinations as vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent not like ''
GROUP BY dea.continent, dea.location, dea.population
Order by 2;

-- Get rolling count of people vaccinated by day

SELECT
	dea.continent,
    dea.location,
    dea.date,
    dea.population,
    CAST(vac.new_vaccinations AS UNSIGNED) as new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS UNSIGNED))
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM COVID.deaths as dea
JOIN COVID.vaccinations as vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent not like ''
Order by 2, 3;

-- Can look specifically at a single country

SELECT
	dea.continent,
    dea.location,
    dea.date,
    dea.population,
	CAST(vac.new_vaccinations AS UNSIGNED) as new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS UNSIGNED))
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM COVID.deaths as dea
JOIN COVID.vaccinations as vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent not like ''
	AND dea.location like 'United States'
Order by 2, 3;

-- Temp Table to Perform Calculations on Partition in previous query


DROP TEMPORARY TABLE IF EXISTS COVID.PercentVaccinated;
CREATE TEMPORARY TABLE IF NOT EXISTS COVID.PercentVaccinated
AS(
SELECT
	dea.continent,
    dea.location,
    dea.date,
    dea.population,
    CAST(vac.new_vaccinations AS UNSIGNED) as new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM COVID.deaths as dea
JOIN COVID.vaccinations as vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent not like ''
Order by 2, 3);

-- The above doesn't work when casting the values of new_vaccinations, with that removed, it does: 

DROP TEMPORARY TABLE IF EXISTS COVID.PercentVaccinated;
CREATE TEMPORARY TABLE IF NOT EXISTS COVID.PercentVaccinated
AS(
SELECT
	dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations as new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM COVID.deaths as dea
JOIN COVID.vaccinations as vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent not like ''
Order by 2, 3);

SELECT 
	*,
    (rolling_people_vaccinated/population)*100 AS percentage_vaxxed
FROM COVID.PercentVaccinated;

-- Above query worked, even without casting the values
-- Can look at single country

SELECT 
	*,
    (rolling_people_vaccinated/population)*100 AS percentage_vaxxed
FROM COVID.PercentVaccinated
WHERE
	location like 'United States';
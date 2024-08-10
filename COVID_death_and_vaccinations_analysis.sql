*.COVID_death_and_vaccinations_analysis.sql linguist-language=SQL
SELECT *
FROM 
	PortfolioProject..CovidDeaths
WHERE 
	continent is not null

--Showing death percentage in the Czech Republic changing in time 
SELECT 
	Location, date, total_cases, total_deaths, population,
	CASE
		WHEN total_cases = 0 THEN 0
		ELSE (total_deaths/total_cases)*100 
	END AS death_percentage
FROM
	PortfolioProject..CovidDeaths
WHERE 
	location like '%czech%' AND
	continent is not null
ORDER BY 
	1,2

--Showing infection percentage in the Czech Republic changing in time 
SELECT 
	Location, date, total_cases, population,
	CASE
		WHEN population = 0 THEN 0
		ELSE (total_cases/population)*100 
	END AS infected_percentage
FROM
	PortfolioProject..CovidDeaths
WHERE 
	location like '%czech%' AND
	continent is not null
ORDER BY 
	1,2

--Order countries by the highest infection count per population
SELECT 
	Location, population, MAX(total_cases) AS highest_infected_count,
	CASE
		WHEN population = 0 THEN 0 
		ELSE MAX(total_cases)/population * 100
	END AS infected_percentage
FROM 
	PortfolioProject..CovidDeaths
WHERE 
	continent is not null
GROUP BY 
	Location, population
ORDER BY 
	infected_percentage DESC

--Order countries by the total deaths count
SELECT 
	Location, MAX(total_deaths) AS highest_deaths_count
FROM 
	PortfolioProject..CovidDeaths
WHERE 
	continent is not null
GROUP BY 
	Location
ORDER BY 
	highest_deaths_count DESC


--Order countries by the highest deaths count per population
SELECT 
	Location, population, MAX(total_deaths) AS highest_deaths_count,
	CASE
		WHEN population = 0 THEN 0 
		ELSE MAX(total_deaths)/population * 100
	END AS deaths_percentage
FROM 
	PortfolioProject..CovidDeaths
WHERE 
	continent is not null
GROUP BY 
	Location, population
ORDER BY 
	deaths_percentage DESC

--Order continents by the total deaths count
SELECT 
	continent, MAX(total_deaths) AS highest_deaths_count
FROM 
	PortfolioProject..CovidDeaths
WHERE 
	continent is not null
GROUP BY 
	continent
ORDER BY 
	highest_deaths_count DESC

SELECT 
	location, MAX(total_deaths) AS highest_deaths_count
FROM 
	PortfolioProject..CovidDeaths
WHERE 
	continent is null
GROUP BY 
	location
ORDER BY 
	highest_deaths_count DESC


-- Global numbers
SELECT
	date, 
	SUM(new_cases) AS total_cases, 
	SUM(new_deaths) AS total_deaths,
	CASE 
		WHEN SUM(new_cases) = 0 THEN 0 
		ELSE SUM(new_deaths) / SUM(new_cases) * 100
	END  AS death_percentage
FROM
	PortfolioProject..CovidDeaths
WHERE 
	continent is not null
GROUP BY 
	date
HAVING
	SUM(new_cases) != 0
ORDER BY 
	date, total_cases


-- Looking at Total Psopulation vs Vaccination
-- Use CTE
WITH PopvsVac(continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE 
	dea.continent is not null
)
SELECT *, rolling_people_vaccinated/population*100 AS vaccinated_per_population
FROM
	PopvsVac


-- TEMP TABLE
DROP TABLE IF EXISTS #Percent_population_vaccinated
CREATE TABLE #Percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT INTO #Percent_population_vaccinated
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE 
	dea.continent is not null
ORDER BY 2,3

SELECT *, rolling_people_vaccinated/population*100 AS vaccinated_per_population
FROM
	#Percent_population_vaccinated

--Creating view for storing data for later visualizations
CREATE VIEW Percent_population_vaccinated AS
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE 
	dea.continent is not null

SELECT *
FROM Percent_population_vaccinated

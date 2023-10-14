-- Specifying the database
USE PortfolioProject;


select * 
from PortfolioProject..CovidDeaths
order by 3,4

--select * 
--from PortfolioProject..CovidVaccinations
--order by 3,4

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2

--- Looking at Total Cases Vs Total Deaths
ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN total_deaths float; -- Change the data type to FLOAT

ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN total_cases float; -- Change the data type to FLOAT


select location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 AS 'death_percentage'
from PortfolioProject..CovidDeaths
where location like '%Germany%'
order by 1,2

---Looking at Total Case vs Population

select location, date, total_cases, population, (total_cases/population)*100 as percent_population_infected
from PortfolioProject..CovidDeaths
--Where location = 'Germany'
order by 1,2

---Looking at countries with highest infection rate compared to population

select location,population, Max(total_cases) AS highest_infection_count, MAX(total_cases/population)*100 as cases_percentage
from PortfolioProject..CovidDeaths
--Where location = 'Germany'
group by location, population
order by location, population;

---Countries with highest Death count per population

select location, MAX(total_deaths) AS total_death_count
from PortfolioProject..CovidDeaths
where continent IS NOt NULL
Group by location
order by total_death_count DESC
	
---Breaking things down by continent

select continent, MAX(cast(total_deaths AS int)) AS total_death_count
from PortfolioProject..CovidDeaths
where continent IS NOt NULL
Group by continent
order by total_death_count DESC

---Continents with the highest death count per population

select continent, population, MAX(cast(total_deaths AS int)) AS total_death_count, MAX(total_deaths/population)*100 AS highest_death_percentage
from PortfolioProject..CovidDeaths
where continent IS Not NULL
Group by continent,population
order by highest_death_percentage DESC

---Gloabl Numbers

/* SELECT date,
       SUM(new_cases) AS toal_cases,
       SUM(new_deaths) AS total_deaths,
       CASE WHEN SUM(new_cases) = 0 THEN 0
            ELSE (SUM(new_deaths) / SUM(new_cases)) * 100
       END AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date; */


---Gloabl Numbers
SELECT 
	SUM(new_cases) as total_cases,
	SUM(CAST(new_deaths as INT)) as total_deaths,
	SUM(CAST(new_deaths as INT)) / SUM(new_cases) * 100 as deathpercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
 --GROUP BY date
 order by 1,2


---Joining the tables
select * 
from PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date =vac.date


---Looking at Population vs Vaccinations
select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations
, SUM(convert(bigint, vac.new_vaccinations)) OVER (partition by dea.location 
order by dea.location, dea.date) AS rolling_people_vaccinated
from PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date =vac.date
where dea.continent IS NOT NULL
order by 2,3


---USE CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
    SELECT dea.continent, dea.location, dea.date, dea.population, new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_people_vaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT * 
FROM PopvsVac
ORDER BY location, date;



---USE TEMP TABLE
DROP TABLE IF EXISTS #percentpopulationvaccinated
CREATE TABLE #percentpopulationvaccinated
(continent nvarchar(255), 
location nvarchar(255), 
date datetime, 
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)

INSERT INTO #percentpopulationvaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_people_vaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
    --WHERE dea.continent IS NOT NULL
	--order by 2,3

SELECT *, (rollingpeoplevaccinated/population)*100
FROM #percentpopulationvaccinated



--Craeting View to store data for later Visualisations

CREATE VIEW percentpopulationvaccinated as
	SELECT dea.continent, dea.location, dea.date, dea.population, new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location 
	ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3


--DROP VIEW IF EXISTS

IF OBJECT_ID('percentpopulationvaccinated', 'V') IS NOT NULL
BEGIN
    DROP VIEW percentpopulationvaccinated;
END



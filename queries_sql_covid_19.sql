/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types
*/
use covid_schemas ;
SELECT *
FROM covid_schemas.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 3,4;


-- Select Data that we are going to be starting with

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM covid_schemas.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM covid_schemas.CovidDeaths
WHERE location LIKE '%states%'
AND continent IS NOT NULL 
ORDER BY 1,2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT Location, date, Population, total_cases, (total_cases / population) * 100 AS PercentPopulationInfected
FROM covid_schemas.CovidDeaths
ORDER BY 1,2;


-- Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM covid_schemas.CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;


-- Countries with Highest Death Count per Population

SELECT Location, MAX(CAST(Total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM covid_schemas.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC;


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

SELECT continent, MAX(CAST(Total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM covid_schemas.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, 
       SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths, 
       (SUM(CAST(new_deaths AS UNSIGNED)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM covid_schemas.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM covid_schemas.CovidDeaths dea
JOIN covid_schemas.CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3;


-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM covid_schemas.CovidDeaths dea
    JOIN covid_schemas.CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL 
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PopvsVac;


-- Using Temporary Table to perform Calculation on Partition By in previous query

CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATETIME,
    Population DECIMAL(15,2),
    New_vaccinations DECIMAL(15,2),
    RollingPeopleVaccinated DECIMAL(15,2)
);

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM covid_schemas.CovidDeaths dea
JOIN covid_schemas.CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM covid_schemas.CovidDeaths dea
JOIN covid_schemas.CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

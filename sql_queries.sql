/*

*/

-- 1. 

SELECT SUM(new_cases) AS total_cases, 
       SUM(CAST(new_deaths AS SIGNED)) AS total_deaths, 
       (SUM(CAST(new_deaths AS SIGNED)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM covid_schemas.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

-- 2. 

SELECT location, SUM(CAST(new_deaths AS SIGNED)) AS TotalDeathCount
FROM covid_schemas.CovidDeaths
WHERE continent IS NULL 
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- 3. 

SELECT location, population, MAX(total_cases) AS HighestInfectionCount,  
       MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM covid_schemas.CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- 4. 

SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount,  
       MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM covid_schemas.CovidDeaths
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC;


-- 

WITH PopvsVac AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
    FROM covid_schemas.CovidDeaths dea
    JOIN covid_schemas.CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPeopleVaccinated
FROM PopvsVac;

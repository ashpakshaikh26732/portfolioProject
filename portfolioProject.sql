

/*
Covid 19 Data Exploration 

Skills used: Joins, CTEs, Temporary Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types

*/
use portfolioProject ;
-- Initial Data Query
SELECT *
FROM CovidDeaths1
WHERE continent IS NOT NULL 
ORDER BY 3, 4;


-- alter database portfolioProject modify name = PortfolioProject ; 

-- Select Data that we are going to be starting with
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths1
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths1
WHERE location LIKE '%states%'
AND continent IS NOT NULL 
ORDER BY 1, 2;

-- Total Cases vs Population
-- Shows what percentage of the population is infected with Covid
SELECT Location, date, Population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths1
ORDER BY 1, 2;

-- Countries with Highest Infection Rate compared to Population
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths1
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count per Population
SELECT Location, MAX(CAST(Total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM CovidDeaths1
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population
SELECT continent, MAX(CAST(Total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM CovidDeaths1
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths, 
       (SUM(CAST(new_deaths AS UNSIGNED))/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths1
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths1 dea
JOIN CovidVaccination2 vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2, 3;

-- Using CTE to perform Calculation on Partition By in the previous query
WITH PopvsVac AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM CovidDeaths1 dea
    JOIN CovidVaccination2 vac
    ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL 
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopulationVaccinated
FROM PopvsVac;

-- Using Temp Table to perform Calculation on Partition By in the previous query
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATE,
    Population DECIMAL(15, 2),
    New_vaccinations DECIMAL(15, 2),
    RollingPeopleVaccinated DECIMAL(15, 2)
);

-- Drop the table if it exists (handles both temporary and regular tables)
DROP TABLE IF EXISTS PercentPopulationVaccinated;

-- Create the temporary table
CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATE,
    Population DECIMAL(15, 2),
    New_vaccinations DECIMAL(15, 2),
    RollingPeopleVaccinated BIGINT
);

-- Insert data into the temporary table
INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location,STR_TO_DATE(dea.date, '%d/%m/%Y') AS date, dea.population, vac.new_vaccinations,
       SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths1 dea
JOIN CovidVaccination2 vac
ON dea.location = vac.location
AND STR_TO_DATE(dea.date, '%d/%m/%Y') = vac.date;

-- Query the temporary table
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths1 dea
JOIN CovidVaccination2 vac
ON dea.location = vac.locations
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

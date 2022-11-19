/*
 Covid 19 Data Exploration 
 Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
 */

SELECT * FROM covid_deaths WHERE continent IS NOT NULL ORDER BY 3, 4;

-- Selecting data

CREATE OR REPLACE VIEW working_data AS 
	Select
	    continent,
	    Location,
	    date,
	    total_cases,
	    new_cases,
	    total_deaths,
	    new_deaths,
	    population
	From covid_deaths
	Where continent is not null
	order by 1,
2; 

-- Shows likelihood of dying if you contract covid in your country

SELECT
    location,
    date,
    total_cases,
    total_deaths, (total_deaths / total_cases) * 100 as death_percentage
FROM working_data;

-- Shows what percentage of population infected with Covid

SELECT
    location,
    date,
    population,
    total_cases, (total_cases / population) * 100 AS percent_population_infected
FROM working_data;

-- Countries with Highest Infection Rate compared to Population

SELECT
    location,
    Population,
    MAX(total_cases) as HighestInfectionCount,
    Max(total_cases / population * 100) AS percent_population_infected
FROM working_data
GROUP BY Location, population
ORDER BY
    percent_population_infected DESC;

-- Countries with Highest Death Count per Population

SELECT
    location,
    MAX(total_deaths) as total_death_count
FROM working_data
GROUP BY location
ORDER BY
    total_death_count DESC;

-- Show contintents with the highest death count per population

SELECT
    continent,
    MAX(total_deaths) as total_death_count
FROM working_data
GROUP BY continent
ORDER BY
    total_death_count DESC;

-- Global numbers

SELECT
    SUM(new_cases) AS total_cases,
    SUM(new_deaths) as total_deaths,
    SUM(new_deaths) / SUM(new_cases) * 100 AS death_percentage
From working_data;

-- Total Population vs Vaccinations

-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(cv.new_vaccinations) OVER (
        PARTITION BY cd.location
        ORDER BY
            cd.location,
            cd.date
    ) AS rolling_people_vaccinated
FROM covid_deaths cd
    JOIN covid_vaccinations cv USING (location, date)
WHERE
    cd.continent IS NOT NULL
    AND cv.new_vaccinations IS NOT NULL
ORDER BY 1, 2, 3;

--USING Common Table Expressions (CTE)

WITH
    pop_vs_vac (
        continent,
        location,
        date,
        population,
        new_vaccinations,
        rolling_people_vaccinated
    ) AS (
        SELECT
            cd.continent,
            cd.location,
            cd.date,
            cd.population,
            cv.new_vaccinations,
            SUM(cv.new_vaccinations) OVER (
                PARTITION BY cd.location
                ORDER BY
                    cd.location,
                    cd.date
            ) AS rolling_people_vaccinated
        FROM covid_deaths cd
            JOIN covid_vaccinations cv USING (location, date)
        WHERE
            cd.continent IS NOT NULL
            AND cv.new_vaccinations IS NOT NULL
    )
SELECT
    *, (
        rolling_people_vaccinated / population
    ) * 100
From pop_vs_vac;

-- Create Temporary Table

DROP TABLE IF EXISTS _percent_population_vaccinated;

Create Table
    _percent_population_vaccinated (
        continent nvarchar(255),
        location nvarchar(255),
        date datetime,
        population numeric,
        new_vaccinations numeric,
        rolling_people_vaccinated numeric
    );

Insert into
    _percent_population_vaccinated
SELECT
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(cv.new_vaccinations) OVER (
        PARTITION BY cd.location
        ORDER BY
            cd.location,
            cd.date
    ) AS rolling_people_vaccinated
FROM covid_deaths cd
    JOIN covid_vaccinations cv USING (location, date)
WHERE
    cd.continent IS NOT NULL
    AND cv.new_vaccinations IS NOT NULL;

Select
    *, (
        rolling_people_vaccinated / population
    ) * 100
From
    _percent_population_vaccinated;

-- Creating View to store data for later visualizations

CREATE OR REPLACE VIEW percent_population_vaccinated 
AS 
	SELECT
	    cd.continent,
	    cd.location,
	    cd.date,
	    cd.population,
	    cv.new_vaccinations,
	    SUM(cv.new_vaccinations) OVER (
	        PARTITION BY cd.location
	        ORDER BY
	            cd.location,
	            cd.date
	    ) AS rolling_people_vaccinated
	FROM covid_deaths cd
	    JOIN covid_vaccinations cv USING (location, date)
	WHERE
	    cd.continent IS NOT NULL
	    AND cv.new_vaccinations IS NOT NULL
; 
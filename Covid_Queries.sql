--Covid Data collected from https://ourworldindata.org/covid-deaths
--Data collected from (2020-01-01 to 2022-10-31)

--Order by Date 
SELECT * FROM Covid_Deaths 
ORDER BY date ASC
SELECT * FROM Covid_Tests_Vac
ORDER BY date ASC

--Continent wise Death count-1
SELECT Continent,max(cast(total_deaths as bigint)) AS TotalDeathCount
FROM Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY continent asc

--Total population
SELECT continent, SUM(cast(population as bigint)) AS TotalPopulation 
FROM Covid_Deaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY continent asc



--Death Percentage when considering New Cases -2
SELECT  SUM(new_cases) as Total_Cases, SUM(CAST(new_deaths AS int)) AS total_deaths,
SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM Covid_Deaths
WHERE Continent  is not null
--GROUP BY date
ORDER BY 1,2

-- Total ICU_patients by Location (Global number) -- 3
SELECT Location,COUNT(icu_patients) AS Total_ICU_Patients
FROM Covid_Deaths
WHERE icu_patients IS NOT NULL
GROUP BY location
ORDER BY 1,2

-- No patients reported to be in ICU
SELECT Location,COUNT(icu_patients) AS Total_ICU_Patients
FROM Covid_Deaths
WHERE icu_patients IS  NULL
GROUP BY location
ORDER BY 1,2


--Global numbers: Total icu_patients vs total cases and finding the percentage of ICU_Patients globally -- 4
SELECT  SUM(CAST(icu_patients as bigint)) as Total_icu_patients, SUM(CAST(total_cases AS bigint)) AS TotalCases,
SUM(cast(icu_patients as int))/ SUM(total_cases)*100 as ICUPatientsPercentage
FROM Covid_Deaths
WHERE Continent is not null

-- Global numbers to show Total_cases between '10/31/2021' and  '10/31/2022' -- 5
SELECT date, SUM(CAST(total_cases AS bigint)) AS Global_Total_Cases
FROM Covid_Deaths
WHERE date between '10/31/2021' and  '10/31/2022'
GROUP BY date
ORDER BY date

-- Total population that was fully vaccinated! --6
SELECT a.continent, SUM(CAST(b.people_fully_vaccinated AS bigint)) AS Population_Vaccinated
FROM Covid_Deaths a
JOIN Covid_Tests_Vac b
ON a.iso_code = b.iso_code
WHERE people_fully_vaccinated IS NOT NULL AND a.continent IS NOT NULL
GROUP BY a.continent

--Life Expectancy (Output: Not much change in the life expectancy) --7
SELECT continent,AVG(life_expectancy) as Avg_life_expectancy
FROM Covid_Tests_Vac
WHERE date BETWEEN '2020-01-01' AND '2022-10-31'
GROUP BY continent
ORDER BY 1,2

SELECT continent,AVG(life_expectancy)
FROM Covid_Tests_Vac
WHERE date BETWEEN '2021-01-01' AND '2022-10-31'
GROUP BY continent
ORDER BY 1,2

-- People who are fully vaccinated and also taken booster shots--8
SELECT a.continent, b.people_fully_vaccinated, b.total_boosters
FROM Covid_Tests_Vac b
JOIN Covid_Deaths a
ON a.iso_code = b.iso_code
WHERE people_fully_vaccinated IS NOT NULL AND total_boosters IS NOT NULL AND a.continent IS NOT NULL

-- People who are fully vaccinated and also taken booster shots--8  (Optimized query)
SELECT continent, sum( cast(b.total_boosters as bigint)) AS population_taken_booster -- 8
FROM Covid_Tests_Vac b
--JOIN Covid_Deaths a
--ON a.iso_code = b.iso_code
WHERE total_boosters IS NOT NULL AND continent IS NOT NULL
GROUP BY continent


--Global numbers
WITH CTEReports AS (SELECT continent, SUM(CAST(people_fully_vaccinated AS BIGINT)) AS Total_Vaccinated
FROM Covid_Tests_Vac 
GROUP BY continent)
SELECT b.continent, b.people_fully_vaccinated, b.total_boosters, c.Total_Vaccinated AS CTEReports
FROM Covid_Tests_Vac b
JOIN CTEReports c
ON b.continent = c.continent
WHERE people_fully_vaccinated IS NOT NULL AND total_boosters IS NOT NULL AND b.continent IS NOT NULL

--Showing the percentage of the population that have had Vaccines--9 (Using CTE)
WITH CTEReports (continent, location, date , population,new_vaccinations,PeopleGettingVaccinated )
AS 
(
SELECT a.continent, a.location, a.date, a.population, b.new_vaccinations, 
SUM(CONVERT(bigint, b.new_vaccinations)) OVER (PARTITION by a.location ORDER BY a.location,a.date) as PeopleGettingVaccinated
FROM Covid_Deaths a
JOIN Covid_Tests_Vac b
ON a.location = b.location
AND a.date = b.date
WHERE a.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (PeopleGettingVaccinated/population)* 100 AS TotalPercentageVac FROM CTEReports
--

--Continents that had handwashing facilities --9a 
SELECT  continent, count(handwashing_facilities) as HandWashFacilities
FROM Covid_Tests_Vac
WHERE continent IS NOT NULL
GROUP BY continent

--locations that doesnot have handwash facilities
SELECT location, handwashing_facilities AS  No_handwash_Facitilites
FROM Covid_Tests_Vac
WHERE handwashing_facilities IS  NULL

--Creating and Using Temp Table for Percentage of population Vaccinated
DROP Table if exists PercentPopulationVaccinated
Create Table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
PeopleGettingVaccinated numeric
)

Insert into PercentPopulationVaccinated
SELECT a.continent, a.location, a.date, a.population, b.new_vaccinations, 
SUM(CONVERT(bigint, b.new_vaccinations)) OVER (PARTITION by a.location ORDER BY a.location,a.date) as PeopleGettingVaccinated
FROM Covid_Deaths a
JOIN Covid_Tests_Vac b
ON a.location = b.location
AND a.date = b.date
--WHERE a.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (PeopleGettingVaccinated/population)* 100 
From PercentPopulationVaccinated


-- Creating Views for later visualization
create view people_fully_vaccinated as
SELECT a.continent, SUM(CAST(b.people_fully_vaccinated AS bigint)) AS Population_Vaccinated
FROM Covid_Deaths a
JOIN Covid_Tests_Vac b
ON a.iso_code = b.iso_code
WHERE people_fully_vaccinated IS NOT NULL AND a.continent IS NOT NULL
GROUP BY a.continent













# UltimateDashboard
Dashboard project which is intended to provide an operations and security dashboard which conveys important information concisely and enables quick responses on monitored systems.

# Technologies
* Universal Dashboard
Universal Dashboard is a module made by Adam Driscoll which allows for the easy creation of webpages using PowerShell. The technology defines simple powershell functions which represent ASP.NET Core, .NET Core, and React objects. More information can be found here, I highly recommend exploring and supporting this awesome technology! https://universaldashboard.io/ 

# Prerequisites
* Required

PowerShell 5.1 or greater or PowerShell Core 6.1 or greater

.NET Framework 4.7.2

* Optional

Git

# Starting the Dashboard
From a PowerShell Prompt:
1) Install Universal Dashboard
`Install-Module -Name UniversalDashboard -AcceptLicense -Confirm`
2) Clone our code
`git clone https://github.com/theabraxas/UltimateDashboard`
3) Navigate to the dashboards
`cd UltimateDashboard`
4) Launch Dashboard
`./Dashboard.ps1`

# Architecture and Function
This project is based on a web server which leverages both a database and live calls to various datasources to produce visualizations, tables, health checks, and interactive capabilities. 

The database is populated both by the activites performed in the web interface as well as through a series of data collection scripts which can be set as cron jobs or schedule tasks. 

These collecters are located included in the scheduled_jobs folder, a separate README will be provided in that folder to describe configurations and recommended ways to implement.

A SQL Express server is used in the documentation here although a full SQL server can be leveraged if available. The server will store various data depending on what is enabled in the dashboard. These will allow for longer-term analysis of the environment's health.

The webserver is, as mentioned previously, utilizing PowerShell UniversalDashboard and requires no additional services or technologies to be running in order to run. It can only run on Windows systems and binds to a port specified in dashboard.ps1

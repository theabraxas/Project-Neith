# Project Neith
*THIS PROJECT IS STILL IN AN ALPHA STATE AND SHOULLD NOT BE USED IN PRODUCTION ENVIRONMENTS.*

Neith was an early Egyptian deity said to be the first god and creator of the universe. It is also said she controlled and knew all that was within it. The scope of this dashboard is to give visibility and control to any desired remotely connectable systems.

Project Neith aspires to be an easily extensible dashboard which allows for the monitoring and control of virtually any remotely accessible technology. It's primary target for its initial release is to hook in to common infrastructure and security tooling which exists in most enterprises. These include systems such as Active Directory, VMware, antivirus, backup, endpoints, and more. 

Project Neith has a simple workflow where integrations are selected from a list of available modules, once activated they create the appropriate database tables and scheduled tasks to retreive data if required, the pages associated with each integration are then added to the website navigation menus. Additionally, because of it's highly modular design, it is often a matter of tweaking a single file or two in order to add new visualizations, or change how the various pages look.

This project is in very very early stages, please feel free to comment, open issues, and make any suggestions. I do not come from a software background so this is all new territory for me and I know there are many aspects of the programs design which can be improved. (encrypted tables for credentials/keys, breaking up the dbconfig.ps1 file, etc.)

# Technologies
* Universal Dashboard
Universal Dashboard is a module made by Adam Driscoll which allows for the easy creation of webpages using PowerShell. More information can be found [here](https://universaldashboard.io "Universal Dashboard"), I highly recommend checking out this awesome project!

* SQL Server Express (Postgres and others to come later!)
SQL Server Express is used to store the results of the various integrations and data-pulls performed from the different integrations. Some integrations require no use of the database but many do.


# Prerequisites
Required
* PowerShell 5.1 or greater or PowerShell Core 6.1 or greater
* .NET Framework 4.7.2 (for Powershell -> https://dotnet.microsoft.com/download/thank-you/net472) 
* SQL Server Express 2017

Optional
* Git
* PowerCLI - `Install-Module -Name VMware.PowerCLI`
* SQL PowerShell Cmdlets - `Import-Module -Name SQLPS`


# Tips to Contribute!
Within the `pages` directory new integration folders are created. Each folder should have a couple files, a README explaining the ingegration, a ps1 file for the pages which will be made avaialble in the webserver, an optional file to create the database tables required. A `scheduled_tasks` file should be provided if periodic data collections are required or needed for the technology. 

# Starting the Dashboard
From a PowerShell Prompt:
1) Install Universal Dashboard
`Install-Module -Name UniversalDashboard -AcceptLicense -Confirm`
2) Clone the code
`git clone https://github.com/theabraxas/UltimateDashboard`
3) Prepare the database
Run the `./dbconfig.ps1` script
4) Launch Dashboard
`./main.ps1`

# Some Screenshots
Menu with a few integrations enabled:

![Menu based on enabled integrations](https://raw.githubusercontent.com/theabraxas/project-neith/master/images/menu.png)

Integration selection menu:

![List of available integrations, leads to config page](https://raw.githubusercontent.com/theabraxas/project-neith/master/images/templates.png)

AD Summary Information Page:

![High level information plus the ability to investigate users and computers](https://raw.githubusercontent.com/theabraxas/project-neith/master/images/AD_Summary.png)

AD Computer Information:

![Result of connecting to a computer from the previous image](https://raw.githubusercontent.com/theabraxas/project-neith/master/images/AD_Computer_Data.png)

AD Computer Live Information:

![Live Data view from the previous image](https://raw.githubusercontent.com/theabraxas/project-neith/master/images/AD_Computer_Detail_Data.png)

AD User Summary Page:

![User Info](https://raw.githubusercontent.com/theabraxas/project-neith/master/images/AD_User_Summary.png)

Cylance Information:

![User Info](https://raw.githubusercontent.com/theabraxas/project-neith/master/images/Cylance_Overview.png)

VMware Information:

![User Info](https://raw.githubusercontent.com/theabraxas/project-neith/master/images/VMware_Overview.png)

# Architecture and Function
This project is based on a web server which leverages both a database and live calls to various datasources to produce visualizations, tables, health checks, and interactive capabilities. 

The database is populated both by the activites performed in the web interface as well as through a series of data collection scripts which can be set as cron jobs or schedule tasks. 

These collecters are located included in the scheduled_jobs folder, a separate README will be provided in that folder to describe configurations and recommended ways to implement.

A SQL Express server is used in the documentation here although a full SQL server can be leveraged if available. The server will store various data depending on what is enabled in the dashboard. These will allow for longer-term analysis of the environment's health.

The webserver is, as mentioned previously, utilizing PowerShell UniversalDashboard and requires no additional services or technologies to be running in order to run. It can only run on Windows systems and binds to a port specified in dashboard.ps1

# Setting Up SQL Server Express 2017
* Download from https://www.microsoft.com/en-us/sql-server/sql-server-editions-express
* Select Default Installation Options
* Use Windows authentication
* It is recommended to also install SQL Server Management Studio as well: https://go.microsoft.com/fwlink/?linkid=2043154

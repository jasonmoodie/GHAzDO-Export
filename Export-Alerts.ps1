# Export all Advanced Security alerts for all repositories in an Azure DevOps organization using Azure CLI authentication
# Use AZ Login to authenticate with Azure CLI before running this script

$organization = "jm-demo"  # Just the org name, not the full URL
$orgUrl = "https://dev.azure.com/$organization"
$advSecUrl = "https://advsec.dev.azure.com/$organization"
$outputCsv = "All-ADO-Alerts.csv"

# Toggle verbose output (set to $false to suppress Write-Host messages)
$VerboseOutput = $true

try {
    # Get Azure CLI token for Azure DevOps
    $tokenResponse = az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" | ConvertFrom-Json
    $token = $tokenResponse.accessToken

    # Set Authorization header
    $headers = @{
        'Authorization' = "Bearer $token"
        'Content-Type'  = 'application/json'
    }

    # Retrieve all projects
    if ($VerboseOutput) { Write-Host "Retrieving all projects..." -ForegroundColor Cyan }
    $projectsResponse = Invoke-RestMethod -Uri "$orgUrl/_apis/projects?api-version=6.0" -Headers $headers -Method Get
    $projects = $projectsResponse.value

    if ($VerboseOutput) { Write-Host "Found $($projects.Count) projects." -ForegroundColor Green }

    # Prepare array to store all alerts
    $allAlerts = @()

    foreach ($project in $projects) {
        if ($VerboseOutput) { Write-Host "`nProject: $($project.name)" -ForegroundColor Yellow }

        # Retrieve repositories for each project
        $reposUri = "$orgUrl/$($project.name)/_apis/git/repositories?api-version=6.0"
        $reposResponse = Invoke-RestMethod -Uri $reposUri -Headers $headers -Method Get
        $repos = $reposResponse.value

        if ($repos.Count -gt 0) {
            if ($VerboseOutput) { Write-Host "  Repositories ($($repos.Count)):" -ForegroundColor Green }

             foreach ($repo in $repos) {
                if ($VerboseOutput) { Write-Host "    Checking alerts for repo: $($repo.name)" -ForegroundColor Cyan }
            
                $alerts = @()
                $continuationToken = $null
                # $page = 1
            
                do {
                    $alertsUri = "$advSecUrl/$($project.name)/_apis/alert/repositories/$($repo.id)/alerts?api-version=7.2-preview.1&top=10000"
                    if ($continuationToken) {
                        $alertsUri += "&continuationToken=$continuationToken"
                    }
            
                    if ($VerboseOutput) { Write-Host "        Fetching..." -ForegroundColor DarkCyan }
                    try {
                        $alertsResponse = Invoke-RestMethod -Uri $alertsUri -Headers $headers -Method Get
                        $alerts += $alertsResponse.value
            
                        # Check explicitly for continuationToken
                        if ($alertsResponse.PSObject.Properties["continuationToken"]) {
                            $continuationToken = $alertsResponse.continuationToken
                            $alertsUri = "$advSecUrl/$($project.name)/_apis/alert/repositories/$($repo.id)/alerts?api-version=7.2-preview.1&continuationToken=$continuationToken"
                            if ($VerboseOutput) { Write-Host "      Continuation token found, fetching next page..." -ForegroundColor DarkGray }
                        }
                        else {
                            $continuationToken = $null
                        }
                    }
                    catch {
                        if ($VerboseOutput) { Write-Host "      No alerts or access denied for repo: $($repo.name)" -ForegroundColor DarkYellow }
                        break
                    }
            
                    $page++
                } while ($continuationToken)
            
                if ($VerboseOutput) { Write-Host "      Found: $($alerts.Count) alerts total." -ForegroundColor Green }
            
                  foreach ($alert in $alerts) {
                    $alertInfo = [PSCustomObject]@{
                        ProjectName     = $project.name
                        RepositoryName  = $repo.name
                        RepositoryId    = $repo.id
                        AlertId         = $alert.alertId
                      # AlertNumber     = $alert.alertNumber
                        Title           = $alert.title
                        Severity        = $alert.severity
                        State           = $alert.state
                        Tool            = $alert.tools.name
                        FirstDetectionDate = $alert.firstSeenDate
                        LastDetectionDate = $alert.lastSeenDate
                        IntroductionDate = $alert.introducedDate                   
                    }
                
                    # Add the alert info to the collection
                    $allAlerts += $alertInfo
                }
                
                # if ($VerboseOutput) { Write-Host "      Found: $($alerts.Count) alerts total." -ForegroundColor Green }
            }
        }
        else {
            if ($VerboseOutput) { Write-Host "  No repositories found." -ForegroundColor DarkYellow }
        }
    }

    # Export to CSV
    $allAlerts | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8

    if ($VerboseOutput) {
        Write-Host "`nExport completed successfully!" -ForegroundColor Green
        Write-Host "Output file: $outputCsv" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
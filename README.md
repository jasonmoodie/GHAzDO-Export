# Export-Alerts.ps1

This PowerShell script exports all Advanced Security alerts for all repositories in an Azure DevOps organization. It uses Azure CLI authentication to retrieve an access token and then queries the Azure DevOps REST API to collect security alerts from every repository in every project within the specified organization. The results are saved to a CSV file (`All-ADO-Alerts.csv`).

## Features
- Authenticates using Azure CLI (`az login` required beforehand)
- Retrieves all projects and repositories in the organization
- Collects all Advanced Security alerts for each repository
- Handles paginated results using continuation tokens
- Exports the collected alert data to a CSV file

## Usage
1. Ensure you are logged in to Azure CLI: `az login`
2. Update the `$organization` variable in the script to your Azure DevOps organization name.
3. Run the script in PowerShell:
   ```powershell
   .\Export-Alerts.ps1
   ```
4. The output will be saved as `All-ADO-Alerts.csv` in the current directory.

## Requirements
- Azure CLI installed and authenticated
- Sufficient permissions to access Azure DevOps REST APIs and Advanced Security alerts

## Output
- `All-ADO-Alerts.csv`: Contains details of all security alerts, including project, repository, alert ID, title, severity, state, tool, and detection dates.

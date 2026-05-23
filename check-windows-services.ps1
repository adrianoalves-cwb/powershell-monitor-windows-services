
$configPath = "$PSScriptRoot\appsettings.json"
$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json

# Credentials
$tenantId     = $config.Credentials.TenantId
$clientId     = $config.Credentials.ClientId
$clientSecret = $config.Credentials.ClientSecret

# Email settings
$fromEmailAddress = $config.EmailSettings.FromEmailAddress
$toEmailAddress   = $config.EmailSettings.ToEmailAddress
$modulePath       = $config.EmailSettings.EmailModulePath

#Servers
$prodServer = $config.Servers.Prod

# Proxy
$proxy       = $config.ProxySettings.Proxy

# Logging
$serviceLogsPath = $config.LoggingSettings.ServiceLogsPath
$scriptLogsPath  = $config.LoggingSettings.ScriptLogsPath

# Configuration
$textPattern               = $config.ConfigurationSettings.TextPattern
$scriptRunIntervalSeconds  = [int]$config.ConfigurationSettings.ScriptRunIntervalSeconds

# Environment
$serverName = $env:COMPUTERNAME
if ($serverName -eq $prodServer){
    $environment = "PROD"
}else{
    $environment = "QA"
}

# WindowsServiceList
$windowsServiceList = $config.WindowsServiceList

Import-Module $modulePath -Force

if (-not (Test-Path -LiteralPath $scriptLogsPath)) {
    New-Item -ItemType Directory -Path $scriptLogsPath | Out-Null
}

function Write-ActionLog {
  param(
    [Parameter(Mandatory = $true)]
    [string]$message
  )

  $line = "{0} {1} " -f (Get-Date -Format "yyyy-MM-dd'T'HH:mm:sszzz"), $message
  Add-Content -Path $scriptLogsFullPath -Value $line
}


while ($true) {
  foreach ($serviceName in $windowsServiceList) 
  {
    #Getting the MyApp service windows service log full path
    $serviceLogFullPath = Join-Path $serviceLogsPath ("{0}.log" -f $serviceName)

    #Getting the script log name with path
    $scriptLogsFullPath = Join-Path $scriptLogsPath ("{0}_{1}.log" -f $serviceName, (Get-Date -Format 'yyyyMMdd'))

    #If the script log does not exist, it eates
    if (!(Test-Path -LiteralPath $scriptLogsFullPath)) {
      Write-Host "Creating the file: $scriptLogsFullPath"
      New-Item -ItemType File -Path $scriptLogsFullPath | Out-Null
    }

    #Confirm if the MyApp service windows service log exist
    Write-Host "Checking serviceName: " $serviceName
    if (-not (Test-Path -LiteralPath $serviceLogFullPath)) { continue }

    try {
      $lastLine = Get-Content -LiteralPath $serviceLogFullPath -Tail 2 -ErrorAction Stop
      if ($lastLine -match [regex]::Escape($textPattern)) {

        Write-ActionLog ("Error Pattern Found: {0}" -f $textPattern)

        $subject = ("MyApp {0} | Service Restarted | $textPattern | {1}" -f $environment, $serviceName)

        # Get last 10 lines from the MyApp Windows Service log
        $lines = Get-Content -LiteralPath $serviceLogFullPath -Tail 10 -ReadCount 1

        $sb = New-Object System.Text.StringBuilder

        foreach($line in $lines){
        $null = $sb.Append([System.Net.WebUtility]::HtmlEncode($line.TrimEnd("`r","`n")))
        $null = $sb.Append("<br>`r`n")
        }

        $body = $sb.ToString()

        # Send email
        try {

        Send-GraphMail -TenantId $tenantId -ClientId $clientId -ClientSecret $clientSecret -FromEmailAddress $fromEmailAddress -ToEmailAddress $toEmailAddress -Subject $subject -BodyContent $body -Proxy $proxy
        Write-ActionLog "Email sent to $toEmailAddress."
        }
        catch {

        Write-ActionLog ("Send Email FAILED: {0}" -f $_.Exception.Message)
        throw
        }

        # Restarting the Windows service
        try {
            
        Write-Host "Restarting the service: $serviceName"
        Write-ActionLog "Restarting the service: $serviceName"

        Restart-Service -Name $serviceName -Force -ErrorAction Stop

        Write-ActionLog "Windows Service restarted."
        Write-Host  "Windows Service restarted."
        }
        catch {

        Write-Error ("Service restart FAILED: {0}" -f $_.Exception.Message)
        }

      }
      #else{
        #Write-ActionLog "Heartbeat."
      #}

    }
    catch {
      continue
    }
  }

  Write-Host "Waiting $scriptRunIntervalSeconds seconds..."
  Start-Sleep -Seconds $scriptRunIntervalSeconds
}
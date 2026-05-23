# Windows Services Monitoring and Auto-Restart

## Overview

This project monitors Windows Service log files for a specific error pattern. When the configured pattern is detected, the script:

1. Sends an email notification using Microsoft Graph API
2. Restarts the affected Windows Service
3. Writes execution logs for auditing and troubleshooting

The solution is implemented in PowerShell and is designed to run continuously in the background.

---

# Project Structure

```text
.
├── check-windows-services.ps1          # Main monitoring script
├── appsettings.json                    # Configuration file
└── send-email-microsoft-graph-proxy.psm1 # Microsoft Graph email module
```

---

# Components

## check-windows-services.ps1

Main script responsible for:

- Loading configuration from `appsettings.json`
- Monitoring Windows Service log files
- Detecting configured error patterns
- Sending email alerts
- Restarting Windows Services automatically
- Writing script execution logs
- Running continuously with a configurable interval

### Main Workflow

```text
Load configuration
        ↓
Monitor configured service logs
        ↓
Check latest log lines for error pattern
        ↓
If pattern found:
    ├── Send email notification
    └── Restart Windows Service
        ↓
Wait configured interval
        ↓
Repeat forever
```

---

## send-email-microsoft-graph-proxy.psm1

Reusable PowerShell module responsible for sending emails through Microsoft Graph API.

### Features

- OAuth2 Client Credentials authentication
- Microsoft Graph API integration
- HTML email support
- Proxy support
- Strict PowerShell validation
- Error handling with `-ErrorAction Stop`

### Exported Function

```powershell
Send-GraphMail
```

### Authentication Flow

The module authenticates against Azure AD using:

- Tenant ID
- Client ID
- Client Secret

Then obtains an OAuth2 access token and sends email using:

```text
https://graph.microsoft.com/v1.0/users/{from-email}/sendMail
```

---

## appsettings.json

Centralized configuration file used by the monitoring script.

### Example Configuration

```json
{
  "Credentials": {
    "TenantId": "",
    "ClientId": "",
    "ClientSecret": ""
  },
  "EmailSettings": {
    "FromEmailAddress": "",
    "ToEmailAddress": "",
    "EmailModulePath": ""
  },
  "ProxySettings": {
    "Proxy": ""
  },
  "Servers": {
    "Prod": ""
  },
  "LoggingSettings": {
    "ServiceLogsPath": "",
    "ScriptLogsPath": ""
  },
  "ConfigurationSettings": {
    "TextPattern": "Connection to queue manager lost",
    "ScriptRunIntervalSeconds": 300
  },
  "WindowsServiceList": [
    "my-windows-service-01",
    "my-windows-service-02"
  ]
}
```

---

# Configuration Reference

## Credentials

Azure AD Application credentials used to authenticate against Microsoft Graph.

| Setting | Description |
|---|---|
| `TenantId` | Azure AD tenant ID |
| `ClientId` | Azure AD application client ID |
| `ClientSecret` | Azure AD application secret |

---

## EmailSettings

Email configuration used when sending alerts.

| Setting | Description |
|---|---|
| `FromEmailAddress` | Sender email address |
| `ToEmailAddress` | Recipient email address |
| `EmailModulePath` | Full path to `send-email-microsoft-graph-proxy.psm1` |

---

## ProxySettings

| Setting | Description |
|---|---|
| `Proxy` | HTTP/HTTPS proxy used for outbound requests |

Example:

```text
http://proxy.company.local:8080
```

---

## Servers

| Setting | Description |
|---|---|
| `Prod` | Production server hostname |

The script automatically determines whether the current environment is:

- `PROD`
- `QA`

based on the current hostname.

---

## LoggingSettings

| Setting | Description |
|---|---|
| `ServiceLogsPath` | Directory containing Windows Service log files |
| `ScriptLogsPath` | Directory where monitoring logs will be written |

---

## ConfigurationSettings

| Setting | Description |
|---|---|
| `TextPattern` | Error pattern to search in service logs |
| `ScriptRunIntervalSeconds` | Delay between monitoring cycles |

---

## WindowsServiceList

Array containing the Windows Services to monitor.

Example:

```json
"WindowsServiceList": [
  "service-a",
  "service-b",
  "service-c"
]
```

---

# Log File Behavior

The script expects each monitored service to have a corresponding log file.

Example:

```text
<ServiceLogsPath>\my-windows-service-01.log
```

The monitoring script:

- Reads the latest log entries
- Checks for the configured error pattern
- Captures the last 10 log lines in the notification email

---

# Email Notification

When an error pattern is detected:

- The last 10 log lines are included in the email body
- Content is HTML encoded
- Subject includes:
  - Environment
  - Service name
  - Error pattern

Example subject:

```text
MyApp PROD | Service Restarted | Connection to queue manager lost | my-windows-service-01
```

---

# Automatic Service Restart

After sending the email notification, the script attempts to restart the affected Windows Service using:

```powershell
Restart-Service -Name <service-name> -Force
```

Restart actions are logged to the script log file.

---

# Script Logs

The monitoring script writes operational logs into daily log files.

Example:

```text
<ScriptLogsPath>\my-windows-service-01_20260522.log
```

Logged actions include:

- Error pattern detection
- Email delivery
- Service restart attempts
- Failures and exceptions

---

# Requirements

## PowerShell

Recommended:

- Windows PowerShell 5.1+
- PowerShell 7+

---

## Permissions

The execution account must have permission to:

- Read service log files
- Restart Windows Services
- Access Microsoft Graph API
- Access proxy server (if applicable)

---

## Azure AD Application Permissions

The Azure AD application requires Microsoft Graph Mail permissions.

Recommended permission:

```text
Mail.Send
```

Application permissions must be granted and admin consent approved.

---

# Running the Script

## Execute Manually

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\check-windows-services.ps1
```

---

## Run as Scheduled Task

Recommended for production environments.

Suggested settings:

- Run whether user is logged on or not
- Restart on failure
- Run with highest privileges
- Trigger at startup

---

# Error Handling

The solution includes:

- Try/catch blocks
- Email send failure handling
- Service restart failure handling
- Safe log monitoring
- Graceful continuation on errors

---

# Security Recommendations

## Protect Secrets

Avoid storing secrets in plain text when possible.

Recommended approaches:

- Windows Credential Manager
- Azure Key Vault
- Environment variables
- Encrypted secure files

---

## Restrict Access

Limit access to:

- `appsettings.json`
- Log directories
- Service accounts
- Azure AD credentials

---

# Example Use Cases

This solution is useful for:

- Middleware monitoring
- MQ connectivity monitoring
- Legacy Windows Service environments
- Automatic recovery scenarios
- Operational alerting

---

# Future Improvements

Possible enhancements:

- Multiple email recipients
- Teams/Slack integration
- Structured JSON logging
- Windows Event Log integration
- Service health dashboards
- Retry logic for email delivery
- Configuration validation
- Parallel monitoring
- Duplicate alert suppression

---

# License

Internal/private project.


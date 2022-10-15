### POWERSHELL ON WINDOWS ###


# 1. Install the App on your BC
# 2. Make sure the required printers are installed and working on your PC
# 3. Download PDF-XChange Viewer Portable on your PC: https://portableapps.com/apps/office/pdf-xchange-portable
# 4. Modify the Configuration part of this script
# 5. Run it
# 6. Open BC, go to the PIPrint page. Disable printers you don't need in BC
# 7. The printers are now available for direct print in BC


### Configuration ###
# Authentication:
$Authentication = @{
    "Company"                     = 'CRONUS Danmark A/S' # Note: Must exist or be left empty if a Default Company is setup in the Service Tier. Only used for authentication as printers and jobs are PerCompany=false

    "BasicAuthLogin"              = 'Support'
    "BasicAuthPassword"           = 'Support7913!'

    "OAuth2CustomerAADIDOrDomain" = '1234'
    "OAuth2ClientID"              = '1234'
    "OAuth2ClientSecret"          = '1234'
}
#

# URLs for webservices:
$BaseURL    = "https://<hostname>/<instance>/ODataV4/"
$PrintersWS = "PIPrintPrinterWS"
$QueuesWS   = "PIPrintQueueWS"

# Misc.:
$IgnorePrinters = @("OneNote for Windows 10","Microsoft XPS Document Writer","Microsoft Print to PDF","Fax") # Don't offer these printers to Business Central
$PDFXCview_exe  = "<path to PDFXCview.exe>" # 
$Delay          = 5 # Delay between checking for print jobs in seconds
$UpdateDelay    = 300 # Delay between updating printers in seconds

### End of Configuration ###

#########################################################################################################
### YOU ARE NOT SUPPOSED TO CHANGE ANYTHING BEYOND THIS POINT UNLESS YOU WANT TO MODIFY FUNCTIONALITY ###
#########################################################################################################

function Get-BasicAuthentication
{
    param (
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [String]$Login,
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [String]$Password
    )
    PROCESS
    { 
        return [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$Login`:$Password"))
    }
}

function Get-OAuth2AccessToken
{
    param (
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [String]$ClientID,
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [String]$ClientSecret,
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [String]$CustomerAAD_ID_Or_Domain
    )
    PROCESS
    { 
        Add-Type -AssemblyName System.Web
        $Body = "client_id=" + [System.Web.HttpUtility]::UrlEncode($ClientID) + "&client_secret=" + [System.Web.HttpUtility]::UrlEncode($ClientSecret) +
                "&scope=https://api.businesscentral.dynamics.com/.default&grant_type=client_credentials"
        Try {
            $Json = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$CustomerAAD_ID_Or_Domain/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $Body 
        }
        Catch {
            $Reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $Reader.BaseStream.Position = 0
            $Reader.DiscardBufferedData()
            Write-Host ($Reader.ReadToEnd() | ConvertFrom-Json).error.message -ForegroundColor Red
        }

        return $Json.access_token
    }
}

function Call-BCWebService
{
    param (
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [String]$Method,
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [String]$BaseURL,
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [String]$WebServiceName,
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
            [String]$DirectLookup,
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
            [String]$Filter,
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
            [String]$ETag,
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [Object]$Authentication,
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
            [String]$Body,
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
            [switch]$GetParametersOnly
    )
    PROCESS
    { 
        $URL = $BaseURL.trimend("/")

        $Headers = @{"Accept" = "application/json"}
        if(($Authentication.BasicAuthLogin -ne "") -and ($Authentication.BasicAuthPassword -ne "")) {
            $Headers.Add("Authorization","Basic $(Get-BasicAuthentication -Login $Authentication.BasicAuthLogin -Password $Authentication.BasicAuthPassword)")
        }
        else {
            $Headers.Add("Authorization","Bearer $(Get-OAuth2AccessToken -ClientID $Authentication.OAuth2ClientID -ClientSecret $Authentication.OAuth2ClientSecret `
                                                                         -CustomerAAD_ID_Or_Domain $Authentication.OAuth2CustomerAADIDOrDomain)")
        }

        if($Method -eq "Get") {
            $Headers.Add("Data-Access-Intent","ReadOnly")
        }

        if(-not [string]::IsNullOrEmpty($Body)) {
            $Headers.Add("Content-Type","application/json")
        }
        
        if(-not [string]::IsNullOrEmpty($ETag)) {
            $Headers.Add("If-Match",$ETag)
        }
        
        if(-not ([string]::IsNullOrEmpty($Authentication.Company))) {
            $URL = "$URL/Company('$($Authentication.Company)')"
        }

        $URL = "$URL/$WebServiceName"

        if(-not ([string]::IsNullOrEmpty($DirectLookup))) {
            $URL = "$URL($DirectLookup)"
        }

        if(-not ([string]::IsNullOrEmpty($Filter))) {
            $URL = "$URL`?`$filter=$Filter"
        }

        $Parameters = @{
            Method = $Method
            Uri = $URL
            Headers = $Headers
        }

        if(-not [string]::IsNullOrEmpty($Body)) {
            $Parameters.Add("Body", $Body)
        }

        if($GetParametersOnly) {
            return $Parameters
        }
        else {
            Try {
                $Response = Invoke-RestMethod @Parameters
            }
            Catch { 
                $Reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $Reader.BaseStream.Position = 0
                $Reader.DiscardBufferedData()
                Write-Host ($Reader.ReadToEnd() | ConvertFrom-Json).error.message -ForegroundColor Red
            }

            return $Response
        }
    }
}

#House keeping
$ErrorActionPreference = 'Continue'
$LastPrinterUpdate = (Get-Date).AddSeconds(-$UpdateDelay) # Make sure the update is run immediately on startup of the script

while($true) {
    #Fetch printers on this host from BC    
    Clear-Variable -Name "BCPrinters" -ErrorAction SilentlyContinue
    $BCPrinters = (Call-BCWebService -Method Get -BaseURL $BaseURL -WebServiceName $PrintersWS -Filter "HostID eq '$env:COMPUTERNAME'" -Authentication $Authentication).value

    #Register new printers in BC
    foreach($Printer in (Get-Printer | Where-Object { $IgnorePrinters -notcontains $_.Name } | Where-Object { $BCPrinters.PrinterID -notcontains $_.Name })) {
       Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Adding new printer in BC: $($Printer.Name)" -ForegroundColor Yellow
       Call-BCWebService -Method Post -BaseURL $BaseURL -WebServiceName $PrintersWS -Authentication $Authentication `
                         -Body "{""HostID"":""$env:COMPUTERNAME"",""PrinterID"":""$($Printer.Name)""}" | Out-Null
    }
          
    #Update existing printers in BC
    if(($(Get-Date) - $LastPrinterUpdate).TotalSeconds -gt $UpdateDelay) {
        foreach($Printer in (Get-Printer | Where-Object { $IgnorePrinters -notcontains $_.Name } | Where-Object { $BCPrinters.PrinterID -contains $_.Name })) {
            $BCPrinter = $BCPrinters | Where-Object { $Printer.Name -eq $_.PrinterID }
            Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Updating printer in BC (RowNo: $($BCPrinter.RowNo)): $($Printer.Name)" -ForegroundColor Yellow   
            Call-BCWebService -Method Patch -BaseURL $BaseURL -WebServiceName $PrintersWS -DirectLookup $BCPrinter.RowNo -ETag $BCPrinter."@odata.etag" -Authentication $Authentication `
                              -Body "{""HostID"":""$env:COMPUTERNAME"",""PrinterID"":""$($Printer.Name)""}" | Out-Null
        }
        $LastPrinterUpdate = Get-Date
        Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Looking for print jobs every $Delay seconds, updating printers every $UpdateDelay seconds..." -ForegroundColor White   
    }

    #Print the queued jobs for the printers on this host
    if(($BCPrinters.NoQueued | Measure-Object -Sum).Sum -gt 0 ) {
        foreach($Job in (Call-BCWebService -Method Get -BaseURL $BaseURL -WebServiceName $QueuesWS -Filter "HostID eq '$env:COMPUTERNAME' and Status eq 'Queued'" -Authentication $Authentication).value) {
            $Job = Call-BCWebService -Method Patch -BaseURL $BaseURL -WebServiceName $QueuesWS -DirectLookup ($Job.RowNo) -ETag ($Job."@odata.etag") `
                                     -Body "{""Status"":""Printing""}" -Authentication $Authentication
            Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Printing job (RowNo: $($Job.RowNo)) on printer $($Job.PrinterID)..." -ForegroundColor Yellow
            $InvokeRestMethodParameters = (Call-BCWebService -Method Patch -BaseURL $BaseURL -WebServiceName $QueuesWS -DirectLookup ($Job.RowNo) -ETag ($Job."@odata.etag") `
                                                             -Body "{""Status"":""Printed"",""PrinterMessage"":""PDFXCview.exe called for printing""}" `
                                                             -Authentication $Authentication -GetParametersOnly)
            Start-Job -Arg $Job,$PDFXCview_exe,$InvokeRestMethodParameters -ScriptBlock {
                Param($Job,$PDFXCview_exe,$InvokeRestMethodParameters)
                Invoke-RestMethod @InvokeRestMethodParameters
                $PDFFile = "$(New-TemporaryFile).pipp.pdf"
                [IO.File]::WriteAllBytes($PDFFile, [System.Convert]::FromBase64String($Job.PDFPrintJobBASE64))
                Start-Process -FilePath "$PDFXCview_exe" -ArgumentList "/printto ""$($Job.PrinterID)"" ""$PDFFile""" -Wait -PassThru
                Remove-Item -Force -Path $PDFFile
            } | Out-Null
        }
        Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Looking for print jobs every $Delay seconds, updating printers every $UpdateDelay seconds..." -ForegroundColor White   
    }

    Start-Sleep -Seconds $Delay
}

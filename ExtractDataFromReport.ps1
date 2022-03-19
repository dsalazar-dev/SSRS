# ---- GET REPORT FROM SSRS AND PARSE TO JSON ----

#Config
$reportServerURI = "ReportServer/ReportExecution2005.asmx?WSDL"
$Username = "username"
$Password = "Password" | ConvertTo-SecureString -AsPlainText -Force
$reportPath = "/Informe_Resumen"

$UserCreds =  New-Object System.Management.Automation.PSCredential($Username, $Password)

$RS = New-WebServiceProxy -Class 'RS' -NameSpace 'RS' -Uri $reportServerURI -Credential $UserCreds

$deviceInfo = "<DeviceInfo><NoHeader>True</NoHeader></DeviceInfo>"
$extension = ""
$mimeType = ""
$encoding = ""
$warnings = $null
$streamIDs = $null

#Set report
$Report = $RS.GetType().GetMethod("LoadReport").Invoke($RS, @($reportPath, $null))

$json = Get-Content 'parameters.json' | Out-String | ConvertFrom-Json

$parameters = @()

$parameters += New-Object RS.ParameterValue
$parameters[0].Name  = "INI_DATE"
$parameters[0].Value = $json.INI_DATE

$parameters += New-Object RS.ParameterValue
$parameters[1].Name  = "FIN_DATE"
$parameters[1].Value = $json.FIN_DATE

$parameters += New-Object RS.ParameterValue
$parameters[2].Name  = "VALUE"
$parameters[2].Value = $json.VALUE


$RS.SetExecutionParameters($parameters, "en-us") > $null

$RenderOutput = $RS.Render('XML',
    $deviceInfo,
    [ref] $extension,
    [ref] $mimeType,
    [ref] $encoding,
    [ref] $warnings,
    [ref] $streamIDs
)

$Stream = New-Object System.IO.FileStream("output.xml"), Create, Write
$Stream.Write($RenderOutput, 0, $RenderOutput.Length)
$Stream.Close()

Get-Content -Path output.xml | ConvertTo-JSON -Depth 3 | Out-File -FilePath output.json
<#
.SYNOPSIS
    Select a file for printing on a OctoPrint server.
.DESCRIPTION
    Select a file for printing on a OctoPrint server. The file may be located on the printer SD Card or Local to the OctoPrint server.
.EXAMPLE
    PS C:\> Select-OctoPSFile -Id 1 -SkipCertificateCheck -Location Local -Path xyzCalibration_cube.gcode
    Select the xyzCalibration_cube.gcode on the local storage.
.EXAMPLE
    PS C:\> Select-OctoPSFile -Id 1 -SkipCertificateCheck -Location Local -Path xyzCalibration_cube.gcode -Print 
    Select the xyzCalibration_cube.gcode on the local storage and start printing it.
.INPUTS
    Int32
#>
function Select-OctoPSFile {
    [CmdletBinding(DefaultParameterSetName = "none")]
    param (

        # Printer Host Id
        [Parameter(Mandatory=$false,
                   ParameterSetName = 'Index',
                   Position=0,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('HostId')]
        [int32[]]
        $Id = @(),

        # Skips certificate validation checks. This includes all validations such as expiration, revocation, trusted root authority, etc.
        [Parameter(Mandatory = $false)]
        [switch]
        $SkipCertificateCheck,

        # Name of the file to select.
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $Path,

        # Location of the files.
        [Parameter(Mandatory = $false,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Local',"SDCard")]
        [string]
        $Location = "Local",

        # Print selected file.
        [Parameter(Mandatory = $false)]
        [switch]
        $Print
    )

    begin {
    }

    process {
        if ($Id.count -gt 0) {
            $PHosts = Get-OctoPSHost -Id $Id
        }
        else {
            $PHosts = Get-OctoPSHost | Select-Object -First 1
        }
        foreach ($h in $PHosts) {
            Write-Verbose -Message "Path: $($Path)"
            $RestMethodParams = @{
                'Method'        = "Post"
                'ContentType'   = "application/json"
            }

            $UriPath = "/api/files/$($Location.ToLower())/$($Path)"
            $command =  @{"command" = "select"}

            if ($Print) {
                $command.Add('print',$true)
            }
            $RestMethodParams.Add('Body', (ConvertTo-Json -InputObject $command))
            $RestMethodParams.Add('URI',"$($h.Uri)$($UriPath)")
            $RestMethodParams.Add('Headers',@{'X-Api-Key' = $h.ApiKey})

            if ($SkipCertificateCheck)
            {
                $RestMethodParams.Add('SkipCertificateCheck', $SkipCertificateCheck)
            }
            Invoke-RestMethod @RestMethodParams | Out-Null
        }
    }

    end {
    }
}
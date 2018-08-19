<#
.SYNOPSIS
	Script to auto-update terraform to latest version
.DESCRIPTION
	Script will scrape "https://api.github.com/repos/hashicorp/terraform/releases/latest" for latest terraform version
	If local version does not match the remote version, it will download and replace terraform with latest version
	Script gets the current version by running "terraform version".
.PARAMETER tf_path
	Specify the path where terraform.exe is located.
	Ex: $tf_path = "C:\Terraform"
.PARAMETER tf_arch
	Specify the System Architecture.
	Allowed values:
		amd64 - For 64-bit systems
		386 - For 32-bit systems
	ex: $tf_arch = "amd64"
.LINK
	https://releases.hashicorp.com/terraform/$($LATEST_RELEASE)/terraform_$($LATEST_RELEASE)_windows_$($tf_arch).zip
	https://api.github.com/repos/hashicorp/terraform/releases/latest
    
 
.NOTES
    Version: 1.1
    
    Creation Date: 18 Nov 2017
    
    Purpose/Change: 
        version 1.0 - Original
        Version 1.1 - Added environment path settings. 

    Author:    Samuel Than
    Original Author: https://github.com/pvicol/get-latest-terraform


#>

# Set parameters
param(
	# Terraform path
	[string] $tf_path = "C:\Terraform",

	# Terraform Arch to be downloaded
	[string] $tf_arch = "amd64"
)

$tf_release_url = "https://api.github.com/repos/hashicorp/terraform/releases/latest"

# Check if last "\" was provided in $tf_path, if it was not, add it
if (-not $tf_path.EndsWith("\")){
	$tf_path = $tf_path+"\"
}

# Get terraform version
function get_cur_tf_version (){
	<#
	.SYNOPSIS
		Function returns current terrafom versions from "terraform version" command.
	#>
	# Regex for version number
	[regex]$regex = '\d+\.\d+\.\d+'
	
	# Build terraform command and run it
	$command = "$tf_path" + "terraform.exe"
	$version = &$command version | Write-Output

	# Match and return versions
	[string]$version -match $regex > $null
	return $Matches[0]
}

function get_latest_tf_version() {
	<#
	.SYNOPSIS
		Function will get latest version number from github page
	.LINK
		https://api.github.com/repos/hashicorp/terraform/releases/latest
	#>

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	# Get web content and convert from JSON
	$web_content = Invoke-WebRequest -Uri $tf_release_url -UseBasicParsing |	ConvertFrom-Json

	return $web_content.tag_name.replace("v","")
}

function get_terraform () {
	<#
	.SYNOPSIS
		Function will download and install latest version of terraform
	.LINK
		https://releases.hashicorp.com/terraform/$(get_latest_tf_version)/terraform_$(get_latest_tf_version)_windows_$tf_arch.zip
	#>
	Write-Host "Downloading latest version"

	# Build download URL
	$url = "https://releases.hashicorp.com/terraform/$(get_latest_tf_version)/terraform_$(get_latest_tf_version)_windows_$tf_arch.zip"

	# Output folder (in location provided)
	$download_location = $tf_path + "terraform.zip"

	# Set TLS to 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Download terraform
	Invoke-WebRequest -Uri $url -OutFile $download_location  > $null

	# Unzip terraform and replace existing terraform file
	Write-Host "Installing latest terraform"
	Expand-Archive -Path $download_location -DestinationPath $tf_path -Force

	# Remove zip file
	Write-Host "Remove zip file"
	Remove-Item $download_location -Force
}


# Check if terraform exists in $tf_path
if (-not (Test-Path ($tf_path + "terraform.exe"))){
	Write-Host "Terraform could not be located in $tf_path"
	Write-Host
	get_terraform
}

# Check if current version is different than latest version
elseif ((get_latest_tf_version) -ne (get_cur_tf_version)) {
	# Write basic info to sceen
	Write-Host "Current Terraform version: $(get_cur_tf_version)"
	Write-Host "Latest Terraform Version: $(get_latest_tf_version)"
	Write-Host
	get_terraform
}

# If versions match, display message
else {
	Write-Host "Latest Terraform already installed."
	Write-Host
	Write-Host "Current Terraform version: $(get_cur_tf_version)"
	Write-Host "Latest Terraform Version: $(get_latest_tf_version)"
}


## Get the PATH environmental Variable
$Path=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path

## Create New PATH environmental Variable
$NewPath=$Path+";"+$tf_path

## Set the New PATH environmental Variable
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH –Value $NewPath

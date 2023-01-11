<#
******************************************************************************
* @file    AzCheckPrereq.ps1
* @author  MCD Application Team
* @brief   Check the presequists for the X-CUBE-AZURE Quick Connect scripts
******************************************************************************
 * Copyright (c) 2022 STMicroelectronics.

 * All rights reserved.

 * This software component is licensed by ST under BSD 3-Clause license,
 * the "License"; You may not use this file except in compliance with the
 * License. You may obtain a copy of the License at:
 *                        opensource.org/licenses/BSD-3-Clause
 *
******************************************************************************
#>

$Script_Version = "1.0.0 azvws q1 2023 1"
$copyright      = "Copyright (c) 2022 STMicroelectronics."
$about          = "STM32U5 AWS Virtual workshop 2023 prerequisite check"
$privacy        = "The script doesn't collect or share any data"

$Required_Version_STM32CubeProgrammer = "STM32CubeProgrammer v2.12.0"
$Required_Version_Python              = "Python 3.11.1"
$Required_Version_AZCLI               = "azure-cli                         2.40.0 *"

$PATH_STM32CubeProgrammer_CLI        = "C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe"
$PATH_FIRMWARE                       = "C:\STM32CubeExpansion_Cloud_AZURE_V2.1.0\Projects\B-U585I-IOT02A\Applications\TFM_Azure_IoT"
$PATH_TOOLS                          = ".\tools"
$PATH_LOG                            = ".\log"

$ZIP_STM32_CUBE_PROG           = "en.stm32cubeprg-win64-v2-12-0.zip"
$ZIP_X_CUBE_AZURE              = "en.x-cube-azure_v2-1-0.zip"

$INSTALLER_STM32_CUBE_PROG     = "SetupSTM32CubeProgrammer_win64.exe"
$INSTALLER_PYTHON              = "python-3.11.1-amd64.exe"
$INSTALLER_PPIP                = "get-pip.py"

$URL_LINK_STM32_CUBE_PROG = "https://www.st.com/content/ccc/resource/technical/software/utility/group0/e4/fa/e0/4f/c4/0e/4b/41/stm32cubeprg-win64-v2-12-0/files/stm32cubeprg-win64-v2-12-0.zip/jcr:content/translations/en.stm32cubeprg-win64-v2-12-0.zip"
$URL_LINK_X_CUBE_AZURE    = "https://www.st.com/content/ccc/resource/technical/software/firmware/group1/33/52/eb/c6/5b/33/44/57/x-cube-azure_v2-1-0/files/x-cube-azure_v2-1-0.zip/jcr:content/translations/en.x-cube-azure_v2-1-0.zip"
$URL_LINK_PYTHON          = "https://www.python.org/ftp/python/3.11.1/$INSTALLER_PYTHON"
$URL_LINK_PIP             = "https://bootstrap.pypa.io/$INSTALLER_PPIP"
$URL_LINK_AZCLI           = "https://azcliprod.blob.core.windows.net/msi/azure-cli-2.40.0.msi"

$ws_tenant_id = "aedf9cbb-56df-47c5-82a7-9a57071cab8e"

$tools_path = ".\tools"
$log_path   = ".\log"

<# Refresh envirement variables #>
function refresh_envirement_variables 
{
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

<# Check if PC is connected to internet #>
function Internet_Connection_Check
{
    Write-Output "Checking Internet connection"

    return Test-Connection -ComputerName www.st.com -Quiet
}

<# Create tools directory #>
function ToolsDir_Create()
{
  If(!(test-path -PathType container $tools_path))
  {
      New-Item -ItemType Directory -Path $tools_path
  }

  If(!(test-path -PathType container $log_path))
  {
      New-Item -ItemType Directory -Path $log_path
  }
}

function Cleanup()
{
    Remove-Item $PATH_TOOLS -Recurse -Force
    Remove-Item $PATH_LOG   -Recurse -Force
}

<# Clone iot-reference-stm32u5 #>
function FIRMWARE_Install()
{
    $downloadsFolder    = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders").PSObject.Properties["{374DE290-123F-4565-9164-39C4925E467B}"].Value
    $firmware_zip       = "$downloadsFolder\$ZIP_X_CUBE_AZURE"

    if (!(Test-Path $firmware_zip))
    {
        Write-Host "Downloading $ZIP_X_CUBE_AZURE"
        Start-Process -Wait $URL_LINK_X_CUBE_AZURE

        while (!(Test-Path "$firmware_zip")) 
        {
             Start-Sleep 10 
        }

        if (!(Test-Path $cubeprog_installer))
        {
            Write-Host "Extracting $ZIP_X_CUBE_AZURE"
            Expand-Archive "$firmware_zip" "C:\"
        }
    }

}

<# Check iot-reference-stm32u5 is installed #>
function FIRMWARE_Check()
{
    if (Test-Path -Path $PATH_FIRMWARE)
    {
        Write-Output "STM32CubeExpansion_Cloud_AZURE_V2.1.0 exist" | Green

        return 'True'
    }

    FIRMWARE_Install

    return "False"
}

<# Install AZCLI extensions #>
function AZCLI_Extensions_Install()
{
    Write-Output "Installing AZ extensions"

  try 
  {
    & az extension add --name azure-iot 
    & az extension update --name azure-iot
    & az extension add --name account
    & az extension update --name account
  }
  catch
  {
    return 'False'
  }

  return 'True'
}

<# Locgin to Azure account #>
function AZCLI_Login()
{
    Write-Output "Redirecting to a browser window to log in to Azure"
    Start-Sleep -Seconds 1

    Write-Output "Use the credential from  credentials.txt to log in to Azure"
    Write-Output "credentials.txt will automatically open in 3 seconds"
    Write-Output "Please return to the terminal after you login to Azure"

    Start-Sleep -Seconds 3
    
    & notepad "credentials.txt"

    Start-Sleep -Seconds 3

    #Logout from Azure
   & az logout

   #Login to Azure
   & az login  |  Out-String | Set-Content $log_path\az_login.json

   $login_info = Get-Content $log_path\az_login.json | Out-String | ConvertFrom-Json
   
   if($login_info.tenantId -eq $ws_tenant_id)
   {
    return 'True'
   }
   
   return 'Falase'
}

<# Install Python #>
function AZCLI_Install()
{
    Write-Output "Installing $Required_Version_AZCLI"

    Start-Sleep -Seconds 3

    $azcli_installer = "$tools_path\azure-cli-2.40.0.msi"

    if (!(Test-Path $azcli_installer))
    {
      Write-Output "Downloading AZCLI"
      Import-Module BitsTransfer
      Start-BitsTransfer -Source $URL_LINK_AZCLI -Destination $azcli_installer
    }
    
    Start-Process -Wait -FilePath  $azcli_installer

    # Refresh envirement variables
    refresh_envirement_variables
}

<# Check if AZCLI is installed #>
function AZCLI_Check()
{
    Try
    {
        $azcli_version = & az --version

        if(!$azcli_version)
        {
            Write-Output "AZCLI not installed"
            AZCLI_Install

            return 'True'
        }

        if($azcli_version -like $Required_Version_AZCLI)
        {
            Write-Output "AZCLI $Required_Version_AZCLI installed"
            return 'True'
        }

        return 'False'
    }
    Catch
    {
        Write-Output "AZCLI not installed"
        AZCLI_Install
    }

    return 'True'
}

<# Install Python modules #>
function Python_Modules_Install()
{
    Write-Host "Installing Python libraries"

    & python -m pip install pyserial
}

<# Install Python #>
function Python_Pip_Check()
{
    $pip_version = & python -m pip --version

    if(!$pip_version)
    {
      $pip_installer = "$PATH_TOOLS\$INSTALLER_PPIP"

      if (!(Test-Path $pip_installer))
      {
        Write-Host "Downloading pip"
        Import-Module BitsTransfer
        Start-BitsTransfer -Source $URL_LINK_PIP -Destination $pip_installer
      }
    
      Write-Host "Installing pip"
      Start-Process -Wait -FilePath  python -ArgumentList "$pip_installer"

      refresh_envirement_variables
    }
    else 
    {
        Write-Output "pip installed"
    }
}

<# Install Python #>
function Python_Install()
{
    Start-Sleep -Seconds 3

    $python_installer = "$tools_path\python-3.10.7-amd64.exe"

    if (!(Test-Path $python_installer))
    {
        Write-Output "Downloading $Required_Version_Python"
        Import-Module BitsTransfer
        Start-BitsTransfer -Source $URL_LINK_PYTHON -Destination $python_installer
    }

    Write-Output "Installing $Required_Version_Python"
    Start-Process -Wait -FilePath  $python_installer -ArgumentList "/passive InstallAllUsers=1 PrependPath=1 Include_test=0"

    # Refresh envirement variables
    refresh_envirement_variables
}

<# Check if Python is installed #>
function Python_Check()
{
    Try
    {
        $python_version = & python --version

        if(!$python_version)
        {
            Write-Output "Python not installed"
            Python_Install

            return 'True'
        }

        if($python_version -like $Required_Version_Python)
        {
            return 'True'
        }

        return 'False'
    }
    Catch
    {
        Write-Output "Python not installed"
        Python_Install
    }

    return 'True'
}

<# Install STM32CubeProgrammer #>
function STM32CubeProg_Install()
{
    $downloadsFolder    = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders").PSObject.Properties["{374DE290-123F-4565-9164-39C4925E467B}"].Value
    $cubeprog_zip = "$downloadsFolder\$ZIP_STM32_CUBE_PROG"

    if (!(Test-Path $cubeprog_zip))
    {
        Write-Host "Downloading $ZIP_STM32_CUBE_PROG"
        Start-Process -Wait $URL_LINK_STM32_CUBE_PROG

        while (!(Test-Path "$cubeprog_zip")) 
        {
             Start-Sleep 10 
        }
    }

    $cubeprog_installer = "$PATH_TOOLS\$INSTALLER_STM32_CUBE_PROG"

    if (!(Test-Path $cubeprog_installer))
    {
        Write-Host "Extracting $ZIP_STM32_CUBE_PROG"
        Expand-Archive "$cubeprog_zip" "$PATH_TOOLS"
    }

    Write-Host "Installing $Required_Version_STM32CubeProgrammer"

    Start-Process -Wait -FilePath  $cubeprog_installer

    # Refresh envirement variables
    refresh_envirement_variables  
}

<# Check STM32CubeProgrammer is installed #>
function STM32CubeProg_Check()
{
    if (Test-Path -Path $PATH_STM32CubeProgrammer_CLI)
    {
        Write-Output "STM32CubeProgrammer exist"
      & $PATH_STM32CubeProgrammer_CLI "--version" |  Out-String | Set-Content $PATH_LOG\STM32CubeProgrammer_version.txt

      foreach($line in Get-Content $PATH_LOG\STM32CubeProgrammer_version.txt) 
      {
        if($line -match $regex)
        {
            if ($line.Contains($Required_Version_STM32CubeProgrammer))
            {
                return "True"
            }
        }
      }

      return 'False'
    }

    STM32CubeProg_Install

     return "True"
}

function Green
{
    process { Write-Host $_ -ForegroundColor Green }
}

function Red
{
    process { Write-Host $_ -ForegroundColor Red }
}

function White
{
    process { Write-Host $_ -ForegroundColor White }
}

<#######################################################  

                     Script start 

########################################################>
Clear-Host


Write-Output "Script version: $Script_Version"   | Green
Write-Output "$copyright"
Write-Output "$about"
Write-Output "$privacy"

# Refresh envirement variables
refresh_envirement_variables

# Check if PC is connected to Internet
$connection_status = Internet_Connection_Check

if(!($connection_status -like 'True'))
{
    Write-Output "You are not connected to Internet. Please connect to Internet and run the script again" | Red
    Start-Sleep -Seconds 2
    Exit 1
}

Write-Output "You are connected to Internet."  | Green

# Create tools directory
$value = ToolsDir_Create

# Check if X-CUBE-AZURE is installed
$value = FIRMWARE_Check

# Check if STM32CubeProg_Check is installed
$value = STM32CubeProg_Check

if(!($value -like 'True'))
{
    Write-Output "STM32CubeProgrammer version error"  | Red
    Write-Output "Required version : $Required_Version_STM32CubeProgrammer"
    Write-Output "please Uninstall STM32CubeProgrammer and run the script again"

    Start-Sleep -Seconds 5
    Exit 1
}

Write-Output "STM32CubeProgrammer version OK"   | Green

$value = Python_Check

if(!($value -like 'True'))
{
    Write-Output "Python version error"  | Red
    Write-Output "Required version : $Required_Version_Python"
    Write-Output "please Uninstall Python and run the script again"

    Start-Sleep -Seconds 5
    Exit 1
}

Write-Output "Python version OK"   | Green

Python_Pip_Check

Python_Modules_Install

$value = AZCLI_Check

if(!($value -like 'True'))
{
    Write-Output "AZCLI version error"  | Red
    Write-Output "Required version : $Required_Version_AZCLI"
    Write-Output "please Uninstall AZCLI and run the script again"

    Start-Sleep -Seconds 5
    Exit 1
}

Write-Output "AZCLI version OK" | Green

$value = AZCLI_Extensions_Install

if(!($value -like 'True'))
{
    Write-Output "Issue installing AZ extensions"  | Red
    Start-Sleep -Seconds 5
    Exit 1
}

Write-Output "System check successful" | Green
Exit 0

# Locgin to Azure account
$value = AZCLI_Login

if(!($value -like 'True'))
{
    Write-Output "AZCLI login error. Please run the script again and try to login again"   | Red

    Start-Sleep -Seconds 5
    Exit 1
}

Write-Output "Successful AZ login" | Green

& python .\scripts\configureJson.py

Start-Process $PATH_FIRMWARE

Exit 0

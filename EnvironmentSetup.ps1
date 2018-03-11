Param(
    # The EC2 key pair assigned to all instances launched.
    [Parameter(mandatory=$true)]
    [string]
    $ec2KeyPair,

    # The instance type for the stage you want
    [Parameter()]
    [string]
    $appInstanceType = "t2.small"   
)

function _LaunchCloudFormationStack([string]$bucketName, [string]$appInstanceType,[string]$keyPair, [bool]$openRDP)
{
    Write-Host "Creating CloudFormation Stack to launch an EC2 instance and configure it for CodeDeploy deployments"

    $templatePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "./CloudFormationSetupProject/cloudformationyaml.template"))
    $templateBody = [System.IO.File]::ReadAllText($templatePath)

    Write-Host 'Using cf template ' $templatePath

    $imageId = (Get-EC2ImageByName WINDOWS_2016_BASE).ImageId
    
    $openRDPTranslated = "Yes"  

    $parameters = @(
        @{ParameterKey = "ImageId"; ParameterValue = $imageId},
        @{ParameterKey = "AppInstanceType"; ParameterValue = $appInstanceType},        
        @{ParameterKey = "EC2KeyName"; ParameterValue = $keyPair},
        @{ParameterKey = "OpenRemoteDesktopPort"; ParameterValue = $openRDPTranslated},
        @{ParameterKey = "PipelineBucket"; ParameterValue = $bucketName}
    )

    $stackId = New-CFNStack -StackName "DemoTestNetCoreApp" -Capability "CAPABILITY_IAM" -Parameter $parameters -TemplateBody $templateBody
    $stackId
}


function _SetupPipelineBucket()
{
    # make sure this S3 bucket is unique
    $bucketName = "demoinstallbucket";
    $bucket = New-S3Bucket -BucketName $bucketName
    Write-S3BucketVersioning -BucketName $bucketName -VersioningConfig_Status Enabled

    Write-Host 'Setting up S3 source for pipeline: ' $bucketName
    Add-Type -assembly "system.io.compression.filesystem"
   
    Write-Host 'Writing artifacts to s3'
    
    #
    # replace this with your application settings
    #
    Write-Host 'Writing objects application to s3'
    #Write-S3Object -BucketName $bucketName -File .\toinstall\example_app.zip -Key 'example_app.zip'

    #Write-Host 'Writing runtime to s3'
    #Write-S3Object -BucketName $bucketName -File .\toinstall\dotnet-runtime-2.0.5-win-x64.exe -Key 'dotnet-runtime-2.0.5-win-x64.exe'

    #Write-Host 'Writing host software to s3'
    #Write-S3Object -BucketName $bucketName -File .\toinstall\DotNetCore.2.0.5-WindowsHosting.exe -Key 'DotNetCore.2.0.5-WindowsHosting.exe'    

    $bucketName
}

function ProcessInput([string]$appInstanceType,[string]$keyPair,[bool]$openRDPPort)
{
    if ((Get-AWSCredentials) -eq $null)
    {
        throw "You must set credentials via Set-AWSCredentials before running this cmdlet."
    }
    if ((Get-DefaultAWSRegion) -eq $null)
    {
        throw "You must set a region via Set-DefaultAWSRegion before running this cmdlet."
    }

    $bucketName = _SetupPipelineBucket
    $stackId = _LaunchCloudFormationStack $bucketName $appInstanceType $keyPair $openRDPPort
    $stack = Get-CFNStack -StackName $stackId

    while ($stack.StackStatus.Value.toLower().EndsWith('in_progress'))
    {
        $stack = Get-CFNStack -StackName $stackId
        "Waiting for CloudFormation Stack to be created"
        Start-Sleep -Seconds 10
    }

    if ($stack.StackStatus -ne "CREATE_COMPLETE") 
    {
        "CloudFormation Stack was not successfully created, view the stack events for further information on the failure"
        Exit
    }

    $stageDNS = ""
   
    ForEach($output in $stack.Outputs)
    {
        if($output.OutputKey -eq "CodeDeployTrustRoleARN")
        {
            $serviceRoleARN = $output.OutputValue
        }        
    }


    ("CodePipeline environment setup complete")
    ("Stage DNS: " + $stageDNS)
    ("S3 Bucket for Pipeline Source: " + $bucketName)
    ("S3 Object Key for Pipeline Source: example_app.zip")
}


ProcessInput $appInstanceType $ec2KeyPair
#Requires -Version 5.1

<#
.SYNOPSIS
    AWS Resource Inventory and Security Audit Tool
    
.DESCRIPTION
    Comprehensive AWS inventory across regions
    Security and compliance checks for AWS resources
    
.PARAMETER ProfileName
    AWS credentials profile name (optional)
    
.PARAMETER Region
    AWS region to query (default: us-east-1)
    
.PARAMETER OutputPath
    Output directory for reports
    
.EXAMPLE
    .\aws_resource_inventory.ps1 -Region us-east-1 -OutputPath C:\Reports
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ProfileName,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = 'us-east-1',
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\aws_reports",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeSecurityChecks
)

$ErrorActionPreference = 'Stop'

# Check for AWS CLI/Tools
try {
    aws --version | Out-Null
} catch {
    Write-Error "AWS CLI not found. Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
}

# Initialize output directory
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Set AWS profile if specified
if ($ProfileName) {
    $env:AWS_PROFILE = $ProfileName
    Write-Host "Using AWS profile: $ProfileName" -ForegroundColor Green
}

Write-Host "Using AWS region: $Region" -ForegroundColor Green

# Function to get AWS account information
function Get-AWSAccount {
    Write-Host "Retrieving AWS account information..." -ForegroundColor Cyan
    
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    
    return [PSCustomObject]@{
        AccountID = $identity.Account
        UserArn = $identity.Arn
    }
}

# Function to list EC2 instances
function Get-EC2Instances {
    param([string]$Region)
    
    Write-Host "Retrieving EC2 instances..." -ForegroundColor Cyan
    
    $instances = aws ec2 describe-instances --region $Region --output json | ConvertFrom-Json
    
    $instancesList = @()
    
    foreach ($reservation in $instances.Reservations) {
        foreach ($instance in $reservation.Instances) {
            $instancesList += [PSCustomObject]@{
                InstanceID = $instance.InstanceId
                InstanceType = $instance.InstanceType
                State = $instance.State.Name
                LaunchTime = $instance.LaunchTime
                ImageID = $instance.ImageId
                PrivateIP = $instance.PrivateIpAddress
                PublicIP = $instance.PublicIpAddress
                VPCID = $instance.VpcId
                SubnetID = $instance.SubnetId
                SecurityGroups = ($instance.SecurityGroups | ForEach-Object { $_.GroupName }) -join ','
                KeyName = $instance.KeyName
                Tags = if (($instance.Tags | Where-Object { $_.Key -eq 'Name' }).Value) { ($instance.Tags | Where-Object { $_.Key -eq 'Name' }).Value } else { 'N/A' }
            }
        }
    }
    
    return $instancesList
}

# Function to list S3 buckets
function Get-S3Buckets {
    Write-Host "Retrieving S3 buckets..." -ForegroundColor Cyan
    
    $buckets = aws s3api list-buckets --output json | ConvertFrom-Json
    
    $bucketDetails = @()
    
    foreach ($bucket in $buckets.Buckets) {
        try {
            $location = aws s3api get-bucket-location --bucket $bucket.Name --output text 2>$null
            
            $bucketDetails += [PSCustomObject]@{
                BucketName = $bucket.Name
                CreationDate = $bucket.CreationDate
                Region = $location
            }
        } catch {
            $bucketDetails += [PSCustomObject]@{
                BucketName = $bucket.Name
                CreationDate = $bucket.CreationDate
                Region = 'Unknown'
            }
        }
    }
    
    return $bucketDetails
}

# Function to list security groups
function Get-SecurityGroups {
    param([string]$Region)
    
    Write-Host "Retrieving security groups..." -ForegroundColor Cyan
    
    $groups = aws ec2 describe-security-groups --region $Region --output json | ConvertFrom-Json
    
    $groupsList = @()
    
    foreach ($group in $groups.SecurityGroups) {
        # Check for overly permissive rules
        $highRiskRules = 0
        foreach ($rule in $group.IpPermissions) {
            foreach ($ipRange in $rule.IpRanges) {
                if ($ipRange.CidrIp -eq '0.0.0.0/0') {
                    $highRiskRules++
                }
            }
        }
        
        $groupsList += [PSCustomObject]@{
            GroupID = $group.GroupId
            GroupName = $group.GroupName
            Description = $group.Description
            VPCID = $group.VpcId
            IngressRules = $group.IpPermissions.Count
            EgressRules = $group.IpPermissionsEgress.Count
            HighRiskRules = $highRiskRules
        }
    }
    
    return $groupsList
}

# Main execution
Write-Host "=== AWS Resource Inventory Tool ===" -ForegroundColor Yellow

# Get account info
$account = Get-AWSAccount
Write-Host "Account ID: $($account.AccountID)" -ForegroundColor Green

# Collect inventory
Write-Host "`nCollecting AWS resources..." -ForegroundColor Cyan

$ec2Instances = Get-EC2Instances -Region $Region
$s3Buckets = Get-S3Buckets
$securityGroups = Get-SecurityGroups -Region $Region

# Generate reports
Write-Host "`nGenerating reports..." -ForegroundColor Cyan

# Export EC2 instances
if ($ec2Instances.Count -gt 0) {
    $ec2Path = Join-Path $OutputPath "aws_ec2_$timestamp.csv"
    $ec2Instances | Export-Csv -Path $ec2Path -NoTypeInformation
    Write-Host "EC2 instances exported to: $ec2Path" -ForegroundColor Green
}

# Export S3 buckets
if ($s3Buckets.Count -gt 0) {
    $s3Path = Join-Path $OutputPath "aws_s3_$timestamp.csv"
    $s3Buckets | Export-Csv -Path $s3Path -NoTypeInformation
    Write-Host "S3 buckets exported to: $s3Path" -ForegroundColor Green
}

# Export security groups
if ($securityGroups.Count -gt 0) {
    $sgPath = Join-Path $OutputPath "aws_security_groups_$timestamp.csv"
    $securityGroups | Export-Csv -Path $sgPath -NoTypeInformation
    Write-Host "Security groups exported to: $sgPath" -ForegroundColor Green
}

# Generate summary report
$report = @"
# AWS Resource Inventory Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Account ID: $($account.AccountID)
Region: $Region

## Summary
- EC2 Instances: $($ec2Instances.Count)
- Running Instances: $(($ec2Instances | Where-Object { $_.State -eq 'running' }).Count)
- S3 Buckets: $($s3Buckets.Count)
- Security Groups: $($securityGroups.Count)
- High-Risk Security Groups: $(($securityGroups | Where-Object { $_.HighRiskRules -gt 0 }).Count)

## Security Findings
"@

if ($IncludeSecurityChecks) {
    $report += @"

### Security Recommendations
1. **Security Groups**: Review security groups with overly permissive rules (0.0.0.0/0)
2. **S3 Buckets**: Audit S3 bucket permissions and enable versioning
3. **EC2 Instances**: Review public IP addresses and security group assignments
4. **Key Management**: Audit use of EC2 key pairs
5. **IAM**: Review IAM roles and policies

### High-Risk Resources
"@

    $highRiskSGs = $securityGroups | Where-Object { $_.HighRiskRules -gt 0 }
    if ($highRiskSGs.Count -gt 0) {
        $report += "`nSecurity Groups with open rules:`n"
        $highRiskSGs | ForEach-Object {
            $report += "- $($_.GroupName) ($($_.GroupID)): $($_.HighRiskRules) high-risk rules`n"
        }
    }
}

$reportPath = Join-Path $OutputPath "aws_summary_$timestamp.md"
$report | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "`nSummary report: $reportPath" -ForegroundColor Green

# Display summary
Write-Host "`n=== Inventory Summary ===" -ForegroundColor Yellow
Write-Host "EC2 Instances: $($ec2Instances.Count)" -ForegroundColor Cyan
Write-Host "S3 Buckets: $($s3Buckets.Count)" -ForegroundColor Cyan
Write-Host "Security Groups: $($securityGroups.Count)" -ForegroundColor Cyan

if ($ec2Instances.Count -gt 0) {
    Write-Host "`nEC2 Instance States:" -ForegroundColor Yellow
    $ec2Instances | Group-Object State | Format-Table Name, Count -AutoSize
}

exit 0

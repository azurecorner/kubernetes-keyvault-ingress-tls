
 $pfxPassword="Ingress-tls-1#*" # Replace with your desired password

 # Convert plain text to SecureString if necessary
if ($pfxPassword -isnot [System.Security.SecureString]) {
    $pfxPassword = ConvertTo-SecureString $pfxPassword -AsPlainText -Force
}

$domain="cloud-devops-craft.com"
# Create the root signing cert
# Get the current working directory
$currentPath = Get-Location

Write-Host "path = $currentPath"
# $currentPath = "$currentPath\iac\scripts"

Write-Host "Create the root signing cert"
$root = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
    -Subject "CN=cloud-devops-craft-com-signing-root" -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 -KeyLength 4096 `
    -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign `
    -KeyUsage CertSign -NotAfter (get-date).AddYears(5)
# Create the wildcard SSL cert.

Write-Host "Create the wildcard SSL cert"
$ssl = New-SelfSignedCertificate -Type Custom -DnsName "*.$domain",$domain `
    -KeySpec Signature `
    -Subject "CN=*.$domain" -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 -KeyLength 2048 `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -Signer $root

    # Export CER of the root and SSL certs
Write-Host "Export CER of the root and SSL certs"
# Export-Certificate -Type CERT -Cert $root -FilePath $currentPath\ssl\datasync-signing-root.cer
Export-Certificate -Type CERT -Cert $ssl -FilePath $currentPath\ssl\datasync-ssl.cer

# Export PFX of the root and SSL certs
Write-Host "Export PFX of the root and SSL certs"

<# Export-PfxCertificate -Cert $root -FilePath $currentPath\ssl\datasync-signing-root.pfx `
    -Password $pfxPassword #(read-host -AsSecureString -Prompt "password") #>
Export-PfxCertificate -Cert $ssl -FilePath $currentPath\ssl\datasync-ssl.pfx `
    -ChainOption BuildChain -Password $pfxPassword # (read-host -AsSecureString -Prompt "password")


    # Variables
$vaultName = "kv-shared-edusync-dev"     # Replace with your Key Vault name
$certificateName = "logcorner-datasync-cert"  # Replace with desired certificate name in Key Vault
$pfxFilePath = "$currentPath\ssl\datasync-ssl.pfx" # Path to your PFX file
#####$pfxPassword = Read-Host -AsSecureString -Prompt "Enter PFX password" # Securely input PFX password

# Upload the PFX certificate to Azure Key Vault
Import-AzKeyVaultCertificate -VaultName $vaultName `
    -Name $certificateName `
    -FilePath $pfxFilePath `
    -Password $pfxPassword

<# # Upload the PFX certificate root to Azure Key Vault
$certificateName = "logcorner-datasync-cert-root"  # Replace with desired certificate name in Key Vault
$pfxFilePath = "$currentPath\ssl\datasync-signing-root.pfx" # Path to your PFX file
#####$pfxPassword = Read-Host -AsSecureString -Prompt "Enter PFX password" # Securely input PFX password

# Upload the PFX certificate to Azure Key Vault
Import-AzKeyVaultCertificate -VaultName $vaultName `
    -Name $certificateName `
    -FilePath $pfxFilePath `
    -Password $pfxPassword
 #>

# Define variables
$acrName = "aksingrestlsacr"  # Name of your Azure Container Registry (ACR)

 #  *************************************** web api ***************************************
$imageName = "kubernetes-ingress-tls-api"  # Name of the image
$imageTag = "v1.0.0"  # Tag for the image

# Get the full path to the current script location
$scriptPath = (Get-Location).Path  # Current folder path where the script is running
$dockerFilePath = "$scriptPath\src\kubernetes-ingress-tls\WebApi\Dockerfile"  # Path to the Dockerfile
$buildContextPath = "$scriptPath\src\kubernetes-ingress-tls\WebApi"  # Path to the folder containing Dockerfile

# Display info about the paths being used
Write-Host "Building Docker image from context: $buildContextPath"
Write-Host "Using Dockerfile located at: $dockerFilePath"

# Build and tag the Docker image
docker build -f $dockerFilePath -t "${acrName}.azurecr.io/${imageName}:${imageTag}" $buildContextPath 

# Check if the build was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host "Docker image built successfully: ${acrName}.azurecr.io/${imageName}:${imageTag}"
} else {
    Write-Error "Docker image build failed"
}

#  docker run  --name kubernetes-ingress-tls-api --rm -it -p 8080:8070/tcp -p  ${acrName}.azurecr.io/${imageName}:${imageTag}


# curl http://localhost:8080/api/WeatherForecast


# Get the access token from Azure CLI
$accessToken = az acr login --name $acrName --expose-token --output tsv --query accessToken

# Login to ACR using the access token
$accessToken | docker login "${acrName}.azurecr.io" --username 00000000-0000-0000-0000-000000000000 --password-stdin

docker push "${acrName}.azurecr.io/${imageName}:${imageTag}"


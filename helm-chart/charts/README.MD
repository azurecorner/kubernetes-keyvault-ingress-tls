 kubectl port-forward pod/datasynchro-api-http-api-deployment-6f756c67d7-jqbdj 8081:8080
http://localhost:8080/api/WeatherForecast


 kubectl port-forward pod/datasynchro-app-http-app-deployment-d4888f45c-6l7q5 8082:8080
 http://localhost:8082/
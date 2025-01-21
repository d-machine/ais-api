# ais-api
```
npm install
docker-compose --env-file .env.development build api
docker-compose --env-file .env.development up -d
```

# Execute following, one time
```
curl --location --request POST 'localhost:3000/api/storage/initializeDatabase'
```
# Execute following, first time and on any config changes
```
curl --location --request POST 'localhost:3000/api/storage/loadConfigs'
```

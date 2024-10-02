# Docker for development version of Omeka-S

## Quickstart
```
git clone https://github.com/martinlovell/docker-omeka-s.git
cd docker-omeka-s
docker compose build
docker compose up
```
Open http://localhost

## Clearing all data for a fresh install
```
docker down -v
```

## API Key
There is an API key created during the first `docker compose up`. View the output to get the key and credential.

## Initial User and password
The initial admin user is configured in [docker-compose.yml](docker-compose.yml).
```
      OMEKA_ADMIN_EMAIL: martin.lovell@yale.edu
      OMEKA_ADMIN_NAME: Martin
      OMEKA_ADMIN_PASSWORD: password
```
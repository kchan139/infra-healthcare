#!/bin/sh

export SPRING_DATASOURCE_PASSWORD=$(cat /run/secrets/db_password)
export SPRING_DATASOURCE_URL=$(cat /run/secrets/testorder_db_url)
export SPRING_DATASOURCE_USERNAME=$(cat /run/secrets/db_username)

export SPRING_DATA_MONGODB_URI=$(cat /run/secrets/mongodb_uri)
export SPRING_RABBITMQ_USERNAME=$(cat /run/secrets/rabbitmq_username)
export SPRING_RABBITMQ_PASSWORD=$(cat /run/secrets/rabbitmq_password)

exec java -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 \
    -XX:+UseG1GC -XX:+UseStringDeduplication -Djava.security.egd=file:/dev/./urandom \
    -jar app.jar

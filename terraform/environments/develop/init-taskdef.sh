#!/bin/sh

profile="sc-develop"

aws ecs register-task-definition \
  --profile $profile \
  --family simple-community-develop-api-main \
  --network-mode "awsvpc" \
  --requires-compatibilities "FARGATE" \
  --cpu "256" \
  --memory "512" \
  --container-definitions "[{\"name\":\"api\",\"image\":\"nginx\",\"portMappings\": [{\"containerPort\": 80}]}]"

aws ecs register-task-definition \
  --profile $profile \
  --family simple-community-develop-app-community \
  --network-mode "awsvpc" \
  --requires-compatibilities "FARGATE" \
  --cpu "256" \
  --memory "512" \
  --container-definitions "[{\"name\":\"app\",\"image\":\"nginx\",\"portMappings\": [{\"containerPort\": 80}]}]"
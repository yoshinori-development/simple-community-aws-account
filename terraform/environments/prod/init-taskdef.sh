#!/bin/sh

aws ecs register-task-definition \
  --profile community \
  --family simple-community-prod-api-main \
  --network-mode "awsvpc" \
  --requires-compatibilities "FARGATE" \
  --cpu "256" \
  --memory "512" \
  --container-definitions "[{\"name\":\"api\",\"image\":\"nginx\",\"portMappings\": [{\"containerPort\": 80}]}]"

aws ecs register-task-definition \
  --profile community \
  --family simple-community-prod-app-community \
  --network-mode "awsvpc" \
  --requires-compatibilities "FARGATE" \
  --cpu "256" \
  --memory "512" \
  --container-definitions "[{\"name\":\"app\",\"image\":\"nginx\",\"portMappings\": [{\"containerPort\": 80}]}]"
#!/bin/bash
source .gitlab-ci.env && gitlab-runner exec shell build \
    --env CI_REGISTRY_IMAGE=$CI_REGISTRY_IMAGE \
    --env CI_REGISTRY=$CI_REGISTRY \
    --env CI_REGISTRY_USER=$CI_REGISTRY_USER \
    --env CI_REGISTRY_PASSWORD=$CI_REGISTRY_PASSWORD \
#!/bin/bash

wget -O - https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.0/deploy/static/provider/cloud/deploy.yaml | kubectl apply -f -
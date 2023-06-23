#!/bin/bash

for arg in $(cat ../.env | xargs);
do
	gh secret set $(echo $arg | cut -d '=' -f 1) --body $(echo $arg | cut -d '=' -f 2)
done

#gh secret set AWS_ROLE_ARN $(aws iam get-role --role-name SF-Admin | jq '.Role.Arn' | tr -d '"')

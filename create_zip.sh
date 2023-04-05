#!/bin/bash
rm express-aws.zip
echo * .* | sed 's/node_modules//;s/dist//;s/.git//;s/.env//' | xargs zip -r express-aws.zip
aws s3 cp ./express-aws.zip s3://valerio-bucket-s3/deployment/express-aws.zip
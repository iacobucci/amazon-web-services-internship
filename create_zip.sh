#!/bin/bash
rm express-aws.zip

ignore="node_modules dist .git .env"

s=""
for i in $ignore; do
    s="$s s/$i//;"
done
echo * .* | sed "$s" | xargs zip -r express-aws.zip
aws s3 cp ./express-aws.zip s3://valerio-bucket-s3/deployment/express-aws.zip
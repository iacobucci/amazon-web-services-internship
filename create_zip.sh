#!/bin/bash
rm express-aws-declarative.zip

ignore="node_modules dist .git .env"

s=""
for i in $ignore; do
    s="$s s/$i//;"
done
echo * .* | sed "$s" | xargs zip -r express-aws-declarative.zip
aws s3 cp ./express-aws-declarative.zip s3://valerio-bucket-s3/deployment/express-aws-declarative.zip
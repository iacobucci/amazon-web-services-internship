
// WIP!! da qui si dovrà spostare tutto in moduli di es6 per webpack (magari passando per typescript)
  
import { S3Client } from "@aws-sdk/client-s3";
// Set the AWS Region.
const REGION = "eu-north-1"; //e.g. "us-east-1"
// Create an Amazon S3 service client object.
const s3Client = new S3Client({ region: REGION });

const params = {
  Bucket: "valerio-bucket-s3", // The name of the bucket. For example, 'sample-bucket-101'.
  Key: "file_node.txt", // The name of the object. For example, 'sample_upload.txt'.
  Body: "hello", // The content of the object. For example, 'Hello world!".
};

import { PutObjectCommand } from "@aws-sdk/client-s3";

const run = async () => {
  const results = await s3Client.send(new PutObjectCommand(params));
  console.log(
    "Successfully created " +
    params.Key +
    " and uploaded it to " +
    params.Bucket +
    "/" +
    params.Key
  );
  return results; // For unit tests.
};

run();


// const express = require('express')
// const app = express()
// const port = 3000

// app.get('/', (req, res) => {
//   res.send('Hello World!')
// })

// app.listen(port, () => {
//   console.log(`Example app listening on port ${port}`)
// })

import { GetObjectCommand, PutObjectCommand, ListObjectsCommand, S3Client } from "@aws-sdk/client-s3";
import express, { Request, Response } from "express";
import path from "path";
import dotenv from "dotenv";
import mysql from "mysql";
import { v4 as uuidv4 } from 'uuid';

const REGION = "eu-north-1";
const s3Client = new S3Client({ region: REGION });

const app = express();
const port = process.env.PORT || 3000;

import { fileURLToPath } from 'url';
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();
// load environment variables from /var/www/efs/.env if it exists
dotenv.config({ path: "/var/www/efs/.env" });

const s3config = {
  Bucket: process.env.S3_BUCKET,
};

let dbconn: any = null;

async function connectToDb(): Promise<void> {
  return new Promise<void>((resolve, reject) => {
    if (dbconn) {
      resolve();
      return;
    }
    dbconn = mysql.createConnection({
      host: process.env.RDS_HOSTNAME,
      user: process.env.RDS_USERNAME,
      password: process.env.RDS_PASSWORD,
      database: process.env.RDS_DATABASE,
    });
    dbconn.connect((err) => {
      if (err) {
        reject(err);
      } else {
        console.log("Connected to database at " + process.env.RDS_HOSTNAME);
        resolve();
      }
    });
  });
}

connectToDb().then(() => {
  app.get("/", (req: Request, res: Response) => {
    res.sendFile(__dirname + "/index.html");
  });

  app.get("/create", (req: Request, res: Response) => {
    var content: string = req.query.content as string;

    var A = uuidv4();
    var B = uuidv4();

    //save string to s3 with A as key
    const params = {
      Bucket: s3config.Bucket,
      Key: B,
      Body: content,
    };

    s3Client.send(new PutObjectCommand(params)).then(() => {
      console.log("new " + B);

      dbconn.query("INSERT INTO node.tab1 (A,B) VALUES (?,?)", [A, B], (err, result, fields) => {
        if (err) throw err;

        res.send(A);
      });

    }).catch((err) => {
      console.log(err);
    });
  });

  app.get("/read", (req: Request, res: Response) => {
    var A: string = req.query.id as string;
    var B: string;

    dbconn.query("SELECT B FROM node.tab1 WHERE A = ?", [A], (err, result, fields) => {
      if (err) throw err;
      B = result[0].B;
      const params = {
        Bucket: s3config.Bucket,
        Key: B,
      };

      console.log("access " + B);

      s3Client.send(new GetObjectCommand(params)).then((data) => {
        data.Body.transformToByteArray().then((data) => {
          var td: TextDecoder = new TextDecoder();
          res.send(td.decode(data));
        });

      }).catch((err) => {
        console.log(err);
      });
    }); //get B from rds

  });

  app.get("/list", (req: Request, res: Response) => {
    dbconn.query("SELECT A FROM node.tab1", (err, result, fields) => {

      res.send(result.map((row: any) => row.A).join(", "));

    });
  });

  app.listen(port, () => {
    console.log(`express-aws started on port ${port}`);
  });

}).catch((err) => {
  console.log(err);
});
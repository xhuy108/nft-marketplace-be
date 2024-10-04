// import express from "express";
// import rateLimit from "express-rate-limit";

const express = require('express')
const dotenv = require('dotenv')
const mongoose = require('mongoose')
const routes = require('./routes/auth.route')
const bodyParter = require('body-parser')
const cors = require('cors')
const fileUpload = require('express-fileupload');
dotenv.config()


const app = express();
const port = 3001;

app.use(bodyParter.json({ limit: '50mb' }));
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use(fileUpload({
    useTempFiles: true,
    tempFileDir: '/tmp/',
    limits: { fileSize: 50 * 1024 * 1024 } // Giới hạn kích thước tệp là 50MB
}));

routes(app);
mongoose.connect('mongodb+srv://ngotrungquan1412:J0AAd9Xgad0eU75d@nftmarketplace.lyc7n.mongodb.net/')
    .then(() => {
        console.log("Connect success");
    })
    .catch((err) => {
        console.log(err);
    })

app.listen(port, () => {
    console.log('Server is running in port ' + port);
})


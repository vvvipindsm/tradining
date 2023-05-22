// import "dotenv/config";
const fs = require("fs");
const open = require("open");
require("ejs")
const cors = require("cors");
const db = require("./models");
const order_route = require("./route/order");
const tutorial_route = require("./route/tutorial");
const stockPicks = require("./route/stockPicks");
const trades_route = require("./route/trade");
const express = require("express");
const bodyparser = require("body-parser");
require('dotenv').config()



const app = express();
app.use(express.static('public'))
app.use(cors());
app.use(bodyparser.urlencoded({extended:false}))
app.use(bodyparser.json())
app.use("/api/order", order_route);
app.use("/api/data_analysis", tutorial_route);
app.use("/api/trades", trades_route);
app.use("/api/stock_pickes", stockPicks);
app.set('view engine', 'ejs')


// db.sequelize.sync()
//   .then(() => {
//     console.log("Synced db.");
//   })
//   .catch((err) => {
//     console.log("Failed to sync db: " + err.message);
//   });
app.listen(3000,() => console.log(`Example app listening on port 3000!`));

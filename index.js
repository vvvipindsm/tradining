// import "dotenv/config";
const fs = require("fs");
const open = require("open");
require("ejs")
const cors = require("cors");

const order_route = require("./route/order");

const express = require("express");
const bodyparser = require("body-parser");
require('dotenv').config()



const app = express();
app.use(express.static('public'))
app.use(cors());
app.use(bodyparser.urlencoded({extended:false}))
app.use(bodyparser.json())
app.use("/api/order", order_route);
app.set('view engine', 'ejs')
// app.get("/api/init", (req, res) => {
//   const api_secert = "sdsdsf";
//   const api_key = "8awvtofko79ukeoj";
//   const kc = new KiteConnect({
//     api_key: "8awvtofko79ukeoj",
//   });
  const access_key = "dfdfdf";
  // fs.appendFile(
  //   "keys/keys.json",
  //   `{ 
  //   "data" : "${access_key}"
  // }`,
  //   function (err) {
  //     if (err) throw err;
  //     console.log("Saved!");
  //   }
  // );
  // open(kc.getLoginURL());
  // console.log("kc", kc.getLoginURL());

//   kc.generateSession("request_token", api_secert)
//     .then(function (response) {
//       init();
//       console.log("rs", response);
//     })
//     .catch(function (err) {
//       console.log(err);
//     });
// });

app.listen(3000, () => console.log(`Example app listening on port 3000!`));

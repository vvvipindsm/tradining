const accessKeyFile = require("../keys/keys.json");
const yahooFinance = require("yahoo-finance");
const path = require('path')
const get = require("lodash.get");
const moment = require("moment");
const csv = require("csvtojson");
let { SmartAPI, WebSocket } = require("smartapi-javascript");
const { authenticator } = require('otplib');
const stockList = require("../csv/data");
const API_KEY = "Q1TIE8hH"
const testDebug = false;
// const get = require('lodash.get')
// const start_data = '2000-01-01';
const Instrument = require('../localData/Instrument')
const start_data = "2022-06-01";
const end_date = moment().format("YYYY-MM-DD");
const timeF = "d"; //'w' , 'm'
const limitPer = 30;
const SEND_ITEM_COUNT = 3;
const dlog = (preText = "", obj = []) => {
  if (testDebug) console.log(preText, obj);
};
const setUpperNdLowerLimit = (currentPrice) => {
  currentPrice = Math.round(currentPrice);
  const limit = (currentPrice * limitPer) / 100;
  return limit;
};
const INTEVAL_TIME = 10000

const rounding = (lastPrice) => {
  let splitAr = lastPrice.toString().split(".");

  if (get(splitAr, "length", 1) == 1) {
    return lastPrice;
  }
  const trucPoint = splitAr[1].slice(0, 2);

  let pointPrice = parseInt(trucPoint);
  pointPrice = pointPrice < 9 ? pointPrice * 10 : pointPrice;
  pointPrice;
  if (pointPrice > 0 && pointPrice < 30) {
    return Math.floor(lastPrice);
  } else if (pointPrice > 70 && pointPrice < 100) {
    return Math.ceil(lastPrice);
  } else {
    splitAr[1] = 50;
    return parseFloat(splitAr.join("."));
  }
};
const VPBasedStretegy = async (data) => {
  const lastPrice = data[0].close;
  let finalRlt = [];
  try {
    dlog("total obj", data);

    dlog("last price ", lastPrice);
    const limit = setUpperNdLowerLimit(lastPrice);
    const upperLimitNdLower = {
      upper: lastPrice + limit,
      lower: lastPrice - limit,
    };
    dlog("upperlimit  ", upperLimitNdLower);
    //change to buy to sell for buy >
    const dataFilteredWithLimit = data.filter(
      (item) =>
        item.close < item.open &&
        item.close >= upperLimitNdLower.lower &&
        item.close <= upperLimitNdLower.upper
    );

    if (dataFilteredWithLimit.length == 0) return [];

    dataFilteredWithLimit.map((d) => {
      let closePrice = rounding(d.close);
      console.log(closePrice);
      let checkAlreadyHaving = false;
      if (finalRlt.length > 0) {
        finalRlt.map((d, idx) => {
          // console.log(d.close+":"+closePrice,d.close == closePrice);
          if (d.close == closePrice) {
            checkAlreadyHaving = idx;
          } else {
            checkAlreadyHaving = false;
          }
        });
      }

      if (!checkAlreadyHaving) {
        finalRlt.push({ vol: d.volume, close: closePrice });
      } else {
        finalRlt[checkAlreadyHaving].vol += d.volume;
      }

      // return { close: d.close, vol: d.vol }
    });
    finalRlt = finalRlt.filter((d) => d !== "");
    finalRlt = finalRlt.filter((d) => d.close < lastPrice);
    finalRlt.sort(function (a, b) {
      return b.vol - a.vol;
    });
  } catch (error) {
    dlog("error vpstr", error);
  }

  return { res: finalRlt.slice(0, SEND_ITEM_COUNT), lastPrice: lastPrice };
};
const sleep = ms => new Promise(r => setTimeout(r, ms));

const fetchSymbolData = (symbol = "AAPL") => {
  return new Promise(async (resolve, reject) => {
    console.log(symbol);
    try {
      await sleep(INTEVAL_TIME)
      yahooFinance.historical(
        {
          symbol,
          from: start_data,
          to: end_date,
          period: timeF, // 'd' (daily), 'w' (weekly), 'm' (monthly), 'v' (dividends only)
        },
        async (err, quotes) => {
          if (err) {
            console.log("error",err);
            reject(false);
          } else {
            console.log(quotes);
            dlog("fetch from yfina", quotes.length);
            if (quotes.length == 0) reject(false);
            console.log(get(quotes,'[0].close',false));
            if(!get(quotes,'[0].close',false)) {
              reject(false)
              return
            }
            const { res, lastPrice } = await VPBasedStretegy(quotes);
            dlog("root responsed after VP str");
            resolve({ res, symbol, lastPrice });
          }
        }
      );
    } catch (error) {
      console.log("erro", error);
      resolve(false);
    }
  });
};

module.exports = {
  takeOrder :async (req,res)=>{
    const {refreshToken ,token,
      tradingsymbol,
      symboltoken,transactiontype,exchange,
      producttype,quantity,price } = req.body;
       
    let smart_api = new SmartAPI({
      api_key: API_KEY,
      access_token : token,
      refresh_token : refreshToken
    });
    const parms = {
      "variety":"NORMAL",
      "tradingsymbol":tradingsymbol,
      "symboltoken":symboltoken,
      "transactiontype":transactiontype, //"BUY"
      "exchange":exchange,
      "ordertype":"MARKET",
      "producttype":producttype,//"INTRADAY",
      "duration":"DAY",
      // "price":"194.50",
      "squareoff":"0",
      "stoploss":"0",
      "quantity":quantity,//"50"
    }
    console.log(parms);
    const result = await smart_api.placeOrder(parms)
    console.log(result);
    res.send({status : result})
  },
  getVolstregry: (req, res) => {
    // const symbols = ["DRREDDY.NS","AAPL","KRBL","KRBL.NS","GESHIP.NS","RBLBANK.NS"];
    const symbols = stockList

    Promise.allSettled(symbols.map((d) => fetchSymbolData(d))).then(
      (resulArr) => {
        if (resulArr.length) {
          const formatedData = [];
          resulArr.map(async (d) => {
            if (d.status == "fulfilled") {
              console.log(resulArr);
              formatedData.push({
                symbols: d.value.symbol,
                lastPrice: d.value.lastPrice,
                data: d.value.res,
              });
            }
          });
          const sortedResult = formatedData.sort(
            (a, b) =>
              a.lastPrice - a.data[0].close - (b.lastPrice - b.data[0].close)
          );

          res.send(sortedResult);
        } else {
          tlog("failed from root order.js 51");
          res.send("not data found");
        }

        // console.log('Waited enough!',resu)
      }
    );

    // res.send({ hh: end_date });
  },
  setUpFile: (req,res) => {
    csv()
    .fromFile('../csvFile/stock.csv')
    .then(function(jsonArrayObj){ //when parse finished, result will be emitted here.
       console.log(jsonArrayObj); 
     })
    res.send({ff :123})
  },
  setUpAlog : async (req,res)=>{
    const {otp} = req.body
    const CLIENT_CODE = "V154772"
    const API_KEY = "Q1TIE8hH"
    const CLIENT_PASS = process.env.PASSWORD

    let smart_api = new SmartAPI({
      api_key: API_KEY
    });

    const data = await smart_api.generateSession(CLIENT_CODE, CLIENT_PASS,otp)
 
    res.send({status : data})
  },
  getOrders : async (req,res)=>{
    const {refreshToken ,token } = req.body;
       
    let smart_api = new SmartAPI({
      api_key: API_KEY,
      access_token : token,
      refresh_token : refreshToken
    });
    const profileInfo = await smart_api.getTradeBook()
    console.log(profileInfo);
    res.send({status : profileInfo})
  },
  dashboard : async (req,res)=> {
    // res.send({sdf: 'dfds'})
    const payload = {
      baseURl: 'http://localhost:3000/api/',
    }
      res.render(path.join(__dirname,'../templates/dashboard'),{payload})
  },
  placeOrder: async (req,res)=> {
    // {"token":"11983","symbol":"SASKEN-EQ",
    // "name":"SASKEN","expiry":"","strike":"-1.000000",
    // "lotsize":"1","instrumenttype":"","exch_seg":"NSE",
    // "tick_size":"5.000000"}
    const payload = {
      baseURl: 'http://localhost:3000/api/',
      Instrument : Instrument.Instrument
    }
    res.render(path.join(__dirname,'../templates/placeOrder'),{payload})
  }
};

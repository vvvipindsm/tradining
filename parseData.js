const data = require('./csv/data.json')
const fs = require('fs')
const dd = require('./csv/data')

const parseDat = data.map(d=>{

    return `"${d.Ticker}.${d.Exchange == "NSE"?"NS":"BO"}"`
})

const parseData = `const stockList = [${parseDat}]
module.exports = stockList `

fs.writeFile('./csv/data.js',parseData, (err)=>{
    console.log("store",err);
})
const db = require("../models");
const Tutorial = db.tutorials;
const Op = db.Sequelize.Op;
const seq = require("sequelize");
const yfData = require("../csv/eurusd");
const moment = require("moment");
const cotData = require("../csv/cotData");

exports.getAllCotReport = async (req, res) => {
  //chart data start date should be greater than db date

  const cotDbData = await db.sequelize.query("SELECT * FROM cot_report", {
    type: seq.QueryTypes.SELECT,
  });


  return res.json(cotDbData);
};

// Retrieve all Tutorials from the database.
exports.findAll = async (req, res) => {
  //chart data start date should be greater than db date

  const cotDbData = await db.sequelize.query("SELECT * FROM cot_report", {
    type: seq.QueryTypes.SELECT,
  });
  cotDbData.sort((a, b) => {
    const aa = moment(a.dates);
    const bb = moment(b.dates);
    const status = aa.diff(bb, "days");
    return status < 0 ? -1 : status;
  });
 
  for (let i = 0; i < cotDbData.length; i++) {
    let idx = Math.ceil(i == 0 ? 1 : i / 8);
    idx = idx - 1;
    try {
      const chartDate = yfData[idx].date.split(" ")[0];
      console.log("trend",yfData[idx].Trend,"id : ",idx,"cot full size", cotDbData.length)
      cotDbData[i]["chartDate"] = chartDate;
      cotDbData[i]["Trend"] = yfData[idx].Trend;
    } catch (error) {}
  }

  return res.json(cotDbData);
};

exports.insertTODb = async (req, res) => {
  let insertString = "";
  cotData[0].forEach((rw, key) => {
   console.log(rw['dealer_long'],key)
    insertString += "('"+rw['chartDate']+"','"+rw['Trend']+"','"+rw['name']+"',"+rw['open_interest']+","+rw['non_long']+","+rw['non_short']+","+rw['com_long']+","+rw['com_short']+","+rw['non_repo_long']+","+rw['non_repo_short']+","+rw['dealer_long']+","+rw['dealer_short']+","+rw['asset_long']+","+rw['asset_short']+","+rw['leve_long']+","+rw['leve_short']+",'"+rw['dates']+"')";
    if((cotData[0].length) != ( key +1) ) {
      insertString += ",";
    }
  });

  const sqlQuery =
    "INSERT INTO cot_report (chartDate,real_status,name,open_interest,non_long,non_short,com_long,com_short,non_repo_long,non_repo_short,dealer_long,dealer_short,asset_long,asset_short,leve_long,leve_short,dates) VALUES " +
    insertString;
  console.log(sqlQuery);
   const insertTODb = await db.sequelize.query(sqlQuery, {
      type: seq.QueryTypes.INSERT,
    });
  return res.json({ data: "cotData" });
};

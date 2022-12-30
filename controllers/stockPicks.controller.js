const db = require("../models");
const Stockpicks = db.stockpicks;
const Op = db.Sequelize.Op;
const intr = require("../localData/Instrument")
// Create and Save a new Tutorial
exports.create = (req, res) => {
  // Create a Tutorial
  const tutorial = {
    token: req.body.token,
    symbol: req.body.symbol,
    name: req.body.name,
    exch_seg: req.body.exch_seg,
  }
  // Save Tutorial in the database 
  Stockpicks.create(tutorial)
    .then((data) => {
      res.send(data);
    })
    .catch((err) => {
      res.status(500).send({
        message:
          err.message || "Some error occurred while creating the Tutorial.",
      });
    });
};
// Retrieve all Tutorials from the database.
exports.findAll = (req, res) => {
  Stockpicks.findAll({
    order: [
      ['id', 'DESC']
    ]})
    .then((data) => {
      res.send(data);
    })
    .catch((err) => {
      res.status(500).send({
        message:
          err.message || "Some error occurred while retrieving tutorials.",
      });
    })
  
};
exports.getIntruments = (req, res) => {
    const data = intr.Instrument
    const ress = data.filter(it=>it.symbol.includes('-EQ'))
    res.send(ress);
};
exports.findStock = async (req,res) => {
  const name = req.query.name
  console.log(name);
  Stockpicks.findOne({
    where : {
      name : name
    },
    order: [
      ['id', 'DESC']
    ]})
    .then((data) => {
      res.send(data);
    })
    .catch((err) => {
      res.status(500).send({
        message:
          err.message || "Some error occurred while retrieving tutorials.",
      });
    })
 
}

exports.delete = (req, res) => {
  const id = req.params.id
  Stockpicks.destroy({
    where : {
      id : id
    }
  })
    .then((data) => {
      res.status(200).send(data);
    })
    .catch((err) => {
      res.status(200).send(err);
    })
  
};
exports.resetAll = (req, res) => {

  Stockpicks.destroy({
    where: {},
    truncate: true
  })
    .then((data) => {
      res.status(200).send(data);
    })
    .catch((err) => {
      res.status(200).send(err);
    })
  
};




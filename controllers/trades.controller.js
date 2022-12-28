const db = require("../models");
const Trades = db.trades;
const Op = db.Sequelize.Op;
const moment = require('moment')
// Create and Save a new Tutorial
exports.create = (req, res) => {

    // Create a Tutorial
    const trades = {
      sybol: req.body.sybol,
      typeoftrade: req.body.typeoftrade,
    
    };
  
    // Save Tutorial in the database
    Trades.create(trades)
      .then(data => {
        res.send(data);
      })
      .catch(err => {
        res.status(500).send({
          message:
            err.message || "Some error occurred while creating the Tutorial."
        });
      });
  };
// Retrieve all Tutorials from the database.
// exports.findAll = (req, res) => {

//     const tutorial = {
//         title: req.body.title,
//         description: req.body.description,
//         published: true
//       };
    
//       // Save Tutorial in the database
//       Tutorial.create(tutorial)
//         .then(data => {
//             res.send(data);
//             // Tutorial.findAll()
//             // .then(data => {
//             //   res.send(data);
//             // })
//             // .catch(err => {
//             //   res.status(500).send({
//             //     message:
//             //       err.message || "Some error occurred while retrieving tutorials."
//             //   });
//             // });
//         })
//         .catch(err => {
      
//         });
   

// };

exports.resetAll = (req, res) => {
  Trades.destroy({
    where: {},
    truncate: false
  })
    .then(nums => {
      res.send({ message: `${nums} Tutorials were deleted successfully!` });
    })
    .catch(err => {
      res.status(500).send({
        message:
          err.message || "Some error occurred while removing all tutorials."
      });
    });
};

exports.find = (req, res) => {
  const title = req.query.sybmol;
  const condition = title ? { 
    [Op.and]: [
      {sybol: { [Op.iLike]: `%${title}%` }  },
      {createdAt: {[Op.gte]: moment().startOf('day').subtract(0, 'days').toDate()}  },

    ]} : null;
  console.log(title,"condi",condition);
  Trades.findAll({ where: condition })
    .then(data => {
      res.send({
        status : (data.length)?true:false,
        msg : (data.length)?"Already having take order":"Freash"
      }
        );
    })
    .catch(err => {
      res.status(500).send({
        message:
          err.message || "Some error occurred while retrieving tutorials."
      });
    });
};




module.exports = (sequelize, Sequelize) => {
    const Trade = sequelize.define("trade", {
      sybol: {
        type: Sequelize.STRING
      },
      typeoftrade: {
        type: Sequelize.STRING
      }
    });
  
    return Trade;
  };
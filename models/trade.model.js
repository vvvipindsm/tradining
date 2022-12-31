module.exports = (sequelize, Sequelize) => {
    const Trade = sequelize.define("trade", {
      sybol: {
        type: Sequelize.STRING
      },
      typeoftrade: {
        type: Sequelize.STRING
      },
      orderId: {
        type: Sequelize.STRING
      },
      token: {
        type: Sequelize.STRING
      },
      isCompleted: {
        type: Sequelize.BOOLEAN
      }
    });
  
    return Trade;
  };
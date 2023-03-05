module.exports = (sequelize, Sequelize) => {
    const TradeHis = sequelize.define("trade_his", {
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
  
    return TradeHis;
  };
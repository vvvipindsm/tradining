module.exports = (sequelize, Sequelize) => {
    const StockPicks = sequelize.define("stockpick", {
      token: {
        type: Sequelize.STRING
      },
      symbol: {
        type: Sequelize.STRING
      },
      name: {
        type: Sequelize.STRING
      },
      exch_seg: {
        type: Sequelize.STRING
      },
    });
  
    return StockPicks;
  };
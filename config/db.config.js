module.exports = {
    HOST: "localhost",
    USER: "newuser",
    PASSWORD: "root",
    DB: "alog",
    dialect: "postgres",
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  };
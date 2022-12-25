const accessKeyFile = require("../keys/keys.json");
const keys = require("../keys/apiKey.json");
const KiteConnect = require("kiteconnect").KiteConnect;

module.exports = {
  authMiddle: (req, res, next) => {
    // console.log("accessKeyFile.data", accessKeyFile.data);
    // const kc = KiteConnect((api_keys = keys.api_key));
    // kc.set_access_token(accessKeyFile.data);
    // req.accessToken = accessKeyFile.data;
    next();
  },
};

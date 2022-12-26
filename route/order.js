const express = require("express");
const { authMiddle } = require("../middleware/auth");
const router = express.Router();

const order = require("../model/order");

router.post("/getOrder", authMiddle, order.getOrders);

router.get("/setUpFile",authMiddle, order.setUpFile);
router.post("/setUpAlog", authMiddle, order.setUpAlog);
router.get("/getVolstregry", authMiddle, order.getVolstregry);
router.post("/takeOrder", authMiddle, order.takeOrder);
//view
router.get("/dashboard", authMiddle, order.dashboard);
router.get("/placeOrder", authMiddle, order.placeOrder);



module.exports = router;

const express = require("express");
const { authMiddle } = require("../middleware/auth");
const router = express.Router();

const order = require("../model/order");

router.get("/getVolstregry", authMiddle, order.getOrders);

router.get("/setUpFile", order.setUpFile);
router.post("/setUpAlog", authMiddle, order.setUpAlog);
router.post("/getOrders", authMiddle, order.getOrders);
//view
router.get("/dashboard", authMiddle, order.dashboard);




module.exports = router;

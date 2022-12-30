const express = require("express");
const { authMiddle } = require("../middleware/auth");
const router = express.Router();

const stockPicks = require("../controllers/stockPicks.controller");

router.post("/stock", authMiddle, stockPicks.create);
router.get("/stock", authMiddle, stockPicks.findAll);
router.delete("/stock/:id", authMiddle, stockPicks.delete);
router.delete("/stockr/resetAll", authMiddle, stockPicks.resetAll);


router.get("/intruments", authMiddle, stockPicks.getIntruments);
router.get("/stock_find", authMiddle, stockPicks.findStock);


module.exports = router;

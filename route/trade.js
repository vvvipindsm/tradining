const express = require("express");
const { create ,resetAll,find,findALL,resetActive} = require("../controllers/trades.controller");
const { authMiddle } = require("../middleware/auth");
const router = express.Router();

router.post("/create", create);
router.get("/reset", resetAll);
router.get("/find", find);
router.get("/findAll", findALL);

router.get("/resetActiveAll", resetActive);

module.exports = router;

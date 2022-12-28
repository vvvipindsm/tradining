const express = require("express");
const { create ,resetAll,find} = require("../controllers/trades.controller");
const { authMiddle } = require("../middleware/auth");
const router = express.Router();

router.post("/create", create);
router.get("/reset", resetAll);
router.get("/find", find);



module.exports = router;

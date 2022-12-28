const express = require("express");
const { findAll } = require("../controllers/tutorial.controller");
const { authMiddle } = require("../middleware/auth");
const router = express.Router();

router.get("/find", findAll);



module.exports = router;

const express = require("express");
const { findAll,insertTODb } = require("../controllers/tutorial.controller");
const { authMiddle } = require("../middleware/auth");
const router = express.Router();

router.post("/cot", findAll);

router.post("/cotInsert", insertTODb);

module.exports = router;

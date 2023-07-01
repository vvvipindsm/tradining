const express = require("express");
const { findAll,insertTODb,getAllCotReport } = require("../controllers/tutorial.controller");
const { authMiddle } = require("../middleware/auth");
const router = express.Router();

router.get("/cot", findAll);

router.get("/getAllCot", getAllCotReport);
router.post("/cotInsert", insertTODb);

module.exports = router;

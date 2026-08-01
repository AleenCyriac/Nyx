const express = require("express");

const router = express.Router();

const chatController = require("../controllers/chatController");

router.post("/chat", chatController.postChat);
router.get("/messages", chatController.getChat);

module.exports = router;
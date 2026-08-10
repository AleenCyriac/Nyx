const express = require("express");

const router = express.Router();

const chatController = require("../controllers/chatController");

router.post("/chat", chatController.postChat);
router.get("/messages/:senderId/:receiverId", chatController.getChat);

module.exports = router;
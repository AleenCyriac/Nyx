const express = require("express");

const router = express.Router();

const userController = require("../controllers/userController");

router.get("/user/phone/:phone_no", userController.findUserByPhone); //add_contact_page(searchContact)
router.post("/contact", userController.saveContact); 
router.get("/contacts/:owner_user_id", userController.getContacts); 

module.exports = router;
const pool = require("../config/db");
exports.postChat = async (req, res) => {

    const { message } = req.body;
    await pool.query("INSERT INTO messages (message) VALUES ($1)", [message]);

     console.log("Received message:", message);
        res.json({
            success: true,
            message: "Message received"
        });
    };
exports.getChat = async (req, res) => {
    try {
        const messagesQuery = await pool.query("SELECT * FROM messages ORDER BY created_at ASC");
        res.json({
            success: true,
            messages: messagesQuery.rows
        });
       
    } catch (error) {
        console.error("Error occurred while fetching messages:", error);
        res.status(500).json({
            success: false,
            message: "An error occurred while fetching messages."
        });
    }
};
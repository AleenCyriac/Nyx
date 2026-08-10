const pool = require("../config/db");
exports.postChat = async (req, res) => {

    const { sender_id,receiver_id,message } = req.body;
    await pool.query("INSERT INTO messages (sender_id,receiver_id,message) VALUES ($1, $2, $3)", [sender_id, receiver_id, message]);


    
        res.json({
            success: true,
            message: "Message received"
        });
    };
exports.getChat = async (req, res) => {
    try {
        const { senderId, receiverId } = req.params;
         const messagesQuery = await pool.query(
            `SELECT *
             FROM messages
             WHERE
             (sender_id = $1 AND receiver_id = $2)
             OR
             (sender_id = $2 AND receiver_id = $1)
             ORDER BY created_at ASC`,
            [senderId, receiverId]
        );
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
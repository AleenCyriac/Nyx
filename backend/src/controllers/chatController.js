const pool = require("../config/db");

exports.postChat = async (req, res) => {
  try {
    const {
      sender_id,
      receiver_id,
      message,
      client_message_id,
    } = req.body;

    await pool.query(
      `INSERT INTO messages
        (sender_id, receiver_id, message, client_message_id)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (client_message_id) DO NOTHING`,
      [
        sender_id,
        receiver_id,
        message,
        client_message_id ?? null,
      ]
    );

    res.json({
      success: true,
      message: "Message saved",
    });
  } catch (error) {
    console.error("Error saving message:", error);
    res.status(500).json({
      success: false,
      message: "Failed to save message",
    });
  }
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
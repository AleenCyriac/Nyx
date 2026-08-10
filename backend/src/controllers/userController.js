const pool = require("../config/db");
exports.findUserByPhone = async (req, res) => {
    try {
        const { phone_no } = req.params;

        const userQuery = await pool.query(
            "SELECT id, name, phone_no FROM users WHERE phone_no = $1",
            [phone_no]
        );

        if (userQuery.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "User not found"
            });
        }

        res.json({
            success: true,
            user: userQuery.rows[0]
        });

    } catch (error) {
        console.error(error);

        res.status(500).json({
            success: false,
            message: "Server error"
        });
    }
};
exports.saveContact = async (req, res) => {
    try {
        const {
            owner_user_id,
            contact_user_id,
            display_name
        } = req.body;

        await pool.query(
            `INSERT INTO contacts
             (owner_user_id, contact_user_id, display_name)
             VALUES ($1, $2, $3)`,
            [
                owner_user_id,
                contact_user_id,
                display_name
            ]
        );

        res.json({
            success: true,
            message: "Contact saved"
        });

    } catch (error) {
        console.error(error);

        res.status(500).json({
            success: false,
            message: "Failed to save contact"
        });
    }
};

exports.getContacts = async (req, res) => {
    try {

        const { owner_user_id } = req.params;

        const contactsQuery =
            await pool.query(
                `SELECT
    contacts.contact_user_id,
    contacts.display_name,
    users.phone_no
FROM contacts
JOIN users
ON contacts.contact_user_id = users.id
WHERE contacts.owner_user_id = $1`,
                [owner_user_id]
            );

        res.json({
            success: true,
            contacts: contactsQuery.rows
        });

    } catch (error) {

        console.error(error);

        res.status(500).json({
            success: false,
            message: "Failed to fetch contacts"
        });
    }
};
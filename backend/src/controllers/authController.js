const pool = require("../config/db");
exports.login = async (req, res) => {

    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({
            success: false,
            message: "Email and password are required."
        });
    }

    try {
        const userQuery = await pool.query("SELECT * FROM users WHERE email = $1 AND password = $2", [email, password]);

        if (userQuery.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: "Invalid email or password."
            });
        }

        res.json({
            success: true,
            message: "Login successful.",
            userid: userQuery.rows[0]
        });

        
    } catch (error) {
        console.error("Error occurred while logging in:", error);
        return res.status(500).json({
            success: false,
            message: "An error occurred while logging in."
        }); 
    }

};

exports.signup = async (req, res) => {
    const { email, password, name, conform_password,phone_no } = req.body;

    if (!email || !password || !name ||!conform_password || !phone_no) {
        return res.status(400).json({
            success: false,
            message: "All fields are required."
        });
    }

    if (password != conform_password ) {
        return res.status(400).json({
            success: false,
            message: "Passwords do not match."
        });
    }

try{
    const existinguserQuery = await pool.query("SELECT * FROM users WHERE email = $1", [email]);

    if (existinguserQuery.rows.length > 0) {
        return res.status(400).json({
            success: false,
            message: "User with this email already exists."
        });
    }
    
   const query=` INSERT INTO users (name, email, password, phone_no)
VALUES($1, $2, $3, $4)`;

await pool.query(query, [name, email, password, phone_no]);

res.json({
        success: true,
        message: "User created successfully."
    });
} catch (error) {
    console.error("Error occurred while creating user:", error);
    return res.status(500).json({
        success: false,
        message: "An error occurred while creating the user."
    });
} 
};


const WebSocket = require("ws");
const pool = require("./config/db");
const express = require("express");
const cors = require("cors");
const app = express();


app.use(cors());
app.use(express.json());

const authRoutes = require("./routes/authRoutes");
app.use(authRoutes);

const chatRoutes = require("./routes/chatRoutes");
app.use(chatRoutes);

const PORT = 3000;

app.get("/", (req, res) => {
    res.send("Hybrid Chat Backend is running!");
});

pool.query("SELECT NOW()", (err, result) => {
    if (err) {
        console.error("Database connection failed:", err.message);
    } else {
        console.log("Database connected!");
        console.log(result.rows[0]);
    }
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
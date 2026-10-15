const pool = require("./config/db");
const express = require("express");
const cors = require("cors");
const app = express();

const { Server } = require("socket.io");
const http = require("http");
const server = http.createServer(app);

const onlineUsers = {};

const io = new Server(server, {
    cors: {
        origin: "*",
    },
});
io.on("connection", (socket) => {

    console.log("User connected:", socket.id);

socket.on("register_user", (userId) => {

    onlineUsers[userId] = socket.id;
     console.log(`User ${userId} registered with socket ${socket.id}` );    
});
// Handle incoming messages and sends to receiver if they are online   
socket.on("send_message", (data) => {
     console.log("Message received:");
        console.log(data);

    const receiverSocket =
        onlineUsers[data.receiver_id];

    if (receiverSocket) {

        io.to(receiverSocket).emit(
            "receive_message",
            data,
        );

    }else {
            console.log(
                `User ${data.receiver_id} is not online`
            );
        }

});
socket.on("disconnect", () => {
        console.log("User disconnected:", socket.id);
    for (const userId in onlineUsers) {
        if (onlineUsers[userId] === socket.id) {
            delete onlineUsers[userId];

            console.log(
                `User ${userId} removed from online users`
            );

            break;
        }
    }
});
    });


io.on("disconnect", (socket) => {
    console.log("User disconnected:", socket.id);
});

app.use(cors());
app.use(express.json());

const authRoutes = require("./routes/authRoutes");
app.use(authRoutes);

const chatRoutes = require("./routes/chatRoutes");
app.use(chatRoutes);

const userRoutes = require("./routes/userRoutes");
app.use(userRoutes);

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

server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});

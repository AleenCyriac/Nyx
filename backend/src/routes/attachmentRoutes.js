
const express = require("express");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const crypto = require("crypto");

const router = express.Router();

const uploadDirectory = path.join(__dirname, "../../uploads");

fs.mkdirSync(uploadDirectory, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, callback) => {
    callback(null, uploadDirectory);
  },
  filename: (_req, file, callback) => {
    const extension = path.extname(file.originalname).slice(0, 20);
    callback(null, `${crypto.randomUUID()}${extension}`);
  },
});

const upload = multer({
  storage,
  limits: {
    fileSize: 100 * 1024 * 1024,
  },
});

router.post("/", (req, res) => {
  upload.single("file")(req, res, (error) => {
    if (error) {
      const status = error.code === "LIMIT_FILE_SIZE" ? 413 : 400;
      return res.status(status).json({
        success: false,
        message: error.message || "Upload failed",
      });
    }

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "No file was uploaded",
      });
    }

    // Return metadata first. The next step will connect this
    // upload route to your existing chat-message persistence.
    res.json({
      success: true,
      attachment: {
        file_name: req.file.originalname,
        file_size: req.file.size,
        mime_type: req.file.mimetype,
        file_url: `/attachments/files/${req.file.filename}`,
      },
    });
  });
});

router.get("/files/:filename", (req, res) => {
  const filename = req.params.filename;

  // Only accept generated UUID filenames with a short extension.
  if (!/^[0-9a-f-]{36}(?:\.[a-zA-Z0-9]{1,20})?$/.test(filename)) {
    return res.status(400).json({
      success: false,
      message: "Invalid file name",
    });
  }

  const filePath = path.join(uploadDirectory, filename);

  if (!fs.existsSync(filePath)) {
    return res.status(404).json({
      success: false,
      message: "File not found",
    });
  }

  res.setHeader("X-Content-Type-Options", "nosniff");
  res.download(filePath);
});

module.exports = router;

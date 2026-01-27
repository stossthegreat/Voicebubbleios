// backend/routes/extract.js

import express from "express";
import { extractOutcomes, extractUnstuck } from "../controllers/extractcontroller.js";

const router = express.Router();

// Extract outcomes from text (for Outcomes preset)
router.post("/outcomes", extractOutcomes);

// Extract insight + action from text (for Unstuck preset)
router.post("/unstuck", extractUnstuck);

export default router;

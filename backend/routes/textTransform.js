// backend/routes/textTransform.js

import express from 'express';
import { transformText } from '../controllers/textTransformController.js';

const router = express.Router();

/**
 * POST /api/transform/text
 * Transform selected text using AI
 */
router.post('/text', transformText);

export default router;
import google.generativeai as genai
import os
from dotenv import load_dotenv
import json

load_dotenv()
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

def process_image_with_gemini(image_bytes, mime_type):
    """
    Uses Gemini 1.5 Flash to extract text and generate all study materials at once.
    Returns a JSON-formatted string containing summary, quiz, and cards.
    """
    if not os.getenv("GEMINI_API_KEY"):
        return "Error: GEMINI_API_KEY missing."

    try:
        model = genai.GenerativeModel('gemini-1.5-flash')
        
        prompt = """
        Analyze this study material and provide:
        1. A comprehensive summary.
        2. A 3-question multiple choice quiz (with options and correct answer).
        3. 3 Flashcards (Question and Answer pairs).
        
        Return the output ONLY as a valid JSON object with the following keys:
        {
          "summary": "...",
          "quiz": [{"question": "...", "options": ["A", "B", "C", "D"], "answer": "..."}],
          "cards": [{"front": "...", "back": "..."}]
        }
        """
        
        response = model.generate_content([
            prompt,
            {"mime_type": mime_type, "data": image_bytes}
        ])
        
        # Clean the response to ensure it's valid JSON
        text = response.text.strip()
        if "```json" in text:
            text = text.split("```json")[1].split("```")[0].strip()
        
        return text
    except Exception as e:
        return f"Error: {str(e)}"

def summarize_text(text):
    """Fallback if Gemini Vision fails but we have extracted text"""
    try:
        model = genai.GenerativeModel('gemini-1.5-flash')
        response = model.generate_content(f"Summarize this study text and provide 3 quiz questions and 3 flashcards in JSON format: {text}")
        return response.text
    except:
        return "Summary generation failed."

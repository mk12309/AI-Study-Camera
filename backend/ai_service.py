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
        model = genai.GenerativeModel('gemini-1.5-flash-latest')
        
        prompt = """
        You are an expert tutor. Analyze this study material and provide:
        1. A comprehensive summary titled "summary".
        2. A 3-question multiple choice quiz titled "quiz" (each question must have 'question', 'options' list, and 'answer').
        3. 3 Flashcards titled "cards" (each with 'front' and 'back').
        
        CRITICAL: Return the output ONLY as a single valid JSON object. 
        Do not include any intro or outro text.
        
        Structure:
        {
          "summary": "Full summary text here...",
          "quiz": [{"question": "...", "options": ["...", "..."], "answer": "..."}],
          "cards": [{"front": "...", "back": "..."}]
        }
        """
        
        response = model.generate_content([
            prompt,
            {"mime_type": mime_type, "data": image_bytes}
        ])
        
        # Robust cleaning of the response
        text = response.text.strip()
        
        # Remove any leading/trailing non-JSON characters
        if "{" in text:
            text = text[text.find("{"):text.rfind("}")+1]
        
        # Replace common AI formatting issues
        text = text.replace("```json", "").replace("```", "").strip()
        
        print(f"DEBUG: Gemini Raw Cleaned Text: {text[:100]}...")
        return text
    except Exception as e:
        return f"Error: {str(e)}"

def summarize_text(text):
    """Fallback if Gemini Vision fails but we have extracted text"""
    try:
        model = genai.GenerativeModel('gemini-1.5-flash-latest')
        response = model.generate_content(f"Summarize this study text and provide 3 quiz questions and 3 flashcards in JSON format: {text}")
        return response.text
    except:
        return "Summary generation failed."

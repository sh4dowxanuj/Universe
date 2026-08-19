# Sh4dowXanuj YouTube Bridge

This is a FastAPI-based backend that uses `yt-dlp` to provide YouTube streaming and search capabilities to the Universe Flutter Web app.

## Local Setup

1. Install Python 3.10+
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Run the server:
   ```bash
   python main.py
   ```
   The server will run at `http://localhost:8000`.

## Deployment

You can deploy this folder to **Render**, **Railway**, or **Fly.io**.

### Steps for Render:
1. Push this folder to a GitHub repository.
2. Create a new "Web Service" on Render.
3. Select your repository.
4. Render will detect the `requirements.txt` and `Procfile`.
5. Once deployed, copy your service URL (e.g., `https://sh4dowxanuj.onrender.com`).
6. Update the `bridgeUrl` in `lib/Services/ytdlp/ytdlp_service_web.dart` in your Flutter project.

### Why do I need this?
Browsers cannot run the Python-based `yt-dlp` library directly, and they block direct YouTube requests due to CORS. This bridge handles the extraction on the server and provides CORS-compliant responses to your web app.

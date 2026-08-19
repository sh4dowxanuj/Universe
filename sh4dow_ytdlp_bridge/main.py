from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
import yt_dlp
import uvicorn
import os

app = FastAPI(title="Sh4dowXanuj YtDlp Bridge")

# Allow your Flutter Web app to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, replace with your web app's URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_ydl_options(extract_flat=False):
    return {
        'format': 'bestaudio/best',
        'quiet': True,
        'no_warnings': True,
        'extract_flat': extract_flat,
        'skip_download': True,
        'nocheckcertificate': True,
        'ignoreerrors': True,
        'logtostderr': False,
        'no_color': True,
    }

@app.get("/")
async def root():
    return {"message": "Sh4dowXanuj YouTube Bridge is running!"}

@app.get("/getAudioStream")
async def get_audio_stream(videoId: str, quality: str = "High"):
    url = f"https://www.youtube.com/watch?v={videoId}"
    try:
        with yt_dlp.YoutubeDL(get_ydl_options()) as ydl:
            info = ydl.extract_info(url, download=False)
            if not info:
                raise HTTPException(status_code=404, detail="Video not found")

            # Simple quality selection logic
            formats = [f for f in info.get('formats', []) if f.get('acodec') != 'none']
            if quality == "High":
                formats.sort(key=lambda x: x.get('abr') or 0, reverse=True)
            else:
                formats.sort(key=lambda x: x.get('abr') or 0)

            selected = formats[0] if formats else info

            # Try to extract expiration from URL
            import re
            expire_match = re.search(r'expire=(\d+)', selected.get('url', ''))
            expire_at = int(expire_match.group(1)) if expire_match else 0

            return {
                "url": selected.get('url'),
                "title": info.get('title'),
                "uploader": info.get('uploader'),
                "thumbnail": info.get('thumbnail'),
                "duration": info.get('duration'),
                "bitrate": selected.get('abr'),
                "codec": selected.get('acodec'),
                "expire_at": expire_at
            }
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/getVideoInfo")
async def get_video_info(videoId: str):
    url = f"https://www.youtube.com/watch?v={videoId}"
    try:
        with yt_dlp.YoutubeDL(get_ydl_options(extract_flat=True)) as ydl:
            info = ydl.extract_info(url, download=False)
            if not info:
                raise HTTPException(status_code=404, detail="Video not found")
            return {
                "id": videoId,
                "title": info.get('title'),
                "uploader": info.get('uploader'),
                "thumbnail": info.get('thumbnail'),
                "duration": info.get('duration'),
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/searchVideos")
async def search_videos(query: str, maxResults: int = 10):
    try:
        search_query = f"ytsearch{maxResults}:{query}"
        with yt_dlp.YoutubeDL(get_ydl_options(extract_flat=True)) as ydl:
            info = ydl.extract_info(search_query, download=False)
            entries = info.get('entries', [])
            return [
                {
                    "id": entry.get('id'),
                    "title": entry.get('title'),
                    "uploader": entry.get('uploader'),
                    "thumbnail": entry.get('thumbnails', [{}])[0].get('url') if entry.get('thumbnails') else '',
                    "duration": entry.get('duration'),
                } for entry in entries if entry
            ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/getPlaylistInfo")
async def get_playlist_info(playlistId: str):
    url = f"https://www.youtube.com/playlist?list={playlistId}"
    try:
        with yt_dlp.YoutubeDL(get_ydl_options(extract_flat=True)) as ydl:
            info = ydl.extract_info(url, download=False)
            if not info:
                raise HTTPException(status_code=404, detail="Playlist not found")
            entries = info.get('entries', [])
            return {
                "title": info.get('title'),
                "uploader": info.get('uploader'),
                "entries": [
                    {
                        "id": entry.get('id'),
                        "title": entry.get('title'),
                        "uploader": entry.get('uploader'),
                        "thumbnail": entry.get('thumbnails', [{}])[0].get('url') if entry.get('thumbnails') else '',
                        "duration": entry.get('duration'),
                    } for entry in entries if entry
                ]
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)

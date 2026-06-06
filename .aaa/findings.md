# Rgify Findings

## Project Overview
This project directory `d:\C\Rgify` is currently initialized as a new project workspace.

## Component & Architecture Details
- **Current State**: Empty directory under development.
- **Goal**: Setting up standard workspace-local workflows and commands.

---

## Target Site Analysis: RedGIFs (https://www.redgifs.com/)

### 1. Scraping & API Difficulty
- **API Status**: Public official API keys/registration are officially discontinued for external developers.
- **Undocumented API Endpoint**: RedGIFs serves its content using an undocumented REST API hosted at `https://api.redgifs.com/v2`.
- **Authentication**:
  - Authentication requires obtaining a temporary JSON Web Token (JWT) via a `GET` request to `https://api.redgifs.com/v2/auth/temporary`.
  - The returned token must be passed in the headers of subsequent requests: `Authorization: Bearer <TOKEN>`.
- **Bot Mitigation**: Standard HTTP requests are protected by Cloudflare. Scraping requires browser impersonation headers or specialized browser-like fetch utilities (e.g., Scrapling with stealthy-fetch or header impersonation) to prevent `403 Forbidden` or `429 Too Many Requests` responses.

### 2. API Limits & Rate Limiting
- **Authentication Rate Limit**: The temporary token endpoint is strictly rate-limited. Caching tokens for their duration is mandatory to avoid hitting `429 Too Many Requests`.
- **IP Restrictions**: Many VPN ranges, hosting providers, and non-residential proxies are flagged by Cloudflare and blocked automatically.

### 3. Scraping Quality & Alternatives
- **Direct HTML Scraping**: Low quality and complex due to heavy reliance on client-side rendering (React/Next.js hydration).
- **JSON API Response**: High quality. The undocumented JSON endpoints return clean metadata lists, tags, high/low-resolution video links, and view counts.
- **Libraries Available**: Community-built libraries (such as `redgifs` in Python or dart/pub.dev wrappers) automate temporary token acquisition and token caching.

---

## RedView APK Decompilation & API Survival Report

### 1. APK Structural Analysis
The APK `redview-1.3.4.apk` is a native Android application developed using **Kotlin / Jetpack Compose** and **Retrofit** for network communication.
- Packages located: `se.redview.redview.network.*`
- Models parsed:
  - `GifInfo` (contains media properties)
  - `MediaInfo` (contains direct video urls)
  - `TempToken` (handles JWT token)
  - `UserInfo` (user metadata)
- Network Endpoints configured in Retrofit:
  - `v2/auth/temporary` (JWT login)
  - `v2/gifs/search` (GIF search)
  - `v2/gifs/{id}` (Single video retrieval)
  - `v2/explore/trending-gifs`
  - `v2/feeds/trending/popular`

### 2. The "Shutdown" Mystery: Why it Still Works
- **The Creator's Notice**: The developer announced that RedGIFs threatened to shut down direct file access APIs in favor of embedded iframes.
- **Actual Status**: **The direct file access API was never shut down**.
- **Proof**: 
  - A query to `https://api.redgifs.com/v2/gifs/search?search_text=3d` with a temporary token still returns direct media links pointing to `https://media.redgifs.com/<VideoId>.mp4` under `urls.hd` and `urls.sd`.
  - A direct `GET`/`HEAD` request to the media CDN at `https://media.redgifs.com/<VideoId>.mp4` returns a `200 OK` and serves the file directly without requiring any cookies, referrer headers, or authentication tokens.
- **Why the App Stopped Working**: 
  The developer voluntarily shut down their app/backend services or updated their remote config (likely `version.json` or Firebase settings) to display the notice and block app access because they wanted to comply with the legal/API usage request from RedGIFs. The underlying API, however, remains completely active and functional.

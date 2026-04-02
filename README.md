# Flickr Gallery — Roku Channel

A Roku channel that pulls photos from the Flickr API and displays them in a swimlane gallery, similar to Netflix or YouTube. You get 13 rows of content — each row is a different category — and you can select any photo to see a larger view with details.

---

## How It Works

When you launch the channel, it starts loading each category one at a time. You'll see a spinning indicator while the first row loads, and then the rest of the rows fill in as they finish. If a row fails to load, you'll see an error message on that row and can press OK to retry just that one.

Selecting a photo takes you to a detail screen that shows the large image, the title, description, who took it, upload date, view count, and dimensions. The basic info shows up right away, and the extra details (like the exact upload date) load in the background while you're already looking at the image.

---

## Architecture

The project follows an MVVM structure:

- **Views** (`components/`) handle display and input only. They don't make decisions about data.
- **ViewModels** (`source/viewmodels/`) hold the state and prepare display-ready strings for the views. The view just assigns `label.text = viewModel.someText` — no formatting logic in the view.
- **Services** (`source/services/`) talk to the Flickr API and return structured results.
- **Models** (`source/models/`) are plain data objects — no SceneGraph overhead.
- **Config** (`source/config/`) stores all constants: API key, category list, colors, timeouts.

All HTTP requests happen inside Task nodes (Roku's threading model requires this — you can't make network calls on the render thread). The Task writes its result to a single field, and the scene observes that field to know when data is ready.

Categories are loaded sequentially, not all at once. This keeps the app running smoothly on lower-end Roku devices, which can't handle many concurrent tasks well.

---

## API Methods Used

| Row | Method |
|---|---|
| Featured | `flickr.interestingness.getList` |
| Nature, Architecture, Animals, Historical, Technology, Travel, Food, Sports, Art, People | `flickr.photos.search` |
| Popular | `flickr.photos.getPopular` |
| Recent Uploads | `flickr.photos.getRecent` |
| Detail screen | `flickr.photos.getInfo` |

One thing worth noting: the search requests include an `extras` parameter (`url_q,url_n,url_z,url_b,description,owner_name,views,date_upload`). This tells Flickr to return the image URLs and metadata directly in the search response, so we don't need a separate API call per photo to get the image URL.

---

## Reasoning Behind Technical Choices

**Plain associative arrays instead of ContentNode for models** — ContentNode fields fire observers every time you set a value. If you're updating 20 fields in a loop that's 20 observer events, which blocks the render thread. Plain arrays don't have that overhead.

**Sequential category loading** — Roku has a limited task pool. Loading all 13 categories at the same time on a lower-end device causes noticeable slowdowns. Loading them one after another keeps things smooth and still feels fast because the first row appears quickly.

**ViewModel prepares display strings** — Instead of the view checking `if owner != "" then "Photo by: " + owner else "Unknown"`, the ViewModel does that and exposes `ownerText`. The view just sets the label. This makes the view easier to read and keeps all the display logic in one place.

**Error handling per row** — A failed category doesn't affect the rest. Each row has its own error state and can be retried independently.

---

## Trade-offs and What I'd Do Differently

**No infinite scroll** — The infrastructure is there (`CategoryPaginationManager` exists) but I didn't wire up the "load more" trigger. Each row shows 20 photos. Adding it would be straightforward — detect when the user reaches the last item in a row and fire another task.

**File size not shown** — `flickr.photos.getInfo` doesn't return file size in bytes. You'd need `flickr.photos.getSizes` for that, which is an extra API call per photo. I opted not to add it since it doubles the network requests on the detail screen. The detail screen shows dimensions (width × height) instead, which comes from the search response extras.

**No image caching layer** — Roku's `Poster` node caches by URL automatically, so revisiting a row doesn't re-download images. But there's no LRU cache at the model level, so navigating away and back re-creates the content nodes. For a production app I'd add that.

**No accessibility** — ContentNode has `voiceReadBack` fields for screen reader support. Not implemented here but it would be a small addition.

**Manual testing only** — There's no test runner hooked up to CI. The `source/tests/` folder has manual assertion-style tests you run by calling the functions directly. I'd replace this with the [Rooibos](https://github.com/georgejecook/rooibos) framework for a real project.

---

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/muhammadazeem469/roku-flickr-app.git
cd roku-flickr-app
```

### 2. Enable developer mode on your Roku

On the Roku remote, press: `Home × 3, Up × 2, Right, Left, Right, Left, Right`

A Developer Settings screen will appear. Click **Enable Installer and Restart**.

### 3. Get your Roku's IP address

Go to `Settings → System → About` on the Roku. Note the IP address shown (e.g. `192.168.1.42`).

### 4. Zip the project

The `manifest` file must be at the root of the zip.

**Mac / Linux:**
```bash
cd roku-flickr-app
zip -r ../FlickrGallery.zip .
```

**Windows (PowerShell):**
```powershell
cd roku-flickr-app
Compress-Archive -Path * -DestinationPath ..\FlickrGallery.zip
```

### 5. Install

Open `http://<your-roku-ip>` in a browser, log in with username `rokudev` and the password you set, then upload the zip under **Install Application**.

Or via terminal:
```bash
curl --user rokudev:<your-password> --digest \
     -F "mysubmit=Install" \
     -F "archive=@FlickrGallery.zip" \
     http://<your-roku-ip>/plugin_install
```

The channel launches automatically after install. To find it again later: **My Channels → Dev Channel**.

### 5. View logs (optional)

```bash
telnet <your-roku-ip> 8085
```

---

## Requirements

- Roku device, firmware 7.0 or later
- Roku and your computer on the same Wi-Fi network

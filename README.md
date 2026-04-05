# Flickr Gallery — Roku Channel

A Roku channel that fetches photos from the Flickr public API and displays them in a multi-row swimlane gallery — similar to Netflix or YouTube. Thirteen rows of curated content, each backed by a different Flickr API endpoint or tag-based search, with a full detail screen for every photo.

---

## What You See When You Launch

1. **System splash** — a plain dark frame (identical background to the app) appears instantly while the Roku OS boots the channel runtime. No image flash.
2. **Animated intro** — a branded SplashScene plays over the loading content: a cream-coloured rounded "F" is drawn stroke-by-stroke (top bar → stem → mid bar, sliding masks reveal each stroke), followed by "F L I C K R" fading in with a subtle upward rise, a brief blossom pulse, then a fade to black.
3. **Content gallery** — the RowList appears once the first rows have loaded. A spinner (12 rotating XML dots — no image asset required) and progress counter are visible while remaining rows fill in.
4. **Detail screen** — selecting any photo slides in a detail panel from the right. The large image and basic metadata (title, description, owner, dimensions) appear immediately from search-response extras. Extended metadata (upload date, comment count, refreshed view count) loads asynchronously in the background via `flickr.photos.getInfo`.

---

## Architecture

The project uses a strict **MVVM** split across four layers. No layer reaches into the layer below it except through well-defined interfaces.

```
┌─────────────────────────────────────────────────────────────┐
│  Views  (components/)                                        │
│  Display and input only. Zero business logic.               │
│  MainScene · DetailScene · ImageCard · SplashScene          │
│  ErrorRowItem · CategoryLoadTask · PhotoInfoTask            │
├─────────────────────────────────────────────────────────────┤
│  ViewModels  (source/viewmodels/)                            │
│  State + display-ready strings. Views assign, not format.   │
│  MainViewModel · DetailViewModel  (each split into modules) │
├─────────────────────────────────────────────────────────────┤
│  Services  (source/services/)                                │
│  Flickr API interface. Returns typed, validated results.    │
│  FlickrService · ApiMethods · ResponseParser                │
├─────────────────────────────────────────────────────────────┤
│  Models  (source/models/)                                    │
│  Pure associative arrays. No SceneGraph overhead.           │
│  ImageModel · CategoryModel · ImageMapper                   │
│  CategoryImageManager · CategoryPaginationManager           │
└─────────────────────────────────────────────────────────────┘
          ↑ all layers read from ↓
┌─────────────────────────────────────────────────────────────┐
│  Config  (source/config/)                                    │
│  Single source of truth for every constant.                 │
│  AppConfig · CategoryConfig · NetworkConfig                 │
│  UIConfig · ImageConfig                                     │
└─────────────────────────────────────────────────────────────┘
```

### Threading model

Roku's render thread cannot make network calls. Every HTTP request runs inside a `Task` node on a background thread:

- **`CategoryLoadTask`** — fetches a single category row. `MainScene` creates the task, sets its parameters, observes the `result` field, and destroys the task when the result arrives.
- **`PhotoInfoTask`** — fetches `flickr.photos.getInfo` for one photo. `DetailScene` creates it on selection and observes the result.

The render thread never blocks. All data flows one-way: Task writes a result field → Scene observes the field change → ViewModel parses the result → View reads ViewModel state.

### Category loading strategy

Featured loads first (it has no tag filtering and is the most visually varied). The remaining 12 categories are queued sequentially — one task at a time. This is intentional: lower-end Roku hardware (Roku Stick, Express) struggles when many tasks compete for the network. Sequential loading keeps the UI responsive and the first row appears in under two seconds.

A **2-second minimum spinner** is enforced regardless of network speed. On fast networks the first rows arrive in well under a second, which causes the spinner to flash and disappear — jarring UX. The gate holds the spinner visible for at least two seconds, then shows the RowList the moment both conditions are met: minimum time elapsed **and** at least one row has content.

---

## 13 Category Rows

| # | Row | Flickr API Method | Tag(s) |
|---|-----|-------------------|--------|
| 1 | **Featured** | `flickr.interestingness.getList` | — |
| 2 | **Nature** | `flickr.photos.search` | nature, landscape, mountains, forest, wildlife |
| 3 | **Architecture** | `flickr.photos.search` | architecture, building, cityscape, urban |
| 4 | **Animals** | `flickr.photos.search` | animals, wildlife, pets, birds, cats, dogs |
| 5 | **Historical** | `flickr.photos.search` | history, vintage, historical, heritage, monument |
| 6 | **Technology** | `flickr.photos.search` | technology, tech, gadgets, innovation, digital |
| 7 | **Travel** | `flickr.photos.search` | travel, vacation, tourism, destination, adventure |
| 8 | **Food** | `flickr.photos.search` | food, cooking, cuisine, recipe, restaurant |
| 9 | **Sports** | `flickr.photos.search` | sports, fitness, athlete, game, competition |
| 10 | **Art** | `flickr.photos.search` | art, painting, sculpture, creative, artistic |
| 11 | **People** | `flickr.photos.search` | people, portrait, faces, human, person |
| 12 | **Popular** | `flickr.photos.getPopular` | — |
| 13 | **Recent Uploads** | `flickr.photos.getRecent` | — |

Each row fetches 20 photos per load (`DEFAULT_PER_PAGE = 20`, `DEFAULT_PAGE = 1`).

---

## API Methods Used

| Purpose | Method | When |
|---------|--------|------|
| Featured row | `flickr.interestingness.getList` | App launch |
| 10 tag-based rows | `flickr.photos.search` | App launch, per-row retry |
| Popular row | `flickr.photos.getPopular` | App launch |
| Recent Uploads row | `flickr.photos.getRecent` | App launch |
| Detail screen metadata | `flickr.photos.getInfo` | Photo selected |

### The `extras` parameter

Every search and list request includes:

```
extras=url_q,url_n,url_z,url_b,description,owner_name,views,date_upload
```

This tells Flickr to embed four image URLs (thumbnail through large) and the core metadata **directly in the search response**. The detail screen can therefore display the photo and its basic info instantly — no waiting for a second round-trip. `flickr.photos.getInfo` then runs asynchronously to fetch the extended metadata (comments, exact dimensions, fresher view count).

### Flickr error detection

Flickr always returns HTTP 200, even for API-level failures. Errors are detected by inspecting the JSON body for `"stat": "fail"`. `JsonParser.brs` handles this check on every response before the result is handed to the ViewModel.

---

## Network & Error Handling

### Per-row error states

Every category row is independent. A failed row does not affect any other row. Three error types are distinguished:

| Error type | Trigger | User message |
|------------|---------|--------------|
| `NETWORK` | `roUrlTransfer` returned empty or timed out | "Unable to connect. Check your internet connection." |
| `API_ERROR` | Flickr returned `stat: "fail"` | "Couldn't load images. Please try again later." |
| `EMPTY` | Response succeeded but returned 0 photos | "No images found in this category." |

A row in error state shows a retry indicator. Pressing OK on that row fires a fresh `CategoryLoadTask` for that category only — no page reload.

### Debug flags

`AppConfig.brs` has three boolean flags (`DEBUG_BAD_API_KEY`, `DEBUG_NETWORK_ERROR`, `DEBUG_EMPTY_RESULTS`) that simulate each error path in isolation without touching the network. All three default to `false` for production.

---

## Technical Choices and Reasoning

**Plain associative arrays for models, not ContentNode**

`ContentNode` fires an observer event on every field assignment. Updating 20 fields in a loop generates 20 events that all execute on the render thread. Plain associative arrays have zero overhead — they're just data. The ViewModel mutates them freely on the task thread, then signals the render thread once via a counter field (`categoryUpdateCount`). One signal, one render-thread update.

**ViewModel pre-formats every display string**

The View never does conditional formatting. `if owner <> "" then "Photo by: " + owner else "Unknown"` belongs in the ViewModel, not the scene script. The View assigns `label.text = vm.ownerText` and nothing more. This makes scene scripts short and readable, and makes the display logic trivially testable without a Roku device.

**Sequential category loading**

All 13 categories loading in parallel would saturate the task pool on a Roku Stick or Express and produce stuttering. Sequential loading delivers the first row quickly (Featured appears in ~1s on a good connection) and fills the rest smoothly. The pagination infrastructure (`CategoryPaginationManager`) is designed so "load more" is a future addition that doesn't change the loading strategy.

**`extras` parameter instead of per-photo API calls**

Fetching the image URL separately for each photo would require 20 additional API calls per row — 260 extra requests at launch. Including `url_q,url_n,url_z,url_b` in the extras means URLs arrive with the search response at no extra cost.

**SplashScene over static splash screen**

The system-level splash (`splash_screen_hd` in the manifest) is a plain dark rectangle (`#181210`) that is visually indistinguishable from the SplashScene background. The animated branded intro plays on top inside the SceneGraph — so the launch sequence reads as one continuous experience rather than a static image followed by content. The animation is implemented with a mask-slide technique (three background-coloured rectangles that slide away to reveal the rounded-F strokes) so the F is always rendered at full resolution with correct rounding.

**Spinner as pure XML nodes**

12 small rectangles arranged in a circle, rotated by a `FloatFieldInterpolator`. No image asset required. This approach works on every Roku firmware version and device tier.

---

## Trade-offs and What I'd Do Differently

**No infinite scroll**

`CategoryPaginationManager` tracks the current page and total pages, and `canLoadMore()` is fully implemented. What's not wired is the UI trigger: detecting when the focused item is within N items of the row's end and dispatching a new task. Adding this is straightforward — one `observeField("itemFocused")` check — but wasn't prioritised for this submission.

**File size not shown in the detail screen**

`flickr.photos.getInfo` does not return file size in bytes. Retrieving it requires a separate call to `flickr.photos.getSizes`. That would double the network requests on the detail screen. The detail screen shows pixel dimensions (width × height) instead, which come from the `extras` parameter at no extra cost.

**No model-level image cache**

Roku's `Poster` node caches images by URL automatically, so images don't re-download when the user scrolls back. However, navigating away from and back to the main screen re-creates the content nodes from the ViewModel, which means the Poster cache is what saves you — not a purpose-built LRU. A production app would maintain a hot cache of content nodes for recently visited rows.

**No accessibility support**

`ContentNode` supports a `voiceReadBack` field for screen reader narration. It's not implemented here. For a shipping channel, each `ImageCard` should expose `voiceReadBack = photo.title + ", photo by " + photo.owner` so visually impaired users can navigate.

**Manual tests only**

`source/tests/` contains assertion-style functions that must be invoked manually from a scene. For a production project I'd integrate [Rooibos](https://github.com/georgejecook/rooibos) — a BrightScript unit-test framework with CI support. The current manual tests do catch data-layer regressions but don't run automatically.

---

## Project Structure

```
roku-flickr-app/
├── manifest                          App metadata (title, versions, icon paths)
├── images/
│   ├── channel-poster_hd.png         336×210  Home screen channel icon (HD)
│   ├── channel-poster_sd.png         214×144  Home screen channel icon (SD)
│   ├── splash-screen_fhd.png         1920×1080  Plain dark system splash (FHD)
│   ├── splash-screen_hd.png          1280×720   Plain dark system splash (HD)
│   └── retry_icon.png                Error row retry indicator
│
├── source/
│   ├── main.brs                      Entry point — creates screen and event loop
│   ├── config/
│   │   ├── AppConfig.brs             API key, pagination defaults, debug flags
│   │   ├── CategoryConfig.brs        All 13 category definitions
│   │   ├── NetworkConfig.brs         Timeouts, retry counts, HTTP status codes
│   │   ├── UIConfig.brs              Colors, fonts, animation timings
│   │   └── ImageConfig.brs           Flickr URL size suffixes (q/n/z/b/h/o)
│   ├── services/
│   │   ├── FlickrService.brs         Factory — creates a service object
│   │   ├── FlickrService_ApiMethods.brs   Five API method implementations
│   │   └── FlickrService_ResponseParser.brs  JSON photo array → ImageModel[]
│   ├── network/
│   │   ├── HttpClient.brs            roUrlTransfer wrapper, returns typed response
│   │   ├── JsonParser.brs            JSON parse + stat:fail detection
│   │   ├── NetworkValidator.brs
│   │   ├── RetryManager.brs
│   │   └── ErrorHandler.brs
│   ├── models/
│   │   ├── ImageModel.brs            id, title, description, owner, four URL sizes, metadata
│   │   ├── CategoryModel.brs         name, images[], loading/loaded/error state
│   │   ├── ImageMapper.brs           Flickr photo JSON → ImageModel
│   │   ├── CategoryImageManager.brs  add / remove / clear images on a category
│   │   └── CategoryPaginationManager.brs  page tracking, canLoadMore()
│   ├── viewmodels/
│   │   ├── MainViewModel.brs         Gallery state, category array, update counter
│   │   ├── MainViewModel_StateManager.brs    Global error, category stats
│   │   ├── MainViewModel_CategoryLoader.brs  Load queue, task creation, result parsing
│   │   ├── DetailViewModel.brs       Detail state, basic + extended metadata
│   │   ├── DetailViewModel_StateManager.brs  Loading / error transitions
│   │   ├── DetailViewModel_InfoLoader.brs    PhotoInfoTask creation and result handling
│   │   └── DetailViewModel_InfoParser.brs    Metadata formatting (dates, counts, dimensions)
│   ├── utils/
│   │   ├── ResponseBuilder.brs       Standardised success/error response factory
│   │   ├── ApiHelper.brs             BuildFlickrURL, BuildPhotoInfoURL
│   │   ├── ImageUrlBuilder.brs       Flickr static URL construction from server/id/secret
│   │   ├── ImageUrlBuilder_Extended.brs
│   │   ├── TypeUtils.brs             SafeToInt, SafeToStr, GetField
│   │   ├── FormatUtils.brs           FormatNumber (commas), FormatUnixTimestamp
│   │   ├── ContentNodeConverter.brs
│   │   ├── CategoryContentNodeConverter.brs
│   │   └── NetworkUtils.brs
│   ├── Validators/
│   │   ├── ImageValidators.brs       Validates id, title, at least one URL
│   │   └── CategoryValidator.brs
│   └── tests/                        Manual assertion-style tests (not CI-integrated)
│
└── components/
    ├── MainScene/
    │   ├── MainScene.xml             Scene structure, script imports, RowList config
    │   ├── MainScene.brs             init, key events, splash overlay wiring
    │   ├── MainScene_LoadingState.brs  Spinner, backdrop, progress label
    │   ├── MainScene_CategoryLoader.brs  Task lifecycle, retry, load queue
    │   ├── MainScene_RowList.brs     RowList config, selection, focus
    │   └── MainScene_Navigation.brs  DetailScene slide-in / slide-out animation
    ├── SplashScene/
    │   ├── SplashScene.xml           Three rounded-rect F strokes + three masks
    │   └── SplashScene.brs           Write animation pipeline, skip handler
    ├── DetailScene/
    │   ├── DetailScene.xml           Panel layout — large image + metadata fields
    │   └── DetailScene.brs           Two-phase load: immediate basic info + async getInfo
    ├── ImageCard/
    │   ├── ImageCard.xml             280×210 card, four visual states
    │   └── ImageCard.brs             placeholder → loading → image / error transitions
    ├── ErrorRowItem/
    │   ├── ErrorRowItem.xml
    │   └── ErrorRowItem.brs
    └── tasks/
        ├── CategoryLoadTask.xml      Task component (runs on background thread)
        ├── CategoryLoadTask.brs      Dispatches to correct FlickrService method
        ├── PhotoInfoTask.xml         Task component
        └── PhotoInfoTask.brs         Calls flickr.photos.getInfo, writes result field
```

---

## Installation

### 1. Clone the repository

```bash
git clone -b main https://github.com/muhammadazeem469/roku-flickr-app.git
cd roku-flickr-app
```

### 2. Enable developer mode on your Roku

On the Roku remote press: `Home × 3, Up × 2, Right, Left, Right, Left, Right`

A Developer Settings screen appears. Click **Enable Installer and Restart**.

### 3. Get your Roku's IP address

`Settings → System → About` — note the IP shown (e.g. `192.168.1.42`).

### 4. Package the project

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

### 5. Install via browser

Open `http://<your-roku-ip>` in a browser, log in (`rokudev` / your password), and upload the zip under **Install Application**.

Or via terminal:
```bash
curl --user rokudev:<your-password> --digest \
     -F "mysubmit=Install" \
     -F "archive=@FlickrGallery.zip" \
     http://<your-roku-ip>/plugin_install
```

The channel launches automatically. To find it again later: **My Channels → Dev Channel**.

### 6. View logs (optional)

```bash
telnet <your-roku-ip> 8085
```

---

## Requirements

- Roku device, firmware 7.0 or later
- Roku and your computer on the same Wi-Fi network

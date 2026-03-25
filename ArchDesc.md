Flickr Gallery — Roku Channel
Architecture & Technical Decisions
Corus Coding Challenge Submission



1. Project Overview
   Flickr Gallery is a Roku SceneGraph channel written entirely in BrightScript. It renders a multi-row ("swimlane") gallery of photos fetched live from the Flickr public REST API, closely resembling the browsing experience found on platforms such as Netflix or YouTube.

The channel supports 12 curated categories displayed as horizontal scrolling rows. Selecting any thumbnail opens a detail screen that shows the enlarged image, title, description, owner, upload date, view count, and comment count — with additional metadata fetched asynchronously on a background thread.

2. Overall Architecture
   The channel is structured around a strict MVVM (Model–View–ViewModel) pattern layered on top of a dedicated Service and Network tier. This separates concerns cleanly, keeps UI code thin, and makes each layer independently testable.

2.1 Layer Overview
Layer
Files
Responsibility
View (Scene)
MainScene, DetailScene, SwimLane, ImageCard, ErrorRowItem
XML layout + BrightScript that only reads ViewModel state and manipulates SceneGraph nodes
ViewModel
MainViewModel*, DetailViewModel*
Business logic, state machines, navigation decisions — no SceneGraph or HTTP calls
Service
FlickrService, FlickrService_ApiMethods, FlickrService_ResponseParser
All Flickr API interaction and JSON-to-model conversion
Model
ImageModel, CategoryModel, CategoryStateManager, CategoryImageManager, CategoryPaginationManager
Pure data objects with no dependencies
Config
AppConfig, CategoryConfig, ImageConfig, NetworkConfig, UIConfig
Centralised constants — one place to change keys, URLs, sizes, colours
Network
HttpClient, JsonParser, NetworkValidator, ErrorHandler, RetryManager, NetworkUtils
Reusable HTTP layer with retry, error categorisation, and JSON parsing
Validators
ImageValidators, CategoryValidator
Input validation keeping bad data out of the model layer
Utils
ApiHelper, ImageUrlBuilder, ContentNodeConverter, CategoryContentNodeConverter
URL construction, SceneGraph node conversion helpers

2.2 Thread Safety — The Most Critical Design Decision
Roku strictly forbids HTTP requests on the render thread. Every network call must run on a Task thread node. This is the single most important architectural constraint and drives several design decisions:
• CategoryLoadTask — fetches all images for one category. MainScene creates and observes one task at a time in a sequential queue.
• PhotoInfoTask — fetches extended metadata for a selected image. DetailScene creates this task after the basic image is already displayed.
• All HTTP I/O lives in FlickrService_ApiMethods and HttpClient, which are only ever called from within Task threads.
• Results cross the thread boundary by writing to an output field (result) on the Task node. The render thread observes this field via observeField.

3. Data Flow
   3.1 Main Gallery Loading
   The following sequence shows exactly what happens from app launch to the first row appearing on screen:

init()
└─ buildPlaceholderRowList() // Shows "Loading…" label in every row immediately
└─ showGlobalLoading() // Spinner + 2-second minimum display gate
└─ MainViewModel.loadAllCategories() // Builds loadQueue: [Featured, ...rest]
└─ loadNextCategory() // Pops front of queue, creates CategoryLoadTask
└─ CategoryLoadTask.RUN // HTTP on task thread
└─ onCategoryLoaded()
├─ parseApiResponse() // ImageMapper converts JSON → ImageModels
├─ refreshRowAtIndex() // Replaces placeholder with real ContentNodes
├─ revealRowList() // Hides spinner once first row + 2s elapsed
└─ loadNextCategory() // Continues queue

The "Featured" category (using flickr.interestingness.getList) is always loaded first to ensure the most visually compelling row appears at the top immediately.

3.2 Detail Screen Loading
onItemSelected()
└─ openDetailScreen(imageModel)
└─ DetailScene.onImageModelSet()
├─ CreateDetailViewModel(imageModel)
├─ displayBasicInfo() // Instant: title, image, owner, views
├─ showContent() // Image is visible immediately
└─ loadExtendedInfo() // PhotoInfoTask.RUN
└─ onPhotoInfoLoaded()
└─ updateExtendedInfo() // Adds date, file size, comments

This two-phase approach ensures the user sees the image immediately while secondary metadata loads in the background. Missing metadata fields degrade gracefully with "Not available" labels rather than blocking display.

4. Key Components In Detail
   4.1 CategoryModel
   A pure associative array (not a ContentNode) representing one swimlane row. Key fields:
   Field
   Type
   Purpose
   id / name
   String
   Unique identifier matching CategoryConfig key
   display_name
   String
   Human-readable label shown above the row
   method
   String
   Flickr API method to call (interestingness / search / getRecent)
   tags
   String
   Comma-separated tags for flickr.photos.search rows
   images
   Array
   Array of ImageModel objects for this row
   isLoading / isLoaded / hasError
   Boolean
   State machine flags
   errorMessage / errorType
   String
   Error details for the UI layer
   page / totalPages / hasMorePages
   Integer/Boolean
   Pagination state (ready for infinite scroll)

CategoryModel is intentionally separate from SceneGraph. Keeping it as a plain associative array avoids ContentNode field-change callbacks during batch updates and makes the model testable without a running SceneGraph environment.

4.2 FlickrService
A facade that wraps three subordinate modules:
• FlickrService_ApiMethods — one function per Flickr method: getInterestingImages(), searchImagesByTag(), getRecentImages(), getImageInfo(). Each builds a URL via ApiHelper, calls HttpClient_makeRequest(), and passes the raw response to the ResponseParser.
• FlickrService_ResponseParser — detects Flickr's stat:"fail" error body (Flickr always returns HTTP 200, even for invalid keys), extracts pagination info, and converts the photos array to ImageModel objects via ImageMapper.
• ImageMapper — field-by-field mapping from Flickr JSON to ImageModel. Prefers direct URL fields returned by the extras parameter (url_q, url_n, url_z, url_b) and falls back to constructing static CDN URLs when extras are absent.

4.3 Error Handling — Three-Tier Classification
A deliberate decision was made to classify all errors into exactly three user-visible types so that error messages are consistent and actionable:
Error Type
Trigger Condition
User Message
Retryable?
NETWORK
roDeviceInfo.GetConnectionType() returns neither WiredConnection nor WiFiConnection
Unable to connect. Check your internet connection.
Yes
EMPTY
API succeeded (stat:ok) but returned 0 photos
No images found in this category.
No (no point retrying)
API_ERROR
stat:fail body, HTTP transport failure, JSON parse error, or unknown method
Couldn't load images. Please try again later.
Yes

The errorType is propagated from CategoryLoadTask → MainViewModel_CategoryLoader.parseApiResponse → CategoryModel.errorType → showErrorRow() → sentinel ContentNode.errorType, so the UI can render the correct icon and retry hint without any conditional string matching at the View layer.

4.4 Loading State UX
Two separate loading mechanisms work in concert:
• Global spinner — a pure-XML rotating dot ring (12 Rectangle nodes + FloatFieldInterpolator) that appears immediately on launch. It is gated by two conditions: (a) at least one category row has data, AND (b) a minimum 2-second display timer has elapsed. This prevents a flash of spinner followed by instant content.
• Per-row placeholders — each row is pre-populated with a "Loading…" ContentNode before any HTTP request fires. This fills the RowList immediately so the layout does not jump when real images arrive.

The spinner uses only built-in SceneGraph primitives (Rectangle + Animation) rather than a BusySpinner node or external image asset, ensuring it renders reliably on all Roku firmware versions.

4.5 Retry Architecture
Failed rows are not simply hidden. Instead:
• The row title is updated to show the error message prefixed with "⚠ ".
• An invisible sentinel ContentNode is appended to the row so it remains focusable.
• The sentinel carries isError=true, canRetry, errorType, and categoryIndex fields.
• When the user presses OK on a failed row, onItemSelected() detects isError=true and calls retryCategory(categoryIndex).
• retryCategory() clears the category state, restores the loading placeholder, creates a fresh CategoryLoadTask, and re-runs the load without touching any other row.

5. Categories & API Methods

#

Category
Flickr Method
Tags
1
Featured
flickr.interestingness.getList
—
2
Nature
flickr.photos.search
nature, landscape, mountains, forest, wildlife
3
Architecture
flickr.photos.search
architecture, building, cityscape, urban
4
Animals
flickr.photos.search
animals, wildlife, pets, birds, cats, dogs
5
Historical
flickr.photos.search
history, vintage, historical, heritage, monument
6
Technology
flickr.photos.search
technology, tech, gadgets, innovation, digital
7
Travel
flickr.photos.search
travel, vacation, tourism, destination, adventure
8
Food
flickr.photos.search
food, cooking, cuisine, recipe, restaurant
9
Sports
flickr.photos.search
sports, fitness, athlete, game, competition
10
Art
flickr.photos.search
art, painting, sculpture, creative, artistic
11
People
flickr.photos.search
people, portrait, faces, human, person
12
Recent
flickr.photos.getRecent
—

Adding a new category requires only a single new entry in GetCategories() inside CategoryConfig.brs. No other files need to be touched — the loading queue, RowList, and error handling all adapt automatically from the array length.

6. Network Layer
   6.1 HttpClient
   A thin wrapper around roUrlTransfer that standardises the response shape:
   { success: Boolean, data: String, error: String, statusCode: Integer, errorCategory: String }

Peer and host verification are disabled (EnablePeerVerification(false)) because the Roku's bundled CA store may not include Flickr's CDN certificate chain on older firmware.

6.2 RetryManager
Implements exponential backoff with a configurable cap. The default policy (from NetworkConfig.brs):
• MAX_RETRIES: 3 attempts
• BASE_BACKOFF_SECONDS: 1s
• MAX_BACKOFF_SECONDS: 8s
• Backoff sequence: 1s → 2s → 4s → 8s (capped)
Only retryable errors (NETWORK_UNAVAILABLE, server 5xx, rate limiting, gateway errors) trigger retry. Client errors (4xx except 429) do not retry.

6.3 JsonParser
Calls BrightScript's native ParseJson() and additionally inspects the parsed object for Flickr's application-level error format (stat:"fail"). This is necessary because Flickr always returns HTTP 200, even for invalid API keys — the only way to detect API-level failure is to check the response body.

7. Technical Choices & Reasoning
   7.1 RowList vs Custom SwimLane
   The primary display uses Roku's native RowList SceneGraph node. Reasons:
   • RowList handles focus management, keyboard repeat rate, and content recycling automatically.
   • It works reliably across all firmware versions without custom focus logic.
   • Performance is better than a manually managed list of SwimLane components for 12+ rows.
   The custom SwimLane component is also included for layouts that require fine-grained scroll-offset animation or custom card spacing that RowList cannot provide. It is kept as a reusable component for potential future use.

7.2 Sequential Category Loading
Categories are loaded one at a time rather than in parallel. Reasons:
• Roku's task thread pool is limited. Spawning 12 concurrent tasks degrades performance and can cause task creation failures on lower-end devices.
• Sequential loading ensures rows arrive in a predictable top-to-bottom order, which looks intentional to the user.
• The "Featured" category is always first in the queue, guaranteeing the most visually compelling content appears at the top as quickly as possible.
• A loadQueue array makes it trivial to reorder or prioritise categories in the future.

7.3 Plain Assoc Arrays for ViewModels
ViewModels and Models use BrightScript associative arrays rather than ContentNode objects. Reasons:
• ContentNode field assignments fire observers synchronously. Updating 20 image fields in a loop would fire 20 separate events, blocking the render thread.
• Assoc arrays can be freely passed between functions and mutated in place without SceneGraph overhead.
• The Task result field (a single assocarray write) is the only ContentNode crossing the thread boundary, keeping the architecture clean.

7.4 Config Files as Functions
All configuration lives in functions (GetApiConfig(), GetNetworkConfig(), etc.) that return fresh assoc arrays. This follows BrightScript convention and allows config values to be computed at call time (e.g. swapping the API key when DEBUG_BAD_API_KEY is true) rather than being static globals that are hard to mock in tests.

7.5 extras Parameter for Image URLs
The extras parameter (url_q,url_n,url_z,url_b,description,owner_name,tags,views,date_upload) is passed to all list API calls. This returns pre-built CDN URLs directly in the search/list response, eliminating a separate flickr.photos.getSizes call per image and reducing API round-trips from O(n+1) to O(1) per category.

8. Trade-offs, Omissions & Future Improvements
   8.1 What Was Left Out
   Feature
   Status
   Reason
   Infinite scroll / pagination
   Infrastructure ready, not wired up
   CategoryPaginationManager and hasMorePages are in place. A "load more" trigger at row end would complete this in one session.
   Image caching
   Poster node URL caching only
   Roku's Poster component caches by URL already. A model-layer LRU cache would help on re-entry to the detail screen.
   Search row
   Not implemented
   A search input row using flickr.photos.search with a keyboard overlay would be straightforward to add.
   Accessibility (voiceReadBack)
   Not implemented
   ContentNode voiceReadBack fields would add screen-reader support with minimal effort.
   Proper test runner
   Manual print-based assertions
   Integrating rooibos (the de-facto Roku unit test framework) would give structured pass/fail output and CI compatibility.

8.2 Known Trade-offs
• Peer verification is disabled on roUrlTransfer — acceptable for a demo channel but should be replaced with proper certificate pinning in a production channel.
• The channel loads 20 images per category (perPage=20). A higher value would show more content but slow initial load; lower values would feel sparse.
• DetailViewModel_InfoLoader makes a synchronous HTTP call (FlickrService_GetPhotoInfo). This is safe only because it is called from within PhotoInfoTask which runs on the task thread, not the render thread. The code comment explains this but the coupling is fragile if the call site changes.
• ErrorRowItem.xml defines a custom RowList item component. Due to RowList's content model, the row title approach (updating rowNode.title) is simpler and more compatible across firmware versions, so ErrorRowItem is defined but the row-title approach is used as the primary error display.

8.3 Scalability Considerations
The challenge spec specifically asks: "will this have to be rebuilt when pulling from millions of images from many sources?" The current architecture handles this as follows:
• Adding a new data source requires only: (1) a new entry in CategoryConfig.brs, and (2) optionally a new API method in FlickrService_ApiMethods. All loading, error handling, pagination, and UI code reuse automatically.
• The CategoryModel pagination fields (page, totalPages, hasMorePages) are already tracked — implementing infinite scroll is additive, not a rebuild.
• The Service / ViewModel separation means the Flickr REST API can be replaced or supplemented with another source (e.g. an internal CMS API) by swapping the Service layer only, without touching any ViewModel or Scene code.
• The sequential task queue already handles N categories gracefully. Changing from 12 to 100 categories would work with no code changes, though parallel loading with a configurable concurrency limit would improve performance at that scale.

9. Complete File Map by Directory
   Directory
   Files
   Purpose
   components/
   MainScene, DetailScene, ImageCard, SwimLane, ErrorRowItem (.xml + .brs)
   SceneGraph UI components and their BrightScript logic
   components/tasks/
   CategoryLoadTask, PhotoInfoTask (.xml + .brs)
   Task nodes — all HTTP I/O lives here
   source/config/
   AppConfig, CategoryConfig, ImageConfig, NetworkConfig, UIConfig
   All constants and configuration
   source/models/
   ImageModel, CategoryModel, CategoryStateManager, CategoryImageManager, CategoryPaginationManager, ImageMapper
   Pure data + mutation helpers
   source/services/
   FlickrService, FlickrService_ApiMethods, FlickrService_ResponseParser
   Flickr API facade
   source/viewmodels/
   MainViewModel*, DetailViewModel* (7 files)
   Business logic split by concern
   source/network/
   HttpClient, JsonParser, NetworkValidator, ErrorHandler, RetryManager, NetworkUtils
   Reusable HTTP layer
   source/utils/
   ApiHelper, ImageUrlBuilder, ImageUrlBuilder_Extended, ContentNodeConverter, CategoryContentNodeConverter, NetworkUtils
   URL building and node conversion
   source/validators/
   ImageValidators, CategoryValidator
   Input validation
   source/tests/
   8 test suite files
   Unit tests for all layers

— End of Document —

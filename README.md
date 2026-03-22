# Flickr Gallery Roku Channel

A Roku channel that displays Flickr images in a multi-row swimlane gallery layout, similar to Netflix or YouTube.

## 📋 Overview

Browse public Flickr photos across 10+ categories (Nature, Architecture, Animals, Popular, Historical, etc.) with an intuitive TV-optimized interface.

## 🏗️ Architecture

**Pattern**: MVVM (Model-View-ViewModel)

- **View**: SceneGraph XML components
- **ViewModel**: BrightScript UI logic
- **Model**: API service layer

**Key Design Decisions:**

- Native Roku/BrightScript for optimal TV performance
- Multiple Flickr API methods for diverse content (interestingness, search, recent)
- JSON format for simpler parsing
- Lazy loading for performance at scale

## 📁 Project Structure

```
roku-flickr-app/
├── manifest              # Channel configuration
├── source/
│   ├── main.brs         # Entry point
│   └── Constants.brs    # API config
└── components/          # UI components (future)
```

## 🚀 Quick Start

1. **Clone & Configure**

```bash
   git clone <repo-url>
   cd roku-flickr-app
```

2. **Add API Key** in `source/Constants.brs`:

```brightscript
   FLICKR_API_KEY: "452b3b7a5d806dcd110842e6649c604d"
```

3. **Deploy to Roku**
   - Enable Developer Mode: Home 3x, Up 2x, Right, Left, Right, Left, Right
   - Navigate to `http://<roku-ip>`
   - Upload zipped project

## 🔧 Development Workflow

```bash
# Create feature branch
git checkout develop
git checkout -b feature/FG-XXX-description

# Commit changes
git add .
git commit -m "feat: description"

# Push and create PR to develop
git push --set-upstream origin feature/FG-XXX-description
```

**Branches:**

- `main` → Production
- `develop` → Integration
- `feature/*` → New features
- `bugfix/*` → Bug fixes

## 💡 Technical Choices

| Decision                | Reasoning                                 |
| ----------------------- | ----------------------------------------- |
| BrightScript/SceneGraph | Native performance, TV-optimized controls |
| MVVM Pattern            | Separation of concerns, easier testing    |
| JSON over XML           | Simpler parsing in BrightScript           |
| Multiple API methods    | Diverse content sources                   |

## ⚖️ Trade-offs

**Prioritized:**

- Clean architecture
- Smooth navigation
- Error handling

**Deferred (time constraints):**

- Advanced caching
- Unit tests
- User authentication
- Offline mode

**With More Time:**

- Implement image caching strategy
- Add performance monitoring
- Create reusable component library
- Progressive image loading

## 📈 Scalability

- Modular architecture for easy category additions
- API abstraction supports multiple photo sources
- Lazy loading prevents memory bottlenecks
- Component reusability for future features

## 🛠️ Tech Stack

- **Language**: BrightScript
- **Framework**: Roku SceneGraph
- **API**: Flickr REST API
- **Architecture**: MVVM

## 📚 Resources

- [Roku Developer Docs](https://developer.roku.com/docs)
- [Flickr API Docs](https://www.flickr.com/services/api/)
- [BrightScript Reference](https://developer.roku.com/docs/references/brightscript)

## 📝 Version

**v1.0.0** - Initial Release

---

**Challenge Submission** for Corus coding assessment.

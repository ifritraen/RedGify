# Rgify Codebase Structure & Component Map

This document maps out the detailed file hierarchy, data models, state providers, and network services implemented in the **Rgify** project workspace.

---

## 1. Directory Structure

```
d:\C\Rgify\
├── .aaa\
│   ├── findings.md               # Analysis of API & RedView APK
│   └── structure.md              # [THIS FILE] Project structure mapping
├── .agents\
│   └── workflows\                # Workspace-local slash commands
│       ├── answer.md
│       ├── build.md
│       ├── causion.md
│       ├── concise.md
│       ├── debug.md
│       ├── deep.md
│       ├── feat.md
│       ├── order.md
│       ├── precise.md
│       ├── scrap.md
│       └── up.md
├── lib\
│   ├── main.dart                 # App initialization & provider binding
│   ├── config\
│   │   ├── constants.dart        # Endpoints & User-Agent configurations
│   │   └── theme.dart            # Premium dark glassmorphism theme
│   ├── models\
│   │   ├── gif_info.dart         # Video details & URL mapping models
│   │   ├── niche_info.dart       # Curated tags & category models
│   │   └── user_info.dart        # Creator profile metadata model
│   ├── providers\
│   │   ├── feed_provider.dart    # Infinite scrolling trending feed state
│   │   └── search_provider.dart  # Multi-page search query states
│   ├── services\
│   │   ├── api_client.dart       # Network calls & auto-refresh (401)
│   │   └── token_manager.dart    # Secure storage (JWT) & UA matching
│   └── views\
│       ├── home\
│       │   └── home_screen.dart  # Main masonry feed & search bar view
│       ├── player\
│       │   └── viewer_screen.dart # Immersive looping video player screen
│       └── widgets\
│           ├── sidebar.dart      # Curated side navigation drawer
│           └── video_card.dart   # Glassmorphic grid thumbnail widget
└── pubspec.yaml                  # Declared package configurations
```

---

## 2. Core Service & Network Layers

### `TokenManager` ([token_manager.dart](file:///d:/C/Rgify/lib/services/token_manager.dart))
- **Role**: Acquires, stores, and validates JWT temporary tokens.
- **Key Flow**: Stores matching `User-Agent` in secure storage and forces identical binding for all subsequent REST queries to avoid `401 WrongSender` signature mismatches.

### `ApiClient` ([api_client.dart](file:///d:/C/Rgify/lib/services/api_client.dart))
- **Role**: Communicates with RedGIFs undocumented `/v2/` API.
- **Key Flow**: Automatically catches `401 Unauthorized` responses, triggers `TokenManager` renewal, and retries the failed network operation transparently.

---

## 3. UI Views & Visual Elements

### `HomeScreen` ([home_screen.dart](file:///d:/C/Rgify/lib/views/home/home_screen.dart))
- Coordinates dynamic view switching (search query overlay vs. trending feed).
- Implements infinite-scroll trigger points on the `ScrollController`.

### `ViewerScreen` ([viewer_screen.dart](file:///d:/C/Rgify/lib/views/player/viewer_screen.dart))
- Runs full-screen video player bindings using direct `.mp4` URLs.
- Provides standard gesture bindings (tap-to-toggle play, double-tap actions).

### `VideoCard` ([video_card.dart](file:///d:/C/Rgify/lib/views/widgets/video_card.dart))
- Displays thumbnail loaders wrapped in standard `Shimmer` overlays.
- Employs strict aspect ratio locks to maintain the masonry layout.

---
name: flutter-performance-expert
description: Use when optimizing UI responsiveness, fixing FPS drops, or reducing unnecessary widget rebuilds.
---

# Flutter Performance Expert

## Overview

A premium app must feel butter-smooth (60/120 FPS). Poor performance is usually the result of excessive rebuilds, blocking the main thread, or inefficient memory usage.

**Core principle:** Rebuild only what changed. Move heavy logic out of the UI thread.

## The Performance Checklist

### 1. Minimal Rebuilds (The 80/20 Rule)
- **Problem**: Calling `notifyListeners()` on a large Provider rebuilds everything using `Consumer`.
- **Protocol**:
  - Use `Selector<T, S>` to listen to specific fields.
  - Use `context.select<T, R>((T value) => value.field)` for granular dependencies.
  - Const constructors everywhere possible.
  - Extract large widgets into `StatelessWidget` sub-classes to leverage caching.

### 2. Junk-Free Animations
- **Problem**: Complex animations ticking every frame and triggering parent rebuilds.
- **Protocol**:
  - Use `RepaintBoundary` for complex static layers under animations.
  - Use `flutter_animate` efficiently without nesting multiple controllers.

### 3. Asynchronous Optimization
- **Problem**: Blocking the UI thread with JSON parsing or heavy math.
- **Protocol**:
  - Use `compute()` for heavy data processing.
  - Ensure all `http` calls are properly awaited and handle loading states without blocking the UI.

### 4. Memory Management
- **Problem**: Images being kept in memory or listeners not removed.
- **Protocol**:
  - Always `dispose()` `ScrollControllers`, `VideoPlayers`, and `AnimationControllers`.
  - Remove listeners from `ChangeNotifier` in `dispose()`.
  - Use `cached_network_image` with proper resizing.

## Optimization Workflow

1.  **Profile**: Run with `Flutter DevTools` (Performance/CPU Profiler).
2.  **Identify**: Find the "Red" (high-rebuild) widgets.
3.  **Scoped Fix**: Apply `Selector` or split the widget.
4.  **Verify**: Re-profile to confirm the "Red" areas are now "Green".

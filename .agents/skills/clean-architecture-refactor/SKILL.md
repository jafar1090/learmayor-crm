---
name: clean-architecture-refactor
description: Use when decoupling UI from business logic, standardizing error handling, or refactoring complex providers.
---

# Clean Architecture Refactor

## Overview

A codebase that mixes UI and Business Logic is hard to test and prone to bugs (like self-triggering updates during a build).

**Core principle:** UI should be a reflection of state. State changes should happen in the Provider/Service layer, never in the `build` method.

## The Architecture Checklist

### 1. Separation of Concerns
- **Problem**: Logic inside `build()` or `onPressed` handlers.
- **Protocol**:
  - Move logic to `Provider` methods.
  - UI should only call `provider.doAction()`.
  - Side effects (navigation, snackbars) should be handled via listeners or dedicated event buses, not inside state-changing methods.

### 2. Async Safety
- **Problem**: Updating state after an `await` without checking if the component is still active.
- **Protocol**:
  - Always check `if (!mounted) return` in Widgets.
  - In Providers, use high-level flags (`isLoading`, `hasError`) and ensure state isn't updated if another action has superseded the current one.

### 3. Centralized State Transitions
- **Problem**: Multiple places setting `phase = ...` or `status = ...`.
- **Protocol**:
  - Create internal `_transitionTo(NewState)` methods to handle side effects (logging, analytics, cleanup) consistently.

### 4. Error Handling
- **Problem**: Try/catch blocks scattered everywhere with different error UI.
- **Protocol**:
  - Standardize error responses (e.g., an `ErrorMessage` model).
  - Use a global error handler or a dedicated `ErrorProvider`.

## Refactoring Workflow

1.  **Extract**: Identify logic in the `.dart` UI file and move it to the corresponding `Provider`.
2.  **Simplify**: Replace complex logic chains with single, descriptive method calls.
3.  **Validate**: Ensure the UI only "listens" and "triggers", never "calculates".

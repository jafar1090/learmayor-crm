---
name: secure-backend-development
description: Use when building or refactoring backend endpoints to ensure they are protected against common vulnerabilities (IDOR, Auth bypass, Injection).
---

# Secure Backend Development

## Overview

Security is not an afterthought. Every endpoint must be designed with the assumption that the client is untrusted and malicious actors will attempt to bypass logic.

**Core principle:** NEVER trust client-provided data (IDs, scores, levels) for authority. ALWAYS verify identity and permissions on the server.

## The Secure Checklist

### 1. Identity Verification (No Impersonation)
- **Problem**: Trusting a `uid` or `userId` passed in the request body/query.
- **Protocol**: 
  - Extract the user's identity from a cryptographically signed session token (JWT, Firebase ID Token).
  - Compare the requested action's target ID with the token's authenticated ID.
  - Reject requests where `req.body.uid !== auth.uid`.

### 2. Authority of Truth (No Client Logic)
- **Problem**: Client tells the server "I scored 100" or "I completed Level 5".
- **Protocol**:
  - The server should maintain the state or verify the math.
  - If a level is completed, the server should verify the game session existed and the score is mathematically possible based on the duration and difficulty.

### 3. Input Sanitization & Validation
- **Problem**: SQL Injection, NoSQL Injection, or malformed data causing crashes.
- **Protocol**:
  - Use Mongoose models or Schema validators (Joi/Zod).
  - Treat all strings as potentially malicious.

### 4. Direct Object Reference (IDOR)
- **Problem**: `GET /api/user/profile?uid=ANOTHER_USER_ID` returns private data.
- **Protocol**:
  - Check if the authenticated user has permission to view/modify the resource.

## Implementation Steps

1. **Add Middleware**: Ensure every sensitive route uses an `isAuthenticated` middleware that populates `req.user`.
2. **Standardize Responses**: Do not leak stack traces or internal DB IDs in error messages.
3. **Audit Data Flow**: Trace how a request travels from the route handler to the database. Ensure validation happens early.

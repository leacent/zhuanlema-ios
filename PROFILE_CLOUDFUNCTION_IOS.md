# User Profile Changes via CloudBase Cloud Functions (iOS)

This document describes the **cloud-function-based** approach for user profile changes in the Zhuanlema iOS app. All profile reads and updates go through CloudBase HTTP API → cloud functions (no direct database writes from the app).

---

## Overview

| Operation        | Cloud function   | Auth                     | Purpose                    |
|-----------------|------------------|--------------------------|----------------------------|
| Get profile     | `getProfile`     | `Authorization: Bearer <accessToken>` | Read current user profile  |
| Update profile  | `updateProfile`  | Same                     | Update nickname and/or avatar URL |
| Upload avatar   | `uploadAvatar`   | Same                     | Upload image → get URL → then call updateProfile |

- **Base URL**: `https://{envId}.api.tcloudbasegateway.com` (e.g. `https://prod-1-3g3ukjzod3d5e3a1.api.tcloudbasegateway.com`)
- **Endpoint**: `POST /v1/functions/{functionName}`
- **Headers**:
  - `Content-Type: application/json`
  - `Authorization: Bearer <userAccessToken>` for user-scoped functions (getProfile, updateProfile, uploadAvatar)
  - `X-CloudBase-ApiKey: <publishableKey>` (optional but recommended for gateway)

For **anonymous / API-key–only** calls (e.g. getPosts), use `Authorization: Bearer <publishableKey>` instead of the user token. Profile-related functions **must** use the **user’s access token**.

---

## 1. getProfile (Read)

- **Function name**: `getProfile`
- **Method**: POST
- **Headers**: `Authorization: Bearer <accessToken>`, `X-CloudBase-ApiKey: <publishableKey>`, `Content-Type: application/json`
- **Body**: `{}` (empty object is fine)

**Response (success)**:
```json
{
  "result": {
    "success": true,
    "data": {
      "_id": "userId",
      "nickname": "用户昵称",
      "avatar": "https://...",
      "phone_number": null,
      "created_at": 1234567890.0
    }
  }
}
```

**Response (failure)**:
```json
{ "result": { "success": false, "message": "未登录" } }
```

**iOS**: Already implemented via `CloudBaseDatabaseService.getProfile(accessToken:)` and `UserRepository.refreshProfile()`. Decode `result.data` with `GetProfileData` and call `.toUser()` to get `User`.

---

## 2. updateProfile (Update nickname / avatar URL)

- **Function name**: `updateProfile`
- **Method**: POST
- **Headers**: Same as getProfile (user access token + ApiKey).
- **Body**: JSON with optional fields (only send fields you want to update):
  - `nickname` (string, optional): new nickname
  - `avatar` (string, optional): new avatar URL (e.g. from uploadAvatar)

**Example body**:
```json
{ "nickname": "新昵称" }
```
```json
{ "avatar": "https://xxx.tcb.qcloud.la/avatars/xxx/123.jpg" }
```
```json
{ "nickname": "新昵称", "avatar": "https://..." }
```

**Response (success)**:
```json
{ "result": { "success": true, "message": "更新成功" } }
```

**Response (failure)**:
```json
{ "result": { "success": false, "message": "未登录" } }
```

**iOS (to implement)**:
- URL: `CloudBaseConfig.functionURL(name: "updateProfile")`
- Request: Use `CloudBaseConfig.configureRequestWithAccessToken(&request, body: body, accessToken: token)`.
- Body: `["nickname": nickname, "avatar": avatar]` (omit nil/empty; only include non-empty values).
- Parse `result` as `{ success: Bool, message: String? }`. On success, call `refreshProfile()` and update local `currentUser` (e.g. persist with `UserDefaults`).

---

## 3. uploadAvatar (Upload image → get URL)

- **Function name**: `uploadAvatar`
- **Method**: POST
- **Headers**: Same as getProfile (user access token + ApiKey).
- **Body**:
  - `imageBase64`: string – JPEG image encoded as base64 (with or without `data:image/jpeg;base64,` prefix; the function strips the prefix).

**Constraints** (enforced by cloud function):
- Image size ≤ 2 MB after base64 decode.

**Response (success)**:
```json
{ "result": { "success": true, "url": "https://..." } }
```

**Response (failure)**:
```json
{ "result": { "success": false, "message": "缺少 imageBase64" } }
```

**iOS (to implement)**:
1. Compress and encode image: use `CloudBaseStorageService.compressAndEncodeForAvatar(_ image: UIImage) -> String?` (or equivalent) to get base64.
2. POST to `CloudBaseConfig.functionURL(name: "uploadAvatar")` with `CloudBaseConfig.configureRequestWithAccessToken(&request, body: ["imageBase64": base64], accessToken: token)`.
3. Decode `result` as `{ success: Bool, url: String?, message: String? }`. On success, use `url` as new avatar URL and call `updateProfile` with `avatar: url`, then refresh local user (e.g. `refreshProfile()` and save to UserDefaults).

---

## iOS Integration Checklist

When re-enabling “Edit profile” in the app:

1. **Update profile (nickname and/or avatar URL)**  
   - Add a method that calls the `updateProfile` cloud function via the same HTTP gateway and `configureRequestWithAccessToken`.  
   - Reuse `CloudBaseHTTPClient.callWithAccessToken(name: "updateProfile", body: body, accessToken: accessToken)` once that method is wired to the gateway (it already exists in concept; the implementation was removed from `CloudBaseDatabaseService` and `UserRepository` to leave only cloud-function-based flow).

2. **Upload avatar**  
   - Add a method that calls the `uploadAvatar` cloud function with `imageBase64`, then passes the returned `url` to the update-profile flow above.  
   - Client-side: keep using `CloudBaseStorageService.compressAndEncodeForAvatar` to stay under the 2 MB limit.

3. **Auth and errors**  
   - Use the logged-in user’s access token for all three functions.  
   - On 401 or token-expired behavior, clear local login state and prompt re-login (same as current `UserRepository` session-expired handling).

4. **Suggested places in code**  
   - **CloudBaseDatabaseService**: Re-add `updateProfile(nickname:avatar:accessToken:)` and `uploadAvatar(accessToken:imageBase64:)` that call `CloudBaseHTTPClient.callWithAccessToken` for `updateProfile` and `uploadAvatar` respectively.  
   - **UserRepository**: Re-add `updateProfile(nickname:avatar:)` that gets token, calls `databaseService.updateProfile`, then `refreshProfile()` and saves `currentUser` to UserDefaults.  
   - **EditProfileView**: Use `UserRepository.updateProfile` on Save; for avatar, call `databaseService.uploadAvatar` then update profile with the returned URL (or a single “save” that uploads avatar if changed, then updates nickname/avatar via `updateProfile`).

---

## CloudBase MCP Reference

For managing or invoking these functions via MCP:

- **invokeFunction**: `name` = `getProfile` | `updateProfile` | `uploadAvatar`, `params` = body as object (for updateProfile: `nickname`/`avatar`; for uploadAvatar: `imageBase64`). Note: MCP runs in a tooling context; user token must be supplied by the app when calling from iOS.
- **callCloudApi**: For lower-level CloudBase API operations (e.g. `scf` service); typically the app uses the HTTP gateway above, not callCloudApi directly.

The iOS app does **not** call MCP; it calls the CloudBase HTTP gateway (`POST /v1/functions/{name}`) with the headers and body described in this document.

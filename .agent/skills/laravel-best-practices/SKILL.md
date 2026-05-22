---
name: laravel-best-practices
description: >
  Enforces Laravel SaaS project architecture rules for a dual-dashboard system (Admin + User App).
  Use this skill whenever you are writing, reviewing, generating, or modifying any Laravel code in
  this project — including controllers, services, routes, form requests, API resources, models, or
  middleware. Trigger any time the user mentions controllers, routes, services, requests, resources,
  or asks to scaffold, generate, or refactor any Laravel class. Even if the user just says "create a
  controller" or "add a route", always apply these rules before writing any code.
---

# Laravel SaaS Architecture Skill

This project has two dashboards — **Admin** and **User App** — with strict separation of concerns.
Before writing any code, determine which dashboard the feature belongs to, then follow the rules below.

---

## 1. Controllers

| Dashboard | Namespace | Directory |
|-----------|-----------|-----------|
| Admin | `App\Http\Controllers\Admin\` | `app/Http/Controllers/Admin/` |
| User App | `App\Http\Controllers\App\` | `app/Http/Controllers/App/` |

- **Never** mix admin and app logic in the same controller.
- Controllers must be **thin** — delegate all business logic to a Service.
- Controllers only: validate (via FormRequest), call Service, return Resource.

```php
// ✅ Correct
namespace App\Http\Controllers\Admin;

class UserController extends Controller
{
    public function __construct(private UserManagementService $service) {}

    public function store(StoreUserRequest $request): JsonResponse
    {
        $user = $this->service->create($request->validated());
        return new UserResource($user);
    }
}
```

---

## 2. Services

| Dashboard | Directory | Naming |
|-----------|-----------|--------|
| Admin | `app/Services/Admin/` | `{Resource}Service.php` |
| User App | `app/Services/App/` | `{Resource}Service.php` |

- All business logic lives here — no logic in controllers or models.
- Example: `UserManagementService.php`, `OrderProcessingService.php`

```php
// ✅ Correct
namespace App\Services\Admin;

class UserManagementService
{
    public function create(array $data): User
    {
        // business logic here
        return User::create($data);
    }
}
```

---

## 3. Routes

| Dashboard | File | Prefix |
|-----------|------|--------|
| Admin | `routes/admin.php` | `/api/v1/admin` |
| User App | `routes/app.php` | `/api/v1/app` |

- **Never** add role-specific routes in `routes/api.php`.
- Always wrap with the appropriate middleware group.

```php
// routes/admin.php ✅
Route::prefix('api/v1/admin')->middleware(['auth:sanctum', 'role:admin'])->group(function () {
    Route::apiResource('users', Admin\UserController::class);
});

// routes/app.php ✅
Route::prefix('api/v1/app')->middleware(['auth:sanctum', 'role:app_user'])->group(function () {
    Route::apiResource('orders', App\OrderController::class);
});
```

---

## 4. Form Requests

| Dashboard | Directory | Naming |
|-----------|-----------|--------|
| Admin | `app/Http/Requests/Admin/` | `{Action}{Resource}Request.php` |
| User App | `app/Http/Requests/App/` | `{Action}{Resource}Request.php` |

- Always create a FormRequest for `store` and `update` actions — never use `$request->all()` or `$request->validate()` inline.
- Examples: `StoreUserRequest`, `UpdateOrderRequest`

```php
// ✅ app/Http/Requests/Admin/StoreUserRequest.php
namespace App\Http\Requests\Admin;

class StoreUserRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'name'  => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users'],
        ];
    }
}
```

---

## 5. API Resources

| Dashboard | Directory |
|-----------|-----------|
| Admin | `app/Http/Resources/Admin/` |
| User App | `app/Http/Resources/App/` |

- **Never** return raw Eloquent models from controllers.
- Always wrap responses in an API Resource.

```php
// ✅ app/Http/Resources/Admin/UserResource.php
namespace App\Http\Resources\Admin;

class UserResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'    => $this->id,
            'name'  => $this->name,
            'email' => $this->email,
        ];
    }
}
```

---

## 6. Models

- Models are **always shared** — never split by role or dashboard.
- All models go in `app/Models/`.
- Models hold relationships, scopes, casts — **no business logic**.

```
✅ app/Models/User.php      — shared
✅ app/Models/Order.php     — shared
❌ app/Models/Admin/User.php — NEVER
```

---

## 7. Middleware

| Middleware | Purpose | Role |
|------------|---------|------|
| `auth:sanctum` | Authentication | - |
| `role:admin` | Admin Dashboard Access | `admin` |
| `role:app_user` | User App (Influencer) Access | `app_user` |

- **Never** do role checks inside controllers (`if ($user->role === 'admin')`).
- Apply middleware at the route level (in route files or route service provider).

```php
// ✅ Role check via middleware on the route
Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {
    Route::apiResource('users', Admin\UserController::class);
});

// ❌ Never inside a controller
if (auth()->user()->role !== 'admin') abort(403);
```

---

## Quick Checklist Before Writing Any Code

Before generating any class, verify:

- [ ] Which dashboard does this belong to? → Admin or App?
- [ ] Controller in correct namespace and directory?
- [ ] Logic delegated to a Service (not inline in controller)?
- [ ] FormRequest created for store/update?
- [ ] Response wrapped in API Resource?
- [ ] Route added to correct file (`admin.php` / `app.php`) with correct prefix?
- [ ] No role checks inside the controller?
- [ ] Model placed in `app/Models/` (shared)?

---

## File Generation Reference

When scaffolding a resource (e.g., `Order` for Admin), generate **all** of these:

```
app/Http/Controllers/Admin/OrderController.php
app/Services/Admin/OrderService.php
app/Http/Requests/Admin/StoreOrderRequest.php
app/Http/Requests/Admin/UpdateOrderRequest.php
app/Http/Resources/Admin/OrderResource.php
app/Models/Order.php                          ← shared
routes/admin.php                              ← add routes here
```

See `references/examples.md` for full boilerplate code for each file type.

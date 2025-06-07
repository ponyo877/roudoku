# Backend Refactor Plan (Clean Architecture)

## 🚀 Goal

Refactor your scattered Go backend into **one cohesive folder** that follows a Clean-Architecture-inspired layout and is easy to read, test, and modify.

---

## 📁 Target Directory Structure

```text
myapp/server/                ← new root (pick a name)
│
├── cmd/              ← entry points (CLI, server, tasks)
│   └── server/
│       └── main.go
│
├── models/           ← pure domain structs + value logic
│
├── repository/       ← interfaces + concrete DB impls
│
├── services/         ← business/use-case layer
│
├── handlers/         ← transport layer (HTTP/gRPC/etc.)
│
├── migrations/       ← SQL or Go migration files
│
├── internal/         ← helper pkgs not exported
│   ├── config/
│   └── middleware/
│
└── go.mod
````

---

## 🗺️ Mapping Old → New

| Current folder | Typical contents                  | Move to…                              | Notes                                  |
| -------------- | --------------------------------- | ------------------------------------- | -------------------------------------- |
| **backend**    | Mixed handlers & business logic   | `handlers/`, `services/`              | Split HTTP transport from core rules   |
| **cmd**        | `main.go`, CLI flags              | `cmd/server/`                         | One `main.go` per binary               |
| **internal**   | Helpers, configs                  | `internal/` sub-packages              | E.g. `internal/config`                 |
| **migrations** | SQL migration files               | `migrations/`                         | No change                              |
| **pkg**        | DB adapters, models, misc helpers | `repository/`, `models/`, `internal/` | Only keep `pkg/` for truly public APIs |

---

## 🔄 Dependency Rule

```text
handlers  --->  services  --->  repository  --->  (DB / external)
    ^             ^                ^
    |             |                |
    |             |                +--- models
    |             +-------------------- models
    +---------------------------------- models
```

*Higher layers never import lower-level code.*

---

## 🛠️ Step-by-Step Migration

1. **Create new root**

   ```bash
   mkdir -p ~/code/myapp && cd ~/code/myapp
   go mod init github.com/yourname/myapp
   ```

2. **Move domain structs → `models/`**
   *Keep only pure data & invariants.*

3. **Define repository interfaces** in `repository/`, then add concrete impls (`postgres`, `sqlite`, `mock`).

4. **Refactor business logic** into `services/`; inject repositories via constructors.

5. **Thin transport layer** in `handlers/` (HTTP / gRPC):

   ```go
   // handlers/http/user.go
   func (h *Handler) CreateUser(w http.ResponseWriter, r *http.Request) {
       var req dto.CreateUserRequest
       if err := json.NewDecoder(r.Body).Decode(&req); err != nil { … }

       user, err := h.userSvc.Create(r.Context(), req)
       if err != nil { … }

       json.NewEncoder(w).Encode(dto.FromUser(user))
   }
   ```

6. **Wire everything in `cmd/server/main.go`:**

   ```go
   func main() {
       cfg := config.Load()

       db  := postgres.Connect(cfg.DB)
       userRepo := postgres.NewUserRepository(db)
       userSvc  := services.NewUserService(userRepo)

       router := handlers.NewHTTPRouter(userSvc)
       log.Fatal(http.ListenAndServe(cfg.Port, router))
   }
   ```

7. **Keep migrations** alongside code; run via CI (`goose -dir migrations up`).

---

## 🧪 Testing Matrix

| Layer        | Test style                               |
| ------------ | ---------------------------------------- |
| `models`     | Pure unit tests                          |
| `services`   | Unit & table tests (repositories mocked) |
| `repository` | Integration tests vs Dockerised DB       |
| `handlers`   | `httptest` server for end-to-end routes  |

---

## 🔧 CI & Tooling Quick Wins

```bash
go vet ./...
staticcheck ./...
go test ./... -race -cover
golangci-lint run
```

Use `task` or `mage` for unified dev commands; add pre-commit hooks for `goimports` and `go mod tidy`.

---

## ✅ Migration Checklist

* [ ] Copy old code to a scratch branch
* [ ] Identify domain structs and move to `models/`
* [ ] Create repository interfaces in `repository/`
* [ ] Implement DB adapters (`postgres`, etc.)
* [ ] Refactor services to accept interfaces
* [ ] Slice out HTTP handlers (no direct DB access)
* [ ] Update imports, run `go vet` & `go test`
* [ ] Write/green tests for each layer
* [ ] Remove obsolete folders, tidy `go.mod`
* [ ] Push branch, open PR, ensure CI passes

---

### 🎉 Result

A **decoupled, testable, and technology-agnostic** backend that lets you:

* swap Postgres ↔ Dynamo by editing only `repository/*`,
* add new transports (GraphQL, Kafka) without touching core logic,
* scale confidently as the codebase grows.

Happy refactoring! 🚀

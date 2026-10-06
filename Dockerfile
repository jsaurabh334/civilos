# Backend Builder Stage
FROM golang:alpine AS backend-builder
WORKDIR /app
COPY backend/go.mod backend/go.sum ./
RUN go mod download
COPY backend/ ./
RUN go build -o /server cmd/server/main.go

# Frontend Builder Stage
FROM ghcr.io/cirruslabs/flutter:3.29.0 AS frontend-builder
WORKDIR /app
COPY frontend/ ./
RUN flutter pub get
RUN flutter build web

# Runtime Stage
FROM alpine:latest
RUN apk add --no-cache sqlite-libs ca-certificates
WORKDIR /app
COPY --from=backend-builder /server .
COPY --from=frontend-builder /app/build/web ./web
EXPOSE 8080
CMD ["./server"]

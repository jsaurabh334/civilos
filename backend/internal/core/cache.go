package core

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"time"

	"github.com/redis/go-redis/v9"
)

var (
	CacheClient *redis.Client
	ctx         = context.Background()
)

// InitCache initializes the Redis client
func InitCache() {
	redisURL := os.Getenv("REDIS_URL")
	if redisURL == "" {
		redisURL = "localhost:6379" // default for local dev
	}

	CacheClient = redis.NewClient(&redis.Options{
		Addr:     redisURL,
		Password: "", // no password set
		DB:       0,  // use default DB
	})

	_, err := CacheClient.Ping(ctx).Result()
	if err != nil {
		log.Printf("Warning: Failed to connect to Redis at %s: %v", redisURL, err)
		// We don't panic so the app can still run without Redis
		CacheClient = nil
	} else {
		log.Printf("Connected to Redis at %s", redisURL)
	}
}

// SetCache marshals data to JSON and stores it in Redis with an expiration
func SetCache(key string, value interface{}, expiration time.Duration) error {
	if CacheClient == nil {
		return nil
	}

	bytes, err := json.Marshal(value)
	if err != nil {
		return err
	}

	return CacheClient.Set(ctx, key, bytes, expiration).Err()
}

// GetCache retrieves and unmarshals JSON data from Redis
func GetCache(key string, dest interface{}) error {
	if CacheClient == nil {
		return redis.Nil
	}

	val, err := CacheClient.Get(ctx, key).Result()
	if err != nil {
		return err
	}

	return json.Unmarshal([]byte(val), dest)
}

// InvalidateCache deletes a key from Redis
func InvalidateCache(key string) error {
	if CacheClient == nil {
		return nil
	}
	return CacheClient.Del(ctx, key).Err()
}

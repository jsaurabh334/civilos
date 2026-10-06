package ws

import (
	"log/slog"
	"sync"
)

// Client represents a single websocket connection
type Client struct {
	UserID uint
	Send   chan []byte
}

// Hub maintains a set of active clients grouped by user ID
type Hub struct {
	mu      sync.RWMutex
	clients map[uint]map[*Client]bool
}

var GlobalHub = &Hub{
	clients: make(map[uint]map[*Client]bool),
}

func (h *Hub) Register(client *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.clients[client.UserID] == nil {
		h.clients[client.UserID] = make(map[*Client]bool)
	}
	h.clients[client.UserID][client] = true
	slog.Debug("websocket client connected", slog.Uint64("user_id", uint64(client.UserID)))
}

func (h *Hub) Unregister(client *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if clients, ok := h.clients[client.UserID]; ok {
		delete(clients, client)
		close(client.Send)
		if len(clients) == 0 {
			delete(h.clients, client.UserID)
		}
	}
	slog.Debug("websocket client disconnected", slog.Uint64("user_id", uint64(client.UserID)))
}

// SendToUser sends a message to all connections for a given user
func (h *Hub) SendToUser(userID uint, message []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()
	if clients, ok := h.clients[userID]; ok {
		for client := range clients {
			select {
			case client.Send <- message:
			default:
				// Client's send buffer is full, drop message
				slog.Warn("websocket client buffer full, dropping message",
					slog.Uint64("user_id", uint64(userID)))
			}
		}
	}
}

package ws

import (
	"log/slog"
	"time"

	"github.com/gofiber/contrib/websocket"
	"github.com/gofiber/fiber/v2"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 4096
)

// AuthWS extracts user_id from the fiber context for WebSocket upgrade
func AuthWS(c *fiber.Ctx) error {
	userID := c.Locals("user_id")
	if userID == nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}
	return nil
}

// HandleWebSocket handles the WebSocket connection lifecycle
func HandleWebSocket(c *websocket.Conn) {
	userID := c.Locals("user_id").(uint)
	client := &Client{
		UserID: userID,
		Send:   make(chan []byte, 256),
	}
	GlobalHub.Register(client)

	// Start writer goroutine
	go writePump(c, client)

	// Read loop (in current goroutine)
	readPump(c, client)
}

func readPump(c *websocket.Conn, client *Client) {
	defer func() {
		GlobalHub.Unregister(client)
		c.Close()
	}()

	c.SetReadLimit(maxMessageSize)
	c.SetReadDeadline(time.Now().Add(pongWait))
	c.SetPongHandler(func(string) error {
		c.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, _, err := c.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err,
				websocket.CloseGoingAway, websocket.CloseNormalClosure) {
				slog.Debug("websocket read error",
					slog.Uint64("user_id", uint64(client.UserID)),
					slog.String("error", err.Error()))
			}
			break
		}
		// Client-to-server messages are not processed for now
		// Future: could support typing indicators, read receipts, etc.
	}
}

func writePump(c *websocket.Conn, client *Client) {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.Close()
	}()

	for {
		select {
		case message, ok := <-client.Send:
			if !ok {
				c.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			c.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}
		case <-ticker.C:
			c.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

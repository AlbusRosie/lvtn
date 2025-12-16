import { io } from 'socket.io-client';
import AuthService from './AuthService';

class SocketService {
  constructor() {
    this.socket = null;
    this.isConnected = false;
    this.listeners = new Map();
  }

  connect() {
    if (this.socket?.connected) {
      return;
    }

    const token = AuthService.getToken();
    if (!token) {
      console.warn('No token available for socket connection');
      return;
    }

    const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:3000';
    this.socket = io(apiUrl, {
      auth: {
        token: token
      },
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionAttempts: 5
    });

    this.socket.on('connect', () => {
      console.log('[Socket.IO] ✅ Connected:', this.socket.id);
      console.log('[Socket.IO] Socket connected status:', this.socket.connected);
      this.isConnected = true;
      
      // Join branch room if user has branch_id
      const user = AuthService.getUser();
      console.log('[Socket.IO] User info:', { id: user?.id, role_id: user?.role_id, branch_id: user?.branch_id });
      
      if (user?.branch_id) {
        console.log(`[Socket.IO] Emitting join-branch event for branch:${user.branch_id}`);
        this.socket.emit('join-branch', user.branch_id);
        console.log(`[Socket.IO] ✅ Emitted join-branch for branch:${user.branch_id}`);
      }
      
      // Join admin room if user is admin
      if (user?.role_id === 1) {
        console.log('[Socket.IO] Emitting join-admin event');
        this.socket.emit('join-admin');
        console.log('[Socket.IO] ✅ Emitted join-admin');
      }
      
      // Join delivery room if user is delivery staff
      if (user?.role_id === 7) {
        console.log(`[Socket.IO] Emitting join-delivery event for user:${user.id}`);
        this.socket.emit('join-delivery');
        console.log(`[Socket.IO] ✅ Emitted join-delivery for user:${user.id}`);
      }
      
      // Emit a test event to verify connection
      console.log('[Socket.IO] Socket connection established and rooms joined');
      
      // Re-register all listeners after connection (in case they were registered before connection)
      console.log('[Socket.IO] Re-registering all listeners after connection...');
      console.log('[Socket.IO] Total listeners to re-register:', this.listeners.size);
      this.listeners.forEach((callbacks, event) => {
        console.log(`[Socket.IO] Re-registering ${callbacks.length} listener(s) for event: ${event}`);
        callbacks.forEach(({ wrapped }) => {
          if (this.socket) {
            this.socket.on(event, wrapped);
            console.log(`[Socket.IO] ✅ Re-registered listener for event: ${event}`);
          }
        });
      });
      console.log('[Socket.IO] ✅ Finished re-registering all listeners');
      
      // Verify room membership after a short delay
      setTimeout(() => {
        console.log('[Socket.IO] Verifying room membership...');
        console.log('[Socket.IO] Socket ID:', this.socket.id);
        console.log('[Socket.IO] Socket connected:', this.socket.connected);
        console.log('[Socket.IO] Active listeners:', Array.from(this.listeners.keys()));
        this.listeners.forEach((callbacks, event) => {
          const internalCount = callbacks ? callbacks.length : 0;
          if (this.socket && typeof this.socket.listenerCount === 'function') {
            const nativeCount = this.socket.listenerCount(event);
            console.log(`[Socket.IO] Event '${event}': ${internalCount} listener(s) (internal), ${nativeCount} listener(s) (native)`);
          } else {
            console.log(`[Socket.IO] Event '${event}': ${internalCount} listener(s) (internal tracking)`);
          }
        });
      }, 500);
    });

    this.socket.on('disconnect', () => {
      console.log('Socket disconnected');
      this.isConnected = false;
    });

    this.socket.on('connect_error', (error) => {
      console.error('Socket connection error:', error);
      this.isConnected = false;
    });

    this.socket.on('reconnect', (attemptNumber) => {
      console.log('Socket reconnected after', attemptNumber, 'attempts');
      this.isConnected = true;
      
      // Rejoin rooms after reconnection
      const user = AuthService.getUser();
      if (user?.branch_id) {
        this.socket.emit('join-branch', user.branch_id);
      }
      if (user?.role_id === 1) {
        this.socket.emit('join-admin');
      }
      if (user?.role_id === 7) {
        this.socket.emit('join-delivery');
      }
    });
  }

  disconnect() {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
      this.isConnected = false;
      this.listeners.clear();
    }
  }

  on(event, callback) {
    // Wrap callback to add logging for debugging
    const wrappedCallback = (...args) => {
      console.log(`[Socket.IO] ✅ Received event: ${event}`, args);
      console.log(`[Socket.IO] Event data:`, JSON.stringify(args, null, 2));
      try {
        callback(...args);
      } catch (error) {
        console.error(`[Socket.IO] ❌ Error in callback for ${event}:`, error);
        console.error(`[Socket.IO] Error stack:`, error.stack);
      }
    };
    
    // Log which component/function is registering this listener (for debugging)
    const stack = new Error().stack;
    const caller = stack?.split('\n')[2]?.trim() || 'unknown';
    console.log(`[Socket.IO] 📝 Registering listener for '${event}' from:`, caller);
    
    // Ensure socket is initialized
    if (!this.socket) {
      console.log(`[Socket.IO] Socket not initialized, connecting...`);
      this.connect();
    }
    
    // Register listener immediately if socket exists
    if (this.socket) {
      // Check if listener already exists (if method available)
      const hasListener = typeof this.socket.hasListeners === 'function' 
        ? this.socket.hasListeners(event) 
        : false;
      console.log(`[Socket.IO] 🔵 Registering listener for event: ${event}`);
      console.log(`[Socket.IO] Socket ID: ${this.socket?.id || 'undefined'}`);
      console.log(`[Socket.IO] Socket connected: ${this.socket?.connected || false}`);
      console.log(`[Socket.IO] Already has listener: ${hasListener}`);
      
      this.socket.on(event, wrappedCallback);
      console.log(`[Socket.IO] ✅ Registered listener for event: ${event} (socket exists)`);
      
      // Log listener count if method is available
      if (typeof this.socket.listenerCount === 'function') {
        console.log(`[Socket.IO] Listener count after registration: ${this.socket.listenerCount(event)}`);
      } else {
        console.log(`[Socket.IO] Listener count method not available (using internal tracking)`);
      }
      
      // Track listeners for cleanup (store both original and wrapped)
      if (!this.listeners.has(event)) {
        this.listeners.set(event, []);
      }
      this.listeners.get(event).push({ original: callback, wrapped: wrappedCallback });
      const totalListeners = this.listeners.get(event).length;
      console.log(`[Socket.IO] ✅ Tracked listener for event: ${event} (total: ${totalListeners})`);
      
      // If socket is already connected, ensure listener is active
      if (this.socket.connected) {
        console.log(`[Socket.IO] ⚠️ Socket already connected, ensuring listener is active for: ${event}`);
        // Double-check: try to register again to ensure it's active
        this.socket.on(event, wrappedCallback);
        console.log(`[Socket.IO] ✅ Double-registered listener for event: ${event} (socket already connected)`);
      }
    } else {
      // If socket not created yet, wait for connection
      console.log(`[Socket.IO] Socket not ready, will register after connection...`);
      
      // Track listeners for cleanup BEFORE connection (so they can be re-registered)
      if (!this.listeners.has(event)) {
        this.listeners.set(event, []);
      }
      this.listeners.get(event).push({ original: callback, wrapped: wrappedCallback });
      console.log(`[Socket.IO] ✅ Tracked listener for event: ${event} (will register after connection, total: ${this.listeners.get(event).length})`);
      
      const connectHandler = () => {
        if (this.socket) {
          this.socket.on(event, wrappedCallback);
          console.log(`[Socket.IO] ✅ Registered listener for event: ${event} (after connection)`);
          this.socket.off('connect', connectHandler);
        }
      };
      
      // Try to attach to existing socket connection
      setTimeout(() => {
        if (this.socket) {
          if (this.socket.connected) {
            this.socket.on(event, wrappedCallback);
            console.log(`[Socket.IO] ✅ Registered listener for event: ${event} (delayed, connected)`);
          } else {
            this.socket.once('connect', connectHandler);
          }
        } else {
          console.error(`[Socket.IO] ❌ Failed to register listener for ${event}: socket not available after delay`);
        }
      }, 100);
    }
  }

  off(event, callback) {
    if (this.socket) {
      if (callback) {
        const callbacks = this.listeners.get(event);
        if (callbacks) {
          const listener = callbacks.find(l => l.original === callback);
          if (listener) {
            this.socket.off(event, listener.wrapped);
            const index = callbacks.indexOf(listener);
            if (index > -1) {
              callbacks.splice(index, 1);
            }
          }
        }
      } else {
        // Remove all listeners for this event
        const callbacks = this.listeners.get(event);
        if (callbacks) {
          callbacks.forEach(listener => {
            this.socket.off(event, listener.wrapped);
          });
        }
        this.socket.off(event);
        this.listeners.delete(event);
      }
    }
  }

  emit(event, data) {
    if (this.socket?.connected) {
      this.socket.emit(event, data);
    } else {
      console.warn('Socket not connected, cannot emit:', event);
    }
  }

  getConnectionStatus() {
    return this.isConnected && this.socket?.connected;
  }
  
  // Get socket instance (for debugging)
  getSocket() {
    return this.socket;
  }
  
  // Test if listener is registered for an event
  testListener(event) {
    if (!this.socket) {
      console.log(`[Socket.IO] Test listener ${event}: Socket not initialized`);
      return false;
    }
    // Use internal tracking instead of socket.listenerCount (not available in Socket.IO client)
    const listeners = this.listeners.get(event);
    const count = listeners ? listeners.length : 0;
    console.log(`[Socket.IO] Test listener ${event}: ${count} listener(s) registered (internal tracking)`);
    return count > 0;
  }
  
  // Method to wait for connection
  async waitForConnection(maxWait = 5000) {
    if (this.getConnectionStatus()) {
      return true;
    }
    
    if (!this.socket) {
      this.connect();
    }
    
    return new Promise((resolve) => {
      const timeout = setTimeout(() => {
        resolve(false);
      }, maxWait);
      
      if (this.socket) {
        this.socket.once('connect', () => {
          clearTimeout(timeout);
          resolve(true);
        });
      } else {
        clearTimeout(timeout);
        resolve(false);
      }
    });
  }
}

export default new SocketService();

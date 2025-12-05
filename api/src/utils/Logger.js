/**
 * Structured Logging Service
 */

let winston;
try {
    winston = require('winston');
} catch (error) {
    console.warn('[Logger] ⚠️ Winston not installed, using console.log fallback');
    winston = null;
}
const path = require('path');

// Define log levels
const levels = {
    error: 0,
    warn: 1,
    info: 2,
    http: 3,
    debug: 4,
};

// Fallback logger nếu winston không có
const createFallbackLogger = () => {
    const logLevel = process.env.LOG_LEVEL || 'info';
    const levelNames = ['error', 'warn', 'info', 'http', 'debug'];
    const currentLevel = levelNames.indexOf(logLevel);
    
    const log = (level, message, meta = {}) => {
        const levelIndex = levelNames.indexOf(level);
        if (levelIndex <= currentLevel) {
            const timestamp = new Date().toISOString();
            const metaStr = Object.keys(meta).length ? ` ${JSON.stringify(meta)}` : '';
            console.log(`[${timestamp}] ${level.toUpperCase()}: ${message}${metaStr}`);
        }
    };
    
    return {
        log,
        info: (message, meta) => log('info', message, meta),
        error: (message, meta) => log('error', message, meta),
        warn: (message, meta) => log('warn', message, meta),
        debug: (message, meta) => log('debug', message, meta),
        http: (message, meta) => log('http', message, meta)
    };
};

let logger;

if (winston) {
    // Define log colors
    const colors = {
        error: 'red',
        warn: 'yellow',
        info: 'green',
        http: 'magenta',
        debug: 'blue',
    };

    winston.addColors(colors);

    // Custom format for console
    const consoleFormat = winston.format.combine(
        winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        winston.format.colorize({ all: true }),
        winston.format.printf(
            (info) => {
                const { timestamp, level, message, ...meta } = info;
                const metaStr = Object.keys(meta).length ? `\n${JSON.stringify(meta, null, 2)}` : '';
                return `[${timestamp}] ${level}: ${message}${metaStr}`;
            }
        )
    );

    // Custom format for files
    const fileFormat = winston.format.combine(
        winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        winston.format.json()
    );

    // Create transports
    const transports = [
        // Console transport
        new winston.transports.Console({
            format: consoleFormat,
            level: process.env.LOG_LEVEL || 'info',
        }),
        
        // Error log file
        new winston.transports.File({
            filename: path.join('logs', 'error.log'),
            level: 'error',
            format: fileFormat,
            maxsize: 10485760, // 10MB
            maxFiles: 5,
        }),
        
        // Combined log file
        new winston.transports.File({
            filename: path.join('logs', 'combined.log'),
            format: fileFormat,
            maxsize: 10485760, // 10MB
            maxFiles: 10,
        }),
    ];

    // Create logger instance
    logger = winston.createLogger({
        levels,
        transports,
        exitOnError: false,
    });
} else {
    // Use fallback logger
    logger = createFallbackLogger();
}

class Logger {
    /**
     * Log info message
     */
    static info(message, meta = {}) {
        logger.info(message, meta);
    }
    
    /**
     * Log error message
     */
    static error(message, meta = {}) {
        logger.error(message, meta);
    }
    
    /**
     * Log warning message
     */
    static warn(message, meta = {}) {
        logger.warn(message, meta);
    }
    
    /**
     * Log debug message
     */
    static debug(message, meta = {}) {
        logger.debug(message, meta);
    }
    
    /**
     * Log HTTP request
     */
    static http(message, meta = {}) {
        logger.http(message, meta);
    }
    
    /**
     * Log chat message processing
     */
    static chatMessage(userId, conversationId, message, intent, responseTime) {
        this.info('Chat message processed', {
            userId,
            conversationId,
            message: message.substring(0, 100), // Truncate long messages
            intent,
            responseTime,
            timestamp: new Date().toISOString()
        });
    }
    
    /**
     * Log tool execution
     */
    static toolExecution(toolName, userId, success, duration, error = null) {
        const level = success ? 'info' : 'error';
        logger.log(level, 'Tool executed', {
            toolName,
            userId,
            success,
            duration,
            error: error?.message,
            timestamp: new Date().toISOString()
        });
    }
    
    /**
     * Log AI service call
     */
    static aiCall(service, userId, success, duration, tokensUsed = null) {
        this.info('AI service called', {
            service,
            userId,
            success,
            duration,
            tokensUsed,
            timestamp: new Date().toISOString()
        });
    }
    
    /**
     * Log booking event
     */
    static bookingEvent(event, userId, branchId, reservationId = null, details = {}) {
        this.info('Booking event', {
            event, // 'created', 'cancelled', 'confirmed', etc.
            userId,
            branchId,
            reservationId,
            ...details,
            timestamp: new Date().toISOString()
        });
    }
    
    /**
     * Express request logger middleware
     */
    static requestMiddleware(req, res, next) {
        const start = Date.now();
        
        res.on('finish', () => {
            const duration = Date.now() - start;
            logger.http('HTTP Request', {
                method: req.method,
                url: req.url,
                statusCode: res.statusCode,
                duration,
                userId: req.user?.id,
                ip: req.ip,
                userAgent: req.get('user-agent')
            });
        });
        
        next();
    }
}

module.exports = Logger;


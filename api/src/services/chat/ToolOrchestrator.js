const { getToolByName, USER_ROLES } = require('./ToolRegistry');
const ApiError = require('../../api-error');
const knex = require('../../database/knex');
class ToolOrchestrator {
    constructor() {
        this.rateLimitCache = new Map(); 
        this.toolHandlers = null; 
    }
    async validateToolCall(toolName, parameters, userContext) {
        const toolDef = getToolByName(toolName);
        if (!toolDef) {
            throw new ApiError(400, `Tool không tồn tại: ${toolName}`);
        }
        if (toolDef.require_auth && !userContext.userId) {
            throw new ApiError(401, `Tool "${toolName}" yêu cầu đăng nhập`);
        }
        const userRole = this._getUserRole(userContext);
        if (!toolDef.allowed_roles.includes(userRole)) {
            throw new ApiError(403, `Bạn không có quyền sử dụng chức năng này. User role: ${userRole}, attempted to access restricted tool: ${toolName}`);
        }
        this._validateParameters(parameters, toolDef.parameters);
        await this._checkRateLimit(userContext.userId, toolName, userRole);
        return true;
    }
    _getUserRole(userContext) {
        if (userContext.userId && userContext.role) {
            return userContext.role;
        }
        if (userContext.userId) {
            return USER_ROLES.CUSTOMER;
        }
        return USER_ROLES.GUEST;
    }
    _validateParameters(params, schema) {
        if (!schema || !schema.properties) return;
        const required = schema.required || [];
        for (const field of required) {
            if (params[field] === undefined || params[field] === null) {
                throw new ApiError(400, `Thiếu tham số bắt buộc: ${field}`);
            }
        }
        for (const [key, value] of Object.entries(params)) {
            const propSchema = schema.properties[key];
            if (!propSchema) continue;
            if (value === null && propSchema.nullable) continue;
            if (propSchema.type === 'integer') {
                const numValue = Number(value);
                if (!Number.isInteger(numValue)) {
                    throw new ApiError(400, `"${key}" phải là số nguyên`);
                }
                if (propSchema.minimum !== undefined && numValue < propSchema.minimum) {
                    throw new ApiError(400, `"${key}" phải >= ${propSchema.minimum}`);
                }
                if (propSchema.maximum !== undefined && numValue > propSchema.maximum) {
                    throw new ApiError(400, `"${key}" phải <= ${propSchema.maximum}`);
                }
            }
            if (propSchema.type === 'string' && typeof value !== 'string') {
                throw new ApiError(400, `"${key}" phải là chuỗi`);
            }
            if (propSchema.enum && !propSchema.enum.includes(value)) {
                throw new ApiError(400, `"${key}" phải là một trong: ${propSchema.enum.join(', ')}`);
            }
            if (propSchema.format === 'date') {
                const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
                if (!dateRegex.test(value)) {
                    throw new ApiError(400, `"${key}" phải có định dạng YYYY-MM-DD`);
                }
            }
            if (propSchema.pattern && typeof value === 'string') {
                const regex = new RegExp(propSchema.pattern);
                if (!regex.test(value)) {
                    throw new ApiError(400, `"${key}" không đúng định dạng`);
                }
            }
        }
    }
    async _checkRateLimit(userId, toolName, userRole) {
        const limits = {
            guest: { window: 60000, max: 5 }, 
            customer: { window: 60000, max: 20 }, 
            staff: { window: 60000, max: 50 },
            manager: { window: 60000, max: 100 },
            admin: { window: 60000, max: 999999 }
        };
        const limit = limits[userRole] || limits.guest;
        const key = `${userId || 'anonymous'}:${toolName}`;
        const now = Date.now();
        if (!this.rateLimitCache.has(key)) {
            this.rateLimitCache.set(key, { count: 1, resetAt: now + limit.window });
            return;
        }
        const record = this.rateLimitCache.get(key);
        if (now > record.resetAt) {
            record.count = 1;
            record.resetAt = now + limit.window;
            return;
        }
        record.count++;
        if (record.count > limit.max) {
            throw new ApiError(429, `Bạn đã gọi chức năng này quá nhiều. Vui lòng thử lại sau ${Math.ceil((record.resetAt - now) / 1000)} giây`);
        }
    }
    async executeToolCall(toolName, parameters, userContext) {
        await this.validateToolCall(toolName, parameters, userContext);
        const toolDef = getToolByName(toolName);
        if (!toolDef) {
            throw new ApiError(500, 'Tool handler không tìm thấy');
        }
        if (!this.toolHandlers) {
            this.toolHandlers = require('./ToolHandlers');
        }
        const [moduleName, methodName] = toolDef.handler.split('.');
        const handlerMethod = this.toolHandlers[methodName];
        if (!handlerMethod) {
            throw new ApiError(500, `Method ${methodName} không tồn tại trong ToolHandlers`);
        }
        let finalParams = { ...parameters };
        if (toolDef.inject_user_context) {
            finalParams._user_id = userContext.userId;
            finalParams._user_role = this._getUserRole(userContext);
        }
        if (toolDef.audit_log) {
            await this._logToolUsage(toolName, parameters, userContext);
        }
        try {
            const result = await handlerMethod(finalParams, userContext);
            return {
                success: true,
                data: result,
                tool: toolName
            };
        } catch (error) {
            if (error instanceof ApiError) {
                throw error;
            }
            throw new ApiError(500, `Không thể thực hiện yêu cầu: ${error.message}`);
        }
    }
    async _logToolUsage(toolName, parameters, userContext) {
        try {
            await knex('audit_logs').insert({
                user_id: userContext.userId || null,
                action: `tool_call:${toolName}`,
                details: JSON.stringify({
                    tool: toolName,
                    parameters: parameters,
                    ip: userContext.ip,
                    user_agent: userContext.userAgent
                }),
                ip_address: userContext.ip || null,
                created_at: new Date()
            });
        } catch (error) {
        }
    }
    getAvailableToolsForLLM(userRole = USER_ROLES.GUEST) {
        const { getToolDefinitionsForLLM } = require('./ToolRegistry');
        return getToolDefinitionsForLLM(userRole);
    }
    cleanupRateLimitCache() {
        const now = Date.now();
        for (const [key, record] of this.rateLimitCache.entries()) {
            if (now > record.resetAt) {
                this.rateLimitCache.delete(key);
            }
        }
    }
}
const orchestrator = new ToolOrchestrator();
setInterval(() => {
    orchestrator.cleanupRateLimitCache();
}, 5 * 60 * 1000);
module.exports = orchestrator;

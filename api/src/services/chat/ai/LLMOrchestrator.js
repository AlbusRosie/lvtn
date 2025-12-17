const AIService = require('./AIService');
const IntentDetector = require('../fallback/IntentDetector');
const LegacyFallbackService = require('../fallback/LegacyFallbackService');
const Utils = require('../Utils');
const MessageProcessor = require('../MessageProcessor');
const AnalyticsService = MessageProcessor.AnalyticsService;

class LLMOrchestrator {
    async orchestrate({ message, context, metadata, mergedEntities }) {
        const llmStartTime = Date.now();
        try {
            const aiResult = await AIService.callAI(message, context, (msg, ctx) => LegacyFallbackService.fallbackResponse(msg, ctx));
            const normalizedAiEntities = Utils.normalizeEntityFields(aiResult?.entities || {});
            const llmDuration = Date.now() - llmStartTime;
            if (aiResult?.tool_results && aiResult.tool_results.length > 0) {
                for (const toolResult of aiResult.tool_results) {
                    try {
                        await AnalyticsService.trackToolCall(
                            context.user?.id || null,
                            toolResult.tool,
                            toolResult.success || false,
                            llmDuration / aiResult.tool_results.length,
                            toolResult.error || null
                        );
                    } catch {
                        // Ignore analytics error
                    }
                }
            }
            return {
                ...aiResult,
                intent: aiResult?.intent || IntentDetector.detectIntent(message),
                entities: {
                    ...mergedEntities,
                    ...normalizedAiEntities
                },
                metadata
            };
        } catch (error) {
            try {
                await AnalyticsService.trackEvent(
                    context.user?.id || null,
                    'llm_error',
                    {
                        error: error.message,
                        message: message.substring(0, 100),
                        intent: IntentDetector.detectIntent(message)
                    }
                );
            } catch {
                // Ignore analytics error
            }
            const fallback = await LegacyFallbackService.fallbackResponse(message, context);
            return {
                ...fallback,
                intent: fallback?.intent || IntentDetector.detectIntent(message),
                entities: {
                    ...mergedEntities,
                    ...Utils.normalizeEntityFields(fallback?.entities || {})
                },
                metadata,
                source: 'fallback'
            };
        }
    }
}

module.exports = new LLMOrchestrator();


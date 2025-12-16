# AI Chatbot System Architecture

## Chatbot Architecture Diagram

```mermaid
graph TB
    subgraph "User Input"
        USER[User Message]
    end
    
    subgraph "Chat Service Layer"
        CS[ChatService<br/>Main Orchestrator]
        CONV[ConversationService<br/>Conversation Management]
        MSG[MessageService<br/>Message Storage]
        CTX[ContextService<br/>Context Building]
    end
    
    subgraph "Processing Pipeline"
        ID[IntentDetector<br/>Pattern Matching]
        EE[EntityExtractor<br/>Entity Extraction]
        IR[IntentRouter<br/>Intent Routing]
    end
    
    subgraph "AI Service"
        AI[AIService<br/>Google Gemini AI]
        TO[ToolOrchestrator<br/>Tool Management]
        TR[ToolRegistry<br/>Tool Definitions]
    end
    
    subgraph "Intent Handlers"
        BH[BookingIntentHandler]
        MH[MenuIntentHandler]
        BRH[BranchIntentHandler]
        SH[SearchIntentHandler]
        TH[TakeawayIntentHandler]
        DH[DefaultIntentHandler]
    end
    
    subgraph "Tool Handlers"
        TH1[ToolHandlers<br/>Function Execution]
    end
    
    subgraph "Response Generation"
        RC[ResponseComposer<br/>Response Building]
        RH[ResponseHandler<br/>Response Formatting]
    end
    
    subgraph "Data Sources"
        DB[(MySQL Database)]
        MAP[Mapbox API<br/>Geolocation]
    end
    
    USER -->|Message| CS
    CS -->|Get/Create| CONV
    CS -->|Save| MSG
    CS -->|Build| CTX
    
    CS -->|Detect| ID
    CS -->|Extract| EE
    CS -->|Route| IR
    
    ID -->|Intent| IR
    EE -->|Entities| IR
    CTX -->|Context| IR
    
    IR -->|AI Required| AI
    AI -->|Tool Calling| TO
    TO -->|Validate| TR
    TO -->|Execute| TH1
    
    IR -->|Intent Match| BH
    IR -->|Intent Match| MH
    IR -->|Intent Match| BRH
    IR -->|Intent Match| SH
    IR -->|Intent Match| TH
    IR -->|Intent Match| DH
    
    BH -->|Query| DB
    MH -->|Query| DB
    BRH -->|Query| DB
    SH -->|Query| DB
    TH -->|Query| DB
    
    BRH -->|Geocode| MAP
    
    TH1 -->|Query| DB
    
    BH -->|Result| RC
    MH -->|Result| RC
    BRH -->|Result| RC
    SH -->|Result| RC
    TH -->|Result| RC
    DH -->|Result| RC
    AI -->|Result| RC
    
    RC -->|Format| RH
    RC -->|Save| MSG
    MSG -->|Store| DB
    
    RC -->|Response| USER
```

## Chatbot Processing Flow

```mermaid
sequenceDiagram
    participant U as User
    participant CS as ChatService
    participant CONV as ConversationService
    participant CTX as ContextService
    participant ID as IntentDetector
    participant EE as EntityExtractor
    participant AI as AIService
    participant TO as ToolOrchestrator
    participant IR as IntentRouter
    participant H as IntentHandler
    participant RC as ResponseComposer
    participant DB as Database
    
    U->>CS: Send Message
    CS->>CONV: Get/Create Conversation
    CONV->>DB: Query/Insert
    DB-->>CONV: Conversation
    CONV-->>CS: Conversation
    
    CS->>CTX: Build Context
    CTX->>DB: Get User, Branch, History
    DB-->>CTX: Context Data
    CTX-->>CS: Complete Context
    
    CS->>EE: Extract Entities
    EE-->>CS: Entities (date, time, people)
    
    CS->>ID: Detect Intent
    ID-->>CS: Intent
    
    CS->>AI: Process with AI
    AI->>TO: Execute Tool Calls
    TO->>DB: Query Data
    DB-->>TO: Data Result
    TO-->>AI: Tool Results
    AI-->>CS: AI Response
    
    CS->>IR: Route Intent
    IR->>H: Handle Intent
    H->>DB: Query/Update
    DB-->>H: Result
    H-->>IR: Handler Response
    IR-->>CS: Final Response
    
    CS->>RC: Compose Response
    RC->>DB: Save Messages & Context
    RC-->>CS: Formatted Response
    CS-->>U: Return Response
```

## Components Description

### Core Services
- **ChatService**: Main orchestrator, coordinates all chatbot operations
- **ConversationService**: Manages conversation sessions and context
- **MessageService**: Handles message storage and retrieval
- **ContextService**: Builds conversation context from history and user data

### Processing Components
- **IntentDetector**: Pattern-based intent detection using regex and keyword matching
- **EntityExtractor**: Extracts entities (date, time, people, branch, etc.) from natural language
- **IntentRouter**: Routes detected intents to appropriate handlers

### AI Integration
- **AIService**: Google Gemini AI integration with Tool Calling pattern
- **ToolOrchestrator**: Manages tool execution, validation, and rate limiting
- **ToolRegistry**: Defines available tools and their permissions

### Intent Handlers
- **BookingIntentHandler**: Handles table reservation requests
- **MenuIntentHandler**: Handles menu viewing requests
- **BranchIntentHandler**: Handles branch information and nearest branch queries
- **SearchIntentHandler**: Handles product search requests
- **TakeawayIntentHandler**: Handles takeaway and delivery order requests
- **DefaultIntentHandler**: Handles general inquiries and fallback

### Response Generation
- **ResponseComposer**: Builds and formats bot responses
- **ResponseHandler**: Generates suggestions and action buttons

## Supported Intents

1. **greeting** - Welcome message
2. **book_table** - Table reservation
3. **view_menu** - View restaurant menu
4. **view_branches** - List all branches
5. **ask_branch** - Branch information inquiry
6. **find_nearest_branch** - Find nearest branch by location
7. **order_delivery** - Place delivery order
8. **order_takeaway** - Place takeaway order
9. **search_food** - Search for products
10. **view_orders** - View order history
11. **ask_info** - General information request

## Available Tools (Tool Calling)

1. **get_branch_menu** - Get menu for specific branch
2. **search_products** - Search products by keyword
3. **check_table_availability** - Check table availability
4. **create_reservation** - Create new reservation
5. **get_my_reservations** - Get user's reservations
6. **get_my_orders** - Get user's orders
7. **get_all_branches** - Get all branches
8. **get_branch_details** - Get branch details
9. **get_product_details** - Get product details
10. **get_categories** - Get product categories
11. **check_branch_operating_hours** - Check operating hours
12. **get_revenue_report** - Revenue report (Admin/Manager only)
13. **get_all_users** - Get all users (Admin only)
14. **get_all_reservations** - Get all reservations (Manager/Admin only)

## Key Features

- **Natural Language Processing**: Intent detection and entity extraction
- **Context-Aware Conversations**: Maintains conversation context across turns
- **Tool Calling Pattern**: AI can execute functions to get real-time data
- **Multi-turn Dialogue**: Supports complex multi-step conversations
- **Role-Based Access**: Different tools available based on user role
- **Rate Limiting**: Prevents abuse with role-based rate limits
- **Fallback Handling**: Graceful degradation when AI is unavailable


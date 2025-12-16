# GRADUATION THESIS PRESENTATION
## Building a Table Reservation and Takeaway Ordering System for Multi-Branch Restaurants

---

## SLIDE 1: TITLE SLIDE

**GRADUATION THESIS**

**BUILDING A TABLE RESERVATION AND TAKEAWAY ORDERING SYSTEM FOR MULTI-BRANCH RESTAURANTS**

**INFORMATION TECHNOLOGY**
**(HIGH-QUALITY PROGRAM)**

**Advisor:**
Dr. Bui Vo Quoc Bao

**Student:**
Nguyen Thi Hoai Thuong

---

## SLIDE 2: TABLE CONTENT

1. INTRODUCTION
2. SOLUTION DESIGN & TECHNOLOGIES
3. IMPLEMENTATION RESULTS
4. CONCLUSION & FUTURE WORK

---

## SLIDE 3: INTRODUCTION
### Background of Study

**The Trend:**
- Growing demand for dining out and convenient food ordering in a busy life
- Need for integrated restaurant management solutions

**The Gap:**
- Existing reservation or ordering platforms are often single-function
- Lack comprehensive functionality and limited customization options
- No real-time communication between customers and restaurant staff

**The Solution:**
- Develop a robust system for Table Reservation and Takeaway Ordering for Multi-Branch Restaurants
- Support three main order types: Reservations, Delivery, and Takeaway

---

## SLIDE 4: INTRODUCTION
### Research Objectives & Scope

**Objective:**
- Provide real-time table reservation and place orders for multi-branch order management
- Implement AI-powered chatbot for customer support
- Support multiple user roles with role-based access control

**Scope:**
- Develop customer-facing Mobile App (Flutter)
- Develop administrative Web System (Vue.js, Node.js/Express.js, MySQL)
- Implement real-time communication using Socket.IO
- Integrate AI chatbot using Google Gemini AI

**Key Feature:**
- Implement an AI-powered chatbot using Google Gemini AI and the Tool Calling pattern System

---

## SLIDE 5: SOLUTION DESIGN & TECHNOLOGIES
### Theoretical Foundation

**Backend:**
- Node.js & Express.js (RESTful API)
- Socket.IO (Real-time Communication)
- MySQL (Database)
- JWT (Authentication)

**Frontend Web (Admin/Staff):**
- Vue.js 3 (Composition API)
- Vue Router, Vue Query (Data Management)
- Bootstrap (UI)
- Chart.js (Analytics)

**Mobile App (Customer/Delivery Driver):**
- Flutter & Dart (Cross-platform)
- Provider (State Management)
- Dio (HTTP Client)

**AI/Chatbot:**
- Google Gemini AI
- Tool Calling Pattern
- Intent Detection & Entity Extraction

**Geolocation:**
- Mapbox API (Geocoding/Maps)
- Haversine Formula (Distance Calculation)

---

## SLIDE 6: SOLUTION DESIGN & TECHNOLOGIES
### System Architecture

```
Frontend                    Backend                    Database
┌─────────────┐           ┌─────────────┐           ┌─────────────┐
│ Mobile App  │ ──HTTP──> │ RESTful API │ ──SQL──> │   MySQL     │
│  (Flutter)  │ <──HTTP── │ Node.js/    │ <──SQL── │  Database   │
│             │           │ Express.js  │           │             │
│ Web Admin   │ ──HTTP──> │             │           │             │
│  (Vue.js)   │ <──HTTP── │ Socket.IO   │           │             │
│             │           │  (Real-time) │           │             │
│             │ ──WS──>   │             │           │             │
│             │ <──WS──   │             │           │             │
└─────────────┘           └─────────────┘           └─────────────┘
                                  │
                                  │
                          ┌───────┴───────┐
                          │               │
                    ┌─────▼─────┐   ┌─────▼─────┐
                    │ AI Service │   │ Mapbox   │
                    │ (Gemini)   │   │   API    │
                    └───────────┘   └──────────┘
```

---

## SLIDE 7: IMPLEMENTATION RESULTS
### System Overview

**Core System Features:**
The system successfully implements comprehensive restaurant management with three order types (Dine-in, Takeaway, Delivery), multi-branch table reservations, and real-time order tracking using Socket.IO. It supports 8 user roles with role-based access control, branch-specific product management, and geolocation-based services.

**AI Chatbot Integration:**
An intelligent chatbot powered by Google Gemini AI with Tool Calling pattern supports 20+ intents (booking, ordering, searching) and 11 tools for menu browsing, product search, reservation management, and order tracking. The chatbot provides natural language processing with context-aware multi-turn conversations.

**Multi-Platform Implementation:**
The solution includes a Flutter mobile app for customers and delivery drivers, and a Vue.js web admin panel for staff and managers. The system consists of 14 API route modules, 15+ database tables, and real-time event notifications across all platforms.

---

## SLIDE 8: CONCLUSION & FUTURE WORK
### Conclusion

**Achievements:**
- Successfully developed comprehensive restaurant management system
- Implemented real-time communication using Socket.IO
- Integrated AI chatbot for customer support using Google Gemini AI
- Created multi-platform solution (Mobile App + Web Admin Panel)
- Support 8 user roles with role-based access control
- Implemented three order types: Dine-in, Takeaway, Delivery

## SLIDE 9: CONCLUSION & FUTURE WORK
### Future Work

**Potential Enhancements:**
- Online payment integration (Visa, Mastercard, e-wallets)
- Push notifications for mobile app
- Advanced analytics and machine learning for sales prediction
- Multi-language support
- Inventory management system
- Staff scheduling system
- Customer loyalty program
- Integration with third-party delivery services (Grab, GoFood)
- QR code ordering system
- Table ordering via QR code scan

---

## SLIDE 10: Q&A

**Thank You**

**Questions & Answers**

---

## NOTES FOR PRESENTATION:

1. **Slide Format**: Follow CTU presentation template (blue theme, white background)
2. **Visuals**: Include screenshots of Mobile App and Web Admin Panel
3. **Demo**: Prepare live demo of key features (if possible)
4. **Timing**: 15-20 minutes presentation + 5-10 minutes Q&A
5. **Focus**: Emphasize real-time capabilities, AI chatbot, and multi-platform support


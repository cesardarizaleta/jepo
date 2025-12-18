# Jepo - Proactive Assistance System (Copilot Instructions)

## Project Context
**Jepo** is a mobile application developed as a thesis project titled "Sistema de Asistencia Proactiva a Personas" (Proactive Person Assistance System). 
The core philosophy is to shift from a **reactive model** (user asks for help) to a **proactive model** (system detects danger and asks for help on behalf of the user).

## Technical Stack
- **Framework**: Flutter (Cross-platform, initially focused on Android).
- **Language**: Dart.
- **Target Platform**: Android (Primary), iOS (Secondary).
- **Architecture**: Based on General Systems Theory.

## Core Architecture Components
1.  **Mobile App**: Data collector and first level of processing (The "Intelligent Agent").
2.  **Cloud Services**: Connection and data management.
3.  **Control Panel**: Interface for authorized third parties to view user status/location.

## Critical Technical Modules
When generating code or suggesting features, focus on these three interacting modules:

### 1. Continuous Geolocation Module
-   **Goal**: Real-time, uninterrupted position tracking.
-   **Tech**: GPS, Mobile Networks, Trilateration.
-   **Logic**: Implement **Graph Theory** (Nodes/Edges) for route calculation to "Safe Zones" or proximity to help.
-   **Features**: Geofencing capabilities (alerts when leaving safe zones).

### 2. Sensor Reading & Activity Recognition (HAR)
-   **Role**: The "Brain" of the system (AI/ML).
-   **Sensors**: Accelerometer, Gyroscope (Inertial sensors), Camera (contextual).
-   **Logic**: Distinguish between **Normal Activity** (walking, running) and **Risk Situations** (sudden falls, impacts, prolonged inactivity, unusual high-speed movement).
-   **Constraint**: Prioritize battery efficiency. Do not use continuous video analysis. Use sensors for detection and camera only for alert context.

### 3. Alert & Notification Management
-   **Behavior**: **Automated** (Zero user intervention required).
-   **Payload**: Rich context (Risk type, Location, Visual data).
-   **Recipients**: Trusted personal contacts (not public emergency services in this prototype phase).

## Development Methodology
-   **Methodology**: XP (Extreme Programming).
-   **Process**: Iterative coding, constant testing.
-   **Testing**:
    -   *White Box*: Validate internal algorithms.
    -   *Black Box*: Validate inputs (movements) -> outputs (alerts).

## Non-Functional Requirements (Critical)
1.  **Ubiquitous Computing**: Must run as a **Background Service** (even with screen locked). The app should be "invisible but omnipresent".
2.  **Energy Efficiency**: Optimize GPS and Sensor usage to prevent battery drainage.
3.  **Connectivity Handling**: Robust logic for offline scenarios (Store & Forward alerts, SMS fallback).

## The "Automatic Braking" Analogy
Always keep this analogy in mind:
> Current security apps are like seatbelts (passive). **Jepo is the Automatic Braking System.**
> - **Sensors**: The eyes on the road.
> - **AI**: The brain deciding "Pothole vs Wall".
> - **Alert**: The system taking control to save the user.

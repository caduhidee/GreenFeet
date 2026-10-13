# 🌱 GreenFeet

### Smarter transportation. Smaller carbon footprint.

**GreenFeet** is an iOS application designed to help users understand their transportation habits, discover sustainable alternatives, and reduce their environmental impact.

By analyzing location data, identifying recurring travel patterns, and integrating public transportation information, GreenFeet helps users make more informed decisions about how they travel.

## Overview

Transportation is a significant contributor to personal carbon emissions, but understanding the environmental impact of everyday travel can be difficult.

GreenFeet addresses this challenge by combining trip tracking, public transit recommendations, and carbon emissions estimates into a single mobile application.

The goal is simple: **make sustainable transportation choices easier, more accessible, and more practical.**

## Features

### Trip Tracking

- Uses device geolocation to identify individual trips.
- Analyzes travel history to recognize recurring routes and travel patterns.
- Provides a visual record of previously detected trips.

### Sustainable Route Recommendations

- Integrates Apple MapKit and public transportation APIs.
- Identifies public transit alternatives based on users' existing travel routes.
- Helps users explore transportation options that may reduce their carbon footprint.

### Public Transit Information

- Displays public transportation routes and departure information.
- Incorporates transit schedule data into route recommendations.
- Helps users evaluate practical alternatives to their regular commutes.

### Carbon Emissions Estimates

- Calculates estimated transportation-related carbon emissions.
- Compares emissions estimates for different transportation options.
- Shows potential emissions reductions associated with lower-carbon alternatives.

### Travel Insights

- Visualizes trip history and recurring travel patterns.
- Displays recommended routes, transit schedules, and environmental impact estimates.
- Presents transportation data through a native SwiftUI interface.

## Tech Stack

| Technology | Purpose |
|---|---|
| **Swift** | Primary programming language |
| **SwiftUI** | Native iOS user interface |
| **MapKit** | Maps, route visualization, and transportation information |
| **Core Location** | Device location tracking and trip identification |
| **SwiftData** | Local data persistence |
| **Public Transit APIs** | Transit routes and schedule information |

## How It Works

GreenFeet follows a workflow that turns location information into actionable transportation insights.

**1. Detect Trips**

The application uses location data to identify user trips and record relevant travel information.

**2. Analyze Travel Patterns**

Recorded trips are analyzed to identify recurring destinations and transportation patterns.

**3. Find Transportation Alternatives**

GreenFeet uses mapping services and public transit information to identify alternative routes.

**4. Estimate Environmental Impact**

The application estimates carbon emissions for transportation options and calculates potential reductions.

**5. Present Recommendations**

Users can review their travel history, explore transit alternatives, and compare estimated environmental impact through the app's interface.

## Application Architecture

GreenFeet is built using Apple's native iOS development frameworks.

- **Presentation Layer:** SwiftUI views for trip history, maps, recommendations, and environmental insights.
- **Location Services:** Core Location for collecting location information used in trip detection.
- **Mapping and Routing:** MapKit and transit data integrations for displaying routes and transportation options.
- **Data Layer:** SwiftData for local persistence.
- **Analysis Logic:** Trip-pattern analysis and emissions calculations for generating transportation insights.

## Getting Started

### Prerequisites

- an iPhone

### Installation

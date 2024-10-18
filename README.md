
# Weather & Stories App

## Overview

This iOS app, built with SwiftUI and The Composable Architecture (TCA), showcases two main features:
1. A weather screen displaying the current temperature for the user's location.
2. An Instagram-style story view presenting a series of images with auto-progression and manual navigation.

## Architecture

The app is structured using The Composable Architecture (TCA), which provides a robust framework for managing state, handling side effects, and composing features.

### Key Components:

- **ContentViewFeature**: The main feature that manages the overall app state and navigation, including weather data fetching and display.
- **StoryViewFeature**: Manages the Instagram-style story view.

Each feature is composed of:
- **State**: Represents the feature's data.
- **Action**: Defines the possible events in the feature.
- **Environment**: Holds dependencies like API clients or location services.
- **Reducer**: Handles state changes based on actions.

## Weather Data Fetching and Display

1. **Location Services**: 
   - Uses CoreLocation to fetch the user's current location.
   - Implemented in `LocationManager` class.

2. **API Integration**:
   - Utilizes OpenWeatherMap API for fetching weather data.
   - API calls are made using Swift's `URLSession`.

3. **Data Flow**:
   - Location update triggers weather data fetch in ContentViewFeature.
   - Weather data is parsed and stored in `CachedWeatherData` model.
   - UI updates reactively based on the `WeatherViewModel`.

4. **Error Handling**:
   - Gracefully handles API errors and displays appropriate messages.

## Story View Implementation

1. **UI Components**:
   - Custom SwiftUI views for story display and progress indicators.
   - Gesture recognizers for manual navigation.

2. **Auto-progression**:
   - Implemented using a timer in the `StoryViewFeature` reducer.
   - Configurable duration (default: 3 seconds).

3. **Manual Navigation**:
   - Swipe gestures for moving between stories.
   - Tap gesture for pausing/resuming auto-progression.

4. **Progress Tracking**:
   - Custom progress bar indicating the viewing progress of each story.

## Bonus Features Implementation

1. **Pause and Resume**:
   - Implemented in `StoryViewFeature`.
   - Tapping the screen toggles between pause and play states.

2. **Unit Testing**:
   - Comprehensive unit tests for TCA reducers.
   - Tests cover weather fetching logic and story navigation.
   - Utilizes the new Swift Testing framework.

3. **Caching/Offline Mode**:
   - Weather data is cached using SwiftData.
   - Allows display of last fetched data when offline.
   - Implemented in `ContentViewFeature` with `CachedWeatherData` model.

## Getting Started

1. Clone the repository:
   ```
   git clone https://github.com/relliott2016/weather-stories-app.git
   ```
2. Obtain an API key from OpenWeatherMap:
   - Create an account at [OpenWeatherMap](https://home.openweathermap.org/users/sign_up) if you don't have one.
   - Once signed in, select the API keys tab and generate a new API key.
3. Add the API key to the project:
   - Open `WeatherAndStories.xcodeproj` in Xcode.
   - Select the WeatherAndStories target in the project navigator.
   - In the editor view select the info tab and open the Custom iOS Target Properties section.
   - Locate the OPENWEATHERMAP_API_KEY entry and replace the ADD_OPENWEATHERMAP_API_KEY_HERE placeholder value with your key.
4. Build and run the project on your preferred iPhone or iPad simulator or device.

## Requirements

- iOS 18.0+
- Xcode 16.0+

## Dependencies

- The Composable Architecture (TCA)
- SwiftUI
- CoreLocation
- SwiftData

## License

This project is licensed under the MIT License - see the [MIT License](LICENSE) file for details.

## Screenshots

<img src="https://github.com/relliott2016/WeatherAndStories/blob/master/Screenshots/ContentView/ReqAuthLoc.png" width=30% height=30%>          <img src="https://github.com/relliott2016/WeatherAndStories/blob/master/Screenshots/ContentView/FetchLoc.PNG" width=30% height=30%>          <img src="https://github.com/relliott2016/WeatherAndStories/blob/master/Screenshots/ContentView/FetchWea.PNG" width=30% height=30%>          <img src="https://github.com/relliott2016/WeatherAndStories/blob/master/Screenshots/ContentView/Online.PNG" width=30% height=30%>          <img src="https://github.com/relliott2016/WeatherAndStories/blob/master/Screenshots/ContentView/OfflineNoCache.PNG" width=30% height=30%>          <img src="https://github.com/relliott2016/WeatherAndStories/blob/master/Screenshots/ContentView/OfflineCache.PNG" width=30% height=30%> 

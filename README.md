# Pi Auto

Pi Auto is a Creative Solution for Car Head Unit. This project is an application initially designed for running on iPads. 

My design was a support installed in car console that holds your iPad. A Raspberry Pi server will be build-in installed inside the console, which runs a server and a mobile Wi-Fi when powered up. 

An Automation will be installed on the iPad(requires iOS 13.0 or higher) which runs a specific shortcut when connected to a specific Wi-Fi network. The shortcut will automatically launch PiAuto Application and connect to the server in the car using local DNS and hostname. 

For safety concerns, this project was designed to support Voice Control, which is a perfect interaction way to avoid distraction during drive. However, in 0.1.0 version, the project does not support Siri yet. 

The focus of this project is currently on iOS platform since the prefered deployment device is Apple's iPads. In future versions, I will first try to integrate Siri support. Andorid side support will be postpone until iOS has reached a relatively stable and satisfying project ready for a release. 

The built-in music player currently support NeteaseCloudMusic, which means you need to configure your credentials in code files. 

## Requirements

This project is currently designed and programmed to only support iOS platform. It is not tested on Android yet. 

For Flutter UI Part, many components are Cupertino(including Cupertino Icons, and some widgets like cupertino Slider, etc).

For Platform Specific code, this app includes a iOS Platform view written in Swift UIKit but currently with no Android platform code for method calls. 

### Dependencies

#### NeteaseCloudMusicApi

The API server for accessing NeteaseCloudMusic Services which powers the music player widget of this project.

For more information about NeteaseCloudMusicApi, please refer to [its website](https://binaryify.github.io/NeteaseCloudMusicApi/).


#### Flutter Dart Package Dependencies

 - http: ^0.12.2
 - provider: ^4.3.3
 - intl: ^0.16.1
 - volume_watcher: ^1.3.1
 - just_audio: ^0.6.9
 - audio_service: ^0.16.2
 - rxdart: ^0.25.0
 - dio: ^3.0.10
 - dio_cookie_manager: ^1.0.0
 - cookie_jar: ^1.0.1
 - path_provider: ^1.6.27
 - flip_card: ^0.4.4
 - flappy_search_bar: ^1.7.2

### Map & Navigation Services

The Navigation widget partly was powered by AMap iOS SDK, which is another reason why the project supports only iOS yet. 

AMap does have Android SDK, however, due to some reasons, the android side was not implemented yet. Therefore it is better to run this project on iOS devices.

Also, using the Map and Navigation Sevices requires an API Key for AMap services, which can be registered on their [Developer Website](https://developer.amap.com).


## Get Started

The project currently has no release. Therefore, to run this project, you need to build and install this project locally on your computer(for iOS deployment, you need a Mac).

Clone this project to your local directory:
```shell
$ git clone git@gitee.com:EthanGeekFan/pi-auto.git
```
or
```shell
$ git clone https://gitee.com/EthanGeekFan/pi-auto.git
```

To install Flutter dependecies, you should run
```shell
flutter pub get
```

This should install all the required packages to your directory. However, before you can try this app smoothely, there are some other steps you should do.

## Configure the project before Compiling and Building

### Set up the environment

To make it possible for the music player to function, you should make sure that you have a NeteaseCloudMusicApi Server deployed on a machine in your LAN. 

To do that, you may execute the following commands in your server terminal that have `node.js` installed and in `PATH`.

```shell
$ git clone git@github.com:Binaryify/NeteaseCloudMusicApi.git
$ # OR with HTTPS:
$ git clone https://github.com/Binaryify/NeteaseCloudMusicApi.git
$ npm install
```

And run the API Server with
```shell
$ npm start
```

For more customization of the server, see [its website](https://binaryify.github.io/NeteaseCloudMusicApi/).


### Configure the server info and account credentials(`v0.1.0`)

> **For version v0.1.1 or above, you can skip this section**

After you have set up your local API server, you may begin to configure the code in order to make it connect to the server and login as expected.

#### `NeteaseCloudMusicConfig.dart`

> For Music Player Functionalities

In `lib/Configurations/NeteaseCloudMusicConfig.dart`, you should provide values for some `const` properties to make it work.
 - account `phone`, which is the phone binded to your account
 - account `password`, which is the login password of your account
 - server `hostname`, which is the hostname of the server in your LAN
 - server `port`, which is the port your server is listening to

 ```dart
static const String phone = "156********";
static const String password = "******";
static const String hostname = "******.local";
static const String port = "****";
 ```

 #### `AppDelegate.swift`

 > For Navigation Functionalities

The project requires a AMap API key to access the services, and you should configure your key in the `AppDelegate.swift` file.

In `ios/Runner/AppDelegate.swift`, find this line:
```swift
// Configure your API Key here
AMapServices.shared()?.apiKey = ""
```
Enter your Key inside the quotes, and your done configuring the Navigation Widget.


#### `BasicInformationModel.dart`

> For Weather Info Updates

The `BasicInfoWidget` displays the weather for the city you're in automatically. However, this is accomplished using an existed API that requires an API key to request. 

The API belongs to [seniverse](https://seniverse.com/) and it is **free**. But you should register an account and apply for an API key to use the API.

After you get the Key, you need to configure the key in `lib/Models/BasicInformationModel.dart`:
```dart
static const String WEATHER_API_KEY = "";
```

After you configured all these keys and credentials. You are ready to build and launch the application!

Execute:
```shell
$ flutter run --release
```
And select a device if there are multiple devices connected.


## Contribution


This project is currently personal. If you are interested in contributing to this project, you are welcomed to contact me via email:
```
yangyifan529@gmail.com
```


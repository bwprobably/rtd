# RTD | Regional Transportation District - Denver

Reads scheduling and live transit data for notifications on bus/train times.
~C

RTD specific data:
- [Developer Resources](http://www.rtd-denver.com/Developer.shtml)
- [General Transit Feed Specification (GTFS) Schedule Dataset](http://www.rtd-denver.com/gtfs-developer-guide.shtml#schedule-dataset)
RTD schedule data is available in General Transit Feed Specification (GTFS) for use in developing applications and other mobile tools for RTD riders.
- [GTFS-realtime Feeds](http://www.rtd-denver.com/gtfs-developer-guide.shtml#realtime-feeds)

Code resources:
- [What is GTFS?](https://developers.google.com/transit/gtfs/#how-do-i-star)
- [GTFS samples](https://developers.google.com/transit/gtfs/examples/gtfs-feed)
- [Protocol Buffers](https://developers.google.com/protocol-buffer)

Sample Configuration file, settings.yml:
```
boulder-to-elitch:
  0:
    from: Downtown Boulder Station
    to: Union Station
    direction: East
    time: 2016-01-01 06:00:00 -7 #ideal time of route
    type: bus
  1:
      from: Union Station
      to: Elitch
      direction: South
      time_after: 60 #time after first duration of first trip
      type: train
```
Run at current time:
transit boulder-to-elitch
```
'Downtown Boulder Station' to 'Union Station' at ~10:27AM
(1) FF1  10:30AM
(2) FF1  10:45AM

'Union Station' to 'Elitch' at ~11:27AM
(1) 101E 11:37AM
```
Run at specific time:
transit boulder-to-elitch 10:45am
```
'Downtown Boulder Station' to 'Union Station' at ~10:45AM
(1) FF1  10:45AM
(2) FF1  11:00AM

'Union Station' to 'Elitch' at ~11:45AM
(1) 101E 11:37AM
(2) 101E 12:07AM

```
Will show live data when avaliable:
```
'US 36 & Sheridan Station' to 'Union Station' at ~6:27PM
(1) FF1  6:28PM AT STOP NOW
(3) FF1  6:38PM LIVE:  6:26PM (9/13) US 36 & Broomfield Station Gate K
(5) FF1  6:52PM LIVE:  6:26PM (6/13) US 36 & Table Mesa Station Gate A
```
Guessing between stop names: transit osage union
```
'osage' to 'union' at ~10:38AM
(1) 101C 10:32AM
(2) 101E 10:45AM
(3) 101E 10:50AM
(4) 16   10:51AM
(5) 101C 10:57AM
(6) 101C 11:02AM
```
Notes:
- running only "transit" with no parameters (./program.rb) will default to the current time and current route..
- "work" is the default route before noon
- "home" is the default route after noon
- "direction" while not required, eliminates half of routes going the opposite direction
- "favorites" in settings is a way to eliminate routes and query faster

Other settings:
API key needed for live data, [requested here](http://www.rtd-denver.com/gtfs-developer-guide.shtml#realtime-feeds).
```
favorites:
    FF1, FF2, FF3, FF4, FF5, 101F, 101E
api:
  user: ####
  password: ####
```
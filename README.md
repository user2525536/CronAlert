About
=====
CronAlert is a GUI Windows application which is intended to offer Cron like features in Windows.  
Additionally it supports text-to-speech output for acoustic alerts.


How to use
==========
- Create a CronAlert file in a standard text editor
- Start the program
- Open the created CronAlert file


Command-line Syntax
===================
CronAlert can be started with command-line parameters to perform specific settings or action  
on start-up. The following command-line options can be used.
```
CronAlert -hmtv [file]
CronAlert -s text
-h, --help
   Display a short description of command-line options.
-m, --mute
   Start CronAlert with sound muted. Sound is not muted by default.
-s, --say <text>
   Outputs all following values as single text to the speaker.
-t, --tray
   Start CronAlert in system tray mode.
-v, --volume <number>
   Set the volume to the given value (0 to 100).
<file>
   Open the given CronAlert file on start-up. This option overwrites the load last file option.
```

CronAlert File Format
=====================

The CronAlert file format is similar to Cron (Linux).  
See Cron (https://en.wikipedia.org/wiki/Cron) for reference.  
Each line of a CronAlert file may contain a comment, pragma or CronAlert.  

### Comment
This includes all characters starting from a hash tag or semicolon until the end-of-line or  
end-of-file and will be completely ignored.
### Examples
```
# this is a comment
; this is also a comment
```

### Pragma
Every pragma start with an at mark followed by a keyword and optional parameters. A pragma controls  
how following CronAlerts shall be handled. Find next a list of possible pragmas.  
`@timezone <number>`  
&emsp;Change the timezone from local time to UTC+`<number>`.  
&emsp;The `<number>` can be in minutes or in the format `<hours>:<minutes>`.  
&emsp;Use `'local'` instead `<number>` to default back to local time.  
`@preAlert <number>`  
&emsp;Perform an alert `<number>` seconds before the actual trigger event to signal an upcoming event.  
&emsp;The `<number>` can be in seconds or in the format `<minutes>:<seconds>`.  
&emsp;Set <number> to 'off' to disable pre-alerting.  
`@preTrigger <number>`  
&emsp;Perform the event trigger `<number>` seconds before the actual trigger event.  
&emsp;The `<number>` can be in seconds or in the format `<minutes>:<seconds>`.  
&emsp;Set `<number>` to `'off'` to disable pre-triggering.  
&emsp;Set `<number>` to `'default'` to set the value to the program default.  
### Examples
```
@timezone -05:00
@preAlert 15
@preTrigger 2
```

### CronAlert
A CronAlert defines a specific event trigger. The event can trigger a program start or a voice  
output. The date/time for the event is defined similar to Cron. See the following explanation.
```
min hour day month wday name text
 |   |    |    |    |    |    |
 |   |    |    |    |    |    +---- text for voice output or command to execute
 |   |    |    |    |    +--------- name of the event (will be used for pre-alerts)
 |   |    |    |    +-------------- weekday from 0 (Sunday) until 6 (Saturday)
 |   |    |    +------------------- month from 1 (January) to 12 (December)
 |   |    +------------------------ day of the month from 1 to 31
 |   +----------------------------- hour of the day from 0 to 23
 +--------------------------------- minute of the hour from 0 to 59
```
Month can be also one of Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct and Dec.  
Weekday can be also one of Mon, Tue, Wed, Thu, Fri, Sat and Sun.  
The date time values can have additional formats to the numbers to ease setups.  

|Format     |Meaning
|-----------|--------------------------------------
|`*`        |Same as entering every possible value.
|`/<number>`|Use only every `<number>` value.
|`-<number>`|Define a range until `<number>`.

Use a hyphen as prefix to a CronAlert to disable it by default.  
The values in name and text field need to be in the surrounded by double quotes.  
The string in the text field will be used for voice output. If text starts with an exclamation mark  
the following string will be used as command-line to execute the given application instead of a  
voice output.
### Example
```
15,45 10-14 */2 * * "event" !"notepad.exe" "open_this_file.txt"
```
Open the file "open_this_file.txt" with notepad every second day between 10:00 and 14:00 if the  
current minute is 15 or 45.
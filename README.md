# mu2xml
Parses MangaUpdates pages into XML. A horrible workaround for their lack of an API.

This is in a very barebones and untested state, and should not be used for anything important. There are likely to be edge cases that do not work or return poorly formatted text.

## Usage
Currently, only retreiving information about a series is supported. Just pass it the ID in the form of /series/<id>

[A sample is availible](https://mu2xml.herokuapp.com/series/1923). This will run into issues if used for anything more than experimentation.
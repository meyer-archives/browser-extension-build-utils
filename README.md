# browser-extension-build-utils
## What is it?
A few rake tasks, scripts and “assorted whatnot” for building
browser extensions for Chrome and Safari. Designed to be used as a `git`
submodule.

## Dependencies
* [`xar` 1.6.1][xar]
* ruby (system ruby should suffice)

## How it’s used
Run `rake` to build the extension directory to `TEMP_DIR` during development.
Both Chrome and Safari can load the extension from the filesystem.

Once you’re ready to build your extension binaries, run `rake build:release` and
it’ll dump your built and signed extensions in `RELEASE_DIR`. So spice!

## How do I use it?
Detailed installation instructions can be found [in the wiki][wiki].

## What I’d eventually like
* **Cross-platform support**. Right now it’s pretty dang Mac-specific.
* **Support for more complex extension options**. Background pages and all that
jazz. I know it would be pretty simple. I’ve had neither the time nor
the need to implement it (yet).

## What might be cool but haven’t I felt super “yeah” about
* **Firefox/Opera(?)/Other Browser support**. Sure, it’d be swell if this thing
could pump out extensions for browsers other than Safari and Chrome. I haven’t
looked into that _at all_. I really don’t know why someone would use something
other than Chrome or Safari, but since everything’s going to be pretty
“Webkit slash Blink” here in the near future, it’s something I need to consider.

[xar]: http://mackyle.github.io/xar/
[wiki]: https://github.com/meyer/browser-extension-build-utils/wiki/Installation
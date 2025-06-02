# appack

## Use

For both development and use of apps, please ensure you have all of the contents of the folder for your use case. Place the `packager.lua` or `packageInstaller.lua` and their respective lib folder on root.
### Development

To develop programs to work with appack, they simply must:
- have a file named `main.lua`, which is the typical entry point after unpacking (if not suitable for use case, you can omit this file, but warnings will appear.)

You can run `packager.lua` located in `development` to start the process.\
It will ask you a series of simple questions. When prompted about isolation, answer with true/false. If you answer true, your program will be placed into a virtual file system where no matter where run, will seem to run out of root (essentially `chroot`) This ensures compatibly for programs which are picky about their placement.

When filled out, you will see a file named `[app].[version].[author].sp`. This means your app has been packaged, and all that is left is to test it.

### Use

To turn a `.sp` packaged app into an actual app, run `packageInstaller [path to app]`, located in `user`. It will create a folder with the app's contents in it and will, if present, run `main.lua` as the entry point.

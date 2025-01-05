## cdx.js ##

[cdx.js](cdx.js) is a self-contained command-line application that provides a dedicated server for Core Explorer.

You use it like this
`node --experimental-wasm-memory64 cdx server inputfile1 inputfile2 ...`

If you have a sysroot, you can specify it as 

`node --experimental-wasm-memory64 cdx server inputfile1 inputfile2 --sysroot /path/to/sysroot`

Unlike the web application hosted at https://core-explorer.github.io/core-explorer it is not possible to add additional files after startup.

By default, it opens a local webserver on 127.0.0.1 port 8086. The port can be changed with `--port`

Requirements:
- node.js version 23.0.0 or newer
- there are no other dependencies

## Command line operation ##

There are other operating modes besides `server`:
- `cdx virt` implements the virtual table identification and object counting of Core Explorer
- `cdx got` will parse the Global Offset Table of executables and core dumps. It may be used to detect function hijacking like that of the xz-utils backdoor or ODR violations. This functionality is not yet exposed in the Core Explorer web UI


There are some more operating modes used for development, for which there exist better supported alternatives:
- `cdx readelf` behaves similar to readelf, eu-readelf, llvm-readelf and similar tools. This is used to test the ELF parser against those tools. Use them instead
- `cdx ldd` behaves similar to libtree and other utilities that simulate ldd. ldd is a shell script which runs the dynamic loader specified in an executable, which may pose a security risk when a malicious binary replaces the default loader.
Eventually, the Core Explorer web UI will use this information to highlight shared libraries that are not load-time dependencies and have therefore been dynamically loaded with `dlopen()`
- `cdx dwarfdump` is a very crude approximation of dwarfdump and llvm-dwarfdump that I use for testing. Use those tools instead
- `cdx view` is a hexviewer and disassembler. Use objdump, eu-objdump, llvm-objdump or radare2 if you need such functionality.

The list of tools can be obtained with `cdx --help`. Each tool has independent options, which can be seen with, e.g. `cdx virt --help`


## Important: ##
*Do not leak client data by sharing core dumps.* 

*Do not leak confidential information by sharing debug information.*

cdx.js runs locally. Your files are never copied or uploaded anywhere. cdx.js does not use tracking, analytics or cookies.

As a downside of that, the server does not know about each client's dark mode preference and defaults to light mode for server-side color computations. The environment variable CDX_DARK_MODE can be used to change this globally to default to dark mode.

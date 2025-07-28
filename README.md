# Skribidi

[`Skribidi`](https://github.com/memononen/Skribidi) packaged for the [Zig](https://ziglang.org/) build system.

## Status

Mostly untested:

* Tests are passing on `aarch64-macos`/`x86_64-macos`
* Compatible with Zig `0.14.1` and `zig 0.15.0-dev.278+7733b5dbe`

## Usage

```zig
const skribidi_dep = b.dependency("Skribidi", .{
    .target = target,
    .optimize = optimize,
});
exe.linkLibrary(skribidi_dep.artifact("Skribidi"));
```

## Testing

```sh
zig build test
```

## Examples

```sh
# builds the examples and copies the test data file
zig build example
# builds and runs the example
zig build run-example
```

## Dependencies

`Skribidi` depends on libc, as well as:

- [Harfbuzz](https://github.com/harfbuzz/harfbuzz)
- [SheenBidi](https://github.com/Tehreer/SheenBidi)
- [libunibreak](https://github.com/adah1972/libunibreak)
- [budouxc](https://github.com/memononen/budouxc)

The example has additional dependencies:

- [GLFW](https://github.com/glfw/glfw)
- Windows: `imm32.lib` and `Comctl32.lib`
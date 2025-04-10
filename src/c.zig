pub const glfw = @cImport({
    @cDefine("GLFW_EXPOSE_NATIVE_X11 ", "1");
    @cInclude("GLFW/glfw3.h");
    @cInclude("GLFW/glfw3native.h");
});

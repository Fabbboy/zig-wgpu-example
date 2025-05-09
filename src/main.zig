const std = @import("std");
const glfw = @import("c.zig").glfw;
const wgpu = @import("wgpu");

const CallbackData = struct {
    surface: *wgpu.Surface,
    device: *wgpu.Device,
};

fn resize_callback(window: ?*glfw.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    const usrdata = glfw.glfwGetWindowUserPointer(window.?);
    const cb = @as(*CallbackData, @alignCast(@ptrCast(usrdata.?)));

    const surface = cb.surface;
    const device = cb.device;

    const surface_config = wgpu.SurfaceConfiguration{
        .alpha_mode = .auto,
        .device = device,
        .format = .bgra8_unorm,
        .height = @as(u32, @intCast(height)),
        .width = @as(u32, @intCast(width)),
        .present_mode = .immediate,
    };
    surface.configure(&surface_config);
    std.debug.print("Resized to {}x{}\n", .{ @as(u32, @intCast(width)), @as(u32, @intCast(height)) });
}

pub fn main() !void {
    if (glfw.glfwInit() == 0) {
        return error.InitializationFailed;
    }
    defer glfw.glfwTerminate();

    glfw.glfwWindowHint(glfw.GLFW_CLIENT_API, glfw.GLFW_NO_API);
    glfw.glfwWindowHint(glfw.GLFW_RESIZABLE, 0);

    const window = glfw.glfwCreateWindow(800, 600, "Hello World", null, null);
    if (window == null) {
        return error.WindowCreationFailed;
    }
    defer glfw.glfwDestroyWindow(window);

    glfw.glfwMakeContextCurrent(window);
    _ = glfw.glfwSetFramebufferSizeCallback(window, resize_callback);

    const display = glfw.glfwGetX11Display();
    if (display == null) {
        return error.DisplayNotFound;
    }

    const x11Window = glfw.glfwGetX11Window(window);

    const instance = wgpu.Instance.create(null);
    if (instance == null) {
        return error.InstanceCreationFailed;
    }
    defer instance.?.release();

    const surface_x11_desc = wgpu.SurfaceDescriptorFromXlibWindow{
        .display = display.?,
        .window = x11Window,
    };

    const surface_desc = wgpu.SurfaceDescriptor{
        .next_in_chain = @as(*const wgpu.ChainedStruct, @ptrCast(&surface_x11_desc)),
        .label = null,
    };

    const surface = instance.?.createSurface(&surface_desc);
    if (surface == null) {
        return error.SurfaceCreationFailed;
    }
    defer surface.?.release();

    const adapter_options = wgpu.RequestAdapterOptions{
        .next_in_chain = null,
        .compatible_surface = surface,
        .power_preference = wgpu.PowerPreference.high_performance,
        .force_fallback_adapter = 0,
    };

    const resp = instance.?.requestAdapterSync(
        &adapter_options,
    );

    const adapter = switch (resp.status) {
        .success => resp.adapter.?,
        else => unreachable,
    };

    var props: wgpu.AdapterInfo = undefined;
    adapter.getInfo(&props);
    std.debug.print("{s}\n", .{props.vendor});

    defer adapter.release();

    const device_desc = wgpu.DeviceDescriptor{
        .required_limits = null,
    };

    const dev_resp = adapter.requestDeviceSync(
        &device_desc,
    );

    const device = switch (dev_resp.status) {
        .success => dev_resp.device,
        else => unreachable,
    };

    defer device.?.release();

    const surface_config = wgpu.SurfaceConfiguration{
        .alpha_mode = .auto,
        .device = device.?,
        .format = .bgra8_unorm,
        .height = 600,
        .width = 800,
        .present_mode = .immediate,
    };

    surface.?.configure(&surface_config);

    const queue = device.?.getQueue();
    if (queue == null) {
        return error.QueueNotFound;
    }

    defer queue.?.release();

    var cb = CallbackData{
        .surface = surface.?,
        .device = device.?,
    };

    glfw.glfwSetWindowUserPointer(window, @as(*anyopaque, @alignCast(@ptrCast(&cb))));

    while (glfw.glfwWindowShouldClose(window) == 0) {
        glfw.glfwPollEvents();
        var surface_texture: wgpu.SurfaceTexture = undefined;
        surface.?.getCurrentTexture(&surface_texture);

        defer surface_texture.texture.*.release();

        surface.?.present();
    }
}

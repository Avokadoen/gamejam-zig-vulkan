const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const glfw = @import("glfw");
const zlm = @import("zlm");

const render = @import("render/render.zig");
const swapchain = render.swapchain;
const consts = render.consts;

const input = @import("input.zig");
const render2d = @import("render2d/render2d.zig");

const game = @import("game/game.zig");

pub const application_name = "castle defence";

// TODO: wrap this in render to make main seem simpler :^)
var window: glfw.Window = undefined;

var camera: render2d.Camera = undefined;
var zoom_in  = false;
var zoom_out = false;
var move_up = false;
var move_left = false;
var move_right = false;
var move_down = false;

var delta_time: f64 = 0;

pub fn main() anyerror!void {
    const stderr = std.io.getStdErr().writer();
    // create a gpa with default configuration
    var alloc = if (consts.enable_validation_layers) std.heap.GeneralPurposeAllocator(.{}){} else std.heap.c_allocator;
    defer {
        if (consts.enable_validation_layers) {
            const leak = alloc.deinit();
            if (leak) {
                stderr.print("leak detected in gpa!", .{}) catch unreachable;
            }
        }
    }
    const allocator = if (consts.enable_validation_layers) &alloc.allocator else alloc;
    
    // Initialize the library *
    try glfw.init();
    defer glfw.terminate();

    if (!try glfw.vulkanSupported()) {
        std.debug.panic("vulkan not supported on device (glfw)", .{});
    }

    // Tell glfw that we are planning to use a custom API (not opengl)
    try glfw.Window.hint(glfw.Window.Hint.client_api, glfw.no_api);

    // Create a windowed mode window 
    window = glfw.Window.create(1920, 1080, application_name, null, null) catch |err| {
        try stderr.print("failed to create window, code: {}", .{err});
        return;
    };
    defer window.destroy();

    const ctx = try render.Context.init(allocator, application_name, &window, null);
    defer ctx.deinit();

    // init input module with iput handler functions
    try input.init(window, keyInputFn, mouseBtnInputFn, cursorPosInputFn);
    defer input.deinit();
    
    var draw_api = blk: {
        var init_api = try render2d.init(allocator, ctx, 25);

        const window_size = try window.getSize();
        const window_width = @intToFloat(f32, window_size.width);
        const window_height = @intToFloat(f32, window_size.height);

        try game.loadAllTextures(&init_api);
        try game.createAllSprites(&init_api, window_width, window_height);
        
        break :blk try init_api.initDrawApi(.{ .every_ms = 14 });
    };
    defer draw_api.deinit();

    camera = draw_api.createCamera(400, 1.5);
    var camera_translate = zlm.Vec2.zero;

    try game.initAllUnits(allocator);
    defer game.deinitUnits();
    
    try game.initCastles(allocator);
    defer game.deinitCastles();
    
    try game.initGui(allocator);
    defer game.deinitGui();
     
    var prev_frame = std.time.milliTimestamp();
    // Loop until the user closes the window
    while (!window.shouldClose()) {
        const current_frame = std.time.milliTimestamp();
        delta_time = @intToFloat(f64, current_frame - prev_frame) / @as(f64, std.time.ms_per_s);

        const dt = @floatCast(f32, delta_time);
        
        if (zoom_in) {
            camera.zoomIn(dt);
        }
        if (zoom_out) {
            camera.zoomOut(dt);
        }

        var call_translate = false;
        if (move_up) {
            camera_translate.y -= 1;
            call_translate = true;
        }
        if (move_down) {
            camera_translate.y += 1;
            call_translate = true;
        }
        if (move_right) {
            camera_translate.x += 1;
            call_translate = true;
        }
        if (move_left) {
            camera_translate.x -= 1;
            call_translate = true;
        }
        if (call_translate) {
            camera.translate(dt, camera_translate);
            camera_translate = zlm.Vec2.zero;
        }
        
        game.globalTick(dt);

        // Render here
        try draw_api.draw();

        // Poll for and process events
        try glfw.pollEvents();
        prev_frame = current_frame;
    }
}

fn keyInputFn(event: input.KeyEvent) void {
    if (event.action == .press) {
        switch(event.key) {
            input.Key.w => move_up = true,
            input.Key.s => move_down = true,
            input.Key.d => move_left = true,
            input.Key.a => move_right = true,
            input.Key.escape => window.setShouldClose(true) catch unreachable,
            else => { },
        }   
    } else if (event.action == .release) {
        switch(event.key) {
            input.Key.w => move_up = false,
            input.Key.s => move_down = false,
            input.Key.d => move_left = false,
            input.Key.a => move_right = false,
            else => { },
        }
    }   
}

fn mouseBtnInputFn(event: input.MouseButtonEvent) void {
    // if a button is selected, we don't control camera zoom
    if (game.mouseBtnInputFn(event)) {
        zoom_in = false;  
        zoom_out = false;
        return;
    }

    if (event.action == input.Action.press) {
        if (event.button == input.MouseButton.left) {   
            zoom_in = true;    
        } else if (event.button == input.MouseButton.right) {  
            zoom_out = true;
        }
    }
    if (event.action == input.Action.release) {
        if (event.button == input.MouseButton.left) {   
            zoom_in = false;    
        } else if (event.button == input.MouseButton.right) {  
            zoom_out = false;
        }
    }

}

fn cursorPosInputFn(event: input.CursorPosEvent) void {
    game.cursorPosInputFn(event, camera);
}


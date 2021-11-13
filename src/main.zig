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
const Anim = game.Anim;
const Button = game.Button;
const Move = game.Move;
const Unit = game.Unit;

pub const application_name = "zig vulkan";

// TODO: wrap this in render to make main seem simpler :^)
var window: glfw.Window = undefined;
var window_width: f32 = undefined;
var window_height: f32 = undefined;

var delta_time: f64 = 0;

var buttons: ArrayList(Button) = undefined;
var hover_button: ?Button = null;

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

    buttons = ArrayList(Button).init(allocator);
    
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

    // _ = window.setFramebufferSizeCallback(framebufferSizeCallbackFn);
    // defer _ = window.setFramebufferSizeCallback(null);

    // const comp_pipeline = try renderer.ComputePipeline.init(allocator, ctx, "../../comp.comp.spv", &subo.ubo.my_texture);
    // defer comp_pipeline.deinit(ctx);

    // init input module with iput handler functions
    try input.init(window, keyInputFn, mouseBtnInputFn, cursorPosInputFn);
    defer input.deinit();

    var texture_handles: [8]render2d.TextureHandle = undefined;
    var sprites: [5]render2d.Sprite = undefined; 


    var castle_anim: Anim = undefined;
    defer castle_anim.deinit();

    var unit_move: Move = undefined;
    var unit_swordman: Unit = undefined;

    var draw_api = blk: {
        var init_api = try render2d.init(allocator, ctx, 25);

        // load all textures that we will be using
        texture_handles[0] = try init_api.loadTexture("../assets/images/units/unit0000.png"[0..]);
        texture_handles[1] = try init_api.loadTexture("../assets/images/units/unit0001.png"[0..]);
        texture_handles[2] = try init_api.loadTexture("../assets/images/units/unit0002.png"[0..]);

        texture_handles[3] = try init_api.loadTexture("../assets/images/levels/map.png"[0..]);
        texture_handles[4] = try init_api.loadTexture("../assets/images/structures/castle0000.png"[0..]);
        texture_handles[5] = try init_api.loadTexture("../assets/images/structures/castle0001.png"[0..]);

        texture_handles[6] = try init_api.loadTexture("../assets/images/gui/test_btn_idle.png"[0..]);
        texture_handles[7] = try init_api.loadTexture("../assets/images/gui/test_btn_clicked.png"[0..]);

        const window_size = try window.getSize();
        window_width = @intToFloat(f32, window_size.width);
        window_height = @intToFloat(f32, window_size.height);
     
        // create map background sprite
        sprites[0] = try init_api.createSprite(
            texture_handles[3], 
            zlm.Vec2.new(0, 0), 
            0, 
            zlm.Vec2.new(window_width, window_height)
        );

        // create enemy castle sprite
        sprites[1] = try init_api.createSprite(
            texture_handles[4], 
            zlm.Vec2.new(-800, 390), 
            0, 
            zlm.Vec2.new(
                texture_handles[4].width * 2, 
                texture_handles[4].height * 2
            )
        );
        castle_anim = try Anim.init(allocator, &sprites[1], &[_]render2d.TextureHandle{ texture_handles[4], texture_handles[5] }, 1);

        // create player castle sprite
        sprites[2] = try init_api.createSprite(
            texture_handles[4], 
            zlm.Vec2.new(800, -350), 
            0, 
            zlm.Vec2.new(
                texture_handles[4].width * 2, 
                texture_handles[4].height * 2
            )
        );

        sprites[3] = try init_api.createSprite(
            texture_handles[0], 
            zlm.Vec2.new(-200, 0), 
            0, 
            zlm.Vec2.new(
                texture_handles[4].width * 4, 
                texture_handles[4].height * 4
            )
        );
        const anim_move = [_]render2d.TextureHandle{ texture_handles[0], texture_handles[1]};
        const anim_attack = [_]render2d.TextureHandle{ texture_handles[0], texture_handles[2]};
        unit_move = Move.init(&sprites[3], zlm.Vec2.new( 400, 200), zlm.Vec2.new(-400, -200), 100);
        unit_swordman = try Unit.init(
            allocator, 
            &sprites[3], 
            100, 10, 100, 50, 2, 
            [2][]const render2d.TextureHandle{&anim_move, &anim_attack}, 
            unit_move
        );
        unit_swordman.setState(.attacking);

        sprites[4] = try init_api.createSprite(
            texture_handles[6], 
            zlm.Vec2.new(0, 0), 
            0, 
            zlm.Vec2.new(
                texture_handles[4].width * 4, 
                texture_handles[4].height * 4
            )
        );
        try buttons.append(Button.init(&sprites[4], texture_handles[6], texture_handles[7], btnCallback));

        break :blk try init_api.initDrawApi(.{ .every_ms = 14 });
    };
    defer unit_swordman.deinit();
    defer draw_api.deinit();

    var prev_frame = std.time.milliTimestamp();
    // Loop until the user closes the window
    while (!window.shouldClose()) {
        const current_frame = std.time.milliTimestamp();
        delta_time = @intToFloat(f64, current_frame - prev_frame) / @as(f64, std.time.ms_per_s);
        // f32 variant of delta_time
        const dt = @floatCast(f32, delta_time);
        
        castle_anim.tick(dt);
        unit_swordman.tick(dt);

        // Render here
        try draw_api.draw();

        // Poll for and process events
        try glfw.pollEvents();
        prev_frame = current_frame;
    }
}

fn btnCallback() void {
    std.debug.print("hello from button!\n", .{});
}

fn keyInputFn(event: input.KeyEvent) void {
    if (event.action == .press) {
        switch(event.key) {
            input.Key.escape => window.setShouldClose(true) catch unreachable,
            else => { },
        }   
    } else if (event.action == .release) {
        switch(event.key) {
            else => { },
        }
    }   
}

fn mouseBtnInputFn(event: input.MouseButtonEvent) void {
    if (event.button == .left) {
        if (hover_button) |*some| {
            if (event.action == .press) {
                some.onClick();
            } else if (event.action == .release) {
                some.onRelease();
            }
        }
    }
}

fn cursorPosInputFn(event: input.CursorPosEvent) void {
    const vec_event = zlm.Vec2.new(
        @floatCast(f32, event.x) - window_width * 0.5, 
        @floatCast(f32, event.y) - window_height * 0.5
    );

    var prev_button = hover_button;
    hover_button = null;

    for (buttons.items) |button| {
        if (button.bound.contains(vec_event)) {
            hover_button = button;
            break;
        }
    }

    if (prev_button) |prev_some| {
        if (hover_button) |new_some| {
            if(prev_some.sprite.db_id.value == new_some.sprite.db_id.value) {
                return;
            }
        }
        prev_some.onRelease();
    }
}

// TODO: move to internal of pipeline
// var sc_data: swapchain.Data = undefined;
// var view: swapchain.ViewportScissor = undefined;

// /// called by glfw to message pipelines about scaling
// /// this should never be registered before pipeline init
// fn framebufferSizeCallbackFn(_window: ?*glfw.RawWindow, width: c_int, height: c_int) callconv(.C) void {
//     _ = _window;
//     _ = width;
//     _ = height;

//     // recreate swapchain utilizing the old one 
//     const old_swapchain = sc_data;
//     sc_data = swapchain.Data.init(allocator, ctx, old_swapchain.swapchain) catch |err| {
//         std.debug.panic("failed to resize swapchain, err {any}", .{err}) catch unreachable;
//     };
//     old_swapchain.deinit(ctx);

//     // recreate view from swapchain extent
//     view = swapchain.ViewportScissor.init(sc_data.extent);
    
//     gfx_pipeline.sc_data = &sc_data;
//     gfx_pipeline.view = &view;
//     gfx_pipeline.requested_rescale_pipeline = true;
// }


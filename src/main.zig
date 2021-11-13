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
const Move = game.Move;
const Unit = game.Unit;
const Castle = game.Castle;
pub const application_name = "zig vulkan";

// TODO: wrap this in render to make main seem simpler :^)
var window: glfw.Window = undefined;
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

    // _ = window.setFramebufferSizeCallback(framebufferSizeCallbackFn);
    // defer _ = window.setFramebufferSizeCallback(null);

    // const comp_pipeline = try renderer.ComputePipeline.init(allocator, ctx, "../../comp.comp.spv", &subo.ubo.my_texture);
    // defer comp_pipeline.deinit(ctx);

    // init input module with iput handler functions
    try input.init(window, keyInputFn, mouseBtnInputFn, cursorPosInputFn);
    defer input.deinit();

    var texture_handles: [6]render2d.TextureHandle = undefined;
    var sprites: [4]render2d.Sprite = undefined; 


    var castle_anim: Anim = undefined;
    defer castle_anim.deinit();

    var unit_move: Move = undefined;
    var unit_swordman: Unit = undefined;

    var unit_player_castle: Castle = undefined;
    var unit_enemy_castle: Castle = undefined;
    

    var draw_api = blk: {
        var init_api = try render2d.init(allocator, ctx, 25);

        // load all textures that we will be using
        texture_handles[0] = try init_api.loadTexture("../assets/images/units/unit0000.png"[0..]);
        texture_handles[1] = try init_api.loadTexture("../assets/images/units/unit0001.png"[0..]);
        texture_handles[2] = try init_api.loadTexture("../assets/images/units/unit0002.png"[0..]);

        texture_handles[3] = try init_api.loadTexture("../assets/images/levels/map.png"[0..]);
        texture_handles[4] = try init_api.loadTexture("../assets/images/structures/castle0000.png"[0..]);
        texture_handles[5] = try init_api.loadTexture("../assets/images/structures/castle0001.png"[0..]);

        const window_size = try window.getSize();
        const window_width = @intToFloat(f32, window_size.width);
        const window_height = @intToFloat(f32, window_size.height);
     
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
            100, 10, 100, 50, 0.5, 
            [2][]const render2d.TextureHandle{&anim_move, &anim_attack}, 
            unit_move
        );
        unit_swordman.setState(.attacking);

        const caste_anim_idle = [_]render2d.TextureHandle{texture_handles[4]};
        const caste_anim_attack = [_]render2d.TextureHandle{texture_handles[5]};

        unit_player_castle = try Castle.init(
            allocator,
            &sprites[1],
            2000, 300, 200, 1.5,
            [2][]const render2d.TextureHandle{&caste_anim_idle, &caste_anim_attack}
        );

        unit_enemy_castle = try Castle.init(
            allocator,
            &sprites[2],
            2000, 300, 200, 1.5,
            [2][]const render2d.TextureHandle{&caste_anim_idle, &caste_anim_attack}
        );

        unit_enemy_castle.setState(.spawning);


        break :blk try init_api.initDrawApi(.{ .every_ms = 14 });
    };
    defer unit_enemy_castle.deinit();
    defer unit_player_castle.deinit();
    defer unit_swordman.deinit();
    defer draw_api.deinit();

    var prev_frame = std.time.milliTimestamp();
    // Loop until the user closes the window
    while (!window.shouldClose()) {
        const current_frame = std.time.milliTimestamp();
        delta_time = @intToFloat(f64, current_frame - prev_frame) / @as(f64, std.time.ms_per_s);
        // f32 variant of delta_time
        const dt = @floatCast(f32, delta_time);
        
        //castle_anim.tick(dt);

        unit_player_castle.tick(dt);
        unit_enemy_castle.tick(dt);
        unit_swordman.tick(dt);

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
    _ = event;
}
fn cursorPosInputFn(event: input.CursorPosEvent) void {
    _ = event;
    // std.debug.print("cursor pos: {s} {d}, {d} {s}\n", .{"{", event.x, event.y, "}"});
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


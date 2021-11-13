const std = @import("std");
const Allocator = std.mem.Allocator;

const zlm = @import("zlm");

const render2d = @import("../render2d/render2d.zig");
const Sprite = render2d.Sprite;

pub const Anim = @import("anim.zig");


const Self = @This();

pub const State = enum(usize) {
    idle,
    spawning,
};

sprite: *Sprite,
state: State,

anims: [2]Anim,

health: i32,
damage: i32,
range: i32,

attack_speed: f32,

pub fn init(allocator: *Allocator, sprite: *Sprite, health: i32, damage: i32, range: i32, attack_speed: f32, textures: [2][]const render2d.TextureHandle) !Self {
    
    var anim: [2]Anim = undefined;
    anim[0] = try Anim.init(allocator, sprite, textures[0], 1);
    errdefer anim[0].deinit();
    anim[1] = try Anim.init(allocator, sprite, textures[1], 1);
    errdefer anim[1].deinit();

    return Self {
        .sprite = sprite,
        .health = health,
        .damage = damage,
        .range = range,
        .attack_speed = attack_speed,
        .state = State.idle,
        .anims = anim,
    };
}

pub fn setState(self: *Self, state: State) void {
    self.state = state;
}

pub fn tick(self: *Self, delta_time: f32) void{
    self.anims[@enumToInt(self.state)].tick(delta_time);
}

pub fn deinit(self: Self) void {
    self.anims[0].deinit();
    self.anims[1].deinit();
}

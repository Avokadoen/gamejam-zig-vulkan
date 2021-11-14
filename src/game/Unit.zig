const std = @import("std");
const Allocator = std.mem.Allocator;

const zlm = @import("zlm");

const render2d = @import("../render2d/render2d.zig");
const Sprite = render2d.Sprite;

pub const Anim = @import("Anim.zig");
pub const Move = @import("Move.zig");

const Self = @This();

pub const State = enum(usize) {
    moving,
    attacking,
};

sprite: *Sprite,
state: State,
allocator: *Allocator,
textures: [2][]const render2d.TextureHandle,

anims: [2]Anim,
move: ?Move,

health: i32,
damage: i32,
move_speed: f32,
range: i32,

attack_speed: f32,

pub fn init(allocator: *Allocator, sprite: *Sprite, health: i32, damage: i32, move_speed: f32, range: i32, attack_speed: f32, textures: [2][]const render2d.TextureHandle) !Self {
    var anim: [2]Anim = undefined;
    anim[0] = try Anim.init(allocator, sprite, textures[0], 1);
    errdefer anim[0].deinit();
    anim[1] = try Anim.init(allocator, sprite, textures[1], attack_speed);
    errdefer anim[1].deinit();

    return Self {
        .allocator = allocator,
        .textures = textures,
        .sprite = sprite,
        .health = health,
        .damage = damage,
        .move_speed = move_speed,
        .range = range,
        .attack_speed = attack_speed,
        .state = State.moving,
        .anims = anim,
        .move = null,
    };
}

pub fn setState(self: *Self, state: State) void {
    self.state = state;
}

pub fn setMove(self: *Self, start: zlm.Vec2, end: zlm.Vec2) void {
    self.move = Move.init(self.sprite, start, end, self.move_speed);
}

pub fn tick(self: *Self, delta_time: f32) void{
    self.anims[@enumToInt(self.state)].tick(delta_time);

    if(self.state == .moving){
        if (self.move) |*some| {
            some.tick(delta_time);
        }
    }
}

pub fn clone(self: Self, sprite: *Sprite) !Self{
    var uni: Self = try Self.init(self.allocator, sprite, self.health, self.damage, self.move_speed, self.range, self.attack_speed, self.textures);
    uni.setMove(zlm.Vec2.new(800, -350), zlm.Vec2.new(-800, 390));
    return uni;
}

pub fn deinit(self: Self) void {
    self.anims[0].deinit();
    self.anims[1].deinit();
}

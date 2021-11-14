const std = @import("std");
const Allocator = std.mem.Allocator;

const zlm = @import("zlm");

const render2d = @import("../render2d/render2d.zig");
const Sprite = render2d.Sprite;

pub const Anim = @import("anim.zig");
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
move: Move,

health: i32,
damage: i32,
move_speed: i32,
range: i32,

attack_speed: f32,

pub fn init(allocator: *Allocator, sprite: *Sprite, health: i32, damage: i32, move_speed: i32, range: i32, attack_speed: f32, textures: [2][]const render2d.TextureHandle, move: Move) !Self {
    
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
        .move = move,
    };
}

pub fn setState(self: *Self, state: State) void {
    self.state = state;
}

pub fn tick(self: *Self, delta_time: f32) void{
    self.anims[@enumToInt(self.state)].tick(delta_time);
    if(self.state == .moving){
        self.move.tick(delta_time);
    }
}

pub fn clone(self: Self, sprite: *Sprite) !Self{
    var move: Move = Move.init(sprite, zlm.Vec2.new(800, -350), zlm.Vec2.new(-800, 390), 100);
    var uni: Self = try Self.init(self.allocator, sprite, self.health, self.damage, self.move_speed, self.range, self.attack_speed, self.textures, move);
    return uni;
}

pub fn deinit(self: Self) void {
    self.anims[0].deinit();
    self.anims[1].deinit();
}

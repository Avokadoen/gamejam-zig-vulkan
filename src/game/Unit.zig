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
    dead,
};

sprite: *Sprite,
state: State,
allocator: *Allocator,

anims: [2]Anim,
move: ?Move,

health: i32,
damage: i32,
move_speed: f32,
range: f32,

attack_speed: f32,
last_attack: f32 = 0,

pub fn init(allocator: *Allocator, sprite: *Sprite, health: i32, damage: i32, move_speed: f32, range: f32, attack_speed: f32, textures: [2][]const render2d.TextureHandle) !Self {
    var anim: [2]Anim = undefined;
    anim[0] = try Anim.init(allocator, sprite, textures[0], 1);
    errdefer anim[0].deinit();
    anim[1] = try Anim.init(allocator, sprite, textures[1], attack_speed);
    errdefer anim[1].deinit();

    return Self{
        .allocator = allocator,
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

pub fn takeDamage(self: *Self, dmg: i32) void{
    self.health -= dmg;
    if (self.health <= 0) {
        self.sprite.setPosition(zlm.Vec2.new(-200000, 0));
        self.state = .dead;
    }
}

pub fn setMove(self: *Self, start: zlm.Vec2, end: zlm.Vec2) void {
    self.move = Move.init(self.sprite, start, end, self.move_speed);
}

pub fn tick(self: *Self, delta_time: f32, closest_opponent: *Self) void {
    switch (self.state) {
        .moving => {
            self.anims[@enumToInt(self.state)].tick(delta_time);
            if (self.move) |*some| {
                some.tick(delta_time);
            }

            const opponent_pos = closest_opponent.sprite.getPosition();
            const position = self.sprite.getPosition();
            const distance = std.math.absFloat(opponent_pos.x - position.x);
            if (distance < self.range) {
                self.state = .attacking;
            }
        }, 
        .attacking => {
            const opponent_pos = closest_opponent.sprite.getPosition();
            const position = self.sprite.getPosition();
            const distance = std.math.absFloat(opponent_pos.x - position.x);
            if (distance > self.range) {
                self.state = .moving;
            }

            self.anims[@enumToInt(self.state)].tick(delta_time);
            self.last_attack += delta_time;

            if (self.last_attack >= self.attack_speed) {
                closest_opponent.takeDamage(self.damage);
                self.last_attack = 0;
            }
        },
        .dead => {
            return;
        }
    }
}

pub fn clone(self: Self, sprite: *Sprite) !Self {
    sprite.setSize(self.sprite.getSize());
    const textures = [2][]const render2d.TextureHandle{ self.anims[0].textures, self.anims[1].textures };
    var uni: Self = try Self.init(self.allocator, sprite, self.health, self.damage, self.move_speed, self.range, self.attack_speed, textures);

    return uni;
}

pub fn deinit(self: Self) void {
    self.anims[0].deinit();
    self.anims[1].deinit();
}

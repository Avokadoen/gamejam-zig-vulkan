const std = @import("std");
const Allocator = std.mem.Allocator;

const zlm = @import("zlm");

const render2d = @import("../render2d/render2d.zig");
const Sprite = render2d.Sprite;

const Anim = @import("Anim.zig");
const Move = @import("Move.zig");
const Castle = @import("Castle.zig");

const Self = @This();

pub const State = enum(usize) {
    moving,
    attacking,
    dead,
};

sprite: *Sprite,
state: State,
allocator: Allocator,

anims: [2]Anim,
move: ?Move,

health: f32,
damage: f32,
move_speed: f32,
range: f32,

walk_update_rate: f32,
attack_speed: f32,
last_attack: f32 = 0,

pub fn init(allocator: Allocator, sprite: *Sprite, walk_update_rate: f32, health: f32, damage: f32, move_speed: f32, range: f32, attack_speed: f32, textures: [2][]const render2d.TextureHandle) !Self {

    var anim: [2]Anim = undefined;
    anim[0] = try Anim.init(allocator, sprite, textures[0], walk_update_rate);
    errdefer anim[0].deinit();
    anim[1] = try Anim.init(allocator, sprite, textures[1], attack_speed);
    errdefer anim[1].deinit();

    const rtr = Self{
        .allocator = allocator,
        .sprite = sprite,
        .health = health,
        .damage = damage,
        .move_speed = move_speed,
        .range = range,
        .walk_update_rate = walk_update_rate,
        .attack_speed = attack_speed,
        .state = State.moving,
        .anims = anim,
        .move = null,
    };
    return rtr;
}

pub fn takeDamage(self: *Self, dmg: f32) void{
    self.health -= dmg;
    // let unit retaliate for one frame if dead
}

pub fn setMove(self: *Self, start: zlm.Vec2, end: zlm.Vec2) void {
    self.move = Move.init(self.sprite, start, end, self.move_speed);
}

fn bruteForceRangeCheck(self: *Self, opponent_castle: *Castle) ?*Self {
    {
        const self_pos = self.sprite.getPosition();
        var i: usize = 0;
        while (i < opponent_castle.units_spawned) : (i += 1) {
            const target_pos = opponent_castle.units[i].sprite.getPosition();
            const distance = target_pos.sub(self_pos).length2();
            if (std.math.fabs(distance) < self.range) {
                return &opponent_castle.units[i];
            }
        }
    }
    return null;
}

fn castleRange(self: *Self, opponent_castle: *Castle) bool {
    const self_pos = self.sprite.getPosition();
    const target_pos = opponent_castle.sprite.getPosition().add(opponent_castle.sprite.getSize().scale(0.25));
    const distance = target_pos.sub(self_pos).length2();
    if (std.math.fabs(distance) < self.range) {
        return true;
    }
    return false;
}

pub fn tick(self: *Self, delta_time: f32, opponent_castle: *Castle) void {
    switch (self.state) {
        .moving => {
            self.anims[@enumToInt(self.state)].tick(delta_time);
            if (self.move) |*some| {
                some.tick(delta_time);
            }

            // TODO: combat struct to combine castle and units here
            //       also to hold common combat stats ...
            if (self.bruteForceRangeCheck(opponent_castle)) |_| {
                self.state = .attacking;
            } else {
                if (self.castleRange(opponent_castle)) {
                    self.state = .attacking;
                }
            }
        }, 
        .attacking => {
            self.anims[@enumToInt(self.state)].tick(delta_time);
            if (self.bruteForceRangeCheck(opponent_castle)) |some| {
                self.last_attack += delta_time;
                if (self.last_attack >= self.attack_speed) {
                    some.takeDamage(self.damage);
                    self.last_attack = 0;
                }
            } else {
                if (self.castleRange(opponent_castle)) {
                    self.last_attack += delta_time;
                    if (self.last_attack >= self.attack_speed) {
                        opponent_castle.takeDamage(self.damage);
                        self.last_attack = 0;
                    }
                } else {
                    self.last_attack = 0;
                    self.state = .moving;
                }
            }
        },
        .dead => {
            return;
        }
    }
    // let unit retaliate for one frame if dead
    if (self.health <= 0) {
        self.sprite.setPosition(zlm.Vec2.new(-200000, 0));
        self.state = .dead;
    }
}

pub fn clone(self: Self, sprite: *Sprite) !Self {
    const textures = [2][]const render2d.TextureHandle{ self.anims[0].textures, self.anims[1].textures };
    var uni: Self = try Self.init(self.allocator, sprite, self.walk_update_rate, self.health, self.damage, self.move_speed, self.range, self.attack_speed, textures);

    return uni;
}

pub fn deinit(self: Self) void {
    self.anims[0].deinit();
    self.anims[1].deinit();
}

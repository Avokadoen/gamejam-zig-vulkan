const std = @import("std");
const Rnd = std.rand.DefaultPrng;
const Allocator = std.mem.Allocator;

const zlm = @import("zlm");
const Vec2 = zlm.Vec2;

const render2d = @import("../render2d/render2d.zig");
const Sprite = render2d.Sprite;

const Anim = @import("Anim.zig");
const Unit = @import("Unit.zig");
const HealthBar = @import("HealthBar.zig");
const game_sprite = @import("sprite.zig");

const Self = @This();

pub const State = enum(usize) {
    idle,
    spawning,
};

pub const Team = enum {
    enemy,
    player
};

sprite: *Sprite,
swordman_clone: Unit,
laser_goblin_clone: Unit,
units: [game_sprite.team_size]Unit,
health_bar: HealthBar,

spawn_pos: zlm.Vec2,
enemy_pos: zlm.Vec2,

state: State,

anims: [2]Anim,

health_max: f32,
health_current: f32,
damage: f32,
range: i32,
units_spawned: u32,

attack_speed: f32,

unit_getter: fn(number: usize) *render2d.Sprite,
team: Team,

opponent: *Self,

rnd: Rnd,

pub fn init(allocator: *Allocator, sprite: *Sprite, swordman_clone: Unit, laser_goblin_clone: Unit, health: f32, damage: f32, range: i32, attack_speed: f32, textures: [2][]const render2d.TextureHandle, team: Team) !Self {
    var anim: [2]Anim = undefined;
    anim[0] = try Anim.init(allocator, sprite, textures[0], 1);
    errdefer anim[0].deinit();
    anim[1] = try Anim.init(allocator, sprite, textures[1], 1);
    errdefer anim[1].deinit();

    var self_pos: zlm.Vec2 = undefined;
    var enemy_pos: zlm.Vec2 = undefined;

    var health_bar_pos: zlm.Vec2 = undefined;

    var health_bar: *Sprite = undefined;
    var health_bar_fill: *Sprite = undefined; 

    var unit_getter: fn(number: usize) *render2d.Sprite = undefined;

    if (team == Team.player){
        self_pos = zlm.Vec2.new(800, -400);
        enemy_pos = zlm.Vec2.new(-800, 350);

        health_bar_pos = zlm.Vec2.new(450, -450);

        health_bar =  game_sprite.getGlobal(.player_health_bar);
        health_bar_fill = game_sprite.getGlobal(.player_health_bar_fill);

        unit_getter = game_sprite.getPlayerUnit;
    } else{
        self_pos = zlm.Vec2.new(-800, 350);
        enemy_pos = zlm.Vec2.new(800, -400);
        
        health_bar_pos = zlm.Vec2.new(-450, 490);

        health_bar =  game_sprite.getGlobal(.enemy_health_bar);
        health_bar_fill = game_sprite.getGlobal(.enemy_health_bar_fill);

        unit_getter = game_sprite.getEnemyUnit;
    }

    const health_bar_complete = HealthBar.init(health_bar_pos, health_bar, health_bar_fill);

    const rnd = Rnd.init(42);

    return Self {
        .sprite = sprite,
        .swordman_clone = swordman_clone,
        .laser_goblin_clone = laser_goblin_clone,
        .health_bar = health_bar_complete,
        .health_max = health,
        .health_current = health,
        .damage = damage,
        .range = range,
        .attack_speed = attack_speed,
        .state = State.idle,
        .anims = anim,
        .spawn_pos = self_pos,
        .enemy_pos = enemy_pos,
        .units_spawned = 0,
        .units = undefined,
        .unit_getter = unit_getter,
        .team = team,
        .opponent = undefined,
        .rnd = rnd,
    };
}

pub fn setOpponent(self: *Self, castle: *Self) void {
    self.opponent = castle;
}

pub fn takeDamage(self: *Self, dmg: f32) void{
    self.health_current -= dmg;

    if (self.health_current <= 0){
    } else {
        self.health_bar.setValue(self.health_current / self.health_max);
    }
}

pub fn setState(self: *Self, state: State) void {
    self.state = state;
}

pub fn getOuterUnit(self: *Self) ?*Unit {
    if (self.outer_unit) |some| {
        return &self.units[some];
    }
    return null;
}

pub fn tick(self: *Self, delta_time: f32) void{
    self.anims[@enumToInt(self.state)].tick(delta_time);
    
    {
        var i:u32 = 0;
        while (i < self.units_spawned) : (i += 1) {
            // if (self.units[i].state == .dead) {
            //     self.units[i].deinit();
            //     std.mem.swap(Unit, &self.units[i], &self.units[self.units_spawned-1]);
            //     self.units_spawned -= 1;
            //     if (self.units_spawned == 0) break;
            // }

            self.units[i].tick(delta_time, self.opponent);
        }
    }
}

pub fn spawnUnit(self: *Self) !void{
    if (self.units_spawned < game_sprite.team_size) {
        const y_offset = self.rnd.random().float(f32) * 100 - 50;
        const x_offset = self.rnd.random().float(f32) * 100 - 50;
        const start = Vec2.new(self.spawn_pos.x + x_offset, self.spawn_pos.y + y_offset);
        const end   = Vec2.new(self.enemy_pos.x + x_offset, self.enemy_pos.y + y_offset);

        var prototype = blk: {
            if (self.rnd.random().float(f32) >= 0.5) {
                break :blk self.swordman_clone;
            } else {
                break :blk self.laser_goblin_clone;
            }
        };

        var sprite = self.unit_getter(self.units_spawned);
        sprite.setPosition(start);
        sprite.setTexture(prototype.anims[0].textures[0]);
        if (self.team == .player) {
            const size = prototype.sprite.getSize();
            sprite.setSize(zlm.Vec2.new(-size.x, size.y));
        } else {
            sprite.setSize(prototype.sprite.getSize());
        }

        self.units[self.units_spawned] = try prototype.clone(sprite);
        self.units[self.units_spawned].setMove(start, end);

        self.units_spawned += 1;

    }
}

pub fn deinit(self: Self) void {
    self.anims[0].deinit();
    self.anims[1].deinit();
    {   
        var i: u32 = 0;
        while (i < self.units_spawned) : (i += 1) {
            self.units[i].deinit();
        }
    }
}


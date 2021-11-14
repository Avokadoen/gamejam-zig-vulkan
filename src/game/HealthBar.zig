const std = @import("std");

const zlm = @import("zlm");

const render2d = @import("../render2d/render2d.zig");
const Sprite = render2d.Sprite;

const Self = @This();

bar: *Sprite,
fill: *Sprite,

bar_size: zlm.Vec2,
bar_pos: zlm.Vec2,

value: f32,

/// init a health bar
pub fn init(position: zlm.Vec2, bar: *Sprite, fill: *Sprite) Self {
    bar.setPosition(position);
    fill.setPosition(position);

    return Self {
        .bar = bar,
        .fill = fill,
        .bar_size = bar.getSize(),
        .bar_pos = position,
        .value = 1,
    };
}

pub fn setValue(self: *Self, value: f32) void {
    self.value = std.math.max(0, value);
    self.value = std.math.min(1, self.value);
    
    const size = zlm.Vec2.new(lerp(0, self.bar_size.x, self.value), self.bar_size.y);
    self.fill.setSize(size);
    
    var pos = self.bar_pos;
    pos.x -= (self.bar_size.x - size.x) * 0.5;

    self.fill.setPosition(pos); 
}

fn lerp(v0: f32, v1: f32, t: f32) f32 {
    return std.math.fma(f32, t, v1 - v0, v0);
}

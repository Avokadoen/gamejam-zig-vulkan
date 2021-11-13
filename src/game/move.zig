const std = @import("std");

const render2d = @import("../render2d/render2d.zig");
const Sprite = render2d.Sprite;

const zlm = @import("zlm");

const Self = @This();

sprite: *Sprite,

start: zlm.Vec2,
end: zlm.Vec2,

t: f32,
stride: f32,
velocity: f32,

pub fn init(sprite: *Sprite, start: zlm.Vec2, end: zlm.Vec2, velocity: f32) Self{
    const stride = 1/(end.sub(start).length()/ velocity);

    return Self {
        .sprite = sprite,
        .start = start,
        .end = end,
        .velocity = velocity,
        .t = 0,
        .stride = stride,
    };
}

pub fn tick(self: *Self, delta_time: f32) void {
    self.t = std.math.min(1, self.t + delta_time * self.stride);
    const pos = self.start.lerp(self.end, self.t);
    self.sprite.setPosition(pos);
}
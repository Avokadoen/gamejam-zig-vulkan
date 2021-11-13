const std = @import("std");

const zlm = @import("zlm");

const render2d = @import("../render2d/render2d.zig");
const Sprite = render2d.Sprite;
const TextureHandle = render2d.TextureHandle;

const Self = @This();

sprite: *Sprite,
idle: TextureHandle,
clicked: TextureHandle,

bound: render2d.Rectangle,

callback: fn() void,

pub fn init(sprite: *Sprite, idle_texture: TextureHandle, clicked_texture: TextureHandle, callback: fn() void) Self {
    return Self{
        .sprite = sprite,
        .idle = idle_texture,
        .clicked = clicked_texture,
        .bound = sprite.getRectangle(),
        .callback = callback,
    };
}

pub fn setPosition(self: *Self, position: zlm.Vec2) void {
    self.sprite.setPosition(position);
    self.bount = self.sprite.getRectangle();
}

pub fn setScale(self: *Self, scale: zlm.Vec2) void {
    self.sprite.setSize(scale);
}

pub fn onClick(self: Self) void {
    self.sprite.setTexture(self.clicked);
    self.callback();
}

pub fn onRelease(self: Self) void {
    self.sprite.setTexture(self.idle);
}

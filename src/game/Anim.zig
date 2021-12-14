const std = @import("std");
const Allocator = std.mem.Allocator;

const render2d = @import("../render2d/render2d.zig");
const Sprite = render2d.Sprite;
const TextureHandle = render2d.TextureHandle;

const Self = @This();

allocator: Allocator,

sprite: *Sprite,
frame: usize,
textures: []TextureHandle,

last_update: f32,
update_frequency: f32,

/// caller must make sure to call deinit
pub fn init(allocator: Allocator, sprite: *Sprite, textures: []const TextureHandle, update_frequency: f32) !Self {
    // std.debug.print("anim start pos: {d} {d} {d}\n", .{sprite.db_id, sprite.getPosition().x, sprite.getPosition().y});
    
    var alloc_textures = try allocator.alloc(TextureHandle, textures.len);
    std.mem.copy(TextureHandle, alloc_textures, textures);

    //force update texture
    sprite.setTexture(alloc_textures[0]);

    return Self {
        .allocator = allocator,
        .sprite = sprite,
        .frame = 0,
        .textures = alloc_textures,
        .last_update = 0,
        .update_frequency = update_frequency,
    };
}

pub fn tick(self: *Self, delta_time: f32) void {
    self.last_update += delta_time;

    if (self.update_frequency <= self.last_update) {
        self.frame += 1;
        self.frame %= self.textures.len;

        self.sprite.setTexture(self.textures[self.frame]);

        self.last_update = 0;
    }
}

pub fn deinit(self: Self) void {
    self.allocator.free(self.textures);
}

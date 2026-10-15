const Geometry = @import("Geometry");

pub const IslandState = enum(i32) {
    collapsed = 0,
    hover = 1,
    expanded = 2,
    music_strip = 3,
    full_bar = 4,
    notice_strip = 5,
};

pub const full_bar_width_dip: f32 = 0.0;
pub const full_bar_height_dip: f32 = 32.0;
pub const full_bar_radius_dip: f32 = 6.0;
pub const min_band_height_dip: f32 = 8.0;
pub const max_band_height_dip: f32 = 128.0;
pub const card_top_gap_dip: f32 = 8.0;
pub const collapsed_width_dip: f32 = 220.0;
pub const collapsed_height_dip: f32 = 36.0;
pub const expanded_width_dip: f32 = 520.0;
pub const expanded_height_dip: f32 = 280.0;
pub const notice_strip_width_dip: f32 = 420.0;
pub const notice_strip_height_dip: f32 = collapsed_height_dip;
pub const card_radius_dip: f32 = 20.0;

pub const SizeF = struct {
    width: f32 = 0.0,
    height: f32 = 0.0,
    radius: f32 = 0.0,
};

pub const IslandAnchor = struct {
    center_x: f32 = 0.0,
    top_y: f32 = 0.0,
    band_height_dip: f32 = full_bar_height_dip,
};

pub fn stateName(state: IslandState) []const u8 {
    return switch (state) {
        .collapsed => "collapsed",
        .hover => "hover",
        .expanded => "expanded",
        .music_strip => "music-strip",
        .full_bar => "full-bar",
        .notice_strip => "notice-strip",
    };
}

pub fn stateFromName(name: []const u8) IslandState {
    if (stdAsciiEqlIgnoreCase(name, "collapsed")) return .collapsed;
    if (stdAsciiEqlIgnoreCase(name, "hover")) return .hover;
    if (stdAsciiEqlIgnoreCase(name, "expanded")) return .expanded;
    if (stdAsciiEqlIgnoreCase(name, "music-strip")) return .music_strip;
    if (stdAsciiEqlIgnoreCase(name, "full-bar")) return .full_bar;
    if (stdAsciiEqlIgnoreCase(name, "notice-strip")) return .notice_strip;
    return .collapsed;
}

fn stdAsciiEqlIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |ac, bc| {
        if (stdAsciiLower(ac) != stdAsciiLower(bc)) return false;
    }
    return true;
}

fn stdAsciiLower(c: u8) u8 {
    return if (c >= 'A' and c <= 'Z') c + ('a' - 'A') else c;
}

pub fn stadiumRadiusForHeight(height_dip: f32) f32 {
    return height_dip * 0.5;
}

pub fn stateSize(state: IslandState) SizeF {
    return switch (state) {
        .expanded => .{ .width = expanded_width_dip, .height = expanded_height_dip, .radius = card_radius_dip },
        .full_bar => .{ .width = full_bar_width_dip, .height = full_bar_height_dip, .radius = full_bar_radius_dip },
        .notice_strip => .{ .width = notice_strip_width_dip, .height = notice_strip_height_dip, .radius = stadiumRadiusForHeight(notice_strip_height_dip) },
        .collapsed, .hover, .music_strip => .{ .width = collapsed_width_dip, .height = collapsed_height_dip, .radius = stadiumRadiusForHeight(collapsed_height_dip) },
    };
}

pub fn outerCardRevealDip(box_height_dip: f32) f32 {
    const span = expanded_height_dip - collapsed_height_dip;
    const t = @max(0.0, @min(1.0, (box_height_dip - collapsed_height_dip) / span));
    return expanded_height_dip * t;
}

pub fn rowAnchorBox(current: Geometry.RoundedBox, resting_pill: Geometry.RoundedBox) Geometry.RoundedBox {
    const current_width = Geometry.width(current.rect);
    const pill_width = Geometry.width(resting_pill.rect);
    const current_height = Geometry.height(current.rect);
    const pill_height = Geometry.height(resting_pill.rect);
    if (current_width > pill_width + 0.5 and current_width < expanded_width_dip - 0.5 and
        @abs(current_height - pill_height) <= 0.5)
    {
        return current;
    }
    return resting_pill;
}

pub fn anchorForWindow(origin_x: f32, origin_y: f32, monitor_width_dip: f32, band_height_dip: f32) IslandAnchor {
    _ = origin_y;
    const band = if (band_height_dip >= min_band_height_dip and band_height_dip <= max_band_height_dip)
        band_height_dip
    else
        full_bar_height_dip;
    return .{
        .center_x = monitor_width_dip * 0.5 - origin_x,
        .top_y = Geometry.pill_top_margin_dip,
        .band_height_dip = band,
    };
}

pub fn boxForState(state: IslandState, anchor: IslandAnchor) Geometry.RoundedBox {
    var size = stateSize(state);
    if (state == .full_bar) size.height = anchor.band_height_dip;
    if (size.width <= 0.0) size.width = anchor.center_x * 2.0;
    const left = anchor.center_x - size.width * 0.5;
    return .{
        .rect = .{
            .left = left,
            .top = anchor.top_y,
            .right = left + size.width,
            .bottom = anchor.top_y + size.height,
        },
        .radius_x = size.radius,
        .radius_y = size.radius,
    };
}

pub fn placedCardFor(resting_pill: Geometry.RoundedBox, card_left_dip: f32) Geometry.RoundedBox {
    const top = resting_pill.rect.bottom + card_top_gap_dip;
    return .{
        .rect = .{
            .left = card_left_dip,
            .top = top,
            .right = card_left_dip + expanded_width_dip,
            .bottom = top + expanded_height_dip,
        },
        .radius_x = card_radius_dip,
        .radius_y = card_radius_dip,
    };
}

pub fn cardColumnFor(resting_pill: Geometry.RoundedBox, card_left_dip: f32) Geometry.RectF {
    const card = placedCardFor(resting_pill, card_left_dip);
    return .{
        .left = card.rect.left,
        .top = resting_pill.rect.bottom,
        .right = card.rect.right,
        .bottom = card.rect.bottom,
    };
}

pub fn sameBox(a: Geometry.RoundedBox, b: Geometry.RoundedBox) bool {
    const epsilon: f32 = 0.01;
    return @abs(a.rect.left - b.rect.left) < epsilon and
        @abs(a.rect.top - b.rect.top) < epsilon and
        @abs(a.rect.right - b.rect.right) < epsilon and
        @abs(a.rect.bottom - b.rect.bottom) < epsilon;
}

pub const MotionTiming = struct {
    collapse_to_hover: f32 = 0.22,
    hover_to_collapse: f32 = 0.16,
    to_expanded: f32 = 0.36,
    from_expanded: f32 = 0.24,
};

fn clamp01(t: f32) f32 {
    return @max(0.0, @min(1.0, t));
}

pub fn easeOutCubic(t: f32) f32 {
    const u = 1.0 - clamp01(t);
    return 1.0 - u * u * u;
}

/// Symmetric cubic easing retained for callers that need an S-curve. Runtime
/// island transitions use `easeOutCubic`; this remains useful for reversible
/// secondary motion and matches the original Motion API.
pub fn easeInOutCubic(t: f32) f32 {
    const x = clamp01(t);
    if (x < 0.5) return 4.0 * x * x * x;
    const remaining = -2.0 * x + 2.0;
    return 1.0 - remaining * remaining * remaining * 0.5;
}

pub fn transitionSeconds(from: IslandState, to: IslandState, timing: MotionTiming) f32 {
    if (from == to) return 0.0;
    const outward = @backingInt(to) > @backingInt(from);
    if (from == .expanded or to == .expanded) return if (outward) timing.to_expanded else timing.from_expanded;
    return if (outward) timing.collapse_to_hover else timing.hover_to_collapse;
}

pub fn curveFor(_: IslandState, _: IslandState) *const fn (f32) f32 {
    return easeOutCubic;
}

pub fn lerpBox(a: Geometry.RoundedBox, b: Geometry.RoundedBox, t: f32) Geometry.RoundedBox {
    const x = clamp01(t);
    const mix = struct {
        fn run(p: f32, q: f32, amount: f32) f32 {
            return p + (q - p) * amount;
        }
    }.run;
    return .{
        .rect = .{
            .left = mix(a.rect.left, b.rect.left, x),
            .top = mix(a.rect.top, b.rect.top, x),
            .right = mix(a.rect.right, b.rect.right, x),
            .bottom = mix(a.rect.bottom, b.rect.bottom, x),
        },
        .radius_x = mix(a.radius_x, b.radius_x, x),
        .radius_y = mix(a.radius_y, b.radius_y, x),
    };
}

pub const Motion = struct {
    target_state: IslandState = .collapsed,
    from_state: IslandState = .collapsed,
    current_box: Geometry.RoundedBox = .{ .rect = .{} },
    from_box: Geometry.RoundedBox = .{ .rect = .{} },
    to_box: Geometry.RoundedBox = .{ .rect = .{} },
    elapsed: f32 = 0.0,
    duration: f32 = 0.0,
    progress_value: f32 = 1.0,
    animating: bool = false,
    anchor: IslandAnchor = .{},
    has_anchor: bool = false,
    timing: MotionTiming = .{},

    pub fn target(self: *const Motion) IslandState {
        return self.target_state;
    }

    pub fn visibleFromState(self: *const Motion) IslandState {
        return if (self.animating) self.from_state else self.target_state;
    }

    pub fn isAnimating(self: *const Motion) bool {
        return self.animating;
    }

    pub fn progress(self: *const Motion) f32 {
        return self.progress_value;
    }

    pub fn eased(self: *const Motion) f32 {
        return curveFor(self.from_state, self.target_state)(self.progress_value);
    }

    pub fn current(self: *const Motion) Geometry.RoundedBox {
        return self.current_box;
    }

    pub fn scaleDurations(self: *Motion, factor: f32) void {
        if (factor <= 0.0) return;
        self.timing.to_expanded *= factor;
        self.timing.from_expanded *= factor;
        self.timing.collapse_to_hover *= factor;
        self.timing.hover_to_collapse *= factor;
    }

    pub fn setAnchor(self: *Motion, anchor: IslandAnchor) void {
        self.anchor = anchor;
        self.has_anchor = true;
        self.from_box = boxForState(self.from_state, self.anchor);
        self.to_box = boxForState(self.target_state, self.anchor);
        if (self.animating) {
            const amount = curveFor(self.from_state, self.target_state)(self.progress_value);
            self.current_box = lerpBox(self.from_box, self.to_box, amount);
        } else {
            self.current_box = self.to_box;
            self.from_box = self.current_box;
        }
    }

    pub fn setTarget(self: *Motion, state: IslandState) bool {
        if (!self.has_anchor or state == self.target_state) return false;
        const candidate = boxForState(state, self.anchor);
        if (sameBox(self.current_box, candidate)) {
            self.target_state = state;
            self.from_state = state;
            self.to_box = candidate;
            self.animating = false;
            self.elapsed = 0.0;
            self.progress_value = 1.0;
            return false;
        }
        self.from_box = self.current_box;
        self.from_state = self.target_state;
        self.target_state = state;
        self.to_box = candidate;
        self.duration = transitionSeconds(self.from_state, self.target_state, self.timing);
        self.elapsed = 0.0;
        self.progress_value = 0.0;
        if (self.duration <= 0.0) {
            self.current_box = self.to_box;
            self.progress_value = 1.0;
            self.animating = false;
            return true;
        }
        self.animating = true;
        const amount = curveFor(self.from_state, self.target_state)(0.0);
        self.current_box = lerpBox(self.from_box, self.to_box, amount);
        return true;
    }

    pub fn tick(self: *Motion, dt_seconds: f32) bool {
        if (!self.animating) return false;
        self.elapsed += dt_seconds;
        if (self.duration <= 0.0 or self.elapsed >= self.duration) {
            self.current_box = self.to_box;
            self.progress_value = 1.0;
            self.animating = false;
            return false;
        }
        self.progress_value = self.elapsed / self.duration;
        const amount = curveFor(self.from_state, self.target_state)(self.progress_value);
        self.current_box = lerpBox(self.from_box, self.to_box, amount);
        return true;
    }

    pub fn snapTo(self: *Motion, state: IslandState) void {
        self.target_state = state;
        self.from_state = state;
        self.animating = false;
        self.elapsed = 0.0;
        self.progress_value = 1.0;
        if (self.has_anchor) self.current_box = boxForState(state, self.anchor);
        self.from_box = self.current_box;
        self.to_box = self.current_box;
    }
};

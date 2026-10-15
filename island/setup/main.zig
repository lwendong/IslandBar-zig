const Setup = @import("Setup");
const Payload = @import("Payload");

pub fn main() void {
    Setup.run(Payload.bytes);
}

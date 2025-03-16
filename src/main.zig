const std = @import("std");
const builtin = @import("builtin");
const glfw = @cImport({
    @cInclude("GLFW/glfw3.h");
});

const gl = @cImport({
    @cDefine("GL_GLEXT_PROTOTYPES", {});
    // @cDefine("GL_SILENCE_DEPRECATION", {}); // Unterdrückt Warnungen auf macOS

    switch (builtin.os.tag) {
        .macos => @cInclude("OpenGL/gl3.h"),
        .linux => @cInclude("GL/gl.h"),
        .windows => @cInclude("GL/gl.h"),
        else => @compileError("Unsupported OS"),
    }
});

var mouse_pos: MousePosition = undefined;

fn cursorPosCallback(_: ?*glfw.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
    std.debug.print("Mausposition: X={d:.1}, Y={d:.1}\n", .{ xpos, ypos });
    mouse_pos = MousePosition{ .x = xpos, .y = ypos };
}

fn mouseButtonCallback(window: ?*glfw.GLFWwindow, button: c_int, action: c_int, _: c_int) callconv(.C) void {
    var xpos: f64 = 0;
    var ypos: f64 = 0;
    glfw.glfwGetCursorPos(window, &xpos, &ypos);

    if (action == glfw.GLFW_PRESS) {
        const button_name = switch (button) {
            glfw.GLFW_MOUSE_BUTTON_LEFT => "Links",
            glfw.GLFW_MOUSE_BUTTON_RIGHT => "Rechts",
            glfw.GLFW_MOUSE_BUTTON_MIDDLE => "Mitte",
            else => "Andere",
        };
        std.debug.print("Maus-Klick ({s}): X={d:.1}, Y={d:.1}\n", .{ button_name, xpos, ypos });
    }
}

fn keyCallback(window: ?*glfw.GLFWwindow, key: c_int, _: c_int, action: c_int, _: c_int) callconv(.C) void {
    if (key == glfw.GLFW_KEY_ESCAPE and action == glfw.GLFW_PRESS) {
        glfw.glfwSetWindowShouldClose(window, 1);
    }
}

fn errorCallback(error_code: c_int, description: [*c]const u8) callconv(.C) void {
    std.debug.print("GLFW Error {}: {s}\n", .{ error_code, description });
}

fn compileShader(shader_type: c_uint, source: [*c]const u8) c_uint {
    std.debug.print("Kompiliere Shader vom Typ: {s}\n", .{if (shader_type == gl.GL_VERTEX_SHADER) "Vertex" else "Fragment"});
    std.debug.print("Shader Quellcode:\n{s}\n", .{source});

    const shader = gl.glCreateShader(shader_type);
    if (shader == 0) {
        std.debug.print("Fehler beim Erstellen des Shaders\n", .{});
        return 0;
    }

    gl.glShaderSource(shader, 1, &source, null);
    gl.glCompileShader(shader);

    var success: c_int = undefined;
    gl.glGetShaderiv(shader, gl.GL_COMPILE_STATUS, &success);

    // Immer Info-Log ausgeben, unabhängig vom Erfolg
    var info_log: [512]u8 = undefined;
    var log_length: c_int = undefined;
    gl.glGetShaderInfoLog(shader, 512, &log_length, &info_log);

    const shader_type_str = switch (shader_type) {
        gl.GL_VERTEX_SHADER => "Vertex",
        gl.GL_FRAGMENT_SHADER => "Fragment",
        else => "Andere",
    };

    if (success == 0) {
        std.debug.print("{s} Shader Kompilierung fehlgeschlagen: {s}\n", .{ shader_type_str, info_log });
        return 0;
    } else if (log_length > 0) {
        std.debug.print("{s} Shader Kompilierung erfolgreich, aber mit Meldungen: {s}\n", .{ shader_type_str, info_log });
    }

    return shader;
}

fn checkGLError(location: []const u8) void {
    const err = gl.glGetError();
    if (err != gl.GL_NO_ERROR) {
        std.debug.print("OpenGL Fehler bei {s}: 0x{X}\n", .{ location, err });
    }
}

const Cursor = struct {
    x: i32 = 0,
    y: i32 = 0,
};

const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};

const MousePosition = struct {
    x: f64,
    y: f64,
};

const Rect = struct {
    pos_x: i32,
    pos_y: i32,
    width: i32,
    height: i32,
    color: Color,

    fn init(cursor: *Cursor, width: i32, height: i32, color: Color) Rect {
        defer cursor.y += height;
        return Rect{
            .pos_x = cursor.x,
            .pos_y = cursor.y,
            .width = width,
            .height = height,
            .color = color,
        };
    }

    fn input(self: *Rect, pos: MousePosition) void {
        const mouse_pos_y: i32 = @intFromFloat(pos.y);
        const mouse_pos_x: i32 = @intFromFloat(pos.x);
        if (mouse_pos_x > self.pos_x and mouse_pos_x < self.pos_x + self.width and
            mouse_pos_y > self.pos_y and mouse_pos_y < self.pos_y + self.height)
        {
            self.color.r += 1.0;
        }
    }

    fn render(self: *Rect, window_height: i32) void {
        // gl.glBegin(gl.GL_QUADS);
        // gl.glColor4f(self.color.r, self.color.g, self.color.b, self.color.a);
        // gl.glVertex2i(self.pos_x, self.pos_y);
        // gl.glVertex2i(self.pos_x + self.width, self.pos_y);
        // gl.glVertex2i(self.pos_x + self.width, self.pos_y + self.height);
        // gl.glVertex2i(self.pos_x, self.pos_y + self.height);
        // gl.glEnd();

        gl.glScissor(self.pos_x, window_height - self.pos_y - self.height, self.width, self.height);
        gl.glViewport(self.pos_x, window_height - self.pos_y - self.height, self.width, self.height);
        gl.glClearColor(self.color.r, self.color.g, self.color.b, self.color.a);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);
    }
};
fn getWindowSize(window: ?*glfw.GLFWwindow) struct { usize, usize } {
    var width: i32 = 0;
    var height: i32 = 0;
    glfw.glfwGetWindowSize(window, &width, &height);
    return .{ @intCast(width), @intCast(height) };
}
pub fn main() void {
    if (glfw.glfwInit() == 0) {
        std.debug.print("Failed to initialize GLFW\n", .{});
        return;
    }
    // Direkt nach glfwInit()
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_CORE_PROFILE);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_DEBUG_CONTEXT, 1);
    glfw.glfwWindowHint(glfw.GLFW_SAMPLES, 4);

    defer glfw.glfwTerminate();

    _ = glfw.glfwSetErrorCallback(errorCallback);

    const window = glfw.glfwCreateWindow(
        800,
        600,
        "Hello, World",
        null,
        null,
    );
    if (window == null) {
        std.debug.print("Failed to create GLFW window\n", .{});
        return;
    }
    defer glfw.glfwDestroyWindow(window);

    glfw.glfwMakeContextCurrent(window);

    var major: c_int = undefined;
    var minor: c_int = undefined;
    var rev: c_int = undefined;
    glfw.glfwGetVersion(&major, &minor, &rev);
    std.debug.print("GLFW Version: {}.{}.{}\n", .{ major, minor, rev });

    checkGLError("Nach Context Creation");

    // Fügen Sie eine kleine Verzögerung hinzu, um sicherzustellen, dass der Kontext initialisiert ist
    glfw.glfwSwapInterval(1);

    // Überprüfen Sie auch die Fehlermeldungen
    checkGLError("Nach Context Creation");

    _ = glfw.glfwSetKeyCallback(window, keyCallback);
    _ = glfw.glfwSetCursorPosCallback(window, cursorPosCallback);
    _ = glfw.glfwSetMouseButtonCallback(window, mouseButtonCallback);
    glfw.glfwSwapInterval(1);

    gl.glEnable(gl.GL_SCISSOR_TEST);

    while (glfw.glfwWindowShouldClose(window) == 0) {
        const width, const height = getWindowSize(window);
        std.debug.print("Fenstergröße: {d}x{d}\n", .{ width, height });
        gl.glScissor(0, 0, @intCast(width), @intCast(height));
        gl.glViewport(0, 0, @intCast(width), @intCast(height));
        gl.glClearColor(1.0, 0.3, 0.3, 1.0);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);

        var cursor = Cursor{};
        var rect1 = Rect.init(&cursor, 200, 100, .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 });
        var rect2 = Rect.init(&cursor, 200, 100, .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 });

        // rect1.input(mouse_pos);
        // rect2.input(mouse_pos);
        rect1.render(@intCast(height));
        rect2.render(@intCast(height));

        glfw.glfwSwapBuffers(window);
        glfw.glfwPollEvents();
    }
}

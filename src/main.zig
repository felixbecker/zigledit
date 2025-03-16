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

const vertex_shader_source: [*c]const u8 =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\void main() {
    \\    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\}
;

const fragment_shader_source: [*c]const u8 =
    \\#version 330 core
    \\out vec4 FragColor;
    \\void main() {
    \\    FragColor = vec4(1.0, 0.0, 0.0, 1.0); // Rot
    \\}
;

const vertices = [_]f32{
    -0.5, -0.5, 0.0, // Links unten
    0.5, -0.5, 0.0, // Rechts unten
    0.0, 0.5, 0.0, // Oben mitte
};

fn cursorPosCallback(_: ?*glfw.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
    std.debug.print("Mausposition: X={d:.1}, Y={d:.1}\n", .{ xpos, ypos });
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
pub fn main() void {
    if (glfw.glfwInit() == 0) {
        std.debug.print("Failed to initialize GLFW\n", .{});
        return;
    }
    // Direkt nach glfwInit()
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 3); // macOS unterstützt maximal 4.1
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_CORE_PROFILE);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_FORWARD_COMPAT, gl.GL_TRUE);

    defer glfw.glfwTerminate();

    _ = glfw.glfwSetErrorCallback(errorCallback);

    const window = glfw.glfwCreateWindow(800, 600, "Hello, World", null, null);
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
    const vertex_shader = compileShader(gl.GL_VERTEX_SHADER, vertex_shader_source);
    checkGLError("Nach Vertex Shader");

    if (vertex_shader == 0) {
        std.debug.print("Vertex Shader is 0", .{});
        return;
    }

    const fragment_shader = compileShader(gl.GL_FRAGMENT_SHADER, fragment_shader_source);
    if (fragment_shader == 0) {
        std.debug.print("Fragment Shader is 0", .{});
        return;
    }
    checkGLError("Nach Fragment Shader");

    const program = gl.glCreateProgram();
    gl.glAttachShader(program, vertex_shader);
    gl.glAttachShader(program, fragment_shader);
    gl.glLinkProgram(program);

    // Errror handling
    var program_success: c_int = undefined;
    gl.glGetProgramiv(program, gl.GL_LINK_STATUS, &program_success);
    if (program_success == 0) {
        var info_log: [512]u8 = undefined;
        gl.glGetProgramInfoLog(program, 512, null, &info_log);
        std.debug.print("Shader-Programm Linking fehlgeschlagen: {s}\n", .{info_log});
        return;
    }

    gl.glDeleteShader(vertex_shader);
    gl.glDeleteShader(fragment_shader);

    var vob: c_uint = undefined;
    var vao: c_uint = undefined;
    gl.glGenVertexArrays(1, &vao);
    gl.glGenBuffers(1, &vob);
    gl.glBindVertexArray(vao);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vob);

    gl.glBufferData(gl.GL_ARRAY_BUFFER, vertices.len, &vertices, gl.GL_STATIC_DRAW);
    checkGLError("Nach Buffer Data");

    gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 3 * @sizeOf(f32), null);
    gl.glEnableVertexAttribArray(0);

    while (glfw.glfwWindowShouldClose(window) == 0) {
        gl.glClearColor(1.0, 0.3, 0.3, 1.0);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);
        checkGLError("Nach Clear");

        gl.glUseProgram(program);
        checkGLError("Nach Use Program");

        gl.glBindVertexArray(vao);
        gl.glDrawArrays(gl.GL_TRIANGLES, 0, 3);
        checkGLError("Nach Draw Arrays");

        glfw.glfwSwapBuffers(window);
        glfw.glfwPollEvents();
    }
    gl.glDeleteVertexArrays(1, &vao);
    gl.glDeleteBuffers(1, &vob);
    gl.glDeleteProgram(program);
}

{ pkgs ? import <nixpkgs> {} }:

let
  glfw_path = "${pkgs.glfw}";
in

pkgs.mkShell {
  buildInputs = with pkgs; [
    zig
    glfw
    libGL
    mesa
    clang-tools
    darwin.apple_sdk.frameworks.OpenGL
  ];

  shellHook = ''
    # GLFW- und OpenGL-Pfade setzen
    export GLFW_PATH=${pkgs.glfw}
    export CPATH=$GLFW_PATH/include:$CPATH
    export LIBRARY_PATH=$GLFW_PATH/lib:$LIBRARY_PATH

    # SDK für macOS setzen
    export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
    export MACOSX_DEPLOYMENT_TARGET=11.0
  '';
}

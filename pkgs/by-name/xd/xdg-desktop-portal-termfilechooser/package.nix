{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  meson,
  ninja,
  pkg-config,
  wayland-protocols,
  wayland-scanner,
  inih,
  libdrm,
  mesa,
  scdoc,
  systemd,
  wayland,
}:
stdenv.mkDerivation {
  pname = "xdg-desktop-portal-termfilechooser";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "nani8ot";
    repo = "xdg-desktop-portal-termfilechooser";
    rev = "main";
    sha256 = "sha256-4s3n5EONwmDhdMrs7NdCqM/IAcNXmmbuhv84btCredg=";
  };

  strictDeps = true;
  depsBuildBuild = [pkg-config];
  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    scdoc
    wayland-scanner
    makeWrapper
  ];
  buildInputs = [
    inih
    libdrm
    mesa
    systemd
    wayland
    wayland-protocols
  ];

  mesonFlags = [
    "-Dsd-bus-provider=libsystemd"
  ];

  meta = with lib; {
    homepage = "https://github.com/GermainZ/xdg-desktop-portal-termfilechooser";
    description = "xdg-desktop-portal backend for wlroots and the likes of ranger";
    maintainers = with maintainers; [soispha];
    platforms = platforms.linux;
    license = licenses.mit;
  };
}

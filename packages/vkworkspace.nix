# The VK WorkSpace desktop client (the corporate messenger, mail, calendar…)
# from its DEB; nixpkgs has no package for it. The archive carries its own
# Qt 6 with WebEngine, ffmpeg and X11 libraries, so only the rest of the system
# libraries come from nixpkgs.
#
# The download page links to linux/x64/vkworkspace.deb, which always serves
# the latest release; each release also stays at linux/x64/<version>/ along
# with the SHA-256 of its DEB, so this pins that one. To update, put the
# version and the hash printed by these into `version` and `sha256`:
#
#   curl -s https://hb.bizmrg.com/vkteams-www/linux/x64/version.json \
#     | jq -r '.info.version | "\(.major).\(.minor).\(.patch).\(.buildnumber)"'
#   curl -s https://hb.bizmrg.com/vkteams-www/linux/x64/<version>/vkworkspace.deb.sha256
{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, makeWrapper
, alsa-lib
, bzip2
, dbus
, expat
, fontconfig
, freetype
, glib
, krb5
, libICE
, libSM
, libdrm
, libfontenc
, libgbm
, libglvnd
, libgpg-error
, libpng
, libpulseaudio
, libsecret
, libuuid
, libva
, libvdpau
, libxkbfile
, nspr
, nss
, pipewire
, systemdLibs
, wayland
, xz
, zlib
, zstd
}:

stdenv.mkDerivation rec {
  pname = "vkworkspace";
  version = "26.4.21.147345";

  src = fetchurl {
    url = "https://hb.bizmrg.com/vkteams-www/linux/x64/${version}/vkworkspace.deb";
    sha256 = "44a51b15c2b89e97ca25d10047bac4f65d1297b058cd119bed805dc187194b9f";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];

  buildInputs = [
    alsa-lib
    bzip2
    dbus
    expat
    fontconfig
    freetype
    glib
    krb5
    libICE
    libSM
    libdrm
    libfontenc
    libgbm
    libglvnd
    libgpg-error
    libpng
    libpulseaudio
    libsecret
    libuuid
    libva
    libvdpau
    libxkbfile
    nspr
    nss
    stdenv.cc.cc.lib
    systemdLibs
    wayland
    xz
    zlib
    zstd
  ];

  # Libraries that are dlopen'ed, so they don't show up as DT_NEEDED, added to
  # the runpath of every ELF file, not only of executables
  # (runtimeDependencies), because libraries dlopen them too:
  # - libGL: the bundled lib/libGl.so.1 looks for the system's libGL.so.1 and,
  #   when it isn't found, silently switches to the bundled software Mesa
  #   (libGLsoft.so.1). The Qt GLX plugin uses the system's Mesa all the same,
  #   and with two GL stacks in one process QtWebEngine fails to start
  #   ("Could not initialize GLX") every other launch.
  # - PipeWire for Qt Multimedia (call audio, screen sharing)
  appendRunpaths = map (package: "${lib.getLib package}/lib") [ libglvnd pipewire ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt $out/bin
    cp -r usr/local/vkworkspace $out/opt/

    # The bundled Qt must not pick up plugins and QML modules of the system's
    # Qt 6, which is a different version. With GLX, QtWebEngine still fails to
    # start ("Could not initialize GLX", no matching FBConfig for its offscreen
    # surface) on most launches even with the system's Mesa; with EGL it
    # starts every time.
    makeWrapper $out/opt/vkworkspace/vkworkspace $out/bin/vkworkspace \
      --unset QT_PLUGIN_PATH \
      --unset QML2_IMPORT_PATH \
      --unset QML_IMPORT_PATH \
      --set-default QT_XCB_GL_INTEGRATION xcb_egl

    install -Dm644 usr/share/pixmaps/vkworkspace.png $out/share/pixmaps/vkworkspace.png
    for desktopFile in usr/share/applications/*.desktop; do
      install -Dm644 $desktopFile $out/share/applications/$(basename $desktopFile)
    done
    substituteInPlace $out/share/applications/*.desktop \
      --replace-fail /usr/local/vkworkspace/vkworkspace $out/bin/vkworkspace \
      --replace-fail /usr/share/pixmaps/vkworkspace.png vkworkspace

    runHook postInstall
  '';

  meta = {
    description = "VK WorkSpace desktop client";
    homepage = "https://workspace.vk.ru/download/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "vkworkspace";
  };
}

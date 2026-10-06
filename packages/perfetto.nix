# Prebuilt Perfetto command-line tools; nixpkgs has no package for them.
# The UI is not packaged: open traces at https://ui.perfetto.dev.
{ lib, stdenv, fetchurl, unzip, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "perfetto";
  version = "58.2";

  src = fetchurl {
    url = "https://github.com/google/perfetto/releases/download/v${version}/linux-amd64.zip";
    hash = "sha256-Msc59xstOXIa/SlMCwOPJJmkSnG1trzdhbg/rKCyQLk=";
  };

  nativeBuildInputs = [ unzip autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 -t $out/bin perfetto tracebox traceconv trace_processor_shell traced traced_probes
    install -Dm755 -t $out/lib libheapprofd_glibc_preload.so
    runHook postInstall
  '';

  meta = {
    description = "Perfetto tracing and trace analysis tools";
    homepage = "https://perfetto.dev";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

{ lib, stdenv, fetchurl, pkg-config, perl, bison, bootstrap_cmds
, openssl, openldap, libedit, keyutils, libverto, darwin

# for passthru.tests
, bind
, curl
, nixosTests
, openssh
, postgresql
, python3

# Extra Arguments
, type ? ""
# This is called "staticOnly" because krb5 does not support
# builting both static and shared, see below.
, staticOnly ? false
, withVerto ? false
}:

# Note: this package is used for bootstrapping fetchurl, and thus
# cannot use fetchpatch! All mutable patches (generated by GitHub or
# cgit) that are needed here should be included directly in Nixpkgs as
# files.

let
  libOnly = type == "lib";
in
stdenv.mkDerivation rec {
  pname = "${type}krb5";
  version = "1.21.2";

  src = fetchurl {
    url = "https://kerberos.org/dist/krb5/${lib.versions.majorMinor version}/krb5-${version}.tar.gz";
    sha256 = "sha256-lWCUGp2EPAJDpxsXp6xv4xx867W845g9t55Srn6FBJE=";
  };

  outputs = [ "out" "dev" ];

  configureFlags = [ "--localstatedir=/var/lib" ]
    # krb5's ./configure does not allow passing --enable-shared and --enable-static at the same time.
    # See https://bbs.archlinux.org/viewtopic.php?pid=1576737#p1576737
    ++ lib.optionals staticOnly [ "--enable-static" "--disable-shared" ]
    ++ lib.optional withVerto "--with-system-verto"
    ++ lib.optional stdenv.isFreeBSD ''WARN_CFLAGS=""''
    ++ lib.optionals (stdenv.buildPlatform != stdenv.hostPlatform)
       [ "krb5_cv_attr_constructor_destructor=yes,yes"
         "ac_cv_func_regcomp=yes"
         "ac_cv_printf_positional=yes"
       ];

  nativeBuildInputs = [ pkg-config perl ]
    ++ lib.optional (!libOnly) bison
    # Provides the mig command used by the build scripts
    ++ lib.optional stdenv.isDarwin bootstrap_cmds;

  buildInputs = [ openssl ]
    ++ lib.optionals (stdenv.hostPlatform.isLinux && stdenv.hostPlatform.libc != "bionic" && !(stdenv.hostPlatform.useLLVM or false)) [ keyutils ]
    ++ lib.optionals (!libOnly) [ openldap libedit ]
    ++ lib.optionals withVerto [ libverto ]
    ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk; [
      libs.xpc
      frameworks.Kerberos
    ]);

  sourceRoot = "krb5-${version}/src";

  postPatch = ''
    substituteInPlace config/shlib.conf \
        --replace "'ld " "'${stdenv.cc.targetPrefix}ld "
  '';

  libFolders = [ "util" "include" "lib" "build-tools" ];

  buildPhase = lib.optionalString libOnly ''
    runHook preBuild

    MAKE="make -j $NIX_BUILD_CORES"
    for folder in $libFolders; do
      $MAKE -C $folder
    done

    runHook postBuild
  '';

  installPhase = lib.optionalString libOnly ''
    runHook preInstall

    mkdir -p "$out"/{bin,sbin,lib/pkgconfig,share/{et,man/man1}} \
      "$dev"/include/{gssapi,gssrpc,kadm5,krb5}
    for folder in $libFolders; do
      $MAKE -C $folder install
    done

    runHook postInstall
  '';

  # not via outputBin, due to reference from libkrb5.so
  postInstall = ''
    moveToOutput bin/krb5-config "$dev"
  '';

  enableParallelBuilding = true;
  doCheck = false; # fails with "No suitable file for testing purposes"

  meta = with lib; {
    description = "MIT Kerberos 5";
    homepage = "http://web.mit.edu/kerberos/";
    license = licenses.mit;
    platforms = platforms.unix ++ platforms.windows;
  };

  passthru = {
    implementation = "krb5";
    tests = {
      inherit (nixosTests) kerberos;
      inherit (python3.pkgs) requests-credssp;
      bind = bind.override { enableGSSAPI = true; };
      curl = curl.override { gssSupport = true; };
      openssh = openssh.override { withKerberos = true; };
      postgresql = postgresql.override { gssSupport = true; };
    };
  };
}

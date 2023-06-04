{ lib
, stdenvNoCC
, fetchurl
, dbip-country-lite
}:

stdenvNoCC.mkDerivation rec {
  pname = "dbip-country-lite";
  version = "2023-06";

  src = fetchurl {
    url = "https://download.db-ip.com/free/dbip-country-lite-${version}.mmdb.gz";
    hash = "sha256-H+f7OhI03qhgpldF05Nc5ohPIPNhyVRCwiVqeWkvIbc=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preBuild

    gzip -c -d "$src" > dbip-country-lite.mmdb
    install -Dm444 dbip-country-lite.mmdb "$out/share/dbip/dbip-country-lite.mmdb"

    runHook postBuild
  '';

  passthru.mmdb = "${dbip-country-lite}/share/dbip/dbip-country-lite.mmdb";

  meta = with lib; {
    description = "The free IP to Country Lite database by DB-IP";
    homepage = "https://db-ip.com/db/download/ip-to-country-lite";
    license = licenses.cc-by-40;
    maintainers = with maintainers; [ nickcao ];
    platforms = platforms.all;
  };
}

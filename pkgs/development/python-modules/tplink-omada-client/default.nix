{ lib
, aiohttp
, buildPythonPackage
, fetchPypi
, hatchling
, pytestCheckHook
, pythonOlder
}:

buildPythonPackage rec {
  pname = "tplink-omada-client";
  version = "1.1.1";
  format = "pyproject";

  disabled = pythonOlder "3.9";

  src = fetchPypi {
    pname = "tplink_omada_client";
    inherit version;
    hash = "sha256-Fg1rhTS9aP7C1URDfoC3w1w1IduToxYUtwTLDM3916U=";
  };

  nativeBuildInputs = [
    hatchling
  ];

  propagatedBuildInputs = [
    aiohttp
  ];

  # Module have no tests
  doCheck = false;

  pythonImportsCheck = [
    "tplink_omada_client"
  ];

  meta = with lib; {
    description = "Library for the TP-Link Omada SDN Controller API";
    homepage = "https://github.com/MarkGodwin/tplink-omada-api";
    license = licenses.mit;
    maintainers = with maintainers; [ fab ];
  };
}

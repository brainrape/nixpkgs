{ stdenv
, fetchFromGitHub
, buildGoPackage
} :
buildGoPackage rec {
  name = "do-agent-${version}";
  version = "${major}.${minor}.${patch}";
  major = "0";
  minor = "5";
  patch = "1";
  goPackagePath = "github.com/digitalocean/do-agent";

  # excludedPackages = ''\(doctl-gen-doc\|install-doctl\|release-doctl\)'';
  buildFlagsArray = let t = "${goPackagePath}"; in ''
     -ldflags=
        -X ${t}.Major=${major}
        -X ${t}.Minor=${minor}
        -X ${t}.Patch=${patch}
        -X ${t}.Label=release
   '';

  src = fetchFromGitHub {
    owner = "digitalocean";
    repo   = "do-agent";
    rev    = "v${version}";
    sha256 = "15i21cxdc75hb0l3mrwvyqy66h6hm6qa9jv37mx69grjy0cx8kwy";
  };

  meta = {
    description = "Collects system metrics from DigitalOcean Droplets";
    homepage = https://github.com/digitalocean/do-agent;
    license = stdenv.lib.licenses.asl20;
    platforms = stdenv.lib.platforms.all;
    maintainers = [ stdenv.lib.maintainers.siddharthist ];
  };
}

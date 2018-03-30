---
title: User's Guide for Idris in Nixpkgs
author: Marton Boros
date: 2017-03-09
---

# User's Guide to the Idris Infrastructure

Install Idris with default packages into your user environment in the usual way, and start a REPL:

```
nix-env -i idris

idris
```

## How to install Idris packages

Idris packages are not included in the top level package set, so `nix-env -qa` will not show them. Here's how to list available Idris packages:

```
$ nix-env -f "<nixpkgs>" -qaP -A idrisPackages
```

Start a shell with Idris packages available and start a REPL in it:

```
[TODO]
nix-shell -p "idrisPackages.idrisWithPackages (pkgs: with idrisPackages; [ contrib lightyear ])" --run "idris -p contrib -p lightyear"
```

To define a development environment with Idris packages available, create a file named `default.nix` in your project directory, with contents like the following, adapted to your needs:

```
{ pkgs ? import <nixpkgs> {}, ...} :
pkgs.idrisPackages.buildIdrisPackage {
  name = "mypackage";
  version = "1.2.3";

  src = ./.;

  # add Idris dependencies here
  idrisDeps = with pkgs.idrisPackages; [ prelude base lightyear ];

  # add native dependencies here
  extraBuildInputs = with pkgs; [ libuv ];
}

```

Run `nix-shell` to start a shell in the environment defined above, with Idris, Idris packages, and other dependencies available.

To learn more about how to define, build, and publish Idris packages, see the section "Creating Idris package definitions" below.


## Publishing Idris Packages

To publish an Idris package, create a package definition as explained below and follow these steps:

1. Fork the [nixpkgs](https://github.com/NixOS/nixpkgs) repo on github and clone your fork
2. Create a branch off `master` and add the package definition
3. Push the branch and create a Pull Request on nixpkgs
4. After the branch is merged, the changes will land in the `nixpkgs-unstable` channel in  a few days


### Creating Idris package definitions

Here's how to create a package defintion for publishing Idris packages in nixpkgs (as well as projects outside nixpkgs as described in the section "Installing Idris packages").

Make sure ther is a `my-package.ipkg` file in the project that includes everything needed to build the package.

Create a new file `pkgs/development/idris-modules/my-package.nix` in your clone of your fork of `nixpkgs`. It is a good idea to base it off an existing package definition, like `lightyear.nix`. Set the `name`, `version`, `src`, `meta` attributes, according to the nixpkgs [contribution guide](https://github.com/NixOS/nixpkgs/blob/master/.github/CONTRIBUTING.md).

Add the package to the `idrisPackages` set in `pkgs/development/idris-modules/defaut.nix`, in alphabetical order. For example:
```
    my-package = callPackage ./my-package.nix {};
```

The package can now be built (involving `idris --build`) with the following command:

```
nix-build /path/to/nixpkgs/clone -A idrisPackages.my-package
```

Use the `idrisDeps` attribute to add Idris packages as dependencies, and add them as input arguments to the package definition function at the top of the file. For example, the `lightyear` package definition includes the `prelude`, `base`, `effects` libraries as `idrisDeps`.

Use the `extraBuildInputs` attribute to add non-idris packages as dependencies available in the build environment. For example, the `glfw` Idris package definition includes the `glfw` native library (reachable within the pkgs attribute because the package names are the same) in `extraBuildInputs`. If you need `idris-rts.h` to build a package using FFI, include `idris` itself in `extraBuildInputs`.

Use the `postUnpack` attribute to patch files or do pre-build steps if you are in a hurry and do not have control over the repository. Ideally these changes should be included in the repository, and in the build steps in the `.ipkg` file or `Makefile`.

The above should cover most packages. For more information, check out the documentation for the `buildIdrisPackage` function below, and its implementation. After successfully building the package, follow the [contribution guide](https://github.com/NixOS/nixpkgs/blob/master/.github/CONTRIBUTING.md), commit the changes, push the branch, and open a Pull Request on the `nixpkgs` repository.

Naming suggestions:
- name the repo for the Idris package `my-package` or `idris-my-package`
- name the Idris package file `my-package.ipkg`
- name the Idris package `my-package` by starting the above file with the line `package my-package`
- name the nix package definition `pkgs/development/idris-modules/my-package.nix`
- name the nix package `my-package` by setting the `name` attribute in the argument to `buildIdrisPackage`
- in `idris-modules/default.nix`, name the package attribute `my-package`

So name everything the same, and don't include `idris` in it, except maybe add `idris-` to the repo name. Prefer dashes to underscores.


### Updating Idris Packages

The process to update an Idris package in `nixpkgs` is similar to publishing it in the first place. It is usually enough to update the `src` attribute. Sometimes, packaging changes are required. See the section titled "Creating Idris package definition".

Once the updated package is successfully built, it is necessary to check that all the packages that depend on it still work.

The `nox` tool can list the packages that depend on the changed package:

```
TODO
```

Build all the packages depending on the chanted package:

```
TODO
```

If there are broken packages, they must be dealt with in one of these ways, from best to worst:
- fix the broken package, and send one pull request  with all updated packages
- change the package definition of the broken package to patch the differences, if practical, to be removed when the broken package is updated
- change the package definition of the broken package to override the version of the updated package to an older version that doesn't break it
- mark the broken package with `meta.broken = true;`

After all broken packages have been resolved in one of the ways above, proceed to publish the update according to the [contribution guide](https://github.com/NixOS/nixpkgs/blob/master/.github/CONTRIBUTING.md).


### Overriding Idris packages

Sometimes you need a different version of a package that is in the package set, or set different build options, or change it in some other way. The Idris package definitions can be overridden in the usual way:

```
{ ... } :
let
    lightyear = lightyear.override old: {
        version = "1.2.3";
        src = fetchFromGithub {
            owner = "";
            repo = "";
            rev = "";
            sha256 = "";
        };
    };
in buildIdrisPackage {
    name = "my-package";
    idrisDeps = [ ... lightyear ... ];
    ...
}
```


## Useful Attributes in `idrisPackages`

Here are some attributes of `idrisPackages` that are not packages, but useful functions and sets:


`idrisPackages.buildIdrisPackage`
---

Build an idris package. The function's argument is a set with the following possible attributes:

- `name` - package name
- `version` - package version
- `src` - package sources, passed to mkDerivation
- `idrisDeps` - a list of Idris packages to be made available to the Idris runtime
- `extraBuildInputs` - a list of buildInputs to add to the package's build environment
- `postUnpack` - script to run after unpacking sources
- `meta` - package meta attributes, passed to mkDerivation

See `build-idris-package.nix` for details.


`idrisPackages.callPackage`
---

Package composition function for Idris packages. This is used in `default.nix` to create the package attribute by feeding the dependencies to the package definition.



`idrisPackages.idrisWithPackages`
---

Bundle Idris together with a list of packages. Because idris currently
only supports a single directory in its library path, you must add
all desired libraries, including `prelude` and `base`.


`idrisPackages.buildBuiltinPackage`
---

`buildIdrisPackage` specialized to builtin packages.



`idrisPackages.builtins`
---

Contains the set of all libraries that come packaged with Idris
itself, like `prelude`, `base`, `contrib`, `effects`.

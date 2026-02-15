# Fix Plan: Home Manager Module `self` Argument Error

## Problem Summary

When using the zeroclaw flake as a Home Manager module input in a NixOS configuration, the following error occurs:

```
error: function 'anonymous lambda' called without required argument 'self'
at /nix/store/.../nix/home-manager.nix:1:1:
     1| { self }:
        | ^
```

## Root Cause

The [`nix/home-manager.nix`](../nix/home-manager.nix:1) file uses a curried function pattern:

```nix
{ self }:  # First argument
{ config, lib, pkgs, ... }:  # Second argument - the actual HM module
```

While [`flake.nix`](../flake.nix:127) correctly passes `self`:

```nix
homeManagerModules = {
  default = import ./nix/home-manager.nix self;
};
```

The issue occurs because when the flake is used as an input in another flake's Home Manager configuration, the module evaluation context may not correctly preserve the `self` binding. This is a known issue with how Nix evaluates flake outputs when used as inputs.

## Solution

Restructure the module to use a more robust pattern that doesn't rely on curried arguments. The fix involves:

### 1. Modify `nix/home-manager.nix`

Remove the curried `{ self }:` argument and instead:
- Accept the package as an option with a default that uses `builtins.getFlake`
- Or require users to specify the package explicitly

### 2. Update `flake.nix`

Change the `homeManagerModules` export to directly reference the module file without the curried pattern.

## Implementation Details

### Option A: Use `builtins.getFlake` (Recommended)

Change [`nix/home-manager.nix`](../nix/home-manager.nix:1) to:

```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.zeroclaw;
  cfgFile = "${config.xdg.configHome}/zeroclaw/config.toml";
  
  # Get the flake reference dynamically
  zeroclawFlake = builtins.getFlake "github:btripoloni/zeroclaw-flake";
in
{
  options.services.zeroclaw = {
    enable = mkEnableOption "ZeroClaw AI assistant";

    package = mkOption {
      type = types.package;
      default = zeroclawFlake.packages.${pkgs.system}.default;
      defaultText = literalExpression "zeroclaw.packages.\${pkgs.system}.default";
      description = "The ZeroClaw package to use.";
    };
    # ... rest of options
  };
  # ... rest of config
}
```

And update [`flake.nix`](../flake.nix:126-129) to:

```nix
homeManagerModules = {
  default = import ./nix/home-manager.nix;
  zeroclaw = import ./nix/home-manager.nix;
};
```

### Option B: Require explicit package specification

Remove the default entirely and require users to specify the package:

```nix
package = mkOption {
  type = types.package;
  defaultText = literalExpression "zeroclaw.packages.\${pkgs.system}.default";
  description = "The ZeroClaw package to use.";
};
```

Users would then need to specify:

```nix
services.zeroclaw = {
  enable = true;
  package = zeroclaw.packages.${pkgs.system}.default;
};
```

## Recommended Approach

**Option A** is recommended because:
1. It maintains the same user experience (no changes required in user configs)
2. It works reliably when the flake is used as an input
3. It follows a pattern used by other successful flakes

## Files to Modify

1. [`nix/home-manager.nix`](../nix/home-manager.nix) - Remove curried argument, add `builtins.getFlake`
2. [`flake.nix`](../flake.nix) - Update `homeManagerModules` export

## Testing

After making the changes:
1. Run `nix flake check` to verify the flake evaluates correctly
2. Test in a consumer flake to verify the module works as expected

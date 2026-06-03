# FPC Port Status

## Scope

This branch documents and prototypes an initial Free Pascal Compiler port of
DMVCFramework, tested from a consuming project on:

- FPC `3.2.2`
- target `aarch64-linux`
- WSL Ubuntu
- Indy supplied from Lazarus OPM (`Indy10`)

The goal of this branch is not a finished runtime yet. It is a feasibility
probe for compiling the DMVC core and its direct dependencies under FPC while
keeping the Delphi path intact.

## Branch

- Working branch: `fpc-port-core-probe`

## Current Result

The build now gets through a relevant part of the stack:

- `dmvcframework.inc`
- `MVCFramework`
- `MVCFramework.Commons`
- `MVCFramework.Container`
- `MVCFramework.Rtti.Utils`
- `MVCFramework.Session`
- `MVCFramework.Logger`
- `LoggerPro` core
- `LoggerPro.ConsoleAppender`
- `LoggerPro.CallbackAppender`
- `MVCFramework.Logger.ColorConsoleRenderer`

Current blocker:

- `MVCFramework.Serializer.JsonDataObjects.pas`

Current first visible error:

```text
Fatal: Can't find unit System.Classes used by MVCFramework.Serializer.JsonDataObjects
```

This is only the first visible error in that unit. The serializer also depends
on Delphi-specific `System.JSON`, extensive RTTI use, and many `TValue.AsType<>`
paths. This is likely the next substantial porting block, not a one-line fix.

## Build Context

The branch was exercised from a consumer repository using a dedicated probe
program and build script. Relevant external setup:

- FPC available in WSL
- Lazarus installed
- Indy found under:
  - `~/.lazarus/onlinepackagemanager/packages/Indy10/System`
  - `~/.lazarus/onlinepackagemanager/packages/Indy10/Core`
  - `~/.lazarus/onlinepackagemanager/packages/Indy10/Protocols`
  - `~/.lazarus/onlinepackagemanager/packages/Indy10/lib/aarch64-linux`

This branch does not yet contain a self-contained FPC build system inside the
DMVC repository itself. The current probe was driven from the consumer side.

## What Was Changed

### Core preprocessor and namespace work

Initial FPC guards and unit-name splits were added so the compiler can move
past Delphi namespace assumptions:

- `sources/dmvcframework.inc`
- `sources/MVCFramework.pas`
- `sources/MVCFramework.Commons.pas`
- `sources/MVCFramework.Container.pas`
- `sources/MVCFramework.DuckTyping.pas`
- `sources/MVCFramework.Rtti.Utils.pas`
- `sources/MVCFramework.Session.pas`
- `sources/MVCFramework.Logger.pas`
- `sources/MVCFramework.Logger.ColorConsoleRenderer.pas`
- `sources/MVCFramework.Nullables.pas`
- `sources/JsonDataObjects.pas`

### Temporary FPC simplifications

Some areas were intentionally reduced to keep the core probe moving:

- `MVCFramework.Commons` currently avoids the normal `DotEnv` path under FPC.
- `dotEnv`/`dotEnvConfigure` are stubbed for the FPC probe.
- `MVCFramework.Session` includes temporary FPC-side cookie/web-response stubs.

These changes are acceptable for a feasibility branch, but they are not a final
product-quality port.

### LoggerPro work already done

The branch now contains a meaningful first pass over LoggerPro so DMVC logging
can compile deeper under FPC:

- `lib/loggerpro/LoggerPro.pas`
- `lib/loggerpro/LoggerPro.Renderers.pas`
- `lib/loggerpro/LoggerPro.RendererRegistry.pas`
- `lib/loggerpro/LoggerPro.ConsoleAppender.pas`
- `lib/loggerpro/LoggerPro.CallbackAppender.pas`
- `lib/loggerpro/LoggerPro.AnsiColors.pas`
- `lib/loggerpro/ThreadSafeQueueU.pas`

Main adjustments:

- `System.*` unit name splits for FPC
- FPC-safe callback type substitutions where Delphi used `reference to`
- FPC-safe locking path in `LoggerPro.pas`
- FPC-safe replacements for `MemoryBarrier`, `InnerException`,
  `TFormatSettings.Create`, `TValue.AsType<TDateTime>`, and a few thread/wait
  differences
- POSIX console writing through `fpWrite(...)`

## Technical Findings

### 1. The port is possible in principle

This branch already proves that the effort is not blocked at the first layer.
The code can be pushed through:

- compiler directives
- namespace unit differences
- parts of RTTI usage
- Indy-based DMVC dependencies, once Indy is supplied explicitly
- a non-trivial part of LoggerPro

### 2. The cost is higher than a trivial `{$IFDEF FPC}` pass

The work quickly moved beyond unit-name replacements into real language and RTL
differences:

- anonymous methods / `reference to`
- `TValue.AsType<>`
- Delphi-specific `System.JSON`
- threading and synchronization differences
- WebBroker/Web request abstractions

### 3. Serializer and web abstractions are likely the hard part

The current blocker is the serializer layer, but the likely expensive areas are:

- `MVCFramework.Serializer.JsonDataObjects`
- `MVCFramework.Serializer.Text`
- `MVCFramework.Serializer.URLEncoded`
- `MVCFramework.Serializer.Streaming`
- request/response abstractions
- middleware depending on Delphi web stack behavior

### 4. Swagger is not the first milestone

Swagger and related documentation units should stay out of the first porting
milestone. They are useful, but not necessary to prove that:

- routing works
- controllers execute
- middleware runs
- JWT/auth/security paths can be preserved

## Open Problems

### High priority

1. Decide whether the serializer path should be:
   - ported properly to FPC, or
   - temporarily bypassed/stubbed for a narrower core proof
2. Decide whether FPC support is expected to be:
   - full first-class support in DMVC, or
   - a limited Linux/server profile
3. Define the minimum success criterion:
   - core units compile
   - sample HTTP server runs
   - controller attributes and routing work
   - middleware + JWT + auth work

### Medium priority

1. Bring the probe setup into this repository so the branch can be tested
   directly without consumer-specific scripts.
2. Audit LoggerPro appenders and keep only the subset that should be supported
   under FPC in the first phase.
3. Review Indy usage versus alternative FPC-compatible abstractions.

### Low priority

1. Swagger / OpenAPI helpers
2. optional appenders
3. advanced samples

## Recommended Next Paths

### Path A: Stop the broad port and build a narrow vertical slice

Recommended if the goal is decision support rather than a full port.

Suggested target:

1. minimal server bootstrap
2. one controller
3. one route
4. one JSON request/response path
5. one auth/JWT path

To do that, cut away non-essential serializer and documentation features until
the route stack is proven.

### Path B: Continue the DMVC core port

Recommended only if first-class FPC support is a real product goal.

Next concrete block:

1. `MVCFramework.Serializer.JsonDataObjects.pas`
2. serializer siblings
3. web request/response layers
4. middleware and auth stack

This is feasible, but it is not a short cleanup.

### Path C: Re-evaluate framework strategy

If the real goal is Linux/FPC server runtime rather than preserving DMVC
internals, a different server stack may be cheaper overall. The tradeoff is
clear:

- staying with DMVC preserves controller/routing concepts, but the port is deep
- moving to another stack lowers compiler friction, but forces adaptation of
  controllers, routing, middleware, auth and tooling

## Conclusion

This branch demonstrates partial feasibility, but it also shows that a complete
DMVC-to-FPC port is a substantial engineering effort. The branch is useful as a
checkpoint and decision basis. It should not be mistaken for a near-finished
port.

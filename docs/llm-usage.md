# LLM Usage Guide for MonkeyBars

This guide is written for LLMs and tools that need precise instructions to
apply patches safely with MonkeyBars. It focuses on the public API, expected
inputs/outputs, and common failure modes.

## Quick start

Minimal, correct patch that adds a new instance method:

```ruby
class MyPatch
  extend MonkeyBars

  patch(SomeLibrary, version: "2.3.1", version_check: -> { SomeLibrary::VERSION }) do
    new_instance_methods do
      def new_method
        "added"
      end
    end
  end
end
```

## Core concepts

### Monkey resolution

The `monkey` argument can be:

- A module/class reference (e.g. `SomeLibrary`)
- A string constant name (e.g. `"SomeLibrary"`, resolved via `Kernel.const_get`)
- A lambda/proc that returns a module/class (evaluated at patch time)

If it cannot be resolved, `MonkeyBars::NoPatchableMonkeyFoundError` is raised.

### Version checking

`version_check` must be callable and return the current version. MonkeyBars
compares it with `version` using exact equality. Mismatches raise
`MonkeyBars::NoPatchableVersionFoundError`.

### Patch lifecycle

- `patch(...)` validates and applies immediately.
- `prepare_for_patching(...)` validates and stores the patch.
- `patch!` applies a previously prepared patch and can only be called once.

Calling `patch!` more than once raises `MonkeyBars::PatchAlreadyPerformedError`.

## API reference

### Entry points

#### `patch(monkey, version:, version_check:)`

Validates and applies a patch immediately.

- `monkey`: module/class, string, or callable
- `version`: expected version (exact string match)
- `version_check`: callable returning current version
- Side effect: mutates the target module/class in place

#### `prepare_for_patching(monkey, version:, version_check:)`

Validates and stores patch definitions for later application.

#### `patch!`

Applies a prepared patch exactly once.

### Patch blocks (helpers)

Each helper can be called multiple times; MonkeyBars combines the definitions.

#### `new_instance_methods(&block)`

Adds new instance methods via `include`.

- Error: `MonkeyBars::NewInstanceMethodAlreadyExistsError` if method exists.

#### `patch_instance_methods(ignore_arity_errors: false, include_super_super: false, &block)`

Overrides existing instance methods via `prepend`.

- Error: `MonkeyBars::NoPatchableInstanceMethodFoundError` if method does not exist.
- Error: `MonkeyBars::MismatchedInstanceMethodArityError` when arity differs,
  unless `ignore_arity_errors: true` is set.
- `include_super_super: true` makes `#super_super` available for these methods.

#### `new_class_methods(&block)`

Adds new class methods via `extend`.

- Error: `MonkeyBars::NewClassMethodAlreadyExistsError` if method exists.

#### `patch_class_methods(ignore_arity_errors: false, include_super_super: false, &block)`

Overrides existing class methods via `singleton_class.prepend`.

- Error: `MonkeyBars::NoPatchableClassMethodFoundError` if method does not exist.
- Error: `MonkeyBars::MismatchedClassMethodArityError` when arity differs,
  unless `ignore_arity_errors: true` is set.
- `include_super_super: true` makes `#super_super` available for these methods.

#### `patch_constants(&block)`

Redefines existing constants (remove + set).

- Error: `MonkeyBars::PatchConstantNotFoundError` if constant does not exist.

#### `new_constants(&block)`

Adds new constants.

- Error: `MonkeyBars::NewConstantAlreadyExistsError` if constant exists.

#### `post_patch(&block)`

Optional callback after patching. If the block arity is:

- `0`: called with no args
- `1`: called with the patched module/class

## Examples

### Patch an existing instance method

```ruby
class FixPatch
  extend MonkeyBars

  patch(SomeLibrary, version: "1.0.0", version_check: -> { SomeLibrary::VERSION }) do
    patch_instance_methods do
      def compute(value)
        super(value) + 1
      end
    end
  end
end
```

### Add new class method and constant

```ruby
class Additions
  extend MonkeyBars

  patch("SomeLibrary", version: "1.0.0", version_check: -> { SomeLibrary::VERSION }) do
    new_class_methods do
      def new_class_method
        "ok"
      end
    end

    new_constants do
      const_set(:MAX_RETRIES, 5)
    end
  end
end
```

### Use `super_super` to skip the immediate parent

```ruby
class Parent
  def greet
    "parent"
  end
end

class Child < Parent
  def greet
    "child -> " + super
  end
end

class ChildPatch
  extend MonkeyBars

  patch(Child, version: "1.0", version_check: -> { "1.0" }) do
    patch_instance_methods(include_super_super: true) do
      def greet
        "patched -> " + super_super
      end
    end
  end
end
```

## Error reference and fixes

Use this section when the patch fails. The message usually suggests the fix.

- `MonkeyBars::NoPatchableMonkeyFoundError`: the target constant cannot be found.
  Use a valid constant or a callable that returns one.
- `MonkeyBars::NoPatchableVersionCheckError`: `version_check` is missing or not callable.
  Provide a lambda/proc returning the current version.
- `MonkeyBars::NoPatchableVersionFoundError`: current version does not match `version`.
  Update the version string or the version check.
- `MonkeyBars::NoPatchableInstanceMethodFoundError`: method does not exist.
  Move it to `new_instance_methods` or fix the method name.
- `MonkeyBars::NoPatchableClassMethodFoundError`: method does not exist.
  Move it to `new_class_methods` or fix the method name.
- `MonkeyBars::MismatchedInstanceMethodArityError`: arity differs.
  Match the signature or set `ignore_arity_errors: true`.
- `MonkeyBars::MismatchedClassMethodArityError`: arity differs.
  Match the signature or set `ignore_arity_errors: true`.
- `MonkeyBars::NewInstanceMethodAlreadyExistsError`: method already exists.
  Move it to `patch_instance_methods`.
- `MonkeyBars::NewClassMethodAlreadyExistsError`: method already exists.
  Move it to `patch_class_methods`.
- `MonkeyBars::PatchConstantNotFoundError`: constant does not exist.
  Move it to `new_constants` or fix the constant name.
- `MonkeyBars::NewConstantAlreadyExistsError`: constant already exists.
  Move it to `patch_constants`.
- `MonkeyBars::PatchAlreadyPerformedError`: `patch!` was called twice.
  Ensure you only call `patch!` once per prepared patch.

## Best practices for LLMs

- Always include `version_check` and ensure it returns the exact version string.
- Prefer `patch(...)` for immediate application unless delayed patching is required.
- Use `patch_*` helpers for existing methods/constants and `new_*` for new ones.
- Keep patched method arity identical to the original unless explicitly allowed.
- Add targeted tests around the patched behavior; avoid testing internal details.

## Testing checklist

- Patch applies with the expected version and fails with a mismatched version.
- Patched method behavior is correct and `super`/`super_super` calls behave as intended.
- Errors are raised for missing methods/constants and for arity mismatches.

<p align="center">
  <img src="docs/monkey_bars_patch_for_readme.png" alt="MonkeyBars patch n' play logo">
</p>

# MonkeyBars

Safe, version-aware monkey patching for Ruby modules and classes. MonkeyBars
gives you a structured DSL to add or override methods and constants while
verifying the target's version and validating method arity.

## But... why?

Monkey patching is sometimes necessary, but it is easy to get wrong. This gem
adds guardrails so patches fail loudly when:

- The target module/class is missing
- The target version is not what you expect
- You try to add a method/constant that already exists
- You try to patch a method/constant that does not exist
- Method arity changes unexpectedly

## Installation

Add to your Gemfile:

```ruby
gem "monkey_bars"
```

Or install directly:

```sh
gem install monkey_bars
```

Requires Ruby 3.2+.

## Quick start

Create a patcher class and extend `MonkeyBars`, then call the appropriate
methods:

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

## LLM usage guide

If you want LLM-friendly, structured guidance for patching, see:

- `docs/llm-usage.md`

## Core DSL

The patcher is a class or module that `extend`s `MonkeyBars`. Patches are
declared inside a block and then applied with `patch` (immediately) or
`prepare_for_patching` + `patch!` (deferred).

### Patch entry points

- `patch(monkey, version:, version_check:)` applies immediately
- `prepare_for_patching(monkey, version:, version_check:)` prepares a patch
- `patch!` applies a prepared patch

If `patch!` runs without any methods or constants defined, it emits a warning.

The `monkey` can be:

- A module/class reference
- A string constant name (resolved with `Kernel.const_get`)
- A lambda/proc that returns a module/class

### Patch blocks

Use these block helpers to describe changes:

- `patch_instance_methods` to override existing instance methods
- `new_instance_methods` to add new instance methods
- `patch_class_methods` to override existing class methods
- `new_class_methods` to add new class methods
- `patch_constants` to redefine existing constants
- `new_constants` to add new constants
- `post_patch` to run after patching (with 0 or 1 arg)

You can call any of these helpers multiple times; MonkeyBars will combine them.
This is helpful when you want to ignore some arity check errors (see below) for
some methods but not others.

### Method arity checks

When patching existing methods, arity must match by default. You can opt out:

```ruby
patch_instance_methods(ignore_arity_errors: true) do
  def method_with_args(*args)
    args.sum
  end
end
```

### super_super helper

If you're looking to mimic fully replacing an existing method and need to call
`super`, meaning, you want to 'skip' over the original implementation you are
patching on top of, you can include this helper which exposes a `#super_super`
method that does just that.

```ruby
class A
  VERSION = "1.0"

  def cut_out_the_middlemane
    puts "A#cut_out_the_middlemane"
  end
end

class B < A
  def cut_out_the_middlemane
    puts "B#cut_out_the_middlemane"
    super
  end
end

class BPatcher
  extend MonkeyBars

  patch(B, version: "1.0", version_check: -> { B::VERSION }) do
    patch_instance_methods(include_super_super: true) do
      def cut_out_the_middlemane
        puts "BPatcher#cut_out_the_middlemane"
        super_super
      end
    end
  end
end

# B.new.cut_out_the_middlemane
# => BPatcher#cut_out_the_middlemane
# => A#cut_out_the_middlemane
```

The same option is available for class methods.

## Example: full patch

```ruby
class IntegrationPatch
  extend MonkeyBars

  patch("SomeLibrary", version: "1.0.0", version_check: -> { SomeLibrary::VERSION }) do
    new_class_methods do
      def new_class_method
        "new class"
      end
    end

    patch_class_methods do
      def class_method
        super + " + modified"
      end
    end

    new_instance_methods do
      def new_instance_method
        "new instance"
      end
    end

    patch_instance_methods do
      def instance_method
        super + " + modified"
      end
    end

    patch_constants do
      const_set(:TIMEOUT, 60)
    end

    new_constants do
      const_set(:MAX_RETRIES, 5)
    end

    post_patch do |monkey|
      # optional callback
    end
  end

end
```

## Errors you may see

MonkeyBars raises specific errors to keep patches safe and explicit:

- `MonkeyBars::NoPatchableMonkeyFoundError`
- `MonkeyBars::NoPatchableVersionCheckError`
- `MonkeyBars::NoPatchableVersionFoundError`
- `MonkeyBars::NoPatchableInstanceMethodFoundError`
- `MonkeyBars::NoPatchableClassMethodFoundError`
- `MonkeyBars::MismatchedInstanceMethodArityError`
- `MonkeyBars::MismatchedClassMethodArityError`
- `MonkeyBars::NewInstanceMethodAlreadyExistsError`
- `MonkeyBars::NewClassMethodAlreadyExistsError`
- `MonkeyBars::PatchConstantNotFoundError`
- `MonkeyBars::NewConstantAlreadyExistsError`
- `MonkeyBars::PatchAlreadyPerformedError`

## Development

```sh
bin/setup
bin/console
bundle exec rspec
```

## License

MIT. See `LICENSE.txt`.

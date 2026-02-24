# frozen_string_literal: true

module MonkeyBars
  class NewInstanceMethodAlreadyExistsError < StandardError
    def initialize(patcher_name, monkey: nil, method: nil)
      super("[#{patcher_name}] The instance method `##{method}` already exists on `#{monkey}` but is marked as new. Perhaps move it to the `patch_instance_methods` block?")
    end
  end

  class NewClassMethodAlreadyExistsError < StandardError
    def initialize(patcher_name, monkey: nil, method: nil)
      super("[#{patcher_name}] The class method `.#{method}` already exists on `#{monkey}` but is marked as new. Perhaps move it to the `patch_class_methods` block?")
    end
  end

  class MismatchedInstanceMethodArityError < StandardError
    def initialize(patcher_name, monkey: nil, method: nil, prepatched_arity: nil, patched_arity: nil)
      super("[#{patcher_name}] The instance method `##{method}` on `#{monkey}` has an arity of #{patched_arity} but a prepatched arity of #{prepatched_arity}. If you want to ignore this error, set `ignore_arity_errors: true`.")
    end
  end

  class MismatchedClassMethodArityError < StandardError
    def initialize(patcher_name, monkey: nil, method: nil, prepatched_arity: nil, patched_arity: nil)
      super("[#{patcher_name}] The class method `.#{method}` on `#{monkey}` has an arity of #{patched_arity} but a prepatched arity of #{prepatched_arity}. If you want to ignore this error, set `ignore_arity_errors: true`.")
    end
  end

  class NewConstantAlreadyExistsError < StandardError
    def initialize(patcher_name, monkey: nil, constant: nil)
      super("[#{patcher_name}] The constant `#{constant}` already exists on `#{monkey}` but is marked as new. Perhaps move it to the `patch_constants` block?")
    end
  end

  class NoPatchableMonkeyFoundError < StandardError
    def initialize(patcher_name, monkey: nil)
      super("[#{patcher_name}] Couldn't find `#{monkey}` to patch.")
    end
  end

  class NoPatchableVersionFoundError < StandardError
    def initialize(patcher_name, monkey: nil, version: nil, current_version: nil)
      super("[#{patcher_name}] Ready to patch `#{monkey}` but found version `#{current_version}` instead of `#{version}`.")
    end
  end

  class NoPatchableVersionCheckError < StandardError
    def initialize(patcher_name, monkey: nil)
      super("[#{patcher_name}] `version_check` block is missing. Without it, there's no way to know if the version of `#{monkey}` is patchable.")
    end
  end

  class NoPatchableClassMethodFoundError < StandardError
    def initialize(patcher_name, monkey: nil, method: nil)
      super("[#{patcher_name}] Couldn't find class method `.#{method}` on `#{monkey}` despite it being marked as preexisting. Perhaps move it to the `new_class_methods` block?")
    end
  end

  class NoPatchableInstanceMethodFoundError < StandardError
    def initialize(patcher_name, monkey: nil, method: nil)
      super("[#{patcher_name}] Couldn't find instance method `##{method}` on `#{monkey}` despite it being marked as patchable. Perhaps move it to the `new_instance_methods` block?")
    end
  end

  class PatchableClassMethodIsNotPrivateError < StandardError
    def initialize(patcher_name, monkey: nil, method: nil)
      super("[#{patcher_name}] The class method `.#{method}` on `#{monkey}` is not private, but is on the patch. Remove it from `private` in your patch.")
    end
  end

  class PatchableClassMethodIsPrivateError < StandardError
    def initialize(patcher_name, monkey: nil, method: nil)
      super("[#{patcher_name}] The class method `.#{method}` on `#{monkey}` is private, but isn't on the patch. Mark it as `private` in your patch.")
    end
  end

  class PatchableClassMethodIsNotProtectedError < StandardError
    def initialize(patcher_name, monkey: nil, method: nil)
      super("[#{patcher_name}] The class method `.#{method}` on `#{monkey}` is not protected, but is on the patch. Remove it from `protected` in your patch.")
    end
  end

  class PatchableClassMethodIsProtectedError < StandardError
    def initialize(patcher_name, monkey: nil, method: nil)
      super("[#{patcher_name}] The class method `.#{method}` on `#{monkey}` is protected, but isn't on the patch. Mark it as `protected` in your patch.")
    end
  end

  class PatchableInstanceMethodIsNotPrivateError < StandardError
    def initialize(patcher_name, monkey: nil, method: nil)
      super("[#{patcher_name}] The instance method `##{method}` on `#{monkey}` is not private, but is on the patch. Remove it from `private` in your patch.")
    end
  end

  class PatchableInstanceMethodIsPrivateError < StandardError
    def initialize(patcher_name, monkey: nil, method: nil)
      super("[#{patcher_name}] The instance method `##{method}` on `#{monkey}` is private, but isn't on the patch. Mark it as `private` in your patch.")
    end
  end

  class PatchableInstanceMethodIsNotProtectedError < StandardError
    def initialize(patcher_name, monkey: nil, method: nil)
      super("[#{patcher_name}] The instance method `##{method}` on `#{monkey}` is not protected, but is on the patch. Remove it from `protected` in your patch.")
    end
  end

  class PatchableInstanceMethodIsProtectedError < StandardError
    def initialize(patcher_name, monkey: nil, method: nil)
      super("[#{patcher_name}] The instance method `##{method}` on `#{monkey}` is protected, but isn't on the patch. Mark it as `protected` in your patch.")
    end
  end

  class PatchAlreadyPerformedError < StandardError
    def initialize(patcher_name)
      super("[#{patcher_name}] `#patch!` has already been called and cannot be called again")
    end
  end

  class PatchConstantNotFoundError < StandardError
    def initialize(patcher_name, monkey: nil, constant: nil)
      super("[#{patcher_name}] Couldn't find constant `#{constant}` on `#{monkey}` despite it being marked as patchable. Perhaps move it to the `new_constants` block?")
    end
  end

  class PrepareForPatchingAlreadyPerformedError < StandardError
    def initialize(patcher_name)
      super("[#{patcher_name}] `#prepare_for_patching` has already been called and cannot be called again")
    end
  end
end

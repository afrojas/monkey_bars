# frozen_string_literal: true

module MonkeyBars
  module Validation
    private

    def ensure_monkey_exists
      found_const = fetch_const_for(@monkey)
      if found_const
        @monkey = found_const
      else
        raise(NoPatchableMonkeyFoundError.new(@monkey_patcher_name, monkey: @monkey))
      end
    end

    def ensure_patchable_version
      unless @version_check_block.respond_to?(:call)
        raise(NoPatchableVersionCheckError.new(@monkey_patcher_name, monkey: @monkey))
      end

      current_version = @version_check_block.call
      if current_version != @version
        raise(NoPatchableVersionFoundError.new(@monkey_patcher_name, monkey: @monkey, version: @version, current_version: current_version))
      end
    end

    def ensure_patch_instance_methods_are_valid
      return unless @patch_instance_methods.any?

      @patch_instance_methods_module = Module.new
      @include_instance_super_super = false
      @patch_instance_methods.each do |preexisting_instance_method|
        module_to_prepend = Module.new
        preexisting_instance_method => {block:, ignore_arity_errors:, include_super_super:}
        module_to_prepend.module_eval(&block)
        module_to_prepend.instance_methods.each do |method_name|
          next if module_to_prepend.protected_instance_methods.include?(method_name)

          if @monkey.protected_method_defined?(method_name)
            raise(PatchableInstanceMethodIsProtectedError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end

          if @monkey.private_method_defined?(method_name)
            raise(PatchableInstanceMethodIsPrivateError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end

          unless @monkey.method_defined?(method_name)
            raise(NoPatchableInstanceMethodFoundError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end

          next if ignore_arity_errors

          prepatched_method = @monkey.instance_method(method_name)
          patched_method = module_to_prepend.instance_method(method_name)
          if prepatched_method.arity != patched_method.arity
            raise(MismatchedInstanceMethodArityError.new(@monkey_patcher_name, monkey: @monkey, method: method_name, prepatched_arity: prepatched_method.arity, patched_arity: patched_method.arity))
          end
        end

        module_to_prepend.protected_instance_methods.each do |method_name|
          if @monkey.private_method_defined?(method_name) || (@monkey.method_defined?(method_name) && !@monkey.protected_method_defined?(method_name))
            raise(PatchableInstanceMethodIsNotProtectedError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end

          unless @monkey.protected_method_defined?(method_name)
            raise(NoPatchableInstanceMethodFoundError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end

          next if ignore_arity_errors

          prepatched_method = @monkey.instance_method(method_name)
          patched_method = module_to_prepend.instance_method(method_name)
          if prepatched_method.arity != patched_method.arity
            raise(MismatchedInstanceMethodArityError.new(@monkey_patcher_name, monkey: @monkey, method: method_name, prepatched_arity: prepatched_method.arity, patched_arity: patched_method.arity))
          end
        end

        module_to_prepend.private_instance_methods.each do |method_name|
          if @monkey.method_defined?(method_name)
            raise(PatchableInstanceMethodIsNotPrivateError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end

          unless @monkey.private_method_defined?(method_name)
            raise(NoPatchableInstanceMethodFoundError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end

          next if ignore_arity_errors

          prepatched_method = @monkey.instance_method(method_name)
          patched_method = module_to_prepend.instance_method(method_name)
          if prepatched_method.arity != patched_method.arity
            raise(MismatchedInstanceMethodArityError.new(@monkey_patcher_name, monkey: @monkey, method: method_name, prepatched_arity: prepatched_method.arity, patched_arity: patched_method.arity))
          end
        end

        # If anyone asks for super_super, include it
        @include_instance_super_super = true if include_super_super
        @patch_instance_methods_module.module_eval(&block)
      end
    end

    def ensure_new_instance_methods_are_valid
      return unless @new_instance_methods.any?

      @new_instance_methods_module = Module.new
      @new_instance_methods.each do |new_instance_methods_block|
        module_to_include = Module.new
        module_to_include.module_eval(&new_instance_methods_block)
        module_to_include.instance_methods.each do |method_name|
          if @monkey.method_defined?(method_name)
            raise(NewInstanceMethodAlreadyExistsError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end
        end

        @new_instance_methods_module.module_eval(&new_instance_methods_block)
      end
    end

    def ensure_patch_class_methods_are_valid
      return unless @patch_class_methods.any?

      @patch_class_methods_module = Module.new
      @include_class_super_super = false
      @patch_class_methods.each do |preexisting_class_method|
        module_to_prepend = Module.new
        preexisting_class_method => {block:, ignore_arity_errors:, include_super_super:}
        module_to_prepend.module_eval(&block)
        module_to_prepend.instance_methods.each do |method_name|
          next if module_to_prepend.protected_instance_methods.include?(method_name)

          if @monkey.singleton_class.protected_method_defined?(method_name)
            raise(PatchableClassMethodIsProtectedError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end

          if @monkey.singleton_class.private_method_defined?(method_name)
            raise(PatchableClassMethodIsPrivateError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end

          unless @monkey.singleton_class.method_defined?(method_name)
            raise(NoPatchableClassMethodFoundError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end

          next if ignore_arity_errors

          prepatched_method = @monkey.singleton_class.instance_method(method_name)
          patched_method = module_to_prepend.instance_method(method_name)
          if prepatched_method.arity != patched_method.arity
            raise(MismatchedClassMethodArityError.new(@monkey_patcher_name, monkey: @monkey, method: method_name, prepatched_arity: prepatched_method.arity, patched_arity: patched_method.arity))
          end
        end

        module_to_prepend.protected_instance_methods.each do |method_name|
          if @monkey.singleton_class.private_method_defined?(method_name) || (@monkey.singleton_class.method_defined?(method_name) && !@monkey.singleton_class.protected_method_defined?(method_name))
            raise(PatchableClassMethodIsNotProtectedError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end

          unless @monkey.singleton_class.protected_method_defined?(method_name)
            raise(NoPatchableClassMethodFoundError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end

          next if ignore_arity_errors

          prepatched_method = @monkey.singleton_class.instance_method(method_name)
          patched_method = module_to_prepend.instance_method(method_name)
          if prepatched_method.arity != patched_method.arity
            raise(MismatchedClassMethodArityError.new(@monkey_patcher_name, monkey: @monkey, method: method_name, prepatched_arity: prepatched_method.arity, patched_arity: patched_method.arity))
          end
        end

        module_to_prepend.private_instance_methods.each do |method_name|
          if @monkey.singleton_class.method_defined?(method_name)
            raise(PatchableClassMethodIsNotPrivateError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end

          unless @monkey.singleton_class.private_method_defined?(method_name)
            raise(NoPatchableClassMethodFoundError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end

          next if ignore_arity_errors

          prepatched_method = @monkey.singleton_class.instance_method(method_name)
          patched_method = module_to_prepend.instance_method(method_name)
          if prepatched_method.arity != patched_method.arity
            raise(MismatchedClassMethodArityError.new(@monkey_patcher_name, monkey: @monkey, method: method_name, prepatched_arity: prepatched_method.arity, patched_arity: patched_method.arity))
          end
        end

        # If anyone asks for super_super, include it
        @include_class_super_super = true if include_super_super
        @patch_class_methods_module.module_eval(&block)
      end
    end

    def ensure_new_class_methods_are_valid
      return unless @new_class_methods.any?

      @new_class_methods_module = Module.new
      @new_class_methods.each do |new_class_methods_block|
        module_to_include = Module.new
        module_to_include.module_eval(&new_class_methods_block)
        module_to_include.instance_methods.each do |method_name|
          if @monkey.singleton_class.method_defined?(method_name)
            raise(NewClassMethodAlreadyExistsError.new(@monkey_patcher_name, monkey: @monkey, method: method_name))
          end
        end

        @new_class_methods_module.module_eval(&new_class_methods_block)
      end
    end

    def ensure_patch_constants_are_valid
      return unless @patch_constants.any?

      @patch_constants_module = Module.new
      @patch_constants.each do |redefined_constant|
        module_to_redefine = Module.new
        module_to_redefine.module_eval(&redefined_constant)
        module_to_redefine.constants(false).each do |const_name|
          unless @monkey.constants(false).include?(const_name)
            raise(PatchConstantNotFoundError.new(@monkey_patcher_name, monkey: @monkey, constant: const_name))
          end
        end

        @patch_constants_module.module_eval(&redefined_constant)
      end
    end

    def ensure_new_constants_are_valid
      return unless @new_constants.any?

      @new_constants_module = Module.new
      @new_constants.each do |new_constant|
        module_to_include = Module.new
        module_to_include.module_eval(&new_constant)
        module_to_include.constants(false).each do |const_name|
          if @monkey.constants(false).include?(const_name)
            raise(NewConstantAlreadyExistsError.new(@monkey_patcher_name, monkey: @monkey, constant: const_name))
          end
        end

        @new_constants_module.module_eval(&new_constant)
      end
    end
  end
end

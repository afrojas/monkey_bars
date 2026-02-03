# frozen_string_literal: true

module MonkeyBars
  module Patch
    private

    def perform_patch
      patch_class_methods_internal
      patch_instance_methods_internal
      patch_constants_internal
      patch_new_constants_internal

      return unless @post_patch_block.respond_to?(:call)
      if @post_patch_block.arity == 0
        @post_patch_block.call
      else
        @post_patch_block.call(@monkey)
      end
    end

    def patch_class_methods_internal
      patch_additional_class_methods
      patch_preexisting_class_methods
    end

    def patch_additional_class_methods
      return unless @new_class_methods_module
      @monkey.extend(@new_class_methods_module)
    end

    def patch_preexisting_class_methods
      return unless @patch_class_methods_module
      @monkey.singleton_class.prepend(@patch_class_methods_module)
      @monkey.singleton_class.prepend(SuperSuper) if @include_class_super_super
    end

    def patch_instance_methods_internal
      patch_additional_instance_methods
      patch_preexisting_instance_methods
    end

    def patch_additional_instance_methods
      return unless @new_instance_methods_module
      @monkey.include(@new_instance_methods_module)
    end

    def patch_preexisting_instance_methods
      return unless @patch_instance_methods_module
      @monkey.prepend(@patch_instance_methods_module)
      @monkey.include(SuperSuper) if @include_instance_super_super
    end

    def patch_constants_internal
      return unless @patch_constants_module
      @patch_constants_module.constants(false).each do |const_name|
        new_value = @patch_constants_module.const_get(const_name)
        @monkey.send(:remove_const, const_name)
        @monkey.const_set(const_name, new_value)
      end
    end

    def patch_new_constants_internal
      return unless @new_constants_module
      @new_constants_module.constants(false).each do |const_name|
        new_value = @new_constants_module.const_get(const_name)
        @monkey.const_set(const_name, new_value)
      end
    end

    def fetch_const_for(module_or_string_or_block)
      return nil if module_or_string_or_block.nil?

      return module_or_string_or_block if module_or_string_or_block.is_a?(Module)

      if module_or_string_or_block.is_a?(String)
        begin
          return Kernel.const_get(module_or_string_or_block)
        rescue NameError
          return nil
        end
      end

      if module_or_string_or_block.respond_to?(:call)
        begin
          module_or_string_or_block.call
        rescue NameError
          nil
        end
      end
    end
  end

  module SuperSuper
    def super_super(*args, **kwargs)
      # Get the calling method name from the caller stack
      # Caller format can be: "file.rb:line:in 'method_name'" or "file.rb:line:in `method_name'"
      caller_line = caller(1..1).first
      calling_method_name = caller_line[/in [`'](.*?)[`']/, 1] || caller_line[/in (.*?)$/, 1]

      raise "Could not determine calling method name from: #{caller_line}" if calling_method_name.nil?

      if is_a?(Class)
        # For class methods (when extended on a class)
        unless superclass.respond_to?(:singleton_method) && superclass.singleton_methods.include?(calling_method_name.to_sym)
          raise NoMethodError, "undefined method `#{calling_method_name}' for class `#{superclass}'"
        end
        superclass.singleton_method(calling_method_name).call(*args, **kwargs)
      else
        # For instance methods
        unless self.class.superclass&.instance_methods&.include?(calling_method_name.to_sym)
          raise(NoMethodError, "undefined method `#{calling_method_name}' for class `#{self.class.superclass}'")
        end
        self.class.superclass.instance_method(calling_method_name).bind_call(self, *args, **kwargs)
      end
    end
  end
end

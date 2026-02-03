# frozen_string_literal: true

require_relative "monkey_bars/version"
require_relative "monkey_bars/errors"
require_relative "monkey_bars/validation"
require_relative "monkey_bars/patch"

module MonkeyBars
  include Validation
  include Patch

  def self.extended(monkey_patcher)
    monkey_patcher.instance_variable_set(:@monkey_patcher_name, monkey_patcher.name)
    monkey_patcher.instance_variable_set(:@patch_class_methods, [])
    monkey_patcher.instance_variable_set(:@new_class_methods, [])
    monkey_patcher.instance_variable_set(:@patch_instance_methods, [])
    monkey_patcher.instance_variable_set(:@new_instance_methods, [])
    monkey_patcher.instance_variable_set(:@patch_constants, [])
    monkey_patcher.instance_variable_set(:@new_constants, [])
  end

  def patch(monkey, version:, version_check:, &block)
    prepare_for_patching(
      monkey,
      version: version,
      version_check: version_check,
      patch_immediately: true,
      &block
    )
  end
  alias_method :🐵, :patch

  def prepare_for_patching(monkey, version:, version_check:, patch_immediately: false, &block)
    @monkey = monkey
    @version = version
    @version_check_block = version_check

    yield if block_given?

    patch! if patch_immediately
  end

  def patch!
    if @patch_performed
      raise(PatchAlreadyPerformedError.new(@monkey_patcher_name))
    end

    if @patch_class_methods.empty? &&
        @new_class_methods.empty? &&
        @patch_instance_methods.empty? &&
        @new_instance_methods.empty? &&
        @patch_constants.empty? &&
        @new_constants.empty?
      warn "[#{self}] No methods or constants defined. Maybe you're not calling `#patch!` last?"
    end

    ensure_monkey_exists
    ensure_patchable_version
    ensure_patch_instance_methods_are_valid
    ensure_new_instance_methods_are_valid
    ensure_patch_class_methods_are_valid
    ensure_new_class_methods_are_valid
    ensure_patch_constants_are_valid
    ensure_new_constants_are_valid

    perform_patch

    @patch_performed = true
  end

  def patch_class_methods(ignore_arity_errors: false, include_super_super: false, &block)
    @patch_class_methods << {
      block: block,
      ignore_arity_errors: ignore_arity_errors,
      include_super_super: include_super_super
    }
  end

  def new_class_methods(&block)
    @new_class_methods << block
  end

  def patch_instance_methods(ignore_arity_errors: false, include_super_super: false, &block)
    @patch_instance_methods << {
      block: block,
      ignore_arity_errors: ignore_arity_errors,
      include_super_super: include_super_super
    }
  end

  def new_instance_methods(&block)
    @new_instance_methods << block
  end

  def patch_constants(&block)
    @patch_constants << block
  end

  def new_constants(&block)
    @new_constants << block
  end

  def post_patch(&block)
    @post_patch_block = block
  end
end

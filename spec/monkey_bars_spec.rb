# frozen_string_literal: true

RSpec.describe MonkeyBars do
  # Helper to create a fresh monkey bars class for each test
  def build_monkey_bars_class
    Class.new { extend MonkeyBars }
  end

  describe "Core Setup and Initialization" do
    it "initializes instance variables when extended" do
      monkey_bars = build_monkey_bars_class

      expect(monkey_bars.instance_variable_get(:@patch_class_methods)).to eq([])
      expect(monkey_bars.instance_variable_get(:@new_class_methods)).to eq([])
      expect(monkey_bars.instance_variable_get(:@patch_instance_methods)).to eq([])
      expect(monkey_bars.instance_variable_get(:@new_instance_methods)).to eq([])
      expect(monkey_bars.instance_variable_get(:@patch_constants)).to eq([])
      expect(monkey_bars.instance_variable_get(:@new_constants)).to eq([])
    end

    it "allows a class to extend MonkeyBars" do
      monkey_bars = build_monkey_bars_class
      expect(monkey_bars).to respond_to(:patch)
      expect(monkey_bars).to respond_to(:prepare_for_patching)
      expect(monkey_bars).to respond_to(:patch!)
    end
  end

  describe "Patch Lifecycle" do
    let(:monkey) do
      Module.new do
        def self.name
          "TestMonkey"
        end

        const_set(:VERSION, "1.0.0")
      end
    end

    describe "#patch" do
      it "performs immediate patch" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.new_instance_methods do
            def new_method
              "added"
            end
          end
        end

        expect(monkey.instance_methods).to include(:new_method)
      end

      it "is aliased as 🐵" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.🐵(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.new_instance_methods do
            def emoji_method
              "banana"
            end
          end
        end

        expect(monkey.instance_methods).to include(:emoji_method)
      end
    end

    describe "#prepare_for_patching and #patch!" do
      it "performs deferred patch" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.new_instance_methods do
            def deferred_method
              "deferred"
            end
          end
        end

        # Method not yet added
        expect(monkey.instance_methods).not_to include(:deferred_method)

        monkey_bars.patch!

        # Now it's added
        expect(monkey.instance_methods).to include(:deferred_method)
      end

      it "raises PatchAlreadyPerformedError when patch! called twice" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.new_instance_methods do
            def some_method
              "test"
            end
          end
        end

        monkey_bars.patch!

        expect { monkey_bars.patch! }.to raise_error(
          MonkeyBars::PatchAlreadyPerformedError,
          /already been called/
        )
      end
    end

    describe "warning for empty patches" do
      it "warns when patch! runs with no methods or constants" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey, version: "1.0.0", version_check: -> { monkey::VERSION })

        expect { monkey_bars.patch! }.to output(/No methods or constants defined.*patch!/).to_stderr
      end

      it "does not warn when patch! has changes to apply" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.new_instance_methods do
            def test_method
              "test"
            end
          end
        end

        expect { monkey_bars.patch! }.not_to output.to_stderr
      end
    end
  end

  describe "Monkey Resolution" do
    describe "direct module reference" do
      it "resolves monkey from direct module" do
        monkey = Module.new do
          const_set(:VERSION, "1.0.0")
        end
        monkey_bars = build_monkey_bars_class

        monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.new_instance_methods do
            def direct_method
              "direct"
            end
          end
        end

        expect(monkey.instance_methods).to include(:direct_method)
      end
    end

    describe "string monkey name" do
      before do
        stub_const("StringResolvedMonkey", Module.new { const_set(:VERSION, "2.0.0") })
      end

      it "resolves monkey from string constant name" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.patch("StringResolvedMonkey", version: "2.0.0", version_check: -> { StringResolvedMonkey::VERSION }) do
          monkey_bars.new_instance_methods do
            def string_method
              "from string"
            end
          end
        end

        expect(StringResolvedMonkey.instance_methods).to include(:string_method)
      end
    end

    describe "lambda/proc monkey" do
      before do
        stub_const("LambdaResolvedMonkey", Module.new { const_set(:VERSION, "3.0.0") })
      end

      it "resolves monkey from lambda" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.patch(-> { LambdaResolvedMonkey }, version: "3.0.0", version_check: -> { LambdaResolvedMonkey::VERSION }) do
          monkey_bars.new_instance_methods do
            def lambda_method
              "from lambda"
            end
          end
        end

        expect(LambdaResolvedMonkey.instance_methods).to include(:lambda_method)
      end
    end

    describe "non-existent monkey" do
      it "raises NoPatchableMonkeyFoundError for non-existent module" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching("NonExistentModule", version: "1.0.0", version_check: -> { "1.0.0" }) do
          monkey_bars.new_instance_methods do
            def ghost_method
              "ghost"
            end
          end
        end

        expect { monkey_bars.patch! }.to raise_error(
          MonkeyBars::NoPatchableMonkeyFoundError,
          /Couldn't find.*NonExistentModule/
        )
      end

      it "raises NoPatchableMonkeyFoundError for lambda returning nil" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(-> {}, version: "1.0.0", version_check: -> { "1.0.0" }) do
          monkey_bars.new_instance_methods do
            def ghost_method
              "ghost"
            end
          end
        end

        expect { monkey_bars.patch! }.to raise_error(MonkeyBars::NoPatchableMonkeyFoundError)
      end
    end
  end

  describe "Version Checking" do
    let(:monkey) do
      Module.new do
        const_set(:VERSION, "1.2.3")

        def self.name
          "VersionedMonkey"
        end
      end
    end

    it "succeeds when versions match" do
      monkey_bars = build_monkey_bars_class

      expect {
        monkey_bars.patch(monkey, version: "1.2.3", version_check: -> { monkey::VERSION }) do
          monkey_bars.new_instance_methods do
            def version_method
              "matched"
            end
          end
        end
      }.not_to raise_error

      expect(monkey.instance_methods).to include(:version_method)
    end

    it "raises NoPatchableVersionFoundError when versions mismatch" do
      monkey_bars = build_monkey_bars_class

      monkey_bars.prepare_for_patching(monkey, version: "2.0.0", version_check: -> { monkey::VERSION }) do
        monkey_bars.new_instance_methods do
          def mismatch_method
            "mismatch"
          end
        end
      end

      expect { monkey_bars.patch! }.to raise_error(
        MonkeyBars::NoPatchableVersionFoundError,
        /Ready to patch.*but found version `1.2.3` instead of `2.0.0`/
      )
    end

    it "raises NoPatchableVersionCheckError when version_check is not callable" do
      monkey_bars = build_monkey_bars_class

      monkey_bars.prepare_for_patching(monkey, version: "1.2.3", version_check: nil) do
        monkey_bars.new_instance_methods do
          def no_check_method
            "no check"
          end
        end
      end

      expect { monkey_bars.patch! }.to raise_error(
        MonkeyBars::NoPatchableVersionCheckError,
        /block is missing/
      )
    end
  end

  describe "Instance Methods" do
    describe "#new_instance_methods" do
      let(:monkey) do
        Module.new do
          const_set(:VERSION, "1.0.0")

          def self.name
            "InstanceMonkey"
          end
        end
      end

      it "adds new instance methods to the monkey" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.new_instance_methods do
            def added_method
              "added"
            end

            def another_added
              "another"
            end
          end
        end

        mod = monkey
        test_class = Class.new { include mod }
        instance = test_class.new

        expect(instance.added_method).to eq("added")
        expect(instance.another_added).to eq("another")
      end

      it "raises NewInstanceMethodAlreadyExistsError when method already exists" do
        monkey_with_method = Module.new do
          const_set(:VERSION, "1.0.0")

          def self.name
            "MonkeyWithMethod"
          end

          def existing_method
            "original"
          end
        end

        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey_with_method, version: "1.0.0", version_check: -> { monkey_with_method::VERSION }) do
          monkey_bars.new_instance_methods do
            def existing_method
              "conflict"
            end
          end
        end

        expect { monkey_bars.patch! }.to raise_error(
          MonkeyBars::NewInstanceMethodAlreadyExistsError,
          /existing_method.*already exists/
        )
      end
    end

    describe "#patch_instance_methods" do
      let(:monkey) do
        Module.new do
          const_set(:VERSION, "1.0.0")

          def self.name
            "PreexistingMonkey"
          end

          def original_method
            "original"
          end

          def method_with_args(a, b)
            a + b
          end

          private

          def private_method_with_args(a, b)
            "private #{a + b}"
          end
        end
      end

      it "overrides existing instance methods" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_instance_methods do
            def original_method
              "overridden"
            end
          end
        end

        mod = monkey
        test_class = Class.new { include mod }
        instance = test_class.new

        expect(instance.original_method).to eq("overridden")
      end

      it "allows calling super to invoke original method" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_instance_methods do
            def original_method
              super + " + modified"
            end
          end
        end

        mod = monkey
        test_class = Class.new { include mod }
        instance = test_class.new

        expect(instance.original_method).to eq("original + modified")
      end

      it "raises NoPatchableInstanceMethodFoundError when method doesn't exist" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_instance_methods do
            def ghost_method
              "ghost"
            end
          end
        end

        expect { monkey_bars.patch! }.to raise_error(
          MonkeyBars::NoPatchableInstanceMethodFoundError,
          /Couldn't find instance method `#ghost_method`/
        )
      end

      it "raises MismatchedInstanceMethodArityError when arities differ" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_instance_methods do
            def method_with_args(a, b, c)
              a + b + c
            end
          end
        end

        expect { monkey_bars.patch! }.to raise_error(
          MonkeyBars::MismatchedInstanceMethodArityError,
          /arity/
        )
      end

      it "bypasses arity check with ignore_arity_errors: true" do
        monkey_bars = build_monkey_bars_class

        expect {
          monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
            monkey_bars.patch_instance_methods(ignore_arity_errors: true) do
              def method_with_args(*args)
                args.sum
              end
            end
          end
        }.not_to raise_error

        mod = monkey
        test_class = Class.new { include mod }
        instance = test_class.new

        expect(instance.method_with_args(1, 2, 3)).to eq(6)
      end

      it "raises PatchableInstanceMethodIsPrivateError when private method is patched as public" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_instance_methods do
            def private_method_with_args(a, b)
              "patched private #{a + b}"
            end
          end
        end

        expect { monkey_bars.patch! }.to raise_error(
          MonkeyBars::PatchableInstanceMethodIsPrivateError,
          /private_method_with_args/
        )
      end

      it "raises PatchableInstanceMethodIsNotPrivateError when public method is patched as private" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_instance_methods do
            def method_with_args(a, b)
              "patched public #{a + b}"
            end

            private :method_with_args
          end
        end

        expect { monkey_bars.patch! }.to raise_error(
          MonkeyBars::PatchableInstanceMethodIsNotPrivateError,
          /method_with_args/
        )
      end

      it "successfully patches private instance methods when visibility matches" do
        monkey_bars = build_monkey_bars_class

        expect {
          monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
            monkey_bars.patch_instance_methods do
              def private_method_with_args(a, b)
                "patched private #{a + b}"
              end

              private :private_method_with_args
            end
          end
        }.not_to raise_error

        mod = monkey
        test_class = Class.new { include mod }
        instance = test_class.new

        expect { instance.private_method_with_args(1, 2) }.to raise_error(NoMethodError)
        expect(instance.send(:private_method_with_args, 1, 2)).to eq("patched private 3")
      end
    end
  end

  describe "Class Methods" do
    describe "#new_class_methods" do
      let(:monkey) do
        Module.new do
          const_set(:VERSION, "1.0.0")

          def self.name
            "ClassMethodMonkey"
          end
        end
      end

      it "adds new class methods to the monkey" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.new_class_methods do
            def new_class_method
              "new class method"
            end
          end
        end

        expect(monkey.new_class_method).to eq("new class method")
      end

      it "raises NewClassMethodAlreadyExistsError when class method already exists" do
        monkey_with_class_method = Module.new do
          const_set(:VERSION, "1.0.0")

          def self.name
            "MonkeyWithClassMethod"
          end

          def self.existing_class_method
            "original"
          end
        end

        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey_with_class_method, version: "1.0.0", version_check: -> { monkey_with_class_method::VERSION }) do
          monkey_bars.new_class_methods do
            def existing_class_method
              "conflict"
            end
          end
        end

        expect { monkey_bars.patch! }.to raise_error(
          MonkeyBars::NewClassMethodAlreadyExistsError,
          /existing_class_method.*already exists/
        )
      end
    end

    describe "#patch_class_methods" do
      let(:monkey) do
        Module.new do
          const_set(:VERSION, "1.0.0")

          def self.name
            "PreexistingClassMethodMonkey"
          end

          def self.original_class_method
            "original"
          end

          def self.class_method_with_args(a, b)
            a + b
          end

          class << self
            private

            def private_class_method_with_args(a, b)
              "private class #{a + b}"
            end
          end
        end
      end

      it "overrides existing class methods" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_class_methods do
            def original_class_method
              "overridden"
            end
          end
        end

        expect(monkey.original_class_method).to eq("overridden")
      end

      it "allows calling super to invoke original class method" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_class_methods do
            def original_class_method
              super + " + modified"
            end
          end
        end

        expect(monkey.original_class_method).to eq("original + modified")
      end

      it "raises NoPatchableClassMethodFoundError when class method doesn't exist" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_class_methods do
            def ghost_class_method
              "ghost"
            end
          end
        end

        expect { monkey_bars.patch! }.to raise_error(
          MonkeyBars::NoPatchableClassMethodFoundError,
          /Couldn't find class method `.ghost_class_method`/
        )
      end

      it "raises MismatchedClassMethodArityError when arities differ" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_class_methods do
            def class_method_with_args(a, b, c)
              a + b + c
            end
          end
        end

        expect { monkey_bars.patch! }.to raise_error(
          MonkeyBars::MismatchedClassMethodArityError,
          /arity/
        )
      end

      it "bypasses arity check with ignore_arity_errors: true" do
        monkey_bars = build_monkey_bars_class

        expect {
          monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
            monkey_bars.patch_class_methods(ignore_arity_errors: true) do
              def class_method_with_args(*args)
                args.sum
              end
            end
          end
        }.not_to raise_error

        expect(monkey.class_method_with_args(1, 2, 3)).to eq(6)
      end

      it "raises PatchableClassMethodIsPrivateError when private class method is patched as public" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_class_methods do
            def private_class_method_with_args(a, b)
              "patched private class #{a + b}"
            end
          end
        end

        expect { monkey_bars.patch! }.to raise_error(
          MonkeyBars::PatchableClassMethodIsPrivateError,
          /private_class_method_with_args/
        )
      end

      it "raises PatchableClassMethodIsNotPrivateError when public class method is patched as private" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_class_methods do
            def class_method_with_args(a, b)
              "patched public class #{a + b}"
            end

            private :class_method_with_args
          end
        end

        expect { monkey_bars.patch! }.to raise_error(
          MonkeyBars::PatchableClassMethodIsNotPrivateError,
          /class_method_with_args/
        )
      end

      it "successfully patches private class methods when visibility matches" do
        monkey_bars = build_monkey_bars_class

        expect {
          monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
            monkey_bars.patch_class_methods do
              def private_class_method_with_args(a, b)
                "patched private class #{a + b}"
              end

              private :private_class_method_with_args
            end
          end
        }.not_to raise_error

        expect { monkey.private_class_method_with_args(1, 2) }.to raise_error(NoMethodError)
        expect(monkey.send(:private_class_method_with_args, 1, 2)).to eq("patched private class 3")
      end
    end
  end

  describe "Constants" do
    describe "#patch_constants" do
      let(:monkey) do
        Module.new do
          const_set(:VERSION, "1.0.0")
          const_set(:MAX_RETRIES, 3)
          const_set(:TIMEOUT, 30)

          def self.name
            "ConstantMonkey"
          end
        end
      end

      it "redefines existing constants" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_constants do
            const_set(:MAX_RETRIES, 5)
            const_set(:TIMEOUT, 60)
          end
        end

        expect(monkey::MAX_RETRIES).to eq(5)
        expect(monkey::TIMEOUT).to eq(60)
      end

      it "raises RedefinedConstantNotFoundError when constant doesn't exist" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_constants do
            const_set(:NONEXISTENT_CONST, "value")
          end
        end

        expect { monkey_bars.patch! }.to raise_error(
          MonkeyBars::PatchConstantNotFoundError,
          /Couldn't find constant `NONEXISTENT_CONST`/
        )
      end
    end

    describe "#new_constants" do
      let(:monkey) do
        Module.new do
          const_set(:VERSION, "1.0.0")

          def self.name
            "NewConstantMonkey"
          end
        end
      end

      it "adds new constants to the monkey" do
        monkey_bars = build_monkey_bars_class

        monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.new_constants do
            const_set(:NEW_CONST, "new value")
            const_set(:ANOTHER_CONST, 42)
          end
        end

        expect(monkey::NEW_CONST).to eq("new value")
        expect(monkey::ANOTHER_CONST).to eq(42)
      end

      it "raises NewConstantAlreadyExistsError when constant already exists" do
        monkey_with_const = Module.new do
          const_set(:VERSION, "1.0.0")
          const_set(:EXISTING_CONST, "original")

          def self.name
            "MonkeyWithConst"
          end
        end

        monkey_bars = build_monkey_bars_class

        monkey_bars.prepare_for_patching(monkey_with_const, version: "1.0.0", version_check: -> { monkey_with_const::VERSION }) do
          monkey_bars.new_constants do
            const_set(:EXISTING_CONST, "conflict")
          end
        end

        expect { monkey_bars.patch! }.to raise_error(
          MonkeyBars::NewConstantAlreadyExistsError,
          /EXISTING_CONST.*already exists/
        )
      end
    end
  end

  describe "Post-Patch Callback" do
    let(:monkey) do
      Module.new do
        const_set(:VERSION, "1.0.0")

        def self.name
          "PostOpMonkey"
        end
      end
    end

    it "calls post_patch block with no arguments" do
      monkey_bars = build_monkey_bars_class
      callback_called = false

      monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
        monkey_bars.new_instance_methods do
          def test_method
            "test"
          end
        end

        monkey_bars.post_patch do
          callback_called = true
        end
      end

      expect(callback_called).to be true
    end

    it "calls post_patch block with monkey argument" do
      monkey_bars = build_monkey_bars_class
      received_monkey = nil

      monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
        monkey_bars.new_instance_methods do
          def test_method
            "test"
          end
        end

        monkey_bars.post_patch do |pat|
          received_monkey = pat
        end
      end

      expect(received_monkey).to eq(monkey)
    end
  end

  describe "SuperSuper Module" do
    describe "instance methods" do
      it "calls superclass implementation with super_super" do
        # super_super for instance methods uses self.class.superclass
        # So we need proper class inheritance
        grandparent = Class.new do
          def compute(x)
            x * 2
          end
        end

        monkey = Class.new(grandparent) do
          const_set(:VERSION, "1.0.0")

          def self.name
            "SuperSuperMonkey"
          end

          def compute(x)
            x + 100
          end
        end

        monkey_bars = build_monkey_bars_class

        monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_instance_methods(include_super_super: true) do
            def compute(x)
              # super_super calls self.class.superclass's method (grandparent)
              super_super(x)
            end
          end
        end

        instance = monkey.new
        # The prepended module's compute calls super_super, which goes to grandparent (x * 2)
        expect(instance.compute(5)).to eq(10)
      end

      it "raises NoMethodError when superclass method doesn't exist" do
        monkey = Class.new do
          const_set(:VERSION, "1.0.0")

          def self.name
            "NoSuperMonkey"
          end

          def unique_method
            "monkey only"
          end
        end

        monkey_bars = build_monkey_bars_class

        monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_instance_methods(include_super_super: true) do
            def unique_method
              super_super
            end
          end
        end

        instance = monkey.new
        # Object (superclass) doesn't have unique_method
        expect { instance.unique_method }.to raise_error(NoMethodError)
      end
    end

    describe "class methods" do
      it "calls superclass class method implementation with super_super" do
        # super_super for class methods calls superclass.singleton_method(name)
        grandparent = Class.new do
          def self.compute(x)
            x * 3
          end
        end

        monkey = Class.new(grandparent) do
          const_set(:VERSION, "1.0.0")

          def self.name
            "SuperSuperClassMonkey"
          end

          def self.compute(x)
            x + 200
          end
        end

        monkey_bars = build_monkey_bars_class

        monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_class_methods(include_super_super: true) do
            def compute(x)
              # super_super goes to superclass (grandparent) which has compute
              super_super(x)
            end
          end
        end

        # Calls grandparent's compute (x * 3)
        expect(monkey.compute(5)).to eq(15)
      end

      it "raises NoMethodError when superclass class method doesn't exist" do
        monkey = Class.new do
          const_set(:VERSION, "1.0.0")

          def self.name
            "NoSuperClassMethodMonkey"
          end

          def self.unique_class_method
            "monkey only"
          end
        end

        monkey_bars = build_monkey_bars_class

        monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
          monkey_bars.patch_class_methods(include_super_super: true) do
            def unique_class_method
              super_super
            end
          end
        end

        # Object (superclass) doesn't have unique_class_method as singleton method
        expect { monkey.unique_class_method }.to raise_error(NoMethodError)
      end
    end
  end

  describe "Multiple Blocks" do
    let(:monkey) do
      Module.new do
        const_set(:VERSION, "1.0.0")
        const_set(:CONST_A, "a")
        const_set(:CONST_B, "b")

        def self.name
          "MultiBlockMonkey"
        end

        def existing_a
          "a"
        end

        def existing_b
          "b"
        end

        def self.class_existing_a
          "class a"
        end

        def self.class_existing_b
          "class b"
        end
      end
    end

    it "applies multiple patch_instance_methods blocks" do
      monkey_bars = build_monkey_bars_class

      monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
        monkey_bars.patch_instance_methods do
          def existing_a
            super + " modified"
          end
        end

        monkey_bars.patch_instance_methods do
          def existing_b
            super + " also modified"
          end
        end
      end

      mod = monkey
      test_class = Class.new { include mod }
      instance = test_class.new

      expect(instance.existing_a).to eq("a modified")
      expect(instance.existing_b).to eq("b also modified")
    end

    it "applies multiple new_instance_methods blocks" do
      monkey_bars = build_monkey_bars_class

      monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
        monkey_bars.new_instance_methods do
          def new_a
            "new a"
          end
        end

        monkey_bars.new_instance_methods do
          def new_b
            "new b"
          end
        end
      end

      mod = monkey
      test_class = Class.new { include mod }
      instance = test_class.new

      expect(instance.new_a).to eq("new a")
      expect(instance.new_b).to eq("new b")
    end

    it "applies multiple patch_class_methods blocks" do
      monkey_bars = build_monkey_bars_class

      monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
        monkey_bars.patch_class_methods do
          def class_existing_a
            super + " modified"
          end
        end

        monkey_bars.patch_class_methods do
          def class_existing_b
            super + " also modified"
          end
        end
      end

      expect(monkey.class_existing_a).to eq("class a modified")
      expect(monkey.class_existing_b).to eq("class b also modified")
    end

    it "applies multiple new_class_methods blocks" do
      monkey_bars = build_monkey_bars_class

      monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
        monkey_bars.new_class_methods do
          def new_class_a
            "new class a"
          end
        end

        monkey_bars.new_class_methods do
          def new_class_b
            "new class b"
          end
        end
      end

      expect(monkey.new_class_a).to eq("new class a")
      expect(monkey.new_class_b).to eq("new class b")
    end

    it "applies multiple patch_constants blocks" do
      monkey_bars = build_monkey_bars_class

      monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
        monkey_bars.patch_constants do
          const_set(:CONST_A, "modified a")
        end

        monkey_bars.patch_constants do
          const_set(:CONST_B, "modified b")
        end
      end

      expect(monkey::CONST_A).to eq("modified a")
      expect(monkey::CONST_B).to eq("modified b")
    end

    it "applies multiple new_constants blocks" do
      monkey_bars = build_monkey_bars_class

      monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
        monkey_bars.new_constants do
          const_set(:NEW_CONST_A, "new a")
        end

        monkey_bars.new_constants do
          const_set(:NEW_CONST_B, "new b")
        end
      end

      expect(monkey::NEW_CONST_A).to eq("new a")
      expect(monkey::NEW_CONST_B).to eq("new b")
    end
  end

  describe "Integration Tests" do
    it "combines all features in one patch" do
      monkey = Module.new do
        const_set(:VERSION, "1.0.0")
        const_set(:TIMEOUT, 30)

        def self.name
          "IntegrationMonkey"
        end

        def self.class_method
          "original class"
        end

        def instance_method
          "original instance"
        end
      end

      monkey_bars = build_monkey_bars_class
      post_patch_called = false

      monkey_bars.patch(monkey, version: "1.0.0", version_check: -> { monkey::VERSION }) do
        monkey_bars.new_class_methods do
          def new_class_method
            "new class"
          end
        end

        monkey_bars.patch_class_methods do
          def class_method
            super + " + modified"
          end
        end

        monkey_bars.new_instance_methods do
          def new_instance_method
            "new instance"
          end
        end

        monkey_bars.patch_instance_methods do
          def instance_method
            super + " + modified"
          end
        end

        monkey_bars.patch_constants do
          const_set(:TIMEOUT, 60)
        end

        monkey_bars.new_constants do
          const_set(:MAX_RETRIES, 5)
        end

        monkey_bars.post_patch do |pat|
          post_patch_called = pat == monkey
        end
      end

      # Verify class methods
      expect(monkey.new_class_method).to eq("new class")
      expect(monkey.class_method).to eq("original class + modified")

      # Verify instance methods
      mod = monkey
      test_class = Class.new { include mod }
      instance = test_class.new
      expect(instance.new_instance_method).to eq("new instance")
      expect(instance.instance_method).to eq("original instance + modified")

      # Verify constants
      expect(monkey::TIMEOUT).to eq(60)
      expect(monkey::MAX_RETRIES).to eq(5)

      # Verify post_patch
      expect(post_patch_called).to be true
    end
  end
end

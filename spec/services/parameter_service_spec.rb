require "spec_helper"

RSpec.describe ParameterService, type: :service do
  describe ".invalid_parameters" do
    let(:schema) { ParameterService::SCIM_CORE_USER_SCHEMA }
    let(:good_params) do
      {
        "userName" => "Diana",
      }
    end

    it "returns empty array for no issues" do
      result = subject.invalid_parameters(schema, good_params)
      expect(result).to be_a Array
      expect(result).to be_empty
    end

    it "nested hash" do
      params = good_params.merge(
        "name" => {
          "givenName" => "Diana",
        }
      )

      result = subject.invalid_parameters(schema, params)
      expect(result).to be_a Array
      expect(result).to be_empty
    end

    it "multi-value" do
      params = good_params.merge(
        "emails" => %w[one two]
      )

      result = subject.invalid_parameters(schema, params)
      expect(result).to be_empty
    end

    context "ignores" do
      it "ieft metadata keys" do
        params = good_params.merge({
          "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User" => { "a" => "b" },
          "urn:ietf:params:scim:schemas:core:2.0:User" => { "c" => "d" },
          "urn:ietf:params:scim:foo" => { "bar" => "baz" },
          "Operations" => [],
        })

        result = subject.invalid_parameters(schema, params)
        expect(result).to be_empty
      end

      context "rails" do
        %w[action controller].each do |rails_param|
          it "ignores - #{rails_param}" do
            params = good_params.merge({ rails_param => 1234 })

            result = subject.invalid_parameters(schema, params)
            expect(result).to be_empty
          end
        end
      end
    end

    context "invalid" do
      context "data type" do
        it "schema=Hash, param=String" do
          params = good_params.merge("name" => "Diana")

          result = subject.invalid_parameters(schema, params)
          expect(result).to eq ["name"]
        end

        it "schema=String, param=Hash" do
          params = good_params.merge("userName" => { "foo_baz" => "bar" })

          result = subject.invalid_parameters(schema, params)
          expect(result).to eq ["userName"]
        end
      end

      it "top level parameter" do
        params = good_params.merge("foo_baz" => "bar")

        result = subject.invalid_parameters(schema, params)
        expect(result).to eq ["foo_baz"]
      end

      context "nested" do
        context "array" do
          it "top-level" do
            params = good_params.merge(
              "name" => %w[one two]
            )

            result = subject.invalid_parameters(schema, params)
            expect(result).to eq ["name"]
          end

          it "nested hash" do
            params = good_params.merge(
              "name" => {
                "givenName" => %w[one two]
              }
            )

            result = subject.invalid_parameters(schema, params)
            expect(result).to eq ["name.givenName"]
          end
        end

        context "hash" do
          it "does not ignore rails" do
            params = good_params.merge(
              "name" => {
                "givenName" => "your",
                "action" => "bar",      # Invalid in nested context
              }
            )

            result = subject.invalid_parameters(schema, params)
            expect(result).to eq ["name.action"]
          end

          it "with valid top-level" do
            params = good_params.merge(
              "name" => {
                "givenName" => "your",
                "foo_baz" => "bar",
              }
            )

            result = subject.invalid_parameters(schema, params)
            expect(result).to eq ["name.foo_baz"]
          end
        end
      end
    end
  end
end


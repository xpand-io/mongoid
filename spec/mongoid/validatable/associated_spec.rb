# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::Validatable::AssociatedValidator do

  describe "#valid?" do

    context "when validating associated on both sides" do

      context "when the documents are valid" do

        let(:user) do
          User.new(name: "test")
        end

        let(:description) do
          Description.new(details: "testing")
        end

        before do
          user.descriptions << description
        end

        it "only validates the parent once" do
          expect(user).to be_valid
        end

        it "only validates the child once" do
          expect(description).to be_valid
        end
      end

      context "when the documents are not valid" do

        let(:user) do
          User.new(name: "test")
        end

        let(:description1) do
          Description.new
        end

        let(:description2) do
          Description.new
        end

        before do
          user.descriptions << description1
          user.descriptions << description2
          user.valid?
        end

        it "only validates the parent once" do
          expect(user).to_not be_valid
        end

        it "adds the errors from the relation" do
          expect(user.errors[:descriptions]).to_not be_nil
        end

        it 'reports all failed validations' do
          errors = user.descriptions.flat_map { |d| d.errors[:details] }
          expect(errors.length).to be == 2
        end

        it "only validates the child once" do
          expect(description1).to_not be_valid
        end
      end

      context "when the documents are flagged for destroy" do

        let(:user) do
          User.new(name: "test")
        end

        let(:description) do
          Description.new
        end

        before do
          description.flagged_for_destroy = true
          user.descriptions << description
        end

        it "does not run validation on them" do
          expect(user).to be_valid
        end

      end

      context 'when grandchild documents are not valid' do
        let(:user) do
          User.new(name: "test")
        end

        context 'when replicating MONGOID-5905' do
          context 'when assigning directly to the association' do
            let(:xpand_module) { Xpand::Module.new(title: "Module 1") }
            let(:xpand_task)   { Xpand::Task.new }

            before do
              xpand_module.xpand_tasks << xpand_task
              user.xpand_modules << xpand_module

              user.valid?
            end

            it "validates the grandchild documents" do
              expect(user).to_not be_valid
            end

            it "adds the errors from the child relation" do
              expect(user.errors[:xpand_modules]).to_not be_nil
            end

            it 'reports all failed validations' do
              errors = user.xpand_modules.flat_map { |m| m.xpand_tasks.flat_map { |t| t.errors[:title] } }
              expect(errors.length).to be == 1
            end
          end

          context 'when creating a valid child and invalid grandchild using nested attributes' do
            it 'raises an error' do
              expect do
                user.update!(
                  xpand_modules_attributes: [
                    {
                      title: "Module 1",
                      xpand_tasks_attributes: [
                        {
                          title: ""
                        }
                      ]
                    }
                  ]
                )
              end.to raise_error(Mongoid::Errors::Validations, /The following errors were found: Xpand modules is invalid/)
            end
          end

          context 'when creating updating a valid child with an invalid grandchild using nested attributes' do
            let(:xpand_module) { Xpand::Module.create(title: "Module 1", user: user) }

            it 'raises an error' do
              expect do
                user.update!(
                  xpand_modules_attributes: [
                    {
                      _id: xpand_module.id,
                      xpand_tasks_attributes: [
                        {
                          title: ""
                        }
                      ]
                    }
                  ]
                )
              end.to raise_error(Mongoid::Errors::Validations, /The following errors were found: Xpand modules is invalid/)
            end
          end
        end
      end
    end
  end

  describe "#validate" do

    let(:person) do
      Person.new
    end

    let(:validator) do
      described_class.new(attributes: person.relations.keys)
    end

    context "when the association is a one to one" do

      context "when the association is nil" do

        before do
          validator.validate(person)
        end

        it "adds no errors" do
          expect(person.errors[:name]).to be_empty
        end
      end

      context "when the association is valid" do
        before do
          person.name = Name.new(first_name: 'A', last_name: 'B')
          validator.validate(person)
        end

        it "adds no errors" do
          expect(person.errors[:name]).to be_empty
        end
      end

      context "when the association is invalid" do

        before do
          person.name = Name.new(first_name: 'Jamis', last_name: 'Buck')
          validator.validate(person)
        end

        it "adds errors to the parent document" do
          expect(person.errors[:name]).to_not be_empty
        end

        it "translates the error in english" do
          expect(person.errors[:name][0]).to eq("is invalid")
        end
      end
    end

    context "when the association is a one to many" do

      context "when the association is empty" do

        before do
          validator.validate(person)
        end

        it "adds no errors" do
          expect(person.errors[:addresses]).to be_empty
        end
      end

      context "when the association has invalid documents" do

        before do
          person.addresses << Address.new(street: '123')
          validator.validate(person)
        end

        it "adds errors to the parent document" do
          expect(person.errors[:addresses]).to_not be_empty
        end
      end

      context "when the association has all valid documents" do

        before do
          person.addresses << Address.new(street: '123 First St')
          person.addresses << Address.new(street: '456 Second St')
          validator.validate(person)
        end

        it "adds no errors" do
          expect(person.errors[:addresses]).to be_empty
        end
      end
    end
  end

  context "when describing validation on the instance level" do

    let!(:dictionary) do
      Dictionary.create!(name: "en")
    end

    let(:validators) do
      dictionary.validates_associated :words
    end

    it "adds the validation only to the instance" do
      expect(validators).to eq([ described_class ])
    end
  end
end

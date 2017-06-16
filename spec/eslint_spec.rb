require File.expand_path('../spec_helper', __FILE__)

module Danger
  describe Danger::DangerEslint do
    it 'should be a plugin' do
      expect(Danger::DangerEslint.new(nil)).to be_a Danger::Plugin
    end

    #
    # You should test your custom attributes and methods here
    #
    describe 'with Dangerfile' do
      before do
        @dangerfile = testing_dangerfile
        @eslint = @dangerfile.eslint
        allow(@eslint.git).to receive(:deleted_files).and_return([])
        allow(@eslint.git).to receive(:added_files).and_return([])
        allow(@eslint.git).to receive(:modified_files).and_return([])
        allow(@eslint).to receive(:eslint_path).and_return('eslint')
      end

      it 'does not make an empty message' do
        allow(@eslint).to receive(:lint).and_return('[]')
        expect(@eslint.status_report[:errors].first).to be_nil
        expect(@eslint.status_report[:warnings].first).to be_nil
      end

      describe :lint do
        before do
          @error_result = JSON.parse(File.read('spec/fixtures/results/error.json'))
          @warning_result = JSON.parse(File.read('spec/fixtures/results/warning.json'))
          @alter_warning_result = JSON.parse(File.read('spec/fixtures/results/alter_warning.json'))
          @empty_result = JSON.parse(File.read('spec/fixtures/results/empty.json'))
          @ignored_result = JSON.parse(File.read('spec/fixtures/results/ignored.json'))
          @alter_ignored_result = JSON.parse(File.read('spec/fixtures/results/alter_ignored.json'))

          allow(@eslint.git).to receive(:added_files).and_return([])
          allow(@eslint.git).to receive(:modified_files).and_return([])

          allow(@eslint).to receive(:run_lint)
            .with(anything, /error.js/).and_return(@error_result)
          allow(@eslint).to receive(:run_lint)
            .with(anything, /warning.js/).and_return(@warning_result)
          allow(@eslint).to receive(:run_lint)
            .with(anything, /empty.js/).and_return(@empty_result)
          allow(@eslint).to receive(:run_lint)
            .with(anything, /ignored.js/).and_return(@ignored_result)
        end

        it 'lint all js files when filtering disabled' do
          @eslint.lint
          error = @eslint.status_report[:errors].first
          warn = @eslint.status_report[:warnings].first
          expect(error).to eq('Parsing error: Unexpected token ;')
          expect(warn).to eq("'a' is assigned a value but never used.")
        end

        it 'lint only changed files when filtering enabled' do
          allow(@eslint.git).to receive(:modified_files)
            .and_return(['spec/fixtures/javascript/error.js'])

          @eslint.filtering = true
          @eslint.lint
          error = @eslint.status_report[:errors].first
          expect(error).to eq('Parsing error: Unexpected token ;')
          expect(@eslint.status_report[:warnings].length).to be(0)
        end

        it 'accept config file' do
          allow(@eslint).to receive(:run_lint)
            .with(anything, /warning.js/).and_return(@alter_warning_result)

          @eslint.config_file = 'spec/fixtures/config/.eslintrc.json'
          @eslint.lint
          expect(@eslint.status_report[:errors].length).to be(2)
        end

        it 'accept ignore file' do
          allow(@eslint).to receive(:run_lint)
            .with(anything, /ignored.js/).and_return(@alter_ignored_result)

          @eslint.ignore_file = 'spec/fixtures/config/.eslintignore'
          @eslint.lint
          expect(@eslint.status_report[:warnings].length).to be(2)
        end
      end
    end
  end
end

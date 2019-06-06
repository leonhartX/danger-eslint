require 'mkmf'
require 'json'

module Danger
  # Lint javascript files using [eslint](http://eslint.org/).
  # Results are send as inline commen.
  #
  # @example Run eslint with changed files only
  #
  #          eslint.filtering = true
  #          eslint.lint
  #
  # @see  leonhartX/danger-eslint
  # @tags lint, javaxctipt
  class DangerEslint < Plugin
    # An path to eslint's config file
    # @return [String]
    attr_accessor :config_file

    # An path to eslint's ignore file
    # @return [String]
    attr_accessor :ignore_file

    # Enable filtering
    # Only show messages within changed files.
    # @return [Boolean]
    attr_accessor :filtering

    # Specified extentions of target file
    # Default is [".js"]
    # @return [Array]
    attr_writer :target_extensions
    def target_extensions
      @target_extensions ||= %W(.js)
    end

    # Lints javascript files.
    # Generates `errors` and `warnings` due to eslint's config.
    # Will try to send inline comment if supported(Github)
    #
    # @return  [void]
    #
    def lint
      lint_results
        .reject { |r| r.nil? || r['messages'].length.zero? }
        .reject { |r| r['messages'].first['message'].include? 'matching ignore pattern' }
        .map { |r| send_comment r }
    end

    private

    # Get eslint' bin path
    #
    # return [String]
    def eslint_path
      local = './node_modules/.bin/eslint'
      File.exist?(local) ? local : find_executable('eslint')
    end

    # Get lint result regards the filtering option
    #
    # return [Hash]
    def lint_results
      bin = eslint_path
      raise 'eslint is not installed' unless bin
      return run_lint(bin, '.') unless filtering
      ((git.modified_files - git.deleted_files) + git.added_files)
        .select { |f| target_extensions.include?(File.extname(f)) }
        .map { |f| f.gsub("#{Dir.pwd}/", '') }
        .map { |f| run_lint(bin, f).first }
    end

    # Run eslint aginst a single file.
    #
    # @param   [String] bin
    #          The binary path of eslint
    #
    # @param   [String] file
    #          File to be linted
    #
    # return [Hash]
    def run_lint(bin, file)
      command = "#{bin} -f json"
      command << " -c #{config_file}" if config_file
      command << " --ignore-path #{ignore_file}" if ignore_file
      result = `#{command} #{file}`
      JSON.parse(result)
    end

    # Send comment with danger's warn or fail method.
    #
    # @return [void]
    def send_comment(results)
      dir = "#{Dir.pwd}/"
      results['messages'].each do |r|
        filename = results['filePath'].gsub(dir, '')
        method = r['severity'] > 1 ? 'fail' : 'warn'
        send(method, r['message'], file: filename, line: r['line'])
      end
    end
  end
end

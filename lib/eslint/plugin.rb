require 'mkmf'

module Danger
  # This is your plugin class. Any attributes or methods you expose here will
  # be available from within your Dangerfile.
  #
  # To be published on the Danger plugins site, you will need to have
  # the public interface documented. Danger uses [YARD](http://yardoc.org/)
  # for generating documentation from your plugin source, and you can verify
  # by running `danger plugins lint` or `bundle exec rake spec`.
  #
  # You should replace these comments with a public description of your library.
  #
  # @example Ensure people are well warned about merging on Mondays
  #
  #          my_plugin.warn_on_mondays
  #
  # @see  leonhartX/danger-eslint
  # @tags monday, weekends, time, rattata
  #
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

    # Lints javascript files.
    # Generates `errors` and `warnings` due to eslint's config.
    # Will try to send inline comment if supported(Github)
    #
    # @return  [void]
    #
    def lint
      bin = eslint_path
      raise 'eslint is not installed' unless bin
      files = filtering ? (git.modified_files - git.deleted_files) + git.added_files : Dir.glob('**/*')
      files
        .select { |f| f.end_with? '.js' }
        .map { |f| f.gsub("#{Dir.pwd}/", '') }
        .map { |f| run_lint(bin, f).first }
        .reject { |r| r['messages'].length.zero? }
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

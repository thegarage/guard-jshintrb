require 'guard/jshintrb/version'
require 'guard'
require 'guard/plugin'
require 'guard/watcher'
require 'jshintrb'
require 'json'

module Guard
  class Jshintrb < Plugin
    def initialize(options = {})
      super
      @options = {
        all_on_start: false,
        keep_failed: false
      }.merge(options)

      @jshint_options = JSON.load(File.read('.jshintrc'))
      @jshint_globals = @jshint_options.delete('globals') { Hash.new }
      @jshint_ignored = File.read('.jshintignore').split.collect { |pattern| Dir.glob(pattern) }.flatten

      @failed_paths = []
    end

    def start
      UI.info 'Guard::JSHintRB is running'
      run_all if @options[:all_on_start]
    end

    def reload
      @failed_paths = []
    end

    def run_all
      UI.info 'Running JSHint over all JS files.'
      paths = Watcher.match_files(self, Dir.glob(File.join('**', '*.js')))
      run_on_changes paths
    end

    def run_on_changes(paths)
      paths << @failed_paths if @options[:keep_failed]
      run paths.uniq
    end

    private

    def run(paths = [])
      paths -= @jshint_ignored
      total = 0
      paths.each do |path|
        warnings = ::Jshintrb.lint(File.read(path), @jshint_options, @jshint_globals.keys)
        warnings.compact!
        if !warnings.empty?
          UI.info "#{path} - #{warnings.size} Errors"
          warnings.each do |warning|
            UI.error "#{warning['reason']} - #{warning['line']}:#{warning['character']}"
            UI.warning " #{warning['evidence']}"
          end
          total += warnings.size
        end
      end
      UI.info "Guard::JSHintRB inspected #{paths.size} files, found #{total} errors."
    end
  end
end

#!/usr/bin/env ruby

require 'open3'
require 'shellwords'
require 'strscan'
require 'uri'

files = ARGV[0].shellsplit.flat_map { |path| Dir.glob(path) }
args = ARGV[1].shellsplit

raise "No files files specified." if files.empty?

def assert_rest(rest)
  raise "Failed to parse rest of output: #{rest}" unless rest.empty?
end

def check_file(file, args)
  Open3.popen3('aspell', 'pipe', *args) do |stdin, stdout, stderr|
    errors = []

    File.open(file, 'r').each_line.with_index do |line, i|
      next if line == "\n"

      stdin.print line

      if line.start_with?('%')
        next
      end

      loop do
        output = stdout.readline

        next if output.start_with?('@(#)')
        break if output == "\n"

        output = StringScanner.new(output)

        if type = output.scan(/(&|#|\*)/)
          if type == '*'
            output.skip(/\n/)
            next
          end

          output.skip(/\ /)
          word = output.scan(/[^\ \n]+/)
          output.skip(/\ /)
          if type == '&'
            suggestion_count = Integer(output.scan(/\d+/))
            output.skip(/\ /)
          else
            suggestion_count = 0
          end
          column = Integer(output.scan(/\d+/))

          suggestions = (0...suggestion_count).map { |i|
            output.skip(i.zero? ? /:/ : /,/)
            output.skip(/ /)

            output.scan(/[^,\n]+/)
          }

          output.skip(/\n/)

          errors << {
            word: word,
            line: i + 1,
            column: column,
            suggestions: suggestions,
          }
        end

        assert_rest(output.rest)
      end
    end

    stdin.close

    assert_rest(stdout.read)

    errors
  end
end

files.each do |file|
  errors = check_file(file, args)

  errors.each do |word:, line:, column:, suggestions:|
    puts "::error file=#{URI.escape(file)},line=#{line},col=#{column}::#{URI.escape("#{word}: #{suggestions.join(', ')}")}"
  end

  exit errors.empty? ? 0 : 1
end

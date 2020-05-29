#!/usr/bin/env ruby

require 'open3'
require 'shellwords'
require 'strscan'

files = ARGV[0].shellsplit.flat_map { |path| Dir.glob(path) }
args = ARGV[1].shellsplit

raise "No files files specified." if files.empty?

def escape(s)
  s.gsub(/\r/, '%0D')
   .gsub(/\n/, '%0A')
   .gsub(/]/, '%5D')
   .gsub(/;/, '%3B');
end

def assert_rest(rest)
  raise "Failed to parse rest of output: #{rest}" unless rest.empty?
end

def check_file(file, args)
  Open3.popen3('aspell', 'pipe', *args) do |stdin, stdout, stderr|
    errors = []

    extension = File.extname(file)
    code_block = false

    File.open(file, 'r').each_line.with_index do |line, i|
      if extension == '.tex'
        if line.match?(/^\s*\\begin{\s*lstlisting\s*}/)
          code_block = true
          next
        elsif line.match?(/^\s*\\end{\s*lstlisting\s*}/)
          code_block = false
          next
        elsif code_block
          next
        end
      end

      stdin.print '^'
      stdin.print line

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
            column: column - 1, # https://github.com/GNUAspell/aspell/issues/277
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
    message = <<~EOF
      Wrong spelling of “#{word}” found. Maybe you meant one of the following?

      #{suggestions.join(', ')}
    EOF

    puts "::error file=#{escape(file)},line=#{line},col=#{column}::#{escape(message)}"
  end

  exit errors.empty? ? 0 : 1
end
